import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Canvas / Background ──────────────────────────────────────────
  static const Color canvasBlue = Color(0xFF324F9D); // r:0.196 g:0.310 b:0.616
  static const Color background = Color(0xFF1E1E1E);

  // ── Toolbar ──────────────────────────────────────────────────────
  static const Color toolbarBg = Color(0xFF262626); // #262626
  static const Color toolbarActiveBg = Color(0xFF393939); // #393939
  static const Color toolbarInactiveIcon = Color(0xFF8D8D8D); // #8D8D8D

  // ── Button backgrounds ───────────────────────────────────────────
  static const Color buttonDark = Color(0x99002032); // #002032 @ 60% opacity
  static const Color buttonDarkLight = Color(0x66002032); // #002032 @ 40% opacity
  static const Color buttonDarkLighter = Color(0x33002032); // #002032 @ 20% opacity
  static const Color glassWhite30 = Color(0x4DFFFFFF); // white @ 30%
  static const Color glassWhite10 = Color(0x1AFFFFFF); // white @ 10%
  static const Color glassGrey20 = Color(0x33CCCCCC); // grey @ 20% (chips)

  // ── Selected font card ───────────────────────────────────────────
  static const Color fontCardSelected = Color(0xFF0068B3); // solid blue bg

  // ── Slider / accent ──────────────────────────────────────────────
  static const Color sliderBlue = Color(0xFF0095FD); // slider thumb blue
  static const Color keyboardBlue = Color(0xFF6795FF); // keyboard enter

  // ── Surface / sheets ─────────────────────────────────────────────
  static const Color surface = Color(0xFF262626);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color cardBackground = Color(0xFF303030);
  static const Color sheetBg = Color(0xBF262626); // #262626 @ 75%

  // ── Blue accent colors ───────────────────────────────────────────
  static const Color blueLogo = Color(0xFF1759B4);
  static const Color blueBackground = Color(0xFF1A73EC);
  static const Color blueAccent = Color(0xFF0054E9);
  static const Color blueLight = Color(0xFF4D8DFF);

  // ── Icon/badge colors ────────────────────────────────────────────
  static const Color bgIcon = Color(0xFF3A3A3A);
  static const Color plusGreen = Color(0xFF2DD55B);
  static const Color plusDarkBlue = Color(0xFF0163AA);
  static const Color plusCyan = Color(0xFF46B1FF);
  static const Color plusPro = Color(0xFF6030FF);

  // ── Text colors ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textHint = Color(0xFF606060);
  static const Color textDark = Color(0xFF101111); // dark text on white bg

  // ── Drag indicator ───────────────────────────────────────────────
  static const Color dragIndicator = Color(0xFFE0E0E0); // #E0E0E0

  // ── Status colors ────────────────────────────────────────────────
  static const Color success = Color(0xFF2DD55B);
  static const Color warning = Color(0xFFFFC409);
  static const Color error = Color(0xFFC5000F);
  static const Color errorLight = Color(0xFFFA4D56);

  // ── Border colors ────────────────────────────────────────────────
  static const Color border = Color(0xFF404040);
  static const Color borderLight = Color(0xFF505050);
  static const Color borderFocus = Color(0xFF1A73EC);
  static const Color borderWhite = Color(0xFFFFFFFF);
  static const Color borderGrey = Color(0xFFC6C6C6);

  // ── Overlay ──────────────────────────────────────────────────────
  static const Color overlay25 = Color(0x40000000); // black @ 25%
  static const Color overlay = Color(0xBF262626); // #262626bf
  static const Color overlayDark = Color(0xCC000000);

  // ── Gradient presets ─────────────────────────────────────────────
  static const List<Color> blueGradient = [
    Color(0xFF1759B4),
    Color(0xFF1A73EC),
  ];

  // ── Background color circles (from Figma Home-1) ────────────────
  static const List<Color> bgColorCircles = [
    Color(0xFF004144), // teal
    Color(0xFF5E2900), // brown
    Color(0xFFA6C8FF), // lavender (gradient approx)
    Color(0xFF9EF0BA), // cyan-green (gradient approx)
    Color(0xFFFF7EB6), // pink
    Color(0xFF491D8B), // purple
    Color(0xFF6FDC8C), // green
    Color(0xFF78A9FF), // blue-cyan (gradient approx)
    Color(0xFFBA4E00), // orange
    Color(0xFF8E6A00), // gold
    Color(0xFF004A80), // dark blue
    Color(0xFFFFB3B8), // light pink
    Color(0xFF4589FF), // blue
    Color(0xFFFFB784), // peach
    Color(0xFF9F1853), // magenta
    Color(0xFFA21F1F), // red
    Color(0xFFEB6200), // orange
    Color(0xFFF1C21B), // yellow
    Color(0xFF198038), // green
    Color(0xFF0F62FE), // blue
    Color(0xFF8D8D8D), // grey
    Color(0xFF0F0F0F), // near-black
    Color(0xFFFFFFFF), // white
  ];

  // ── Background gradient circles ──────────────────────────────────
  static const List<List<Color>> bgGradientCircles = [
    [Color(0xFF0D9066), Color(0xFF029A23)], // teal-green
    [Color(0xFF3F2B96), Color(0xFFA8C0FF)], // purple-lavender
  ];

  /// رنگ‌های ثابت پس‌زمینه برای مربع بالا (بدون نارنجی و بنفش که گرادیان هستند)
  static const List<Color> topBarBackgroundColors = [
    Color(0xFF324F9D), // Blue Logo
    Color(0xFF636665), // Toosi (grey)
    Color(0xFF009D9A), // Sabz (teal)
    Color(0xFF4589FF), // Abi (blue)
    Color(0xFF101111), // Black
  ];

  /// Orange: linear-gradient(180.29deg, #F53900 -6.64%, #FFA617 45.4%, #A92807 117.72%)
  static const List<Color> topBarOrangeGradient = [
    Color(0xFFF53900),
    Color(0xFFFFA617),
    Color(0xFFA92807),
  ];
  static const List<double> topBarOrangeGradientStops = [0.0, 0.454, 1.0];

  /// Banafsh: linear-gradient(181.09deg, #FF1279 -5.27%, rgba(167,0,125,0.58) 57.05%, rgba(195,42,255,0.5) 109.02%)
  static const List<Color> topBarBanafshGradient = [
    Color(0xFFFF1279),
    Color(0x94A7007D), // rgba(167,0,125,0.58)
    Color(0x80C32AFF), // rgba(195,42,255,0.5)
  ];
  static const List<double> topBarBanafshGradientStops = [0.0, 0.5705, 1.0];

  // ── Preset strip colors (shared order for color rows) ───────────
  static const List<Color> presetColors = [
    // Ordered from right to left to match the provided reference.
    Color(0xFFFFFFFF), // white
    Color(0xFF0F0F0F), // near-black
    Color(0xFF8D8D8D), // grey
    Color(0xFF0F62FE), // blue
    Color(0xFF198038), // green
    Color(0xFFF1C21B), // yellow
    Color(0xFFEB6200), // orange
    Color(0xFFA21F1F), // red
    Color(0xFF9F1853), // magenta
    Color(0xFFFFB784), // peach
    Color(0xFF4589FF), // blue
    Color(0xFFFFB3B8), // light pink
    Color(0xFF004A80), // navy
    Color(0xFF8E6A00), // gold-brown
    Color(0xFFBA4E00), // orange-brown
    Color(0xFF78A9FF), // sky blue
    Color(0xFF6FDC8C), // green
    Color(0xFF491D8B), // purple
    Color(0xFFFF7EB6), // pink
    Color(0xFF9EF0BA), // mint
    Color(0xFFA6C8FF), // lavender
    Color(0xFF5E2900), // brown
    Color(0xFF004144), // teal
  ];

  // ── Preset background colors ─────────────────────────────────────
  static const List<Color> presetBackgrounds = [
    Color(0xFF1E1E1E),
    Color(0xFF000000),
    Color(0xFF1759B4),
    Color(0xFF2D1B69),
    Color(0xFF0D3B0D),
    Color(0xFF3B0D0D),
    Color(0xFF0D2B3B),
    Color(0xFF3B2D0D),
    Color(0xFF1B1B3B),
    Color(0xFF2B1B2B),
    Color(0xFF0D3B2B),
    Color(0xFF3B1B0D),
  ];
}
