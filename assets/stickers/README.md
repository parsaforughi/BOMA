# استیکرها

فایل‌های PNG استیکر را داخل همین پوشه یا پوشه‌های زیرش (مثل Arrow، Emoji، Frame، Like، Memes، Nowruz، Sale، Social Media) قرار بده.

- **فرمت:** PNG
- **سایز پیشنهادی:** حدود ۲۰۰×۲۰۰ تا ۴۰۰×۴۰۰ پیکسل

لیست استیکرها از روی فایل‌های موجود ساخته می‌شود. اگر استیکر جدید اضافه کردی، در `pubspec.yaml` زیر `assets` پوشهٔ جدید را اضافه کن و در `lib/models/sticker_item.dart` لیست مسیرها را با دستور زیر دوباره بساز:

```bash
find assets/stickers -name '*.png' -type f | sort
```
