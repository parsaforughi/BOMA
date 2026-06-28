# BOMA Server (Railway)

بک‌اند اپ بوما — OTP Auth، آنالیتیکس، پنل ادمین، force update و push notification.

## Deploy روی Railway

1. پروژه جدید بساز و ریپو را وصل کن.
2. **Root directory** را `server` بگذار.
3. متغیرهای زیر را در Railway تنظیم کن.
4. یک **Volume** بساز و به مسیر `/app/data` وصل کن (برای SQLite).
5. متغیر `DB_PATH=/app/data/boma.db` را اضافه کن.
6. Deploy کن و URL عمومی را بردار.

## متغیرهای محیطی

| متغیر | توضیح |
|-------|-------|
| `JWT_SECRET` | کلید رمزنگاری توکن — یک رشته تصادفی بلند |
| `ADMIN_USERNAME` | نام کاربری پنل ادمین (پیش‌فرض: admin) |
| `ADMIN_PASSWORD` | ⚠️ حتماً عوض کن (پیش‌فرض: boma1234) |
| `OTP_API_URL` | آدرس endpoint ارسال SMS |
| `OTP_API_KEY` | API Key سرویس SMS |
| `FCM_SERVER_KEY` | Firebase server key برای push notification |
| `DB_PATH` | مسیر فایل SQLite (پیش‌فرض: `./data/boma.db`) |

## API Endpoints

```
GET  /health
GET  /api/app/version?platform=android&build=5
POST /api/auth/send-otp        { phone }
POST /api/auth/verify-otp      { phone, code }
POST /api/analytics/ping       Authorization: Bearer <token>  { fcm_token? }
GET  /admin                    (Basic Auth)
```

## پنل ادمین (/admin)

- **داشبورد** — آمار کاربران، بازدید روزانه
- **کاربران** — لیست کامل کاربران
- **بروزرسانی اجباری** — کنترل force update بدون redeploy
- **نوتیفیکیشن** — ارسال push به همه یا شماره خاص

## Flutter build

```bash
flutter build apk --release \
  --dart-define=BOMA_API_BASE=https://YOUR-APP.up.railway.app
```
