import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sticker_item.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class FavoriteStickersState {
  final List<String> favoriteStickerPaths;

  const FavoriteStickersState({
    this.favoriteStickerPaths = const [],
  });

  FavoriteStickersState copyWith({
    List<String>? favoriteStickerPaths,
  }) {
    return FavoriteStickersState(
      favoriteStickerPaths: favoriteStickerPaths ?? this.favoriteStickerPaths,
    );
  }

  List<StickerItem> get favoriteStickers {
    return StickerItem.allStickers
        .where((sticker) => favoriteStickerPaths.contains(sticker.assetPath))
        .toList();
  }
}

class FavoriteStickersNotifier extends StateNotifier<FavoriteStickersState> {
  final StorageService _storage;

  FavoriteStickersNotifier(this._storage) : super(const FavoriteStickersState()) {
    _loadFavorites();
  }

  void _loadFavorites() {
    state = state.copyWith(favoriteStickerPaths: _storage.getFavoriteStickers());
  }

  Future<void> toggleFavorite(String assetPath) async {
    await _storage.toggleFavoriteSticker(assetPath);
    state = state.copyWith(favoriteStickerPaths: _storage.getFavoriteStickers());
  }

  bool isFavorite(String assetPath) {
    return state.favoriteStickerPaths.contains(assetPath);
  }
}

final favoriteStickersProvider =
    StateNotifierProvider<FavoriteStickersNotifier, FavoriteStickersState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FavoriteStickersNotifier(storage);
});
