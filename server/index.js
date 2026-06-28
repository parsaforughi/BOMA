'use strict';

const express = require('express');
const path    = require('path');
const fs      = require('fs');
const Database = require('better-sqlite3');
const jwt     = require('jsonwebtoken');

const app  = express();
const PORT = Number(process.env.PORT || 3000);

// ═══════════════════════════════════════════════════════════
// DATABASE SETUP
// ═══════════════════════════════════════════════════════════
const DB_DIR  = process.env.DB_PATH ? path.dirname(process.env.DB_PATH) : path.join(__dirname, 'data');
const DB_FILE = process.env.DB_PATH || path.join(DB_DIR, 'boma.db');
fs.mkdirSync(DB_DIR, { recursive: true });

const db = new Database(DB_FILE);
db.pragma('journal_mode = WAL');

db.exec(`
  -- کاربران
  CREATE TABLE IF NOT EXISTS users (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    phone      TEXT    NOT NULL UNIQUE,
    fcm_token  TEXT,
    is_pro     INTEGER NOT NULL DEFAULT 0,
    pro_expire INTEGER,
    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    last_seen  INTEGER
  );

  -- کدهای OTP موقت
  CREATE TABLE IF NOT EXISTS otp_codes (
    phone      TEXT    NOT NULL PRIMARY KEY,
    code       TEXT    NOT NULL,
    expires_at INTEGER NOT NULL
  );

  -- آنالیتیکس روزانه
  CREATE TABLE IF NOT EXISTS daily_stats (
    date        TEXT    NOT NULL PRIMARY KEY,  -- YYYY-MM-DD
    opens       INTEGER NOT NULL DEFAULT 0,
    unique_users INTEGER NOT NULL DEFAULT 0
  );

  -- تنظیمات اپ (force update و سایر کانفیگ‌ها)
  CREATE TABLE IF NOT EXISTS app_config (
    key   TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL
  );

  -- لاگ نوتیفیکیشن‌های ارسال‌شده
  CREATE TABLE IF NOT EXISTS notifications (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    title      TEXT    NOT NULL,
    body       TEXT    NOT NULL,
    target     TEXT    NOT NULL DEFAULT 'all',
    sent_at    INTEGER NOT NULL DEFAULT (unixepoch()),
    sent_count INTEGER NOT NULL DEFAULT 0
  );
`);

// مقادیر پیش‌فرض app_config در صورت خالی بودن
const defaultConfig = {
  min_build_number:    '1',
  latest_build_number: '1',
  latest_version:      '1.0.0',
  force_update:        'false',
  update_message:      'نسخه جدید بوما منتشر شده. برای ادامه، اپ را به‌روزرسانی کنید.',
  android_store_url:   'https://play.google.com/store/apps/details?id=com.boma.app',
  ios_store_url:       'https://apps.apple.com',
};
for (const [k, v] of Object.entries(defaultConfig)) {
  db.prepare('INSERT OR IGNORE INTO app_config (key, value) VALUES (?, ?)').run(k, v);
}

function getConfig(key) {
  const row = db.prepare('SELECT value FROM app_config WHERE key = ?').get(key);
  return row ? row.value : defaultConfig[key] ?? null;
}
function setConfig(key, value) {
  db.prepare('INSERT OR REPLACE INTO app_config (key, value) VALUES (?, ?)').run(key, String(value));
}

// ═══════════════════════════════════════════════════════════
// CONSTANTS / ENV
// ═══════════════════════════════════════════════════════════
const JWT_SECRET   = process.env.JWT_SECRET    || 'boma_dev_secret_CHANGE_IN_PRODUCTION';
const ADMIN_USER   = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASS   = process.env.ADMIN_PASSWORD || 'boma1234';
const OTP_TTL      = 120; // seconds

// FCM v1 — service account JSON (as string in env var)
let FCM_SERVICE_ACCOUNT = null;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    FCM_SERVICE_ACCOUNT = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  }
} catch (e) {
  console.warn('FIREBASE_SERVICE_ACCOUNT parse error:', e.message);
}

