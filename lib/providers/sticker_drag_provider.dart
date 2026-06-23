import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// وضعیت درگ استیکر برای نمایش سطل زباله و حذف با دراپ روی سطل
class StickerDragState {
  final int? draggingIndex;
  final Offset? globalPosition;
  final bool panEnded;

  const StickerDragState({
    this.draggingIndex,
    this.globalPosition,
    this.panEnded = false,
  });

  bool get isDragging => draggingIndex != null;
}

class StickerDragNotifier extends StateNotifier<StickerDragState> {
  StickerDragNotifier() : super(const StickerDragState());

  void start(int index, Offset globalPosition) {
    state = StickerDragState(
      draggingIndex: index,
      globalPosition: globalPosition,
      panEnded: false,
    );
  }

  void update(Offset globalPosition) {
    if (state.draggingIndex == null) return;
    state = StickerDragState(
      draggingIndex: state.draggingIndex,
      globalPosition: globalPosition,
      panEnded: false,
    );
  }

  void end(int index, Offset globalPosition) {
    state = StickerDragState(
      draggingIndex: index,
      globalPosition: globalPosition,
      panEnded: true,
    );
  }

  void clear() {
    state = const StickerDragState();
  }
}

final stickerDragProvider =
    StateNotifierProvider<StickerDragNotifier, StickerDragState>((ref) {
  return StickerDragNotifier();
});
