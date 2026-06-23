import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Layered text-effect renderer for the Figma "Vol.1 — Materialized" presets.
///
/// Each preset is reproduced as a stack of offset/blurred text layers that
/// mimic the original Figma layers (extrusion, bevel highlights, multi-blur
/// shadows, gradient fills). Offsets/blurs are authored at Figma's 200px
/// reference size and scaled to the live font size.
class MaterializedText {
  static const Set<String> ids = {
    'quartz',
    'gold',
    'concrete',
    'acryl',
    'iron',
    'paper',
  };

  static bool handles(String? id) => id != null && ids.contains(id);

  static Widget build({
    required String id,
    required String text,
    required TextStyle baseStyle,
    required TextAlign align,
    required TextDirection direction,
  }) {
    final fontSize = baseStyle.fontSize ?? 28.0;
    final s = fontSize / 200.0; // Figma reference scale.
    switch (id) {
      case 'quartz':
        return _quartz(text, baseStyle, align, direction, s);
      case 'gold':
        return _gold(text, baseStyle, align, direction, s);
      case 'concrete':
        return _concrete(text, baseStyle, align, direction, s);
      case 'acryl':
        return _acryl(text, baseStyle, align, direction, s);
      case 'iron':
        return _iron(text, baseStyle, align, direction, s);
      case 'paper':
        return _paper(text, baseStyle, align, direction, s);
      default:
        return Text(text, textAlign: align, textDirection: direction, style: baseStyle);
    }
  }

  // ── low-level helpers ───────────────────────────────────────────────

  static TextStyle _clean(TextStyle base, Color color) =>
      base.copyWith(color: color, shadows: null, foreground: null, background: null);

  static Widget _solid(String text, TextStyle base, Color color, TextAlign a, TextDirection d) =>
      Text(text, textAlign: a, textDirection: d, style: _clean(base, color));

