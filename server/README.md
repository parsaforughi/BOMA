# BOMA Server (Railway)

بک‌اند اپ بوما — شامل OTP Auth، دیتابیس کاربران، پنل ادمین و API آپدیت اجباری.

## Deploy روی Railway

1. پروژه جدید بساز و ریپو را وصل کن.
2. **Root directory** را `server/` بگذار.
3. متغیرهای `.env.example` را در Railway تنظیم کن.
4. یک **Volume** بساز و آن را به مسیر `/data` وصل کن (برای SQLite).
5. Deploy کن و URL عمومی را بردار.

## متغیرهای محیطی

| متغیر | توضیح |
|-------|-------|
| `JWT_SECRET` | کلید رمزنگاری توکن — یک رشتهٔ تصادفی بلند |
| `ADMIN_USERNAME` | نام کاربری پنل ادمین (پیش‌فرض: admin) |
| `ADMIN_PASSWORD` | رمز پنل ادمین (پیش‌فرض: boma1234 — حتماً عوض کن) |
| `OTP_API_URL` | آدرس endpoint ایده‌آل پیام برای ارسال OTP |
| `OTP_API_KEY` | API Key ایده‌آل پیام |
| `DB_PATH` | مسیر فایل SQLite (پیش‌فرض: `/data/boma.db`) |
| `MIN_BUILD_NUMBER` | build پایین‌تر از این مجبور به آپدیت می‌شود |
| `LATEST_BUILD_NUMBER` | آخرین build استور |
| `LATEST_VERSION` | نسخه نمایشی |
| `FORCE_UPDATE` | true/false |
| `UPDATE_MESSAGE` | پیام صفحه آپدیت اجباری |
| `ANDROID_STORE_URL` | لینک Play Store |
| `IOS_STORE_URL` | لینک App Store |

## API Endpoints

### Auth
```
POST /api/auth/send-otp
Body: { "phone": "09123456789" }
→ { "ok": true }

POST /api/auth/verify-otp
Body: { "phone": "09123456789", "code": "12345" }
→ { "ok": true, "token": "jwt...", "user": { "id": 1, "phone": "09..." } }
```

### Version check
```
GET /api/app/version?platform=android&build=1
```

### Admin panel
```
GET /admin         (Basic Auth: ADMIN_USERNAME / ADMIN_PASSWORD)
GET /admin/api/users  (JSON)
```

### Health
```
GET /health → { "ok": true }
```

## Flutter build

```bash
flutter build apk --release \
  --dart-define=BOMA_API_BASE=https://YOUR-APP.up.railway.app \
  --dart-define=BOMA_VERSION_API=https://YOUR-APP.up.railway.app
```

اگر `BOMA_API_BASE` خالی باشد، OTP به صورت local mock عمل می‌کند (offline-safe برای dev).
