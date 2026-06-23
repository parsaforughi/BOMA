import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/text_style_preset.dart';

/// Loads [TextStylePreset]s exported from Figma local text styles.
///
/// Sync via Cursor + Figma plugin: share your design file URL and ask to
/// "export Figma text styles to assets/figma/text_styles.json".
class FigmaTextStyleLoader {
  static const assetPath = 'assets/figma/text_styles.json';

  static Future<List<TextStylePreset>> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final styles = json['styles'];
      if (styles is! List || styles.isEmpty) return const [];

      final out = <TextStylePreset>[];
      for (final entry in styles) {
        if (entry is! Map<String, dynamic>) continue;
        final preset = _presetFromFigmaJson(entry);
        if (preset != null) out.add(preset);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static TextStylePreset? _presetFromFigmaJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) return null;

    final id = (json['id'] as String?) ?? _slugId(name);
    final displayName =
        (json['displayName'] as String?) ?? name.split('/').last.trim();

    final fontName = json['fontName'];
    String? fontFamily;
    FontWeight? fontWeight;
    if (fontName is Map) {
      fontFamily = fontName['family'] as String?;
      fontWeight = _fontWeightFromStyle(fontName['style'] as String?);
    }

    final fontSize = _toDouble(json['fontSize']);

    final textColor = _colorFromFigmaFills(json['fills']) ?? Colors.white;

    return TextStylePreset(
      id: id.startsWith('figma_') ? id : 'figma_$id',
      name: name,
      displayName: displayName,
      textColor: textColor,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      isPro: json['isPro'] == true,
    );
  }

  static String _slugId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  static FontWeight? _fontWeightFromStyle(String? style) {
    if (style == null) return null;
    final s = style.toLowerCase();
    if (s.contains('thin')) return FontWeight.w100;
    if (s.contains('extra light') || s.contains('extralight')) {
      return FontWeight.w200;
    }
    if (s.contains('light')) return FontWeight.w300;
    if (s.contains('medium')) return FontWeight.w500;
    if (s.contains('semi bold') || s.contains('semibold')) {
      return FontWeight.w600;
    }
    if (s.contains('extra bold') || s.contains('extrabold')) {
      return FontWeight.w800;
    }
    if (s.contains('bold')) return FontWeight.w700;
    if (s.contains('black')) return FontWeight.w900;
    return FontWeight.w400;
  }

  static Color? _colorFromFigmaFills(dynamic fills) {
    if (fills is! List || fills.isEmpty) return null;
    for (final fill in fills) {
      if (fill is! Map) continue;
      if (fill['type'] != 'SOLID') continue;
      final color = fill['color'];
      if (color is! Map) continue;
      final r = _channel(color['r']);
      final g = _channel(color['g']);
      final b = _channel(color['b']);
      final opacity = _toDouble(fill['opacity']) ?? 1.0;
      return Color.fromRGBO(r, g, b, opacity.clamp(0.0, 1.0));
    }
    return null;
  }

  static int _channel(dynamic v) {
    if (v is num) {
      if (v <= 1) return (v * 255).round().clamp(0, 255);
      return v.round().clamp(0, 255);
    }
    return 255;
  }
}
