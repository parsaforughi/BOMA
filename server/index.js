const express = require('express');
const path = require('path');
const Database = require('better-sqlite3');
const jwt = require('jsonwebtoken');

const app = express();
const port = Number(process.env.PORT || 3000);

// ─── Database ─────────────────────────────────────────────────────────────────
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'data', 'boma.db');
const fs = require('fs');
fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });

const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    phone      TEXT    NOT NULL UNIQUE,
    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
    last_login INTEGER
  );
  CREATE TABLE IF NOT EXISTS otp_codes (
    phone      TEXT    NOT NULL,
    code       TEXT    NOT NULL,
    expires_at INTEGER NOT NULL,
    PRIMARY KEY (phone)
  );
`);

// ─── Config helpers ────────────────────────────────────────────────────────────
const JWT_SECRET = process.env.JWT_SECRET || 'boma_dev_secret_change_in_prod';
const OTP_TTL_SECONDS = 120;
const ADMIN_USER = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASS = process.env.ADMIN_PASSWORD || 'boma1234';

function envInt(name, fallback) {
  const v = Number(process.env[name]);
  return Number.isFinite(v) ? v : fallback;
}
function envBool(name, fallback) {
  const raw = process.env[name];
  if (raw == null) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(String(raw).toLowerCase());
}

// ─── OTP sender ────────────────────────────────────────────────────────────────
// When OTP_API_URL and OTP_API_KEY are set, calls the real SMS gateway.
// Otherwise logs the code to console (dev / staging mode).
async function sendOtpSms(phone, code) {
  const apiUrl = process.env.OTP_API_URL;
  const apiKey = process.env.OTP_API_KEY;

  if (apiUrl && apiKey) {
    // ایده‌آل پیام integration — adjust body fields to match their docs
    const res = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: JSON.stringify({
        receptor: phone,
        token: code,
      }),
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`OTP gateway error ${res.status}: ${text}`);
    }
    return true;
  }

  // Dev fallback — print to console
  console.log(`[OTP DEV] ${phone} → ${code}`);
  return true;
}

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

function requireAdmin(req, res, next) {
  const auth = req.headers.authorization || '';
  const [type, creds] = auth.split(' ');
  if (type === 'Basic') {
    const [u, p] = Buffer.from(creds, 'base64').toString().split(':');
    if (u === ADMIN_USER && p === ADMIN_PASS) return next();
  }
  res.set('WWW-Authenticate', 'Basic realm="BOMA Admin"');
  res.status(401).send('Unauthorized');
}

// ─── Health ────────────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'boma-server' });
});

// ─── Force-update API ──────────────────────────────────────────────────────────
app.get('/api/app/version', (req, res) => {
  const platform = String(req.query.platform || 'android').toLowerCase();
  const clientBuild = envInt(req.query.build, 0);

  const minBuildNumber = envInt('MIN_BUILD_NUMBER', 1);
  const latestBuildNumber = envInt('LATEST_BUILD_NUMBER', minBuildNumber);
  const latestVersion = process.env.LATEST_VERSION || '1.0.0';
  const forceUpdate = envBool('FORCE_UPDATE', false);
  const message =
    process.env.UPDATE_MESSAGE ||
    'نسخه جدید بوما منتشر شده. برای ادامه، اپ را به‌روزرسانی کنید.';

  const storeUrls = {
    android:
      process.env.ANDROID_STORE_URL ||
      'https://play.google.com/store/apps/details?id=com.boma.app',
    ios: process.env.IOS_STORE_URL || 'https://apps.apple.com',
  };

  const updateRequired =
    forceUpdate && clientBuild > 0 && clientBuild < minBuildNumber;

  res.json({
    minBuildNumber,
    latestBuildNumber,
    latestVersion,
    forceUpdate,
    updateRequired,
    message,
    storeUrl: platform === 'ios' ? storeUrls.ios : storeUrls.android,
    storeUrls,
  });
});

// ─── Auth: send OTP ────────────────────────────────────────────────────────────
app.post('/api/auth/send-otp', async (req, res) => {
  const phone = String(req.body.phone || '').trim();
  if (!/^09[0-9]{9}$/.test(phone)) {
    return res.status(400).json({ ok: false, error: 'invalid_phone' });
  }

  const code = String(Math.floor(10000 + Math.random() * 90000)); // 5 digits
  const expiresAt = Math.floor(Date.now() / 1000) + OTP_TTL_SECONDS;

  db.prepare(`
    INSERT INTO otp_codes (phone, code, expires_at)
    VALUES (?, ?, ?)
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

