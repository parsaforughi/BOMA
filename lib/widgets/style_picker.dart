import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pinned_styles_provider.dart';
import '../theme/colors.dart';
import '../models/text_style_preset.dart';
import '../services/canvas_state.dart';

/// Design: Frame 656 — style cards 72×78, radius 14, gap 8.
/// Pin: long-press → glass pill + push_pin above card (color strip pattern).
/// Select: thin glass stroke (1px), not a thick padded frame.
class StylePickerPanel extends ConsumerStatefulWidget {
  const StylePickerPanel({super.key});

  static const double _cardWidth = 72;
  static const double _cardHeight = 78;
  static const double _cardRadius = 14;
  static const double _cardGap = 8;
  static const double _pinPopoverExtra = 48;
  static const double _cardRowHeight = 88;

  @override
  ConsumerState<StylePickerPanel> createState() => _StylePickerPanelState();
}

class _StylePickerPanelState extends ConsumerState<StylePickerPanel> {
  int _selectedCategory = 0;
  String? _pinPopoverPresetId;

  List<TextStylePreset> _filteredPresets() {
    final presets = TextStylePreset.allPresets;
    List<TextStylePreset> filtered;
    switch (_selectedCategory) {
      case 1: // بک گراند
        filtered = presets
            .where((p) =>
                p.hasBubble ||
                p.canvasColor != null ||
                (p.canvasGradient != null && p.canvasGradient!.length >= 2))
            .toList();
        break;
      case 2: // رایگان
        filtered = presets.where((p) => !p.isPro).toList();
        break;
      case 3: // افکت متن
        filtered = presets
            .where((p) =>
                p.strokeColor != null ||
                p.shadowColor != null ||
                p.gradientColors != null ||
                p.hasBubble)
            .toList();
        break;
      case 4: // قالب — پکیج پیشرفته (۳۰ استایل)
        filtered = List<TextStylePreset>.from(TextStylePreset.pishraftePresets);
        break;
      default:
        filtered = presets;
    }
    // هرگز لیست خالی نشان نده
    if (filtered.isEmpty) return presets;
    return filtered;
  }

  List<Object> _orderedPresets(List<TextStylePreset> presets, List<String> pinnedIds) {
    final pinned = presets.where((p) => pinnedIds.contains(p.id)).toList();
    final unpinned = presets.where((p) => !pinnedIds.contains(p.id)).toList();
    final items = <Object>[...pinned];
    if (pinned.isNotEmpty && unpinned.isNotEmpty) {
      items.add('__divider__');
    }
    items.addAll(unpinned);
    return items;
  }

  Future<void> _onStyleLongPress(String presetId) async {
    setState(() => _pinPopoverPresetId = presetId);
    await ref.read(pinnedStylesProvider.notifier).toggleStyle(presetId);
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _pinPopoverPresetId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canvas = ref.watch(canvasProvider);
    final pinnedIds = ref.watch(pinnedStylesProvider);
    final presets = _filteredPresets();
    final orderedItems = _orderedPresets(presets, pinnedIds);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _StyleCategoryChip(
                  label: 'همه',
                  isActive: _selectedCategory == 0,
                  onTap: () => setState(() => _selectedCategory = 0),
                ),
                _StyleCategoryChip(
                  label: 'بک گراند',
                  isActive: _selectedCategory == 1,
                  onTap: () => setState(() => _selectedCategory = 1),
                ),
                _StyleCategoryChip(
                  label: 'رایگان',
                  isActive: _selectedCategory == 2,
                  onTap: () => setState(() => _selectedCategory = 2),
                ),
                _StyleCategoryChip(
                  label: 'افکت متن',
                  isActive: _selectedCategory == 3,
                  onTap: () => setState(() => _selectedCategory = 3),
                ),
                _StyleCategoryChip(
                  label: 'قالب',
                  isActive: _selectedCategory == 4,
                  onTap: () => setState(() => _selectedCategory = 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: StylePickerPanel._cardRowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: orderedItems.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: StylePickerPanel._cardGap),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildDefaultCard(context, ref, canvas);
                }
                final item = orderedItems[index - 1];
                if (item is String && item == '__divider__') {
                  return const _StylePinDivider();
                }
                final preset = item as TextStylePreset;
                final isActive = canvas.activePreset?.id == preset.id;
                final showPinPopover = _pinPopoverPresetId == preset.id;
                return GestureDetector(
                  onTap: () {
                    ref.read(canvasProvider.notifier).applyPreset(preset);
                  },
                  onLongPress: () => _onStyleLongPress(preset.id),
                  child: _StyleCard(
                    width: StylePickerPanel._cardWidth,
                    height: StylePickerPanel._cardHeight,
                    borderRadius: StylePickerPanel._cardRadius,
                    preset: preset,
                    isSelected: isActive,
                    showPinPopover: showPinPopover,
                    isLocked: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCard(BuildContext context, WidgetRef ref, CanvasState canvas) {
    const plainPreset = TextStylePreset(
      id: 'plain',
      name: 'Plain',
      displayName: 'پیشفرض',
      textColor: Colors.white,
    );
    final isActive = canvas.activePreset?.id == 'plain';

    final inner = Container(
      width: StylePickerPanel._cardWidth,
      height: StylePickerPanel._cardHeight,
      decoration: BoxDecoration(
        color: const Color(0x99002132), // rgba(0,33,50,0.6)
        borderRadius: BorderRadius.circular(StylePickerPanel._cardRadius),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 24, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 4),
          Text(
            'پیشفرض',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        ref.read(canvasProvider.notifier).applyPreset(plainPreset);
      },
      child: _StyleCardChrome(
        cardWidth: StylePickerPanel._cardWidth,
        cardHeight: StylePickerPanel._cardHeight,
        borderRadius: StylePickerPanel._cardRadius,
        isSelected: isActive,
        showPinPopover: false,
        child: inner,
      ),
    );
  }

  static Widget _buildPresetPreviewText(TextStylePreset preset) {
    final style = TextStyle(
      fontFamily: 'Vazir',
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: preset.textColor,
      shadows: preset.shadowColor != null
          ? [
              Shadow(
                color: preset.shadowColor!,
                offset: preset.shadowOffset ?? Offset.zero,
                blurRadius: preset.shadowBlur ?? 0,
              ),
            ]
          : null,
    );

    Widget text = Text('بما', style: style);

    if (preset.gradientColors != null && preset.gradientColors!.length >= 2) {
      text = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: preset.gradientColors!,
        ).createShader(bounds),
        child: Text('بما', style: style.copyWith(color: Colors.white)),
      );
    }

    if (preset.strokeColor != null) {
      text = Stack(
        children: [
          Text(
            'بما',
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = preset.strokeWidth ?? 2
                ..color = preset.strokeColor!,
            ),
          ),
          text,
        ],
      );
    }

    if (preset.hasBubble) {
      text = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: preset.backgroundColor ?? AppColors.blueAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: text,
      );
    }

