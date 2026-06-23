import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

class PinnedStylesNotifier extends StateNotifier<List<String>> {
  final dynamic _storage;

  PinnedStylesNotifier(this._storage) : super(_storage.getPinnedStyleIds());

  Future<void> toggleStyle(String presetId) async {
    await _storage.togglePinnedStyleId(presetId);
    state = _storage.getPinnedStyleIds();
  }

  bool isPinned(String presetId) => state.contains(presetId);
}

final pinnedStylesProvider =
    StateNotifierProvider<PinnedStylesNotifier, List<String>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PinnedStylesNotifier(storage);
});