// گرفتن OAuth2 access token از Google برای FCM v1
async function getFcmAccessToken() {
  if (!FCM_SERVICE_ACCOUNT) throw new Error('FIREBASE_SERVICE_ACCOUNT not configured');

  const { client_email, private_key, project_id } = FCM_SERVICE_ACCOUNT;
  const now = Math.floor(Date.now() / 1000);

  // ساخت JWT برای Google OAuth2
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    iss: client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  })).toString('base64url');

  const signingInput = `${header}.${payload}`;
  const { createSign } = require('crypto');
  const signer = createSign('RSA-SHA256');
  signer.update(signingInput);
  const signature = signer.sign(private_key, 'base64url');
  const assertion = `${signingInput}.${signature}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) throw new Error(`Token error: ${JSON.stringify(tokenData)}`);
  return { access_token: tokenData.access_token, project_id };
}

// ═══════════════════════════════════════════════════════════
// MIDDLEWARE
// ═══════════════════════════════════════════════════════════
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

function requireAdmin(req, res, next) {
  const auth  = req.headers.authorization || '';
  const [type, creds] = auth.split(' ');
  if (type === 'Basic' && creds) {
    const [u, p] = Buffer.from(creds, 'base64').toString('utf8').split(':');
    if (u === ADMIN_USER && p === ADMIN_PASS) return next();
  }
  res.set('WWW-Authenticate', 'Basic realm="BOMA Admin"');
  return res.status(401).send('Unauthorized');
}

function requireToken(req, res, next) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) return res.status(401).json({ ok: false, error: 'missing_token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ ok: false, error: 'invalid_token' });
  }
}

// ═══════════════════════════════════════════════════════════
// SMS / OTP
// ═══════════════════════════════════════════════════════════
async function sendOtpSms(phone, code) {
  const apiKey      = process.env.SMS_IR_API_KEY;
  const templateId  = process.env.SMS_IR_TEMPLATE_ID || '100000'; // ID قالب OTP در sms.ir

  if (apiKey) {
    // sms.ir Verify API
    const res = await fetch('https://api.sms.ir/v1/send/verify', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: JSON.stringify({
        mobile: phone,
        templateId: Number(templateId),
        parameters: [
          { name: 'Code', value: code },
        ],
      }),
    });
    const data = await res.json();
    if (!res.ok || data.status !== 1) {
      throw new Error(`sms.ir error: ${JSON.stringify(data)}`);
    }
    return;
  }

  // Dev fallback — کد رو توی لاگ نشون بده
  console.log(`[OTP DEV]  ${phone}  →  ${code}`);
}

// ═══════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════
function todayStr() {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD
}

function bumpDailyStats(userId) {
  const date = todayStr();
  const existing = db.prepare('SELECT date FROM daily_stats WHERE date = ?').get(date);
  if (!existing) {
    db.prepare('INSERT INTO daily_stats (date, opens, unique_users) VALUES (?, 1, 1)').run(date);
    return;
  }
  // کاربر را امروز دیده‌ایم؟
  const user = db.prepare('SELECT last_seen FROM users WHERE id = ?').get(userId);
  const todayStart = Math.floor(new Date(date + 'T00:00:00Z').getTime() / 1000);
  const seenToday = user && user.last_seen && user.last_seen >= todayStart;
  if (seenToday) {
    db.prepare('UPDATE daily_stats SET opens = opens + 1 WHERE date = ?').run(date);
  } else {
    db.prepare('UPDATE daily_stats SET opens = opens + 1, unique_users = unique_users + 1 WHERE date = ?').run(date);
  }
}

// ═══════════════════════════════════════════════════════════
// ROUTES — HEALTH
// ═══════════════════════════════════════════════════════════
app.get('/', (_req, res) => res.redirect('/admin'));
app.get('/health', (_req, res) => res.json({ ok: true, service: 'boma-server' }));

// ═══════════════════════════════════════════════════════════
// ROUTES — FORCE-UPDATE / VERSION
// ═══════════════════════════════════════════════════════════
app.get('/api/app/version', (req, res) => {
  const platform    = String(req.query.platform || 'android').toLowerCase();
  const clientBuild = parseInt(req.query.build, 10) || 0;

  const minBuild     = parseInt(getConfig('min_build_number'), 10)    || 1;
  const latestBuild  = parseInt(getConfig('latest_build_number'), 10) || 1;
  const latestVer    = getConfig('latest_version')   || '1.0.0';
  const forceUpdate  = getConfig('force_update') === 'true';
  const message      = getConfig('update_message');
  const androidUrl   = getConfig('android_store_url');
  const iosUrl       = getConfig('ios_store_url');

  const updateRequired = forceUpdate && clientBuild > 0 && clientBuild < minBuild;

  res.json({
    minBuildNumber:    minBuild,
    latestBuildNumber: latestBuild,
    latestVersion:     latestVer,
    forceUpdate,
    updateRequired,
    message,
    storeUrl:  platform === 'ios' ? iosUrl : androidUrl,
    storeUrls: { android: androidUrl, ios: iosUrl },
  });
});

// ═══════════════════════════════════════════════════════════
// ROUTES — AUTH
// ═══════════════════════════════════════════════════════════
app.post('/api/auth/send-otp', async (req, res) => {
  const phone = String(req.body.phone || '').trim();
  if (!/^09[0-9]{9}$/.test(phone)) {
    return res.status(400).json({ ok: false, error: 'invalid_phone' });
  }

  const code      = String(Math.floor(10000 + Math.random() * 90000));
  const expiresAt = Math.floor(Date.now() / 1000) + OTP_TTL;

  db.prepare(`
    INSERT INTO otp_codes (phone, code, expires_at) VALUES (?, ?, ?)
    ON CONFLICT(phone) DO UPDATE SET code = excluded.code, expires_at = excluded.expires_at
  `).run(phone, code, expiresAt);

  try {
    await sendOtpSms(phone, code);
    res.json({ ok: true });
  } catch (err) {
    console.error('OTP send failed:', err.message);
    res.status(502).json({ ok: false, error: 'sms_failed' });
  }
});

app.post('/api/auth/verify-otp', (req, res) => {
  const phone = String(req.body.phone || '').trim();
  const code  = String(req.body.code  || '').trim();

  if (!/^09[0-9]{9}$/.test(phone) || !/^[0-9]{4,6}$/.test(code)) {
    return res.status(400).json({ ok: false, error: 'invalid_input' });
  }

  const row = db.prepare('SELECT * FROM otp_codes WHERE phone = ?').get(phone);
  const now = Math.floor(Date.now() / 1000);

  if (!row || row.code !== code || row.expires_at < now) {
    return res.status(400).json({ ok: false, error: 'invalid_code' });
  }

  db.prepare('DELETE FROM otp_codes WHERE phone = ?').run(phone);

  db.prepare(`
    INSERT INTO users (phone, last_seen)
    VALUES (?, unixepoch())
    ON CONFLICT(phone) DO UPDATE SET last_seen = unixepoch()
  `).run(phone);

  const user  = db.prepare('SELECT * FROM users WHERE phone = ?').get(phone);
  const token = jwt.sign({ sub: String(user.id), phone: user.phone }, JWT_SECRET, { expiresIn: '365d' });

  bumpDailyStats(user.id);

  res.json({
    ok: true, token,
    user: {
      id:    user.id,
      phone: user.phone,
      isPro: user.is_pro === 1 && (!user.pro_expire || user.pro_expire > now),
    },
  });
});

// ═══════════════════════════════════════════════════════════
// ROUTES — ANALYTICS PING
// ═══════════════════════════════════════════════════════════

// بدون login — فقط open count (برای splash)
app.post('/api/analytics/open', (req, res) => {
  const today = new Date().toISOString().slice(0, 10);
  db.prepare(`
    INSERT INTO daily_stats (date, opens, unique_users)
    VALUES (?, 1, 0)
    ON CONFLICT(date) DO UPDATE SET opens = opens + 1
  `).run(today);
  res.json({ ok: true });
});

// با login — open + unique user tracking
app.post('/api/analytics/ping', requireToken, (req, res) => {
  const userId = req.user.sub;

  if (req.body.fcm_token) {
    db.prepare('UPDATE users SET fcm_token = ? WHERE id = ?').run(req.body.fcm_token, userId);
  }

  bumpDailyStats(userId);
  db.prepare('UPDATE users SET last_seen = unixepoch() WHERE id = ?').run(userId);

  res.json({ ok: true });
});

// ═══════════════════════════════════════════════════════════
// ROUTES — ADMIN API (JSON)
// ═══════════════════════════════════════════════════════════

// آمار کلی
app.get('/admin/api/stats', requireAdmin, (_req, res) => {
  const totalUsers  = db.prepare('SELECT COUNT(*) AS n FROM users').get().n;
  const newToday    = db.prepare(`SELECT COUNT(*) AS n FROM users WHERE date(created_at, 'unixepoch') = ?`).get(todayStr()).n;
  const activeMonth = db.prepare(`SELECT COUNT(*) AS n FROM users WHERE last_seen > unixepoch() - 2592000`).get().n; // 30 days
  const active5min  = db.prepare(`SELECT COUNT(*) AS n FROM users WHERE last_seen > unixepoch() - 300`).get().n;

  const daily = db.prepare(`SELECT date, opens, unique_users FROM daily_stats ORDER BY date DESC LIMIT 30`).all().reverse();

  res.json({ ok: true, totalUsers, newToday, activeMonth, active5min, daily });
});

// لیست کاربران
app.get('/admin/api/users', requireAdmin, (req, res) => {
  const page  = Math.max(1, parseInt(req.query.page, 10)  || 1);
  const limit = Math.min(100, parseInt(req.query.limit, 10) || 50);
  const offset = (page - 1) * limit;
  const total = db.prepare('SELECT COUNT(*) AS n FROM users').get().n;

  const users = db.prepare(`
    SELECT id, phone, is_pro, pro_expire,
           datetime(created_at, 'unixepoch', 'localtime') AS created_at,
           datetime(last_seen,  'unixepoch', 'localtime') AS last_seen
    FROM users ORDER BY id DESC LIMIT ? OFFSET ?
  `).all(limit, offset);

  res.json({ ok: true, total, page, limit, users });
});

// بروزرسانی تنظیمات force update
app.post('/admin/api/config', requireAdmin, (req, res) => {
  const allowed = ['min_build_number','latest_build_number','latest_version',
                   'force_update','update_message','android_store_url','ios_store_url'];
  for (const key of allowed) {
    if (req.body[key] !== undefined) setConfig(key, req.body[key]);
  }
  res.json({ ok: true });
});

// ارسال نوتیف‌کیشن از طریق FCM v1
app.post('/admin/api/notify', requireAdmin, async (req, res) => {
  const { title, body, target = 'all' } = req.body;
  if (!title || !body) return res.status(400).json({ ok: false, error: 'title and body required' });

  if (!FCM_SERVICE_ACCOUNT) {
    return res.status(503).json({ ok: false, error: 'FIREBASE_SERVICE_ACCOUNT not configured' });
  }

  let tokens = [];
  if (target === 'all') {
    tokens = db.prepare('SELECT fcm_token FROM users WHERE fcm_token IS NOT NULL').all().map(r => r.fcm_token);
  } else {
    const u = db.prepare('SELECT fcm_token FROM users WHERE phone = ?').get(target);
    if (u?.fcm_token) tokens = [u.fcm_token];
  }

  if (tokens.length === 0) {
    return res.json({ ok: true, sent: 0, message: 'no FCM tokens found' });
  }

  let totalSent = 0;
  try {
    const { access_token, project_id } = await getFcmAccessToken();
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${project_id}/messages:send`;

    // FCM v1 یک پیام در هر درخواست — concurrent برای سرعت
    const results = await Promise.allSettled(tokens.map(token =>
      fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: { title, body },
          },
        }),
      }).then(r => r.ok ? 1 : 0)
    ));

    totalSent = results.reduce((sum, r) => sum + (r.status === 'fulfilled' ? r.value : 0), 0);
  } catch (err) {
    console.error('FCM v1 error:', err.message);
    return res.status(500).json({ ok: false, error: err.message });
  }

  db.prepare(`INSERT INTO notifications (title, body, target, sent_count) VALUES (?, ?, ?, ?)`)
    .run(title, body, target, totalSent);

  res.json({ ok: true, sent: totalSent, total_tokens: tokens.length });
});

