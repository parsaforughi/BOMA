import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../services/canvas_state.dart';
import '../../utils/farsi_utils.dart';

class TextControlsSheet extends ConsumerWidget {
  final VoidCallback onClose;

  const TextControlsSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvas = ref.watch(canvasProvider);
    final notifier = ref.read(canvasProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'تنظیمات متن',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                onPressed: onClose,
              ),
            ],
          ),
          // Font Size
          _SliderControl(
            label: 'اندازه فونت',
            value: canvas.fontSize,
            min: 12,
            max: 80,
            displayValue: toFarsiNumber(canvas.fontSize.toInt()),
            onChanged: (v) => notifier.setFontSize(v),
          ),
          // Letter Spacing
          _SliderControl(
            label: 'فاصله حروف',
            value: canvas.letterSpacing,
            min: -5,
            max: 20,
            displayValue: toFarsiNumber(canvas.letterSpacing.toStringAsFixed(1)),
            onChanged: (v) => notifier.setLetterSpacing(v),
          ),
          // Word Spacing
          _SliderControl(
            label: 'فاصله کلمات',
            value: canvas.wordSpacing,
            min: -5,
            max: 30,
            displayValue: toFarsiNumber(canvas.wordSpacing.toStringAsFixed(1)),
            onChanged: (v) => notifier.setWordSpacing(v),
          ),
          // Line Height
          _SliderControl(
            label: 'فاصله خطوط',
            value: canvas.lineHeight,
            min: 0.8,
            max: 3.0,
            displayValue: toFarsiNumber(canvas.lineHeight.toStringAsFixed(1)),
            onChanged: (v) => notifier.setLineHeight(v),
          ),
          // Opacity
          _SliderControl(
            label: 'شفافیت',
            value: canvas.opacity,
            min: 0.0,
            max: 1.0,
            displayValue: '${toFarsiNumber((canvas.opacity * 100).toInt())}٪',
            onChanged: (v) => notifier.setOpacity(v),
          ),
          // Alignment
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'تراز متن',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _AlignButton(
                icon: Icons.format_align_right,
                isActive: canvas.textAlign == TextAlign.right,
                onTap: () => notifier.setTextAlign(TextAlign.right),
              ),
              _AlignButton(
                icon: Icons.format_align_center,
                isActive: canvas.textAlign == TextAlign.center,
                onTap: () => notifier.setTextAlign(TextAlign.center),
              ),
              _AlignButton(
                icon: Icons.format_align_left,
                isActive: canvas.textAlign == TextAlign.left,
                onTap: () => notifier.setTextAlign(TextAlign.left),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderControl({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.blueAccent,
                inactiveTrackColor: AppColors.border,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                trackHeight: 3,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              displayValue,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlignButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _AlignButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blueAccent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
