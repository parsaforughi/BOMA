import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/canvas_state.dart';
import '../providers/sticker_drag_provider.dart';
import '../theme/colors.dart';
import 'layered_text.dart';
import 'electric_text.dart';

/// Design "Style-selected" title shadows from CSS (پادکست جافکری).
const List<Shadow> _kDesignTitleShadows = [
  Shadow(color: Color(0xB5000000), offset: Offset(0, 4), blurRadius: 4),
  Shadow(color: Color(0x4F890000), offset: Offset(0, 4), blurRadius: 6.8),
  Shadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 4),
  Shadow(color: Color(0x405B0000), offset: Offset(5, 6), blurRadius: 4),
  Shadow(color: Color(0x405E0000), offset: Offset(-3, 4), blurRadius: 4.6),
];

/// Renders styled canvas text on a transparent background (for export / clipboard).
class CanvasStyledText extends ConsumerWidget {
  const CanvasStyledText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvas = ref.watch(canvasProvider);
    if (canvas.text.isEmpty) return const SizedBox.shrink();

    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: canvas.fontFamily,
        fontFamilyFallback: const ['Vazir'],
        fontSize: canvas.fontSize,
        color: canvas.textColor,
      ),
      child: Opacity(
        opacity: canvas.opacity,
        child: TextCanvas.buildStyledText(canvas),
      ),
    );
  }
}

class TextCanvas extends ConsumerWidget {
  final GlobalKey canvasKey;
  /// وقتی false فقط پس‌زمینه و متن رسم می‌شود (استیکرها در لایهٔ بالاتر در HomeScreen)
  final bool showStickers;

  const TextCanvas({super.key, required this.canvasKey, this.showStickers = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvas = ref.watch(canvasProvider);

    return RepaintBoundary(
      key: canvasKey,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: canvas.backgroundGradient == null
              ? canvas.backgroundColor
              : null,
          gradient: canvas.backgroundGradient != null
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: canvas.backgroundGradient!,
                  stops: canvas.backgroundGradientStops,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Quartz: subtle tiled noise texture over the base color.
            if (canvas.activePreset?.id == 'quartz')
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.10,
                    child: Image.asset(
                      'assets/styles/materialized/tex/quartz_bg.png',
                      repeat: ImageRepeat.repeat,
                      fit: BoxFit.none,
                      alignment: Alignment.topLeft,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            // Glitch: horizontal scanline overlay (Figma "Screen effect").
            if (canvas.activePreset?.id == 'glitch')
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _ScanlinePainter()),
                ),
              ),
            // ناحیهٔ متن: IgnorePointer تا لمس به GestureDetector کانواس برسد و با تپ «متنت رو بنویس» کیبورد باز شود
            IgnorePointer(
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: canvas.fontFamily,
                    fontFamilyFallback: const ['Vazir'],
                    fontSize: canvas.fontSize,
                    color: canvas.textColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 48, right: 32, top: 80, bottom: 80),
                    child: Opacity(
                      opacity: canvas.opacity,
                      child: TextCanvas.buildStyledText(canvas),
                    ),
                  ),
                ),
              ),
            ),
            // Stickers (اگر در HomeScreen لایهٔ جدا داریم اینجا خاموش می‌شود)
            if (showStickers) ...canvas.stickers.asMap().entries.map((entry) {
              final index = entry.key;
              final sticker = entry.value;
              return Positioned(
                left: sticker.position.dx,
                top: sticker.position.dy,
                child: GestureDetector(
                  onPanStart: (details) {
                    ref.read(stickerDragProvider.notifier).start(
                          index,
                          details.globalPosition,
                        );
                  },
                  onPanUpdate: (details) {
                    ref.read(canvasProvider.notifier).updateSticker(
                          index,
                          position: sticker.position + details.delta,
                        );
                    ref.read(stickerDragProvider.notifier).update(
                          details.globalPosition,
                        );
                  },
                  onPanEnd: (details) {
                    ref.read(stickerDragProvider.notifier).end(
                          index,
                          details.globalPosition,
                        );
                  },
                  onLongPress: () {
                    _showStickerMenu(context, ref, index);
                  },
                  child: Transform.rotate(
                    angle: sticker.rotation,
                    child: Transform.scale(
                      scale: sticker.scale,
                      child: Image.asset(
                        sticker.sticker.assetPath,
                        width: 80,
                        height: 80,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.emoji_emotions,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static Widget buildStyledText(CanvasState canvas) {
    if (canvas.text.isEmpty) {
      return const SizedBox.shrink();
    }

    // Materialized / Electric presets render through their layered engines.
    final presetId = canvas.activePreset?.id;
    if (MaterializedText.handles(presetId) || ElectricText.handles(presetId)) {
      final base = TextStyle(
        fontFamily: canvas.fontFamily,
        fontFamilyFallback: const ['Vazir'],
        fontSize: canvas.fontSize,
        fontWeight: canvas.fontWeight,
        letterSpacing: canvas.letterSpacing,
        wordSpacing: canvas.wordSpacing,
        height: canvas.lineHeight,
      );
      final layered = MaterializedText.handles(presetId)
          ? MaterializedText.build(
              id: presetId!,
              text: canvas.text,
              baseStyle: base,
              align: canvas.textAlign,
              direction: TextDirection.rtl,
            )
          : ElectricText.build(
              id: presetId!,
              text: canvas.text,
              baseStyle: base,
              align: canvas.textAlign,
              direction: TextDirection.rtl,
            );
      // Cache the expensive layered effect on its own layer so unrelated
      // canvas changes (sticker drag, sliders) don't force it to re-render.
      return RepaintBoundary(
        child: KeyedSubtree(
          key: ValueKey<String>('layered_${presetId}_${canvas.fontFamily}'),
          child: layered,
        ),
      );
    }

    final baseStyle = TextStyle(
      fontFamily: canvas.fontFamily,
      fontFamilyFallback: const ['Vazir'],
      fontSize: canvas.fontSize,
      fontWeight: canvas.fontWeight,
      color: canvas.textColor,
      letterSpacing: canvas.letterSpacing,
      wordSpacing: canvas.wordSpacing,
      height: canvas.lineHeight,
      shadows: canvas.shadowColor != null ? _kDesignTitleShadows : null,
    );

    Widget textWidget;

    // Gradient text
    if (canvas.gradientColors != null && canvas.gradientColors!.length >= 2) {
      textWidget = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: canvas.gradientColors!,
        ).createShader(bounds),
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: canvas.textAlign,
          text: TextSpan(
            text: canvas.text,
            style: baseStyle.copyWith(color: Colors.white),
          ),
        ),
      );
    } else {
      textWidget = RichText(
        textDirection: TextDirection.rtl,
        textAlign: canvas.textAlign,
        text: TextSpan(
          text: canvas.text,
          style: baseStyle,
        ),
      );
    }

    // Stroke effect - uses Stack with two text widgets
    if (canvas.strokeColor != null && canvas.strokeWidth > 0) {
      textWidget = Stack(
        children: [
          RichText(
            textDirection: TextDirection.rtl,
            textAlign: canvas.textAlign,
            text: TextSpan(
              text: canvas.text,
              style: baseStyle.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = canvas.strokeWidth
                  ..color = canvas.strokeColor!,
              ),
            ),
          ),
          textWidget,
        ],
      );
    }

    // Bubble effect
    if (canvas.hasBubble) {
      textWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: canvas.bubbleGradient == null
              ? (canvas.bubbleColor ?? AppColors.blueAccent)
              : null,
          gradient: canvas.bubbleGradient != null && canvas.bubbleGradient!.length >= 2
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: canvas.bubbleGradient!,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: textWidget,
      );
    }

    return KeyedSubtree(
      key: ValueKey<String>('text_${canvas.fontFamily}'),
      child: textWidget,
    );
  }

  void _showStickerMenu(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'استیکر',
          style: TextStyle(fontFamily: 'Vazir', color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(canvasProvider.notifier).removeSticker(index);
              Navigator.pop(ctx);
            },
            child: const Text(
              'حذف',
              style:
                  TextStyle(fontFamily: 'Vazir', color: AppColors.errorLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'بستن',
              style:
                  TextStyle(fontFamily: 'Vazir', color: AppColors.blueLight),
            ),
          ),
        ],
      ),
    );
  }
}

