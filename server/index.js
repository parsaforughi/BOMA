const express = require('express');

const app = express();
const port = Number(process.env.PORT || 3000);

// Railway env vars — only for force-update control:
// MIN_BUILD_NUMBER, LATEST_BUILD_NUMBER, LATEST_VERSION, FORCE_UPDATE,
// UPDATE_MESSAGE, ANDROID_STORE_URL, IOS_STORE_URL

function envInt(name, fallback) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) ? value : fallback;
}

function envBool(name, fallback) {
  const raw = process.env[name];
  if (raw == null) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(String(raw).toLowerCase());
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'boma-version-api' });
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

app.listen(port, () => {
  console.log(`BOMA version API listening on :${port}`);
});
