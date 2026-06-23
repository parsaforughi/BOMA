import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';

class FavoriteBackgroundsState {
  final List<String> favoriteBackgroundIds;

  const FavoriteBackgroundsState({
    this.favoriteBackgroundIds = const [],
  });

  FavoriteBackgroundsState copyWith({
    List<String>? favoriteBackgroundIds,
  }) {
    return FavoriteBackgroundsState(
      favoriteBackgroundIds: favoriteBackgroundIds ?? this.favoriteBackgroundIds,
    );
  }
}

class FavoriteBackgroundsNotifier extends StateNotifier<FavoriteBackgroundsState> {
  final StorageService _storage;

  FavoriteBackgroundsNotifier(this._storage) : super(const FavoriteBackgroundsState()) {
    _loadFavorites();
  }

  void _loadFavorites() {
    state = state.copyWith(favoriteBackgroundIds: _storage.getFavoriteBackgrounds());
  }

  Future<void> toggleFavorite(String id) async {
    await _storage.toggleFavoriteBackground(id);
    state = state.copyWith(favoriteBackgroundIds: _storage.getFavoriteBackgrounds());
  }

  bool isFavorite(String id) {
    return state.favoriteBackgroundIds.contains(id);
  }
}

final favoriteBackgroundsProvider =
    StateNotifierProvider<FavoriteBackgroundsNotifier, FavoriteBackgroundsState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FavoriteBackgroundsNotifier(storage);
});
