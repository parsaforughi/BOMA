const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const path = require('path');
const { initDb } = require('./src/db');
const authRoutes = require('./src/auth-routes');
const { router: adminRoutes } = require('./src/admin-routes');

const app = express();
const port = Number(process.env.PORT || 3000);

function envInt(name, fallback) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) ? value : fallback;
}

function envBool(name, fallback) {
  const raw = process.env[name];
  if (raw == null) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(String(raw).toLowerCase());
}

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'boma-api' });
});

app.get('/api/app/version', (req, res) => {
  const platform = String(req.query.platform || 'android').toLowerCase();
  const clientBuild = envInt(req.query.build, 0);

  const minBuildNumber = envInt('MIN_BUILD_NUMBER', 1);
  const latestBuildNumber = envInt('LATEST_BUILD_NUMBER', minBuildNumber);
  const latestVersion = process.env.LATEST_VERSION || '1.0.0';
  const forceUpdate = envBool('FORCE_UPDATE', true);
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

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

app.get('/admin', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

async function start() {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL is required. Add PostgreSQL on Railway.');
    process.exit(1);
  }
  await initDb();
  app.listen(port, () => {
    console.log(`BOMA API listening on :${port}`);
  });
}

start().catch((err) => {
  console.error('Failed to start:', err);
  process.exit(1);
});
