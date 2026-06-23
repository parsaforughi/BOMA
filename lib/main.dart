import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'models/text_style_preset.dart';
import 'services/figma_text_style_loader.dart';
import 'services/custom_font_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1E1E1E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize storage
  final storage = await StorageService.getInstance();

  final customFontService = CustomFontService(storage);
  await customFontService.registerFonts(customFontService.loadFromStorage());

  TextStylePreset.figmaPresets = await FigmaTextStyleLoader.load();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const BomaApp(),
    ),
  );
}
