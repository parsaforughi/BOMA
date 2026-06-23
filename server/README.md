# BOMA API (Railway)

Backend for BOMA: OTP authentication, user database, admin panel, and app version checks.

## Deploy on Railway

1. Create a project on [Railway](https://railway.app) and connect this repo.
2. Set the **root directory** to `server/`.
3. Add a **PostgreSQL** database to the project.
4. Copy `DATABASE_URL` from Postgres into the API service variables.
5. Set the variables below (see `.env.example`).
6. Deploy and copy the public URL, e.g. `https://boma-api.up.railway.app`.

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string from Railway |
| `JWT_SECRET` | Yes | Secret for user auth tokens |
| `ADMIN_USERNAME` | Yes | Admin panel login |
| `ADMIN_PASSWORD` | Yes | Admin panel password |
| `SMS_PROVIDER` | Yes | `kavenegar`, `smsir`, or `console` (dev) |
| `KAVENEGAR_API_KEY` | If Kavenegar | API key from kavenegar.com |
| `KAVENEGAR_TEMPLATE` | If Kavenegar | Verify lookup template name |
| `SMSIR_API_KEY` | If SMS.ir | API key from sms.ir |
| `SMSIR_TEMPLATE_ID` | If SMS.ir | Verify template ID |
| `MIN_BUILD_NUMBER` | No | Force-update threshold |
| `LATEST_VERSION` | No | Display version string |

## API

### Health
`GET /health`

### Send OTP
`POST /api/auth/send-otp`
```json
{ "phone": "09123456789" }
```

### Verify OTP
`POST /api/auth/verify-otp`
```json
{ "phone": "09123456789", "code": "1234" }
```
Returns `{ token, user }`.

### App version
`GET /api/app/version?platform=android&build=1`

## Admin panel

Open `https://YOUR-APP.up.railway.app/admin` and sign in with `ADMIN_USERNAME` / `ADMIN_PASSWORD`.

You can see all registered users, search by phone, and view signup/login stats.

## Flutter client

```bash
flutter run \
  --dart-define=BOMA_API=https://YOUR-APP.up.railway.app
```

`BOMA_API` is used for both auth and version checks.

## SMS setup

### Kavenegar
1. Create a verify lookup template named e.g. `boma` with token `%token`.
2. Set `SMS_PROVIDER=kavenegar`, `KAVENEGAR_API_KEY`, `KAVENEGAR_TEMPLATE`.

### SMS.ir
1. Create a verify template with parameter `CODE`.
2. Set `SMS_PROVIDER=smsir`, `SMSIR_API_KEY`, `SMSIR_TEMPLATE_ID`.

### Development
Set `SMS_PROVIDER=console` and `DEV_OTP_RESPONSE=true` — OTP codes are logged and returned in the API response.
