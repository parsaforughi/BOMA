import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Layered text-effect renderer for the Figma "Vol.2 — Electric glow" presets
/// (file tnkjanz5uT3hZ6wwk0FWwI, node 246:1428).
///
/// Each preset reproduces the original Figma layer stack — neon strokes,
/// gradient extrusions, chromatic offsets, multi-blur glows and RGB splits.
/// Offsets/blurs are authored at Figma's ~200px reference size and scaled to
/// the live font size so the look holds at any size.
class ElectricText {
  static const Set<String> ids = {
    'holo',
    'laser',
    'arcade',
    'neon',
    'glitch',
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
      case 'holo':
        return _holo(text, baseStyle, align, direction, s);
      case 'laser':
        return _laser(text, baseStyle, align, direction, s);
      case 'arcade':
        return _arcade(text, baseStyle, align, direction, s);
      case 'neon':
        return _neon(text, baseStyle, align, direction, s);
      case 'glitch':
        return _glitch(text, baseStyle, align, direction, s);
      default:
        return Text(text, textAlign: align, textDirection: direction, style: baseStyle);
    }
  }

  // ── low-level helpers ───────────────────────────────────────────────

  static TextStyle _clean(TextStyle base, Color color) =>
      base.copyWith(color: color, shadows: null, foreground: null, background: null);

  static Widget _solid(String text, TextStyle base, Color color, TextAlign a, TextDirection d) =>
      Text(text, textAlign: a, textDirection: d, style: _clean(base, color));

  /// Outline-only text (hollow glyphs) — used for neon tubes.
  static Widget _stroke(
    String text,
    TextStyle base,
    Color color,
    double width,
    TextAlign a,
    TextDirection d,
  ) =>
      Text(
        text,
        textAlign: a,
        textDirection: d,
        style: base.copyWith(
          color: null,
          shadows: null,
          background: null,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        ),
      );

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

  /// Wraps [child] with translate/blur/opacity. [dx]/[dy]/[blur] are Figma px.
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

  /// Solid-fill extrusion body (back → front), diagonal step.
  static List<Widget> _extrude(
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

  /// Neon — hollow green tube with multi-blur glow (Poppins Black).
  static Widget _neon(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const glow = Color(0xFF14F195);
    const core = Color(0xFFB9FFE0);
    return _stack([
      _layer(_stroke(text, base, glow, 17 * s, a, d), blur: 34, opacity: 0.5, s: s),
      _layer(_stroke(text, base, glow, 9 * s, a, d), blur: 11, opacity: 0.72, s: s),
      _layer(_stroke(text, base, glow, 4.5 * s, a, d), blur: 1.5, opacity: 1, s: s),
      _stroke(text, base, core, 2.5 * s, a, d),
    ]);
  }

  /// Laser — red-orange neon with white-hot core + heavy glow (Zen Dots).
  static Widget _laser(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const glow = Color(0xFFFF3B24);
    const mid = Color(0xFFFF6F5A);
    const core = Color(0xFFFFE6DE);
    return _stack([
      _layer(_stroke(text, base, glow, 19 * s, a, d), blur: 38, opacity: 0.5, s: s),
      _layer(_stroke(text, base, const Color(0xFFFF4F37), 8 * s, a, d), blur: 9, opacity: 0.85, s: s),
      _layer(_stroke(text, base, mid, 4 * s, a, d), blur: 2, opacity: 1, s: s),
      _stroke(text, base, core, 2 * s, a, d),
    ]);
  }

  /// Holo — holographic gradient with blurred diagonal extrusion (Staatliches).
  ///
  /// The extrusion trail uses a single representative glow color (instead of a
  /// per-layer gradient ShaderMask) so the whole effect needs just one
  /// ShaderMask + a handful of blur passes — far cheaper while looking the same.
  static Widget _holo(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const grad = [Color(0xFF2900CB), Color(0xFFF93995), Color(0xFF92238D)];
    const stops = [0.21, 0.50, 0.77];
    const trailColor = Color(0xFFC83C93); // representative holographic glow
    final trail = <Widget>[];
    const count = 7;
    for (int i = count; i >= 1; i--) {
      final t = i / count; // 1 (far) → ~0 (near)
      trail.add(_layer(
        _solid(text, base, trailColor, a, d),
        dx: i * 7.7,
        dy: i * 3.85,
        blur: i * 0.5,
        opacity: 0.12 + (1 - t) * 0.42,
        s: s,
      ));
    }
    return _stack([
      ...trail,
      _gradient(text, base, grad, a, d, stops: stops),
    ]);
  }

  /// Arcade — chromatic cyan/blue/magenta 3D with pink glow (Righteous).
  static Widget _arcade(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const magenta = Color(0xFFDB00FF);
    const blue = Color(0xFF0017E2);
    const faceTop = Color(0xFF6FE3FF);
    const faceBottom = Color(0xFF00A6E6);
    return _stack([
      // Outer pink glow halo (single blur pass).
      _layer(_solid(text, base, magenta, a, d), blur: 26, opacity: 0.65, s: s),
      // Magenta deepest extrusion.
      ..._extrude(text, base, magenta, a, d, s, count: 6, stepX: 1.7, stepY: 1.7),
      // Blue mid extrusion.
      ..._extrude(text, base, blue, a, d, s, count: 4, stepX: 1.0, stepY: 1.0),
      // Cyan glossy front face.
      _gradient(text, base, const [faceTop, faceBottom], a, d, stops: const [0.0, 1.0]),
      // Glossy top highlight.
      _layer(
        _gradient(text, base, const [Color(0xFFFFFFFF), Color(0x00FFFFFF)], a, d, stops: const [0.0, 0.35]),
        dx: 0,
        dy: -1,
        opacity: 0.6,
        s: s,
      ),
    ]);
  }

  /// Glitch — RGB split (red/cyan) with white core (Inter Black).
  static Widget _glitch(String text, TextStyle base, TextAlign a, TextDirection d, double s) {
    const red = Color(0xFFDE172D);
    const cyan = Color(0xFF21D9D2);
    return _stack([
      // Red channel (offset left) with glow.
      _layer(_solid(text, base, red, a, d), dx: -9, dy: -2, blur: 6, opacity: 0.55, s: s),
      _layer(_solid(text, base, red, a, d), dx: -6, dy: -2, s: s),
      // Cyan channel (offset right) with glow.
      _layer(_solid(text, base, cyan, a, d), dx: 9, dy: 2, blur: 6, opacity: 0.55, s: s),
      _layer(_solid(text, base, cyan, a, d), dx: 6, dy: 2, s: s),
      // White core.
      _solid(text, base, Colors.white, a, d),
    ]);
  }
}
