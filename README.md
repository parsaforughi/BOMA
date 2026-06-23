# Boma - بما

Persian text-styling and story-creation app built with Flutter.

## Features

- **40+ Persian Fonts**: Vazir, Shabnam, Sahel, Samim, IranNastaliq, Lalezar, and more
- **Text Effects**: Stroke, shadow, bubble, gradient, and preset styles
- **Color Picker**: Text and background color customization with gradient support
- **Stickers**: Drag, resize, and rotate stickers on your canvas
- **Image Export**: Save to gallery, share to Instagram/WhatsApp/Telegram
- **Version 1 Ready**: All premium features are currently free (no payment required)
- **Force Update Control**: Remote version check via Railway API
- **Multi-language**: Persian (Farsi), Arabic, English
- **RTL Support**: Full right-to-left layout for Persian and Arabic
- **Dark Theme**: Modern dark UI matching Figma design

## Getting Started

### Prerequisites

- Flutter SDK >= 3.2.0
- Android Studio / Xcode
- Dart SDK

### Setup

```bash
# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run on Android
flutter run

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Project Structure

```
lib/
  main.dart              # Entry point
  app.dart               # App widget with router and theme
  theme/                 # App theme and colors
  l10n/                  # Localization ARB files (fa, ar, en)
  models/                # Data models
  services/              # Business logic and state management
  screens/               # All app screens
    splash/              # Splash screen
    login/               # Phone login
    otp/                 # OTP verification
    home/                # Main editor screen
    settings/            # App settings
    premium/             # Premium subscription
    purchase/            # Payment flow
  widgets/               # Reusable widgets
    text_canvas.dart     # Main text rendering canvas
    toolbar.dart         # Bottom toolbar
    font_picker.dart     # Font selection panel
    style_picker.dart    # Text style/effect panel
    color_picker.dart    # Text color picker
    bg_color_picker.dart # Background color picker
    sticker_picker.dart  # Sticker selection panel
  utils/                 # Utility functions
```

## Backend (Railway)

فقط پوشه `server/` روی Railway دیپلوی می‌شود — **یک API کوچک برای آپدیت اجباری**. وب‌اپ یا بک‌اند کامل لازم نیست.

```bash
flutter build apk --release \
  --dart-define=BOMA_VERSION_API=https://YOUR-APP.up.railway.app
```

برای فعال کردن آپدیت اجباری، `MIN_BUILD_NUMBER` را روی Railway بالا ببر.

## State Management

Uses **Riverpod** for state management with the following providers:

- `authProvider` - Authentication state
- `canvasProvider` - Text canvas state (text, font, colors, effects, stickers)
- `fontProvider` - Font selection and favorites
- `localeProvider` - App language/locale

## Assets

- `assets/fonts/` - 40+ Persian font files
- `assets/stickers/` - 10 sticker PNGs
- `assets/icons/` - SVG and PNG icons
- `assets/images/` - Splash and app icon images
