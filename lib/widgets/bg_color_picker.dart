import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../services/canvas_state.dart';

class BgColorPickerPanel extends ConsumerStatefulWidget {
  const BgColorPickerPanel({super.key});

  @override
  ConsumerState<BgColorPickerPanel> createState() => _BgColorPickerPanelState();
}

class _BgColorPickerPanelState extends ConsumerState<BgColorPickerPanel> {
  bool _isGradientMode = false;
  Color _gradientStart = const Color(0xFF1759B4);
  Color _gradientEnd = const Color(0xFF46B1FF);

  @override
  Widget build(BuildContext context) {
    final canvas = ref.watch(canvasProvider);
    final notifier = ref.read(canvasProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle: Solid / Gradient
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text(
                'رنگ پس‌زمینه',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _ModeToggle(
                label: 'ساده',
                isActive: !_isGradientMode,
                onTap: () => setState(() => _isGradientMode = false),
              ),
              const SizedBox(width: 6),
              _ModeToggle(
                label: 'گرادیان',
                isActive: _isGradientMode,
                onTap: () => setState(() => _isGradientMode = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isGradientMode) ...[
          // Gradient preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Apply gradient button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 36,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  notifier.setBackgroundGradient([_gradientStart, _gradientEnd]);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'اعمال گرادیان',
                  style: TextStyle(fontFamily: 'Vazir', fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Preset background colors
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: AppColors.presetBackgrounds.length + _gradientPresets.length,
            itemBuilder: (context, index) {
              if (index < AppColors.presetBackgrounds.length) {
                final color = AppColors.presetBackgrounds[index];
                final isSelected = !_isGradientMode &&
                    canvas.backgroundColor == color &&
                    canvas.backgroundGradient == null;

                return GestureDetector(
                  onTap: () {
                    if (_isGradientMode) {
                      // Set as gradient start or end
                      setState(() {
                        if (_gradientStart == _gradientEnd) {
                          _gradientEnd = color;
                        } else {
                          _gradientStart = _gradientEnd;
                          _gradientEnd = color;
                        }
                      });
                    } else {
                      notifier.setBackgroundColor(color);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              } else {
                final gIndex = index - AppColors.presetBackgrounds.length;
                final gradient = _gradientPresets[gIndex];

                return GestureDetector(
                  onTap: () {
                    notifier.setBackgroundGradient(gradient);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  static const List<List<Color>> _gradientPresets = [
    [Color(0xFF1759B4), Color(0xFF46B1FF)],
    [Color(0xFFFF6B00), Color(0xFFFF1493)],
    [Color(0xFF2DD55B), Color(0xFF00FFFF)],
    [Color(0xFF6030FF), Color(0xFFFF1493)],
    [Color(0xFF000000), Color(0xFF1759B4)],
    [Color(0xFF0D3B0D), Color(0xFF2DD55B)],
    [Color(0xFF3B0D0D), Color(0xFFFF6B00)],
    [Color(0xFF1B1B3B), Color(0xFF6030FF)],
  ];
}

class _ModeToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeToggle({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blueAccent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 11,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
