import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/text_style_preset.dart';
import '../models/sticker_item.dart';

class PlacedSticker {
  final StickerItem sticker;
  Offset position;
  double scale;
  double rotation;

  PlacedSticker({
    required this.sticker,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

class CanvasState {
  final String text;
  final String fontFamily;
  final double fontSize;
  final double letterSpacing;
  final double wordSpacing;
  final double lineHeight;
  final double opacity;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final Color textColor;
  final Color backgroundColor;
  final List<Color>? backgroundGradient;
  final List<double>? backgroundGradientStops;
  final TextStylePreset? activePreset;
  final List<PlacedSticker> stickers;

  // Effect overrides
  final Color? strokeColor;
  final double strokeWidth;
  final Color? shadowColor;
  final Offset shadowOffset;
  final double shadowBlur;
  final bool hasBubble;
  final Color? bubbleColor;
  final List<Color>? bubbleGradient;
  final List<Color>? gradientColors;

  const CanvasState({
    this.text = '',
    this.fontFamily = 'Vazir',
    this.fontSize = 28,
    this.letterSpacing = 0,
    this.wordSpacing = 0,
    this.lineHeight = 1.5,
    this.opacity = 1.0,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.center,
    this.textColor = Colors.white,
    this.backgroundColor = const Color(0xFF324F9D),
    this.backgroundGradient,
    this.backgroundGradientStops,
    this.activePreset,
    this.stickers = const [],
    this.strokeColor,
    this.strokeWidth = 0,
    this.shadowColor,
    this.shadowOffset = Offset.zero,
    this.shadowBlur = 0,
    this.hasBubble = false,
    this.bubbleColor,
    this.bubbleGradient,
    this.gradientColors,
  });

  CanvasState copyWith({
    String? text,
    String? fontFamily,
    double? fontSize,
    double? letterSpacing,
    double? wordSpacing,
    double? lineHeight,
    double? opacity,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    Color? textColor,
    Color? backgroundColor,
    List<Color>? backgroundGradient,
    List<double>? backgroundGradientStops,
    bool clearBackgroundGradient = false,
    bool clearBackgroundGradientStops = false,
    TextStylePreset? activePreset,
    bool clearPreset = false,
    List<PlacedSticker>? stickers,
    Color? strokeColor,
    bool clearStroke = false,
    double? strokeWidth,
    Color? shadowColor,
    bool clearShadow = false,
    Offset? shadowOffset,
    double? shadowBlur,
    bool? hasBubble,
    Color? bubbleColor,
    List<Color>? bubbleGradient,
    bool clearBubbleGradient = false,
    List<Color>? gradientColors,
    bool clearGradient = false,
  }) {
    return CanvasState(
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      opacity: opacity ?? this.opacity,
      fontWeight: fontWeight ?? this.fontWeight,
      textAlign: textAlign ?? this.textAlign,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: clearBackgroundGradient ? null : (backgroundGradient ?? this.backgroundGradient),
      backgroundGradientStops: clearBackgroundGradient || clearBackgroundGradientStops ? null : (backgroundGradientStops ?? this.backgroundGradientStops),
      activePreset: clearPreset ? null : (activePreset ?? this.activePreset),
      stickers: stickers ?? this.stickers,
      strokeColor: clearStroke ? null : (strokeColor ?? this.strokeColor),
      strokeWidth: strokeWidth ?? this.strokeWidth,
      shadowColor: clearShadow ? null : (shadowColor ?? this.shadowColor),
      shadowOffset: shadowOffset ?? this.shadowOffset,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      hasBubble: hasBubble ?? this.hasBubble,
      bubbleColor: bubbleColor ?? this.bubbleColor,
      bubbleGradient: clearBubbleGradient ? null : (bubbleGradient ?? this.bubbleGradient),
      gradientColors: clearGradient ? null : (gradientColors ?? this.gradientColors),
    );
  }
}

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());

  void setText(String text) => state = state.copyWith(text: text);
  void setFont(String family) => state = state.copyWith(fontFamily: family);
  void setFontSize(double size) => state = state.copyWith(fontSize: size);
  void setLetterSpacing(double v) => state = state.copyWith(letterSpacing: v);
  void setWordSpacing(double v) => state = state.copyWith(wordSpacing: v);
  void setLineHeight(double v) => state = state.copyWith(lineHeight: v);
  void setOpacity(double v) => state = state.copyWith(opacity: v);
  void setFontWeight(FontWeight w) => state = state.copyWith(fontWeight: w);
  void setTextAlign(TextAlign a) => state = state.copyWith(textAlign: a);
  void setTextColor(Color c) => state = state.copyWith(textColor: c);
  void setBackgroundColor(Color c) => state = state.copyWith(backgroundColor: c, clearBackgroundGradient: true);
  void setBackgroundGradient(List<Color> colors, [List<double>? stops]) => state = state.copyWith(
    backgroundGradient: colors,
    backgroundGradientStops: stops,
    clearBackgroundGradient: false,
    clearBackgroundGradientStops: stops == null,
  );

  void setStrokeColor(Color c) => state = state.copyWith(strokeColor: c);
  void setStrokeWidth(double w) => state = state.copyWith(strokeWidth: w);
  void clearStroke() => state = state.copyWith(clearStroke: true, strokeWidth: 0);

  void setShadow(Color color, Offset offset, double blur) {
    state = state.copyWith(shadowColor: color, shadowOffset: offset, shadowBlur: blur);
  }
  void clearShadow() => state = state.copyWith(clearShadow: true, shadowBlur: 0);

  void setGradientColors(List<Color> colors) => state = state.copyWith(gradientColors: colors);
  void clearGradientColors() => state = state.copyWith(clearGradient: true);

  void setBubble(bool on, {Color? color}) {
    state = state.copyWith(
      hasBubble: on,
      bubbleColor: color,
      clearBubbleGradient: color != null,
    );
  }

  void setBubbleGradient(List<Color> colors) {
    state = state.copyWith(
      hasBubble: true,
      bubbleGradient: colors,
      bubbleColor: colors.first,
      clearBubbleGradient: false,
    );
  }

  void applyPreset(TextStylePreset preset) {
    final hasCanvasGradient =
        preset.canvasGradient != null && preset.canvasGradient!.length >= 2;
    state = state.copyWith(
      activePreset: preset,
      textColor: preset.textColor,
      fontFamily: preset.fontFamily ?? state.fontFamily,
      fontWeight: preset.fontWeight ?? state.fontWeight,
      strokeColor: preset.strokeColor,
      strokeWidth: preset.strokeWidth ?? 0,
      shadowColor: preset.shadowColor,
      shadowOffset: preset.shadowOffset ?? Offset.zero,
      shadowBlur: preset.shadowBlur ?? 0,
      hasBubble: preset.hasBubble,
      bubbleColor: preset.backgroundColor,
      clearBubbleGradient: true,
      gradientColors: preset.gradientColors,
      clearStroke: preset.strokeColor == null,
      clearShadow: preset.shadowColor == null,
      clearGradient: preset.gradientColors == null,
      // Page background from the preset (gradient takes priority over solid).
      backgroundColor: hasCanvasGradient
          ? state.backgroundColor
          : (preset.canvasColor ?? state.backgroundColor),
      backgroundGradient: hasCanvasGradient ? preset.canvasGradient : null,
      backgroundGradientStops: hasCanvasGradient ? preset.canvasGradientStops : null,
      clearBackgroundGradient: !hasCanvasGradient,
      clearBackgroundGradientStops: !hasCanvasGradient,
    );
  }

  void addSticker(StickerItem sticker, Offset position) {
    final placed = PlacedSticker(sticker: sticker, position: position);
    state = state.copyWith(stickers: [...state.stickers, placed]);
  }

  void updateSticker(int index, {Offset? position, double? scale, double? rotation}) {
    final stickers = List<PlacedSticker>.from(state.stickers);
    if (index < stickers.length) {
      if (position != null) stickers[index].position = position;
      if (scale != null) stickers[index].scale = scale;
      if (rotation != null) stickers[index].rotation = rotation;
      state = state.copyWith(stickers: stickers);
    }
  }

  void removeSticker(int index) {
    final stickers = List<PlacedSticker>.from(state.stickers);
    if (index < stickers.length) {
      stickers.removeAt(index);
      state = state.copyWith(stickers: stickers);
    }
  }

  void clearStickers() => state = state.copyWith(stickers: []);

  /// بارگذاری کامل وضعیت کانواس (مثلاً از پیش‌نویس تاریخچه)
  void loadState(CanvasState newState) {
    state = newState;
  }
}

final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});
