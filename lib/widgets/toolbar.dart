import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Figma toolbar: 4 equal tabs, left-to-right: create, style, color, font.
enum ToolbarTab { create, style, color, font }

class BottomToolbar extends StatefulWidget {
  final ToolbarTab? activeTab;
  final ValueChanged<ToolbarTab> onTabSelected;
  final void Function(ToolbarTab tab)? onTabLongPress;

  const BottomToolbar({
    super.key,
    this.activeTab,
    required this.onTabSelected,
    this.onTabLongPress,
  });

  @override
  State<BottomToolbar> createState() => _BottomToolbarState();
}

class _BottomToolbarState extends State<BottomToolbar> {
  // Frame 545: height 48, left/right 24, bottom 12, bg #262626, radius 14
  static const double _barHeight = 48;
  static const double _horizontalMargin = 24;
  static const double _bottomMargin = 12;
  static const double _tabWidth = 91; // Frame 510 per tab
  static const double _pillWidth = 79;
  static const double _pillHeight = 36;
  static const double _pillInset = 6;

  bool _showPinPopoverFont = false;

  double _activeTabLeft(double barWidth) {
    final tabWidth = barWidth / 4;
    final tabIndex = ToolbarTab.values.indexOf(widget.activeTab!);
    return tabIndex * tabWidth + (tabWidth - _pillWidth) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final barWidth = (screenWidth - _horizontalMargin * 2).clamp(0.0, _tabWidth * 4);
    final tabWidth = barWidth / 4;

    return Padding(
      padding: const EdgeInsets.only(
        left: _horizontalMargin,
        right: _horizontalMargin,
        bottom: _bottomMargin,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: barWidth,
          height: _barHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bar background (Neutral/Gray 90 #262626, radius 14)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.toolbarBg,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              // Selected tab pill (Neutral/Gray 80 #393939, inset 6, radius 10)
              if (widget.activeTab != null)
                Positioned(
                  left: _activeTabLeft(barWidth),
                  top: _pillInset,
                  child: Container(
                    width: _pillWidth,
                    height: _pillHeight,
                    decoration: BoxDecoration(
                      color: AppColors.toolbarActiveBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              // Tabs: create | style | color | font — با long-press روی font پین می‌شود
              Row(
                children: ToolbarTab.values.asMap().entries.map((entry) {
                  final tab = entry.value;
                  final isActive = widget.activeTab == tab;
                  final color = isActive
                      ? Colors.white
                      : AppColors.toolbarInactiveIcon;
                  return SizedBox(
                    width: tabWidth,
                    height: _barHeight,
                    child: GestureDetector(
                      onTap: () => widget.onTabSelected(tab),
                      onLongPress: tab == ToolbarTab.font
                          ? () {
                              setState(() => _showPinPopoverFont = true);
                              widget.onTabLongPress?.call(tab);
                              Future.delayed(const Duration(milliseconds: 400), () {
                                if (mounted) setState(() => _showPinPopoverFont = false);
                              });
                            }
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          _labelForTab(tab),
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              // پاپ‌آپ ستاره بالای تب فونت وقتی long-press
              if (_showPinPopoverFont)
                Positioned(
                  left: 3 * tabWidth + (tabWidth - 42) / 2,
                  bottom: _barHeight + 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star_rounded, size: 22, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _labelForTab(ToolbarTab tab) {
    switch (tab) {
      case ToolbarTab.create:
        return 'تنظیم متن';
      case ToolbarTab.style:
        return 'استایل';
      case ToolbarTab.color:
        return 'رنگ';
      case ToolbarTab.font:
        return 'فونت';
    }
  }
}
