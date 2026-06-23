import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/canvas_state.dart';

class ColorPickerPanel extends ConsumerStatefulWidget {
  final Color? initialColor;
  final ValueChanged<Color>? onColorChanged;
  final ValueChanged<Color>? onAddColor;
  final ValueChanged<List<Color>>? onGradientSelected;
  final List<Color>? selectedGradient;

  const ColorPickerPanel({
    super.key,
    this.initialColor,
    this.onColorChanged,
    this.onAddColor,
    this.onGradientSelected,
    this.selectedGradient,
  });

  @override
  ConsumerState<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends ConsumerState<ColorPickerPanel> {
  final TextEditingController _hexController = TextEditingController();
  late HSVColor _selectedHsv;
  bool _showSpectrumPresets = false;
  List<Color>? _selectedSpectrum;

  @override
  void initState() {
    super.initState();
    final canvas = ref.read(canvasProvider);
    final initial = widget.initialColor ?? canvas.textColor;
    _selectedHsv = HSVColor.fromColor(initial);
    _hexController.text = _colorToHex(initial);
    _selectedSpectrum = widget.selectedGradient;
  }

  @override
  void didUpdateWidget(covariant ColorPickerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameGradient(oldWidget.selectedGradient, widget.selectedGradient)) {
      _selectedSpectrum = widget.selectedGradient;
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Color? _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      final intValue = int.tryParse('FF$hex', radix: 16);
      if (intValue != null) return Color(intValue);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(canvasProvider.notifier);
    final selectedColor = _selectedHsv.toColor();
    void applyColor(Color color) {
      if (widget.onColorChanged != null) {
        widget.onColorChanged!(color);
      } else {
        notifier.setTextColor(color);
      }
    }
    void applyGradient(List<Color> gradient) {
      if (widget.onGradientSelected != null) {
        widget.onGradientSelected!(gradient);
      } else {
        notifier.setGradientColors(gradient);
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          if (_showSpectrumPresets)
            _SpectrumPresetGrid(
              selectedGradient: _selectedSpectrum,
              onSelect: (gradient) {
                final color = gradient.first;
                setState(() {
                  _selectedHsv = HSVColor.fromColor(color);
                  _hexController.text = _colorToHex(color);
                  _selectedSpectrum = gradient;
                });
                applyGradient(gradient);
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SaturationValuePicker(
                    hsvColor: _selectedHsv,
                    onChanged: (hsv) {
                      setState(() {
                        _selectedHsv = hsv;
                        _hexController.text = _colorToHex(hsv.toColor());
                      });
                      applyColor(hsv.toColor());
                    },
                  ),
                  const SizedBox(height: 16),
                  _HueSlider(
                    currentColor: selectedColor,
                    onColorSelected: (color) {
                      setState(() {
                        final current = HSVColor.fromColor(color);
                        _selectedHsv = current.withSaturation(_selectedHsv.saturation).withValue(_selectedHsv.value);
                        _hexController.text = _colorToHex(_selectedHsv.toColor());
                      });
                      applyColor(_selectedHsv.toColor());
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final color = selectedColor;
                            widget.onAddColor?.call(color);
                            applyColor(color);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF333333),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: const Icon(Icons.add, size: 24),
                          label: const Text(
                            'افزودن رنگ',
                            style: TextStyle(fontFamily: 'Vazir', fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 108,
                        height: 52,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextField(
                            controller: _hexController,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                              ),
                            ),
                            onSubmitted: (value) {
                              final color = _hexToColor(value);
                              if (color != null) {
                                setState(() {
                                  _selectedHsv = HSVColor.fromColor(color);
                                  _hexController.text = _colorToHex(color);
                                });
                                applyColor(color);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showSpectrumPresets = true),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _showSpectrumPresets
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'طیف رنگ',
                    style: TextStyle(fontFamily: 'Vazir', fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showSpectrumPresets = false),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _showSpectrumPresets
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'رنگ ساده',
                    style: TextStyle(fontFamily: 'Vazir', fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  bool _sameGradient(List<Color>? a, List<Color>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value) return false;
    }
    return true;
  }
}

class _SpectrumPresetGrid extends StatelessWidget {
  final ValueChanged<List<Color>> onSelect;
  final List<Color>? selectedGradient;

  const _SpectrumPresetGrid({required this.onSelect, this.selectedGradient});

  static const List<List<Color>> _presets = [
    [Color(0xFF00E0A4), Color(0xFF29D97A)],
    [Color(0xFFFF4E8A), Color(0xFF4B7BFF)],
    [Color(0xFFFF4D00), Color(0xFFFFC300)],
    [Color(0xFFFF8A6A), Color(0xFFFF4C6A)],
    [Color(0xFF3BA8FF), Color(0xFF2F8DFF)],
    [Color(0xFF9CFFF8), Color(0xFF32D6FF)],
    [Color(0xFFFFA800), Color(0xFFFFE600)],
    [Color(0xFFFF00F5), Color(0xFF2C2CFF)],
    [Color(0xFFFFE8A3), Color(0xFFFFC300)],
    [Color(0xFFFF6A7D), Color(0xFFFFD08A)],
    [Color(0xFF00C6A2), Color(0xFF002B3A)],
    [Color(0xFFFCE1FF), Color(0xFFDA5BA3)],
    [Color(0xFF6BD5E8), Color(0xFFD1F3F8)],
    [Color(0xFFE0E0E0), Color(0xFFFFFFFF)],
    [Color(0xFF14D8FF), Color(0xFFE8FF2F)],
    [Color(0xFFFFFF3A), Color(0xFFFFFFFF)],
    [Color(0xFFE552FF), Color(0xFF79F2FF)],
    [Color(0xFF96FFD8), Color(0xFFEFFFF0)],
    [Color(0xFFFFE600), Color(0xFFFF4AA8)],
    [Color(0xFFE500FF), Color(0xFF00D0FF)],
    [Color(0xFF5A7D13), Color(0xFF1C2525)],
    [Color(0xFFFF4D2A), Color(0xFFE51D7A)],
    [Color(0xFF00B894), Color(0xFFE8D95C)],
    [Color(0xFF6FD23C), Color(0xFFB5F28B)],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1,
        ),
        itemCount: _presets.length,
        itemBuilder: (_, index) {
          final gradient = _presets[index];
          final isSelected = selectedGradient != null &&
              selectedGradient!.length == gradient.length &&
              List.generate(
                gradient.length,
                (i) => selectedGradient![i].value == gradient[i].value,
              ).every((v) => v);
          return GestureDetector(
            onTap: () => onSelect(gradient),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              ),
              padding: const EdgeInsets.all(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SaturationValuePicker extends StatelessWidget {
  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onChanged;

  const _SaturationValuePicker({
    required this.hsvColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.45,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final thumbX = hsvColor.saturation * constraints.maxWidth;
          final thumbY = (1 - hsvColor.value) * constraints.maxHeight;

          void select(Offset position) {
            final saturation = (position.dx / constraints.maxWidth).clamp(0.0, 1.0);
            final value = (1 - position.dy / constraints.maxHeight).clamp(0.0, 1.0);
            onChanged(hsvColor.withSaturation(saturation).withValue(value));
          }

          return GestureDetector(
            onPanDown: (details) => select(details.localPosition),
            onPanUpdate: (details) => select(details.localPosition),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: HSVColor.fromAHSV(1, hsvColor.hue, 1, 1).toColor()),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.transparent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbX - 14,
                    top: thumbY - 14,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _HueSlider({required this.currentColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanDown: (details) => _selectColor(details.localPosition.dx, constraints.maxWidth),
            onPanUpdate: (details) => _selectColor(details.localPosition.dx, constraints.maxWidth),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (HSVColor.fromColor(currentColor).hue / 360 * constraints.maxWidth) - 14,
                  top: -7,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentColor,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectColor(double x, double width) {
    final hue = (x / width).clamp(0.0, 1.0) * 360;
    final color = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    onColorSelected(color);
  }
}
