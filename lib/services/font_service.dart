import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/font_item.dart';
import 'storage_service.dart';
import 'auth_service.dart';

class FontState {
  final String currentFont;
  final List<String> favoriteFonts;
  final FontCategory? filterCategory;

  const FontState({
    this.currentFont = 'Vazir',
    this.favoriteFonts = const [],
    this.filterCategory,
  });

  FontState copyWith({
    String? currentFont,
    List<String>? favoriteFonts,
    FontCategory? filterCategory,
    bool clearFilter = false,
  }) {
    return FontState(
      currentFont: currentFont ?? this.currentFont,
      favoriteFonts: favoriteFonts ?? this.favoriteFonts,
      filterCategory: clearFilter ? null : (filterCategory ?? this.filterCategory),
    );
  }

  List<FontItem> get filteredFonts {
    if (filterCategory != null) {
      return FontItem.allFonts.where((f) => f.category == filterCategory).toList();
    }
    return FontItem.allFonts;
  }

  List<FontItem> get favoriteFontItems {
    return FontItem.allFonts.where((f) => favoriteFonts.contains(f.name)).toList();
  }
}

class FontNotifier extends StateNotifier<FontState> {
  final StorageService _storage;

  FontNotifier(this._storage) : super(const FontState()) {
    _loadFavorites();
  }

  void _loadFavorites() {
    final favorites = _storage.getFavoriteFonts();
    state = state.copyWith(favoriteFonts: favorites);
  }

  void selectFont(String fontName) {
    state = state.copyWith(currentFont: fontName);
  }

  Future<void> toggleFavorite(String fontName) async {
    await _storage.toggleFavoriteFont(fontName);
    final updated = _storage.getFavoriteFonts();
    state = state.copyWith(favoriteFonts: updated);
  }

  void setFilter(FontCategory? category) {
    if (category == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterCategory: category);
    }
  }

  bool isFavorite(String fontName) {
    return state.favoriteFonts.contains(fontName);
  }
}

final fontProvider = StateNotifierProvider<FontNotifier, FontState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FontNotifier(storage);
});
