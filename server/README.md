# BOMA Server

Companion process for OTP auth, analytics, an admin panel, force update, and push notification.

## Deploy

1. Create a new project and connect this repo.
2. Set the **root directory** to `server`.
3. Set the environment variables below.
4. Attach a volume at `/app/data` (SQLite).
5. Set `DB_PATH=/app/data/boma.db`.
6. Deploy and copy the public URL.

## Environment

| Variable | Notes |
|----------|-------|
| `JWT_SECRET` | Token signing key — a long random string |
| `ADMIN_USERNAME` | Admin panel username (default: admin) |
| `ADMIN_PASSWORD` | Change this (default: boma1234) |
| `OTP_API_URL` | SMS send endpoint |
| `OTP_API_KEY` | SMS API key |
| `FCM_SERVER_KEY` | Firebase server key for push notification |
| `DB_PATH` | SQLite file path (default: `./data/boma.db`) |

## API endpoints

```
GET  /health
GET  /api/app/version?platform=android&build=5
POST /api/auth/send-otp        { phone }
POST /api/auth/verify-otp      { phone, code }
POST /api/analytics/ping       Authorization: Bearer <token>  { fcm_token? }
GET  /admin                    (Basic Auth)
```

## Admin panel (`/admin`)

- **Dashboard** — users, daily opens
- **Users** — full user list
- **Force update** — min build without a redeploy
- **Notification** — push to everyone or to one phone

## Flutter build

```bash
flutter build apk --release \
  --dart-define=BOMA_API_BASE=https://YOUR-APP.up.railway.app
```
