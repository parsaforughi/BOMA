import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/custom_font.dart';
import '../models/font_item.dart';
import '../services/auth_service.dart';
import '../services/custom_font_service.dart';

class CustomFontsNotifier extends StateNotifier<List<CustomFont>> {
  final CustomFontService _service;

  CustomFontsNotifier(this._service) : super(const []) {
    _init();
  }

  Future<void> _init() async {
    final fonts = _service.loadFromStorage();
    state = fonts;
    await _service.registerFonts(fonts);
  }

  List<FontItem> get fontItems => state.map((f) => f.toFontItem()).toList();

  Future<FontItem?> importFont() async {
    final custom = await _service.importFromPicker();
    if (custom == null) return null;
    state = [...state, custom];
    return custom.toFontItem();
  }
}

final customFontServiceProvider = Provider<CustomFontService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return CustomFontService(storage);
});

final customFontsProvider =
    StateNotifierProvider<CustomFontsNotifier, List<CustomFont>>((ref) {
  final service = ref.watch(customFontServiceProvider);
  return CustomFontsNotifier(service);
});