// تاریخچه نوتیف‌ها
app.get('/admin/api/notifications', requireAdmin, (_req, res) => {
  const rows = db.prepare(`
    SELECT *, datetime(sent_at, 'unixepoch', 'localtime') AS sent_at_local
    FROM notifications ORDER BY id DESC LIMIT 50
  `).all();
  res.json({ ok: true, notifications: rows });
});

// ═══════════════════════════════════════════════════════════
// ADMIN PANEL — HTML
// ═══════════════════════════════════════════════════════════
app.get('/admin', requireAdmin, (_req, res) => {
  res.send(ADMIN_HTML);
});

// ═══════════════════════════════════════════════════════════
// SERVER START
// ═══════════════════════════════════════════════════════════
app.listen(PORT, () => console.log(`BOMA server on :${PORT}`));

// ═══════════════════════════════════════════════════════════
// ADMIN HTML (inline — no separate file needed)
// ═══════════════════════════════════════════════════════════
const ADMIN_HTML = `<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>پنل مدیریت بوما</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:Tahoma,Arial,sans-serif;background:#0d1117;color:#c9d1d9;min-height:100vh}
a{color:inherit;text-decoration:none}
/* layout */
.sidebar{position:fixed;top:0;right:0;width:220px;height:100vh;background:#161b22;border-left:1px solid #21262d;display:flex;flex-direction:column;padding:24px 0}
.sidebar .logo{padding:0 20px 24px;font-size:18px;font-weight:700;color:#fff;border-bottom:1px solid #21262d;margin-bottom:16px}
.sidebar .logo span{color:#3b82f6}
.nav-item{padding:10px 20px;cursor:pointer;font-size:14px;border-radius:6px;margin:2px 8px;transition:.15s}
.nav-item:hover,.nav-item.active{background:#1f2937;color:#fff}
.main{margin-right:220px;padding:32px}
/* cards */
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:16px;margin-bottom:32px}
.card{background:#161b22;border:1px solid #21262d;border-radius:12px;padding:20px 24px}
.card .val{font-size:32px;font-weight:700;color:#3b82f6}
.card .lbl{font-size:13px;color:#8b949e;margin-top:6px}
/* table */
.tbl-wrap{background:#161b22;border:1px solid #21262d;border-radius:12px;overflow:hidden}
table{width:100%;border-collapse:collapse;font-size:13px}
th{padding:12px 16px;text-align:right;color:#8b949e;font-weight:600;border-bottom:1px solid #21262d;background:#0d1117}
td{padding:11px 16px;border-bottom:1px solid #21262d}
tr:last-child td{border-bottom:none}
tr:hover td{background:#1f2937}
/* form */
.section{background:#161b22;border:1px solid #21262d;border-radius:12px;padding:24px;margin-bottom:20px}
.section h3{font-size:15px;font-weight:600;color:#fff;margin-bottom:16px;padding-bottom:12px;border-bottom:1px solid #21262d}
.form-row{display:flex;align-items:center;gap:12px;margin-bottom:12px}
.form-row label{width:160px;font-size:13px;color:#8b949e;flex-shrink:0}
.form-row input,.form-row textarea,.form-row select{flex:1;background:#0d1117;border:1px solid #30363d;border-radius:6px;padding:8px 12px;color:#c9d1d9;font-size:13px;font-family:inherit}
.form-row input:focus,.form-row textarea:focus{outline:none;border-color:#3b82f6}
.form-row textarea{min-height:70px;resize:vertical}
.toggle{display:flex;align-items:center;gap:8px}
.toggle input[type=checkbox]{width:40px;height:22px;appearance:none;background:#30363d;border-radius:11px;cursor:pointer;transition:.2s;position:relative}
.toggle input[type=checkbox]:checked{background:#3b82f6}
.toggle input[type=checkbox]::after{content:'';position:absolute;top:3px;right:3px;width:16px;height:16px;background:#fff;border-radius:50%;transition:.2s}
.toggle input[type=checkbox]:checked::after{right:auto;left:3px}
.btn{padding:9px 20px;background:#3b82f6;color:#fff;border:none;border-radius:8px;font-size:13px;cursor:pointer;font-family:inherit;transition:.15s}
.btn:hover{background:#2563eb}
.btn.danger{background:#dc2626}
.btn.danger:hover{background:#b91c1c}
.btn.sm{padding:5px 12px;font-size:12px}
.tag{display:inline-block;padding:2px 10px;border-radius:20px;font-size:11px;font-weight:600}
.tag.pro{background:#065f46;color:#6ee7b7}
.tag.free{background:#1f2937;color:#6b7280}
/* chart */
.chart-wrap{height:180px;display:flex;align-items:flex-end;gap:4px;padding:0 4px}
.bar-col{display:flex;flex-direction:column;align-items:center;flex:1}
.bar{background:#3b82f6;border-radius:4px 4px 0 0;min-width:8px;width:100%;transition:.3s;cursor:default}
.bar:hover{background:#60a5fa}
.bar-label{font-size:9px;color:#6b7280;margin-top:4px;writing-mode:vertical-rl;transform:rotate(180deg);white-space:nowrap;max-height:50px;overflow:hidden}
/* tabs */
.tabs{display:flex;gap:8px;margin-bottom:24px;border-bottom:1px solid #21262d;padding-bottom:0}
.tab{padding:10px 18px;cursor:pointer;font-size:14px;border-bottom:2px solid transparent;margin-bottom:-1px;transition:.15s;color:#8b949e}
.tab.active{color:#3b82f6;border-bottom-color:#3b82f6}
.tab-pane{display:none}.tab-pane.active{display:block}
/* alerts */
.alert{padding:12px 16px;border-radius:8px;font-size:13px;margin-bottom:12px}
.alert.ok{background:#0f3d2a;border:1px solid #196b44;color:#6ee7b7}
.alert.err{background:#3d0f0f;border:1px solid #6b1919;color:#fca5a5}
.spinner{display:none;width:16px;height:16px;border:2px solid #374151;border-top-color:#3b82f6;border-radius:50%;animation:spin .6s linear infinite;margin-right:8px}
@keyframes spin{to{transform:rotate(360deg)}}
.flex{display:flex;align-items:center;gap:8px}
/* online dot */
.dot{width:8px;height:8px;border-radius:50%;background:#22c55e;display:inline-block;margin-left:6px;box-shadow:0 0 6px #22c55e}
</style>
</head>
<body>

<!-- Sidebar -->
<div class="sidebar">
  <div class="logo">بوما <span>Admin</span></div>
  <div class="nav-item active" onclick="showTab('dashboard')">📊 داشبورد</div>
  <div class="nav-item" onclick="showTab('users')">👥 کاربران</div>
  <div class="nav-item" onclick="showTab('update')">🔄 بروزرسانی اجباری</div>
  <div class="nav-item" onclick="showTab('push')">🔔 نوتیفیکیشن</div>
</div>

<!-- Main -->
<div class="main">

  <!-- DASHBOARD -->
  <div id="tab-dashboard" class="tab-pane active">
    <h2 style="font-size:20px;color:#fff;margin-bottom:24px">داشبورد</h2>
    <div class="cards" id="stat-cards">
      <div class="card"><div class="val" id="s-total">—</div><div class="lbl">کل کاربران</div></div>
      <div class="card"><div class="val" id="s-today">—</div><div class="lbl">ثبت‌نام امروز</div></div>
      <div class="card"><div class="val" id="s-month">—</div><div class="lbl">فعال ۳۰ روز اخیر</div></div>
      <div class="card"><div class="val" id="s-live"><span class="dot"></span><span id="s-live-num">—</span></div><div class="lbl">آنلاین الان (۵ دقیقه)</div></div>
    </div>
    <div class="section">
      <h3>بازدید روزانه (۳۰ روز اخیر)</h3>
      <div class="chart-wrap" id="chart"></div>
    </div>
  </div>

  <!-- USERS -->
  <div id="tab-users" class="tab-pane">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:20px">
      <h2 style="font-size:20px;color:#fff">کاربران</h2>
      <button class="btn sm" onclick="loadUsers()">↻ رفرش</button>
    </div>
    <div class="tbl-wrap">
      <table>
        <thead><tr><th>#</th><th>شماره</th><th>پلن</th><th>ثبت‌نام</th><th>آخرین بازدید</th></tr></thead>
        <tbody id="users-tbody"><tr><td colspan="5" style="text-align:center;padding:40px;color:#6b7280">در حال بارگذاری...</td></tr></tbody>
      </table>
    </div>
    <div id="users-pagination" style="margin-top:16px;display:flex;gap:8px"></div>
  </div>

  <!-- FORCE UPDATE -->
  <div id="tab-update" class="tab-pane">
    <h2 style="font-size:20px;color:#fff;margin-bottom:24px">تنظیمات بروزرسانی اجباری</h2>
    <div id="update-alert"></div>
    <div class="section">
      <h3>نسخه‌ها</h3>
      <div class="form-row"><label>حداقل بیلد قبول‌شده</label><input type="number" id="u-min-build" placeholder="1"></div>
      <div class="form-row"><label>آخرین بیلد</label><input type="number" id="u-latest-build" placeholder="1"></div>
      <div class="form-row"><label>آخرین نسخه</label><input type="text" id="u-latest-ver" placeholder="1.0.0"></div>
    </div>
    <div class="section">
      <h3>فعال‌سازی</h3>
      <div class="form-row">
        <label>بروزرسانی اجباری</label>
        <div class="toggle"><input type="checkbox" id="u-force"><label for="u-force" style="font-size:13px;cursor:pointer">فعال کردن force update</label></div>
      </div>
      <div class="form-row"><label>پیام نمایش‌داده‌شده</label><textarea id="u-message"></textarea></div>
    </div>
    <div class="section">
      <h3>لینک فروشگاه</h3>
      <div class="form-row"><label>Android (Play Store)</label><input type="url" id="u-android-url"></div>
      <div class="form-row"><label>iOS (App Store)</label><input type="url" id="u-ios-url"></div>
    </div>
    <div class="flex"><div class="spinner" id="u-spinner"></div><button class="btn" onclick="saveConfig()">💾 ذخیره تنظیمات</button></div>
  </div>

  <!-- PUSH NOTIFICATIONS -->
  <div id="tab-push" class="tab-pane">
    <h2 style="font-size:20px;color:#fff;margin-bottom:24px">ارسال نوتیفیکیشن</h2>
    <div id="push-alert"></div>
    <div class="section">
      <h3>پیام جدید</h3>
      <div class="form-row"><label>عنوان</label><input type="text" id="p-title" placeholder="عنوان نوتیف"></div>
      <div class="form-row"><label>متن</label><textarea id="p-body" placeholder="متن پیام..."></textarea></div>
      <div class="form-row">
        <label>ارسال به</label>
        <select id="p-target">
          <option value="all">همه کاربران</option>
          <option value="phone">شماره خاص</option>
        </select>
      </div>
      <div class="form-row" id="p-phone-row" style="display:none"><label>شماره موبایل</label><input type="text" id="p-phone" placeholder="09xxxxxxxxx" dir="ltr"></div>
      <div class="flex"><div class="spinner" id="p-spinner"></div><button class="btn" onclick="sendNotif()">📤 ارسال</button></div>
    </div>
    <div class="section">
      <h3>تاریخچه ارسال</h3>
      <div class="tbl-wrap">
        <table>
          <thead><tr><th>عنوان</th><th>متن</th><th>هدف</th><th>ارسال‌شده</th><th>زمان</th></tr></thead>
          <tbody id="notif-tbody"><tr><td colspan="5" style="text-align:center;padding:30px;color:#6b7280">در حال بارگذاری...</td></tr></tbody>
        </table>
      </div>
    </div>
  </div>

</div>

<script>
let _usersPage = 1;

// ─── NAV
function showTab(name) {
  document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  document.getElementById('tab-'+name).classList.add('active');
  event.currentTarget.classList.add('active');

  if (name === 'dashboard') loadDashboard();
  if (name === 'users')     loadUsers();
  if (name === 'update')    loadConfig();
  if (name === 'push')      loadNotifHistory();
}

// ─── DASHBOARD
async function loadDashboard() {
  const r = await fetch('/admin/api/stats').then(r=>r.json());
  document.getElementById('s-total').textContent = r.totalUsers.toLocaleString('fa');
  document.getElementById('s-today').textContent = r.newToday.toLocaleString('fa');
  document.getElementById('s-month').textContent = r.activeMonth.toLocaleString('fa');
  document.getElementById('s-live-num').textContent = r.active5min.toLocaleString('fa');

  // Bar chart
  const chart = document.getElementById('chart');
  chart.innerHTML = '';
  const max = Math.max(...r.daily.map(d=>d.opens), 1);
  r.daily.forEach(d => {
    const h = Math.max(4, Math.round((d.opens / max) * 160));
    chart.innerHTML += \`
      <div class="bar-col" title="\${d.date}: \${d.opens} بازدید">
        <div class="bar" style="height:\${h}px" title="\${d.opens} بازدید — \${d.unique_users} کاربر یکتا"></div>
        <div class="bar-label">\${d.date.slice(5)}</div>
      </div>\`;
  });
}

// ─── USERS
async function loadUsers(page=1) {
  _usersPage = page;
  const r = await fetch(\`/admin/api/users?page=\${page}&limit=50\`).then(r=>r.json());
  const tbody = document.getElementById('users-tbody');
  if (!r.users.length) {
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:40px;color:#6b7280">هیچ کاربری یافت نشد</td></tr>';
    return;
  }
  tbody.innerHTML = r.users.map(u => \`<tr>
    <td>\${u.id}</td>
    <td dir="ltr">\${u.phone}</td>
    <td><span class="tag \${u.is_pro ? 'pro' : 'free'}">\${u.is_pro ? 'پرو' : 'رایگان'}</span></td>
    <td>\${u.created_at||'—'}</td>
    <td>\${u.last_seen||'—'}</td>
  </tr>\`).join('');

  const pag = document.getElementById('users-pagination');
  const totalPages = Math.ceil(r.total / r.limit);
  pag.innerHTML = '';
  for (let p=1; p<=totalPages; p++) {
    pag.innerHTML += \`<button class="btn sm" style="\${p===page?'background:#1f2937':''}" onclick="loadUsers(\${p})">\${p}</button>\`;
  }
}

// ─── FORCE UPDATE CONFIG
async function loadConfig() {
  const r = await fetch('/api/app/version?platform=android&build=0').then(r=>r.json());
  document.getElementById('u-min-build').value    = r.minBuildNumber;
  document.getElementById('u-latest-build').value = r.latestBuildNumber;
  document.getElementById('u-latest-ver').value   = r.latestVersion;
  document.getElementById('u-force').checked       = r.forceUpdate;
  document.getElementById('u-message').value        = r.message;
  document.getElementById('u-android-url').value   = r.storeUrls.android;
  document.getElementById('u-ios-url').value        = r.storeUrls.ios;
}

async function saveConfig() {
  const spin = document.getElementById('u-spinner');
  spin.style.display = 'block';
  const body = {
    min_build_number:    document.getElementById('u-min-build').value,
    latest_build_number: document.getElementById('u-latest-build').value,
    latest_version:      document.getElementById('u-latest-ver').value,
    force_update:        document.getElementById('u-force').checked ? 'true' : 'false',
    update_message:      document.getElementById('u-message').value,
    android_store_url:   document.getElementById('u-android-url').value,
    ios_store_url:       document.getElementById('u-ios-url').value,
  };
  const r = await fetch('/admin/api/config', {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    body: JSON.stringify(body)
  }).then(r=>r.json());
  spin.style.display = 'none';
  const el = document.getElementById('update-alert');
  if (r.ok) {
    el.innerHTML = '<div class="alert ok">✅ تنظیمات ذخیره شد</div>';
  } else {
    el.innerHTML = '<div class="alert err">❌ خطا در ذخیره</div>';
  }
  setTimeout(() => el.innerHTML='', 3000);
}

// ─── PUSH NOTIFICATIONS
document.getElementById('p-target').addEventListener('change', function() {
  document.getElementById('p-phone-row').style.display = this.value === 'phone' ? 'flex' : 'none';
});

async function sendNotif() {
  const title  = document.getElementById('p-title').value.trim();
  const body   = document.getElementById('p-body').value.trim();
  const target = document.getElementById('p-target').value === 'phone'
    ? document.getElementById('p-phone').value.trim()
    : 'all';

  if (!title || !body) {
    document.getElementById('push-alert').innerHTML = '<div class="alert err">عنوان و متن الزامی است</div>';
    return;
  }

  const spin = document.getElementById('p-spinner');
  spin.style.display = 'block';

  const r = await fetch('/admin/api/notify', {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    body: JSON.stringify({ title, body, target })
  }).then(r=>r.json());

  spin.style.display = 'none';
  const el = document.getElementById('push-alert');
  if (r.ok) {
    el.innerHTML = \`<div class="alert ok">✅ \${r.sent} نوتیف ارسال شد از \${r.total_tokens} دستگاه</div>\`;
    loadNotifHistory();
  } else {
    el.innerHTML = \`<div class="alert err">❌ \${r.error || 'خطا در ارسال'}</div>\`;
  }
  setTimeout(() => el.innerHTML='', 5000);
}

async function loadNotifHistory() {
  const r = await fetch('/admin/api/notifications').then(r=>r.json());
  const tbody = document.getElementById('notif-tbody');
  if (!r.notifications.length) {
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:30px;color:#6b7280">هنوز نوتیفی ارسال نشده</td></tr>';
    return;
  }
  tbody.innerHTML = r.notifications.map(n => \`<tr>
    <td>\${n.title}</td>
    <td>\${n.body}</td>
    <td>\${n.target === 'all' ? 'همه' : n.target}</td>
    <td>\${n.sent_count}</td>
    <td>\${n.sent_at_local||'—'}</td>
  </tr>\`).join('');
}

// ─── INIT
loadDashboard();
setInterval(loadDashboard, 30000); // رفرش هر ۳۰ ثانیه
</script>
</body>
</html>`;