// ─── Auth: verify OTP ──────────────────────────────────────────────────────────
app.post('/api/auth/verify-otp', (req, res) => {
  const phone = String(req.body.phone || '').trim();
  const code = String(req.body.code || '').trim();

  if (!/^09[0-9]{9}$/.test(phone) || !/^[0-9]{4,6}$/.test(code)) {
    return res.status(400).json({ ok: false, error: 'invalid_input' });
  }

  const row = db.prepare('SELECT * FROM otp_codes WHERE phone = ?').get(phone);
  const now = Math.floor(Date.now() / 1000);

  if (!row || row.code !== code || row.expires_at < now) {
    return res.status(400).json({ ok: false, error: 'invalid_code' });
  }

  // Consume code
  db.prepare('DELETE FROM otp_codes WHERE phone = ?').run(phone);

  // Upsert user
  db.prepare(`
    INSERT INTO users (phone, last_login)
    VALUES (?, unixepoch())
    ON CONFLICT(phone) DO UPDATE SET last_login = unixepoch()
  `).run(phone);

  const user = db.prepare('SELECT * FROM users WHERE phone = ?').get(phone);

  const token = jwt.sign(
    { sub: String(user.id), phone: user.phone },
    JWT_SECRET,
    { expiresIn: '365d' }
  );

  res.json({ ok: true, token, user: { id: user.id, phone: user.phone } });
});

// ─── Admin panel ───────────────────────────────────────────────────────────────
app.get('/admin', requireAdmin, (_req, res) => {
  const users = db.prepare(`
    SELECT id, phone,
           datetime(created_at, 'unixepoch', 'localtime') AS created_at,
           datetime(last_login,  'unixepoch', 'localtime') AS last_login
    FROM users ORDER BY id DESC
  `).all();

  const total = users.length;

  const rows = users.map(u => `
    <tr>
      <td>${u.id}</td>
      <td dir="ltr">${u.phone}</td>
      <td>${u.created_at || '—'}</td>
      <td>${u.last_login || '—'}</td>
    </tr>`).join('');

  res.send(`<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>پنل مدیریت بوما</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: Tahoma, Arial, sans-serif; background: #0f1626; color: #e0e6f0; min-height: 100vh; }
    header { background: #1a2744; padding: 20px 32px; display: flex; align-items: center; gap: 16px; border-bottom: 1px solid #2a3a60; }
    header h1 { font-size: 20px; font-weight: 700; color: #fff; }
    header .badge { background: #2563eb; color: #fff; border-radius: 20px; padding: 3px 14px; font-size: 13px; }
    main { padding: 32px; }
    .stat { display: inline-block; background: #1a2744; border-radius: 12px; padding: 20px 32px; margin-bottom: 28px; }
    .stat .num { font-size: 36px; font-weight: 700; color: #60a5fa; }
    .stat .label { font-size: 14px; color: #94a3b8; margin-top: 4px; }
    table { width: 100%; border-collapse: collapse; background: #1a2744; border-radius: 12px; overflow: hidden; }
    thead { background: #162035; }
    th { padding: 14px 18px; text-align: right; font-size: 13px; color: #94a3b8; font-weight: 600; }
    td { padding: 13px 18px; border-top: 1px solid #1e2d4a; font-size: 14px; }
    tr:hover td { background: #1e2d4a; }
    .empty { text-align: center; padding: 60px; color: #64748b; font-size: 16px; }
    .refresh { float: left; background: #2563eb; color: #fff; border: none; border-radius: 8px; padding: 8px 20px; font-size: 14px; cursor: pointer; text-decoration: none; }
    .refresh:hover { background: #1d4ed8; }
  </style>
</head>
<body>
  <header>
    <h1>پنل مدیریت بوما</h1>
    <span class="badge">BOMA Admin</span>
    <a class="refresh" href="/admin">↻ رفرش</a>
  </header>
  <main>
    <div class="stat">
      <div class="num">${total}</div>
      <div class="label">کاربر ثبت‌نام‌شده</div>
    </div>
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>شماره موبایل</th>
          <th>تاریخ ثبت‌نام</th>
          <th>آخرین ورود</th>
        </tr>
      </thead>
      <tbody>
        ${rows || '<tr><td colspan="4" class="empty">هنوز کاربری ثبت‌نام نکرده</td></tr>'}
      </tbody>
    </table>
  </main>
</body>
</html>`);
});

// ─── Admin: users JSON API ─────────────────────────────────────────────────────
app.get('/admin/api/users', requireAdmin, (_req, res) => {
  const users = db.prepare(`
    SELECT id, phone,
           datetime(created_at, 'unixepoch') AS created_at,
           datetime(last_login,  'unixepoch') AS last_login
    FROM users ORDER BY id DESC
  `).all();
  res.json({ ok: true, total: users.length, users });
});

// ─── Start ─────────────────────────────────────────────────────────────────────
app.listen(port, () => {
  console.log(`BOMA server listening on :${port}`);
});