  static Widget _gradient(
    String text,
    TextStyle base,
    List<Color> colors,
    TextAlign a,
    TextDirection d, {
    List<double>? stops,
  }) =>
      ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (b) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(b),
        child: _solid(text, base, Colors.white, a, d),
      );

  /// Wraps [child] with translate/blur/opacity. [dx]/[dy]/[blur] are in Figma px.
  static Widget _layer(
    Widget child, {
    double dx = 0,
    double dy = 0,
    double blur = 0,
    double opacity = 1,
    required double s,
  }) {
    Widget w = child;
    if (blur > 0) {
      final sigma = blur * s;
      w = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: w);
    }
    if (opacity < 1) w = Opacity(opacity: opacity, child: w);
    if (dx != 0 || dy != 0) w = Transform.translate(offset: Offset(dx * s, dy * s), child: w);
    return w;
  }

  static Widget _stack(List<Widget> layers) =>
      Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: layers);

  /// Generates a diagonal/linear extrusion body (back → front).
  static List<Widget> _extrusion(
    String text,
    TextStyle base,
    Color color,
    TextAlign a,
    TextDirection d,
    double s, {
    required int count,
    double stepX = 1,
    double stepY = 1,
  }) {
    final out = <Widget>[];
    for (int i = count; i >= 1; i--) {
      out.add(_layer(_solid(text, base, color, a, d), dx: i * stepX, dy: i * stepY, s: s));
    }
    return out;
  }

  // ── per-style recipes ───────────────────────────────────────────────

  static Widget _quartz(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const fill = Color(0xFFE1E1E1);
    return _stack([
      // Soft contact shadows (Figma overlay-blend approximated with alpha).
      _layer(_solid(text, base, Colors.black, a, d), dx: 58, dy: 58, blur: 22.5, opacity: 0.28, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 42, dy: 42, blur: 17.5, opacity: 0.30, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 26, dy: 26, blur: 12.5, opacity: 0.32, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 18, dy: 18, blur: 5, opacity: 0.40, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 10, dy: 10, blur: 1, opacity: 0.45, s: s),
      // Extrusion body.
      ..._extrusion(text, base, fill, a, d, s, count: 9),
      // Front face.
      _solid(text, base, fill, a, d),
    ]);
  }

  static Widget _gold(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const goldShine = [Color(0xFFFBE7A6), Color(0xFFE7C46B), Color(0xFFB07E29), Color(0xFF8A5E1C)];
    return _stack([
      // Drop shadow stack.
      _layer(_solid(text, base, Colors.black, a, d), dx: 0, dy: 64, blur: 25, opacity: 0.20, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 0, dy: 32, blur: 20, opacity: 0.30, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 0, dy: 18, blur: 17.5, opacity: 0.20, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 0, dy: 10, blur: 13, opacity: 0.20, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 0, dy: 4, blur: 5, opacity: 0.25, s: s),
      _layer(_solid(text, base, Colors.black, a, d), dx: 0, dy: 1, blur: 1, opacity: 0.30, s: s),
      // Dark base for depth.
      _layer(_solid(text, base, const Color(0xFF3A2A0C), a, d), dx: 0, dy: 3, s: s),
      // Metallic gold face.
      _gradient(text, base, goldShine, a, d, stops: const [0.0, 0.42, 0.72, 1.0]),
      // Top sheen highlight.
      _layer(_gradient(text, base, const [Color(0xFFFFFDF2), Color(0x00FFFFFF)], a, d,
              stops: const [0.0, 0.45]),
          dx: 0, dy: -2, opacity: 0.55, s: s),
    ]);
  }

  static Widget _concrete(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const fill = [Color(0xFFF06A6A), Color(0xFFE34949), Color(0xFFB53636)];
    return _stack([
      // Long diagonal shadow (group opacity emulated via wrapper).
      Opacity(
        opacity: 0.40,
        child: _stack([
          for (int i = 23; i >= 0; i--)
            _layer(_solid(text, base, Colors.black, a, d), dx: i.toDouble(), dy: (23 - i).toDouble(), s: s),
        ]),
      ),
      // Extruded red body.
      ..._extrusion(text, base, const Color(0xFFE34949), a, d, s, count: 9),
      // Front gradient face.
      _gradient(text, base, fill, a, d),
    ]);
  }

  static Widget _acryl(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    return _stack([
      // Soft cast shadow.
      _layer(_solid(text, base, Colors.black, a, d), dx: 8, dy: 56, blur: 22.5, opacity: 0.35, s: s),
      // Translucent glass body (faint extrusion).
      ..._extrusion(text, base, const Color(0x33FFFFFF), a, d, s, count: 8),
      // Frosted fill.
      _layer(_solid(text, base, const Color(0x40FFFFFF), a, d), s: s),
      // Glass edge highlight.
      _layer(_solid(text, base, const Color(0xCCFFFFFF), a, d), dx: -1, dy: -1, s: s),
      _solid(text, base, const Color(0x99FFFFFF), a, d),
    ]);
  }

  static Widget _iron(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const metal = [Color(0xFF8FA9BF), Color(0xFF3F6C8E), Color(0xFF21384B), Color(0xFF132231)];
    return _stack([
      // Shadow stack.
      _layer(_solid(text, base, const Color(0xFF102133), a, d), dx: 14, dy: 14, blur: 12, opacity: 0.20, s: s),
      _layer(_solid(text, base, const Color(0xFF102133), a, d), dx: 10, dy: 10, blur: 6, opacity: 0.20, s: s),
      _layer(_solid(text, base, const Color(0xFF102133), a, d), dx: 6, dy: 6, blur: 2, opacity: 0.20, s: s),
      _layer(_solid(text, base, const Color(0xFF102133), a, d), dx: 2, dy: 2, blur: 0.5, opacity: 0.30, s: s),
      // Dark extrusion.
      ..._extrusion(text, base, const Color(0xFF102133), a, d, s, count: 6),
      // Polished metal face.
      _gradient(text, base, metal, a, d, stops: const [0.0, 0.4, 0.7, 1.0]),
      // Specular top edge.
      _layer(_gradient(text, base, const [Color(0xFFE8F2FA), Color(0x00FFFFFF)], a, d, stops: const [0.0, 0.4]),
          dx: 0, dy: -2, opacity: 0.45, s: s),
    ]);
  }

  static Widget _paper(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    final emboss = base.copyWith(
      color: const Color(0xFF0A534F),
      foreground: null,
      shadows: [
        Shadow(color: const Color(0x33FFFFFF), offset: Offset(1 * s, 1 * s), blurRadius: 1 * s),
        Shadow(color: const Color(0x33000000), offset: Offset(-1 * s, -1 * s), blurRadius: 0),
      ],
    );
    return Text(text, textAlign: a, textDirection: d, style: emboss);
  }
}