/// CRT scanline overlay for the Glitch preset — thin dark horizontal lines.
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x14000000);
    const gap = 3.0;
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) => false;
}

/// لایهٔ فقط استیکرها — بالای TextField تا تپ روی فیلد کیبورد را باز کند و درگ استیکر کار کند
class StickerOverlay extends ConsumerWidget {
  const StickerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvas = ref.watch(canvasProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: canvas.stickers.asMap().entries.map((entry) {
        final index = entry.key;
        final sticker = entry.value;
        return Positioned(
          left: sticker.position.dx,
          top: sticker.position.dy,
          child: GestureDetector(
            onPanStart: (d) {
              ref.read(stickerDragProvider.notifier).start(index, d.globalPosition);
            },
            onPanUpdate: (d) {
              ref.read(canvasProvider.notifier).updateSticker(
                    index,
                    position: sticker.position + d.delta,
                  );
              ref.read(stickerDragProvider.notifier).update(d.globalPosition);
            },
            onPanEnd: (d) {
              ref.read(stickerDragProvider.notifier).end(index, d.globalPosition);
            },
            onLongPress: () => _showStickerMenu(context, ref, index),
            child: Transform.rotate(
              angle: sticker.rotation,
              child: Transform.scale(
                scale: sticker.scale,
                child: Image.asset(
                  sticker.sticker.assetPath,
                  width: 80,
                  height: 80,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_emotions,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showStickerMenu(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'استیکر',
          style: TextStyle(fontFamily: 'Vazir', color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(canvasProvider.notifier).removeSticker(index);
              Navigator.pop(ctx);
            },
            child: const Text(
              'حذف',
              style:
                  TextStyle(fontFamily: 'Vazir', color: AppColors.errorLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'بستن',
              style:
                  TextStyle(fontFamily: 'Vazir', color: AppColors.blueLight),
            ),
          ),
        ],
      ),
    );
  }
}
