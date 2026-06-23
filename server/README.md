# BOMA Version API (Railway)

فقط برای **کنترل آپدیت اجباری** اپ موبایل. نه وب‌اپ، نه OTP، نه دیتابیس.

## Deploy روی Railway

1. پروژه جدید بساز و ریپو را وصل کن.
2. **Root directory** را `server/` بگذار.
3. متغیرهای `.env.example` را ست کن.
4. Deploy کن و URL عمومی را بردار.

## متغیرهای مهم

| متغیر | مثال | توضیح |
|-------|------|-------|
| `MIN_BUILD_NUMBER` | `2` | buildهای پایین‌تر باید آپدیت کنند |
| `LATEST_BUILD_NUMBER` | `2` | آخرین build استور |
| `LATEST_VERSION` | `1.0.1` | نسخه نمایشی |
| `FORCE_UPDATE` | `true` | بلاک کردن نسخه‌های قدیمی |
| `UPDATE_MESSAGE` | متن فارسی | پیام صفحه آپدیت |
| `ANDROID_STORE_URL` | لینک Play Store | |
| `IOS_STORE_URL` | لینک App Store | |

## فعال کردن آپدیت اجباری

1. نسخه جدید را در استور منتشر کن و `pubspec.yaml` را بالا ببر، مثلاً `1.0.1+2`.
2. روی Railway: `MIN_BUILD_NUMBER=2` و `LATEST_VERSION=1.0.1`.
3. کاربران با build `1` صفحه آپدیت اجباری می‌بینند.

## API

`GET /api/app/version?platform=android&build=1`

## Flutter

```bash
flutter build apk --release \
  --dart-define=BOMA_VERSION_API=https://YOUR-APP.up.railway.app
```

اگر `BOMA_VERSION_API` خالی باشد، چک آپدیت انجام نمی‌شود (offline-safe).
