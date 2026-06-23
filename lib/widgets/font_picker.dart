import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../models/font_item.dart';
import '../services/font_service.dart';
import '../services/canvas_state.dart';
import '../services/auth_service.dart';

class FontPickerPanel extends ConsumerStatefulWidget {
  const FontPickerPanel({super.key});

  @override
  ConsumerState<FontPickerPanel> createState() => _FontPickerPanelState();
}

class _FontPickerPanelState extends ConsumerState<FontPickerPanel> {
  int _tabIndex = 0; // 0: all, 1: favorites, 2: standard, 3: fancy, 4: formal

  @override
  Widget build(BuildContext context) {
    final fontState = ref.watch(fontProvider);
    final canvasState = ref.watch(canvasProvider);
    final isPro = ref.watch(authProvider).isPro;

    List<FontItem> fonts;
    switch (_tabIndex) {
      case 1:
        fonts = fontState.favoriteFontItems;
        break;
      case 2:
        fonts = FontItem.allFonts.where((f) => f.category == FontCategory.standard).toList();
        break;
      case 3:
        fonts = FontItem.allFonts.where((f) => f.category == FontCategory.fancy).toList();
        break;
      case 4:
        fonts = FontItem.allFonts.where((f) => f.category == FontCategory.formal).toList();
        break;
      default:
        fonts = FontItem.allFonts;
    }

    return Column(
      children: [
        // Tab bar
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _TabChip(label: 'همه', isActive: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
              _TabChip(label: '❤ علاقه‌مندی', isActive: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
              _TabChip(label: 'ساده', isActive: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2)),
              _TabChip(label: 'فانتزی', isActive: _tabIndex == 3, onTap: () => setState(() => _tabIndex = 3)),
              _TabChip(label: 'رسمی', isActive: _tabIndex == 4, onTap: () => setState(() => _tabIndex = 4)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Font list
        Expanded(
          child: fonts.isEmpty
              ? Center(
                  child: Text(
                    _tabIndex == 1 ? 'فونت مورد علاقه‌ای ندارید' : 'فونتی یافت نشد',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: fonts.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final font = fonts[index];
                    final isSelected = canvasState.fontFamily == font.family;
                    final isFav = fontState.favoriteFonts.contains(font.name);
                    final isLocked = font.isPro && !isPro;

                    return GestureDetector(
                      onTap: isLocked
                          ? null
                          : () {
                              ref.read(canvasProvider.notifier).setFont(font.family);
                              ref.read(fontProvider.notifier).selectFont(font.name);
                            },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.blueAccent.withValues(alpha: 0.15)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: AppColors.blueAccent, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    font.displayName,
                                    style: TextStyle(
                                      fontFamily: font.family,
                                      fontSize: 18,
                                      color: isLocked
                                          ? AppColors.textTertiary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'نمونه متن فارسی',
                                    style: TextStyle(
                                      fontFamily: font.family,
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isLocked)
                              const Icon(Icons.lock, size: 18, color: AppColors.textTertiary)
                            else
                              GestureDetector(
                                onTap: () => ref.read(fontProvider.notifier).toggleFavorite(font.name),
                                child: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  size: 20,
                                  color: isFav ? AppColors.errorLight : AppColors.textTertiary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blueAccent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 12,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
