import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class PinnedColorsNotifier extends StateNotifier<List<int>> {
  final dynamic _storage;
  final bool _isTextColors;

  PinnedColorsNotifier(this._storage, {required bool isTextColors})
      : _isTextColors = isTextColors,
        super(isTextColors
            ? _storage.getPinnedTextColors()
            : _storage.getPinnedBgColors());

  void load() {
    state = _isTextColors
        ? _storage.getPinnedTextColors()
        : _storage.getPinnedBgColors();
  }

  Future<void> toggleColor(Color color) async {
    final value = color.value;
    if (_isTextColors) {
      await _storage.togglePinnedTextColor(value);
      state = _storage.getPinnedTextColors();
    } else {
      await _storage.togglePinnedBgColor(value);
      state = _storage.getPinnedBgColors();
    }
  }

  bool isPinned(Color color) {
    return state.contains(color.value);
  }
}

final pinnedTextColorsProvider =
    StateNotifierProvider<PinnedColorsNotifier, List<int>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PinnedColorsNotifier(storage, isTextColors: true);
});

final pinnedBgColorsProvider =
    StateNotifierProvider<PinnedColorsNotifier, List<int>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PinnedColorsNotifier(storage, isTextColors: false);
});