    return text;
  }
}

/// جداکننده عمودی بین استایل‌های پین‌شده و بقیه (مثل پنل فونت).
class _StylePinDivider extends StatelessWidget {
  const _StylePinDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: StylePickerPanel._cardHeight - 12,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.border,
    );
  }
}

class _StyleCategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _StyleCategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isActive ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(18),
            border: isActive ? Border.all(color: Colors.white, width: 1) : null,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass chrome: pin popover (long-press) or selection halo — mirrors color strip.
class _StyleCardChrome extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final double borderRadius;
  final bool isSelected;
  final bool showPinPopover;
  final Widget child;

  const _StyleCardChrome({
    required this.cardWidth,
    required this.cardHeight,
    required this.borderRadius,
    required this.isSelected,
    required this.showPinPopover,
    required this.child,
  });

  static BoxDecoration _glassDecoration(double radius) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.26),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showPinPopover) {
      final outerW = cardWidth + 12;
      final outerH = cardHeight + StylePickerPanel._pinPopoverExtra;
      final outerR = borderRadius + 3;
      return SizedBox(
        width: outerW,
        height: outerH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: outerW,
                height: outerH,
                decoration: _glassDecoration(outerR),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(Icons.push_pin_rounded, size: 22, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(bottom: 0, child: child),
          ],
        ),
      );
    }

    if (isSelected) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.12),
              blurRadius: 3,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      );
    }

    return child;
  }
}

/// Single style card: 72×78, radius 14.
class _StyleCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final TextStylePreset preset;
  final bool isSelected;
  final bool showPinPopover;
  final bool isLocked;

  const _StyleCard({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.preset,
    required this.isSelected,
    this.showPinPopover = false,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: _cardGradient(preset),
        color: _cardGradient(preset) == null ? _cardSolidColor(preset) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isSelected ? null : _cardBorder(preset),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: preset.previewAsset != null
                  ? Image.asset(
                      preset.previewAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _StylePickerPanelState._buildPresetPreviewText(preset),
                        ),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _StylePickerPanelState._buildPresetPreviewText(preset),
                      ),
                    ),
            ),
          ),
          if (isLocked)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.overlayDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.lock, size: 12, color: AppColors.textTertiary),
              ),
            ),
        ],
      ),
    );

    return _StyleCardChrome(
      cardWidth: width,
      cardHeight: height,
      borderRadius: borderRadius,
      isSelected: isSelected,
      showPinPopover: showPinPopover,
      child: inner,
    );
  }

  static List<Color>? _gradientColors(TextStylePreset p) {
    if (p.gradientColors != null && p.gradientColors!.length >= 2) return p.gradientColors;
    if (p.id == 'neon_blue' || p.id == 'gradient_ocean') {
      return [const Color(0xFF0042FE), const Color(0xFF01BCFE)];
    }
    if (p.id == 'gradient_sunset') return [const Color(0xFFFF6B00), const Color(0xFFFF1493)];
    return null;
  }

  static LinearGradient? _cardGradient(TextStylePreset p) {
    final colors = _gradientColors(p);
    if (colors == null) return null;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );
  }

  static Color _cardSolidColor(TextStylePreset p) {
    if (p.strokeColor == Colors.white && p.textColor == Colors.black) {
      return Colors.white;
    }
    if (p.id == 'stroke_blue' || p.id.contains('blue')) {
      return const Color(0xFF0042FE);
    }
    if (p.id.contains('red') || p.strokeColor == const Color(0xFFE53935)) {
      return const Color(0xFFEF2A2B);
    }
    if (p.id.contains('green') || p.id == 'bubble') {
      return const Color(0xFF15735B);
    }
    return AppColors.surfaceVariant;
  }

  static Border? _cardBorder(TextStylePreset p) {
    if (p.id == 'stroke_white' || (p.strokeColor == Colors.white && p.textColor == Colors.black)) {
      return Border.all(color: const Color(0xFF706BFF), width: 2);
    }
    if (p.id.contains('green') || p.backgroundColor == const Color(0xFF15735B)) {
      return Border.all(color: Colors.white, width: 4);
    }
    return null;
  }
}
