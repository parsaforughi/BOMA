import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class CustomColorsNotifier extends StateNotifier<List<int>> {
  final dynamic _storage;
  final bool _isTextColors;

  CustomColorsNotifier(this._storage, {required bool isTextColors})
      : _isTextColors = isTextColors,
        super(isTextColors
            ? _storage.getCustomTextColors()
            : _storage.getCustomBgColors());

  Future<void> addColor(Color color) async {
    if (_isTextColors) {
      await _storage.addCustomTextColor(color.value);
      state = _storage.getCustomTextColors();
    } else {
      await _storage.addCustomBgColor(color.value);
      state = _storage.getCustomBgColors();
    }
  }
}

final customTextColorsProvider =
    StateNotifierProvider<CustomColorsNotifier, List<int>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return CustomColorsNotifier(storage, isTextColors: true);
});

final customBgColorsProvider =
    StateNotifierProvider<CustomColorsNotifier, List<int>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return CustomColorsNotifier(storage, isTextColors: false);
});
