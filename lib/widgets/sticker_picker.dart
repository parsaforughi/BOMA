import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorite_backgrounds_provider.dart';
import '../providers/favorite_stickers_provider.dart';
import '../services/export_service.dart';
import '../theme/colors.dart';
import '../models/sticker_item.dart';

enum _PickerTab { backgrounds, stickers }

class _BackgroundItem {
  final String id;
  final Color? color;
  final List<Color>? gradient;
  final String? imagePath; // مسیر asset تصویر

  const _BackgroundItem({
    required this.id,
    this.color,
    this.gradient,
    this.imagePath,
  }) : assert(color != null || gradient != null || imagePath != null);
}

class StickerPickerPanel extends ConsumerStatefulWidget {
  const StickerPickerPanel({super.key});

  @override
  ConsumerState<StickerPickerPanel> createState() => _StickerPickerPanelState();
}

class _StickerPickerPanelState extends ConsumerState<StickerPickerPanel> {
  static const String _favoritesCategory = 'علاقه‌مندی‌ها';

  late final Map<String, List<StickerItem>> _groupedStickers;
  late final Map<String, List<_BackgroundItem>> _backgroundPacks;
  late final Map<String, _BackgroundItem> _backgroundById;
  _PickerTab _activeTab = _PickerTab.stickers;
  String? _openedCategory;
  String? _openedBackgroundCategory;

  @override
  void initState() {
    super.initState();
    _groupedStickers = _buildGroups(StickerItem.allStickers);
    _backgroundPacks = _buildBackgroundPacks();
    _backgroundById = {
      for (final items in _backgroundPacks.values)
        for (final item in items) item.id: item,
    };
  }

  Map<String, List<_BackgroundItem>> _buildBackgroundPacks() {
    return const {
      'کاراکتر ۳D': [
        _BackgroundItem(id: '3d_1',  imagePath: 'assets/styles/backgrounds/3D Character/1.jpg'),
        _BackgroundItem(id: '3d_2',  imagePath: 'assets/styles/backgrounds/3D Character/2.jpg'),
        _BackgroundItem(id: '3d_3',  imagePath: 'assets/styles/backgrounds/3D Character/3.jpg'),
        _BackgroundItem(id: '3d_4',  imagePath: 'assets/styles/backgrounds/3D Character/4.jpg'),
        _BackgroundItem(id: '3d_5',  imagePath: 'assets/styles/backgrounds/3D Character/5.jpg'),
        _BackgroundItem(id: '3d_6',  imagePath: 'assets/styles/backgrounds/3D Character/6.jpg'),
        _BackgroundItem(id: '3d_7',  imagePath: 'assets/styles/backgrounds/3D Character/7.jpg'),
        _BackgroundItem(id: '3d_8',  imagePath: 'assets/styles/backgrounds/3D Character/8.jpg'),
        _BackgroundItem(id: '3d_9',  imagePath: 'assets/styles/backgrounds/3D Character/9.jpg'),
        _BackgroundItem(id: '3d_10', imagePath: 'assets/styles/backgrounds/3D Character/10.jpg'),
        _BackgroundItem(id: '3d_11', imagePath: 'assets/styles/backgrounds/3D Character/11.jpg'),
        _BackgroundItem(id: '3d_12', imagePath: 'assets/styles/backgrounds/3D Character/12.jpg'),
        _BackgroundItem(id: '3d_13', imagePath: 'assets/styles/backgrounds/3D Character/13.jpg'),
        _BackgroundItem(id: '3d_14', imagePath: 'assets/styles/backgrounds/3D Character/14.jpg'),
        _BackgroundItem(id: '3d_15', imagePath: 'assets/styles/backgrounds/3D Character/15.jpg'),
        _BackgroundItem(id: '3d_16', imagePath: 'assets/styles/backgrounds/3D Character/16.jpg'),
        _BackgroundItem(id: '3d_17', imagePath: 'assets/styles/backgrounds/3D Character/17.jpg'),
        _BackgroundItem(id: '3d_18', imagePath: 'assets/styles/backgrounds/3D Character/18.jpg'),
        _BackgroundItem(id: '3d_19', imagePath: 'assets/styles/backgrounds/3D Character/19.jpg'),
        _BackgroundItem(id: '3d_20', imagePath: 'assets/styles/backgrounds/3D Character/20.jpg'),
        _BackgroundItem(id: '3d_21', imagePath: 'assets/styles/backgrounds/3D Character/21.jpg'),
        _BackgroundItem(id: '3d_22', imagePath: 'assets/styles/backgrounds/3D Character/22.jpg'),
        _BackgroundItem(id: '3d_23', imagePath: 'assets/styles/backgrounds/3D Character/23.jpg'),
      ],
      'ماشین': [
        _BackgroundItem(id: 'car_1',  imagePath: 'assets/styles/backgrounds/Car/1.jpg'),
        _BackgroundItem(id: 'car_2',  imagePath: 'assets/styles/backgrounds/Car/2.jpg'),
        _BackgroundItem(id: 'car_3',  imagePath: 'assets/styles/backgrounds/Car/3.jpg'),
        _BackgroundItem(id: 'car_4',  imagePath: 'assets/styles/backgrounds/Car/4.jpg'),
        _BackgroundItem(id: 'car_5',  imagePath: 'assets/styles/backgrounds/Car/5.jpg'),
        _BackgroundItem(id: 'car_6',  imagePath: 'assets/styles/backgrounds/Car/6.jpg'),
        _BackgroundItem(id: 'car_7',  imagePath: 'assets/styles/backgrounds/Car/7.jpg'),
        _BackgroundItem(id: 'car_8',  imagePath: 'assets/styles/backgrounds/Car/8.jpg'),
        _BackgroundItem(id: 'car_9',  imagePath: 'assets/styles/backgrounds/Car/9.jpg'),
        _BackgroundItem(id: 'car_10', imagePath: 'assets/styles/backgrounds/Car/10.jpg'),
        _BackgroundItem(id: 'car_11', imagePath: 'assets/styles/backgrounds/Car/11.jpg'),
        _BackgroundItem(id: 'car_12', imagePath: 'assets/styles/backgrounds/Car/12.jpg'),
        _BackgroundItem(id: 'car_13', imagePath: 'assets/styles/backgrounds/Car/13.jpg'),
        _BackgroundItem(id: 'car_14', imagePath: 'assets/styles/backgrounds/Car/14.jpg'),
        _BackgroundItem(id: 'car_15', imagePath: 'assets/styles/backgrounds/Car/15.jpg'),
        _BackgroundItem(id: 'car_16', imagePath: 'assets/styles/backgrounds/Car/16.jpg'),
        _BackgroundItem(id: 'car_17', imagePath: 'assets/styles/backgrounds/Car/17.jpg'),
      ],
      'گلس مورفیسم': [
        _BackgroundItem(id: 'glass_1',  imagePath: 'assets/styles/backgrounds/Glass Morphism/1.jpg'),
        _BackgroundItem(id: 'glass_2',  imagePath: 'assets/styles/backgrounds/Glass Morphism/2.jpg'),
        _BackgroundItem(id: 'glass_3',  imagePath: 'assets/styles/backgrounds/Glass Morphism/3.jpg'),
        _BackgroundItem(id: 'glass_4',  imagePath: 'assets/styles/backgrounds/Glass Morphism/4.jpg'),
        _BackgroundItem(id: 'glass_5',  imagePath: 'assets/styles/backgrounds/Glass Morphism/5.jpg'),
        _BackgroundItem(id: 'glass_6',  imagePath: 'assets/styles/backgrounds/Glass Morphism/6.jpg'),
        _BackgroundItem(id: 'glass_7',  imagePath: 'assets/styles/backgrounds/Glass Morphism/7.jpg'),
        _BackgroundItem(id: 'glass_8',  imagePath: 'assets/styles/backgrounds/Glass Morphism/8.jpg'),
        _BackgroundItem(id: 'glass_9',  imagePath: 'assets/styles/backgrounds/Glass Morphism/9.jpg'),
        _BackgroundItem(id: 'glass_10', imagePath: 'assets/styles/backgrounds/Glass Morphism/10.jpg'),
      ],
      'نورپردازی': [
        _BackgroundItem(id: 'lights_1',  imagePath: 'assets/styles/backgrounds/Lights/1.jpg'),
        _BackgroundItem(id: 'lights_2',  imagePath: 'assets/styles/backgrounds/Lights/2.jpg'),
        _BackgroundItem(id: 'lights_3',  imagePath: 'assets/styles/backgrounds/Lights/3.jpg'),
        _BackgroundItem(id: 'lights_4',  imagePath: 'assets/styles/backgrounds/Lights/4.jpg'),
        _BackgroundItem(id: 'lights_5',  imagePath: 'assets/styles/backgrounds/Lights/5.jpg'),
        _BackgroundItem(id: 'lights_6',  imagePath: 'assets/styles/backgrounds/Lights/6.jpg'),
        _BackgroundItem(id: 'lights_7',  imagePath: 'assets/styles/backgrounds/Lights/7.jpg'),
        _BackgroundItem(id: 'lights_8',  imagePath: 'assets/styles/backgrounds/Lights/8.jpg'),
        _BackgroundItem(id: 'lights_9',  imagePath: 'assets/styles/backgrounds/Lights/9.jpg'),
        _BackgroundItem(id: 'lights_10', imagePath: 'assets/styles/backgrounds/Lights/10.jpg'),
      ],
      'طبیعت': [
        _BackgroundItem(id: 'nature_0', gradient: [Color(0xFFFF4E25), Color(0xFF2FA8E8), Color(0xFFE4525D)]),
        _BackgroundItem(id: 'nature_1', gradient: [Color(0xFF240046), Color(0xFF6D2BFF), Color(0xFF006D77)]),
        _BackgroundItem(id: 'nature_2', gradient: [Color(0xFF0F2027), Color(0xFF2C5364), Color(0xFFFF6B6B)]),
        _BackgroundItem(id: 'nature_3', gradient: [Color(0xFF134E5E), Color(0xFF71B280)]),
        _BackgroundItem(id: 'nature_4', gradient: [Color(0xFFFF9966), Color(0xFFFF5E62)]),
        _BackgroundItem(id: 'nature_5', gradient: [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
      ],
      'گرادیان': [
        _BackgroundItem(id: 'gradient_0', gradient: [Color(0xFF12C2E9), Color(0xFFC471ED), Color(0xFFF64F59)]),
        _BackgroundItem(id: 'gradient_1', gradient: [Color(0xFF00F5A0), Color(0xFF00D9F5)]),
        _BackgroundItem(id: 'gradient_2', gradient: [Color(0xFFFFC371), Color(0xFFFF5F6D)]),
        _BackgroundItem(id: 'gradient_3', gradient: [Color(0xFF7F00FF), Color(0xFFE100FF)]),
        _BackgroundItem(id: 'gradient_4', gradient: [Color(0xFF43C6AC), Color(0xFFF8FFAE)]),
        _BackgroundItem(id: 'gradient_5', gradient: [Color(0xFF4568DC), Color(0xFFB06AB3)]),
      ],
      'ساده': [
        _BackgroundItem(id: 'solid_0', color: Color(0xFF324F9D)),
        _BackgroundItem(id: 'solid_1', color: Color(0xFF101111)),
        _BackgroundItem(id: 'solid_2', color: Color(0xFF636665)),
        _BackgroundItem(id: 'solid_3', color: Color(0xFF009D9A)),
        _BackgroundItem(id: 'solid_4', color: Color(0xFF4589FF)),
        _BackgroundItem(id: 'solid_5', color: Color(0xFFFFB784)),
      ],
    };
  }

  Map<String, List<StickerItem>> _buildGroups(List<StickerItem> stickers) {
    final map = <String, List<StickerItem>>{};
    for (final s in stickers) {
      final parts = s.assetPath.split('/');
      final rawCategory = parts.length > 2 ? parts[2] : 'General';
      final category = _localizedCategoryName(rawCategory);
      map.putIfAbsent(category, () => <StickerItem>[]);
      map[category]!.add(s);
    }
    return map;
  }

  String _localizedCategoryName(String raw) {
    switch (raw) {
      case 'Memes':
        return 'پک میم ها';
      case 'Emoji':
        return 'ایموجی';
      case 'Arrow':
        return 'فلش';
      case 'Frame':
        return 'فریم';
      case 'Like':
        return 'لایک';
      case 'Nowruz':
        return 'نوروز';
      case 'Sale':
        return 'فروش';
      case 'Social Media':
        return 'شبکه اجتماعی';
      default:
        return raw;
    }
  }

  Future<void> _copyStickerToClipboard(StickerItem sticker) async {
    await Clipboard.setData(ClipboardData(text: sticker.assetPath));
    if (!mounted) return;
    _showBanner('استیکر در کلیپبورد شما کپی شد');
  }

  Future<Uint8List?> _renderBackgroundImage(_BackgroundItem item) async {
    // اگر تصویر asset داره، مستقیم بایت‌هاشو برگردون
    if (item.imagePath != null) {
      final data = await rootBundle.load(item.imagePath!);
      return data.buffer.asUint8List();
    }

    const width = 1080;
    const height = 1920;
    final w = width.toDouble();
    final h = height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    final paint = Paint();
    if (item.gradient != null) {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: item.gradient!,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      paint.color = item.color!;
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _showBackgroundSaveSheet(_BackgroundItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E2433),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
                title: const Text(
                  'ذخیره در گالری',
                  style: TextStyle(fontFamily: 'Vazir', color: Colors.white, fontSize: 16),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final bytes = await _renderBackgroundImage(item);
                  if (!mounted || bytes == null) return;
                  final ok = await ExportService.saveToGallery(bytes);
                  if (!mounted) return;
                  _showBanner(ok ? 'بک‌گراند در گالری ذخیره شد' : 'خطا در ذخیره‌سازی');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBanner(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.transparent,
        elevation: 0,
        forceActionsBelow: false,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF26334A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF22C55E), width: 2),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                const Icon(Icons.close, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: const [SizedBox.shrink()],
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stickerFavorites = ref.watch(favoriteStickersProvider);
    final bgFavorites = ref.watch(favoriteBackgroundsProvider);
    final favoriteStickers = stickerFavorites.favoriteStickers;
    final favoriteBackgrounds = bgFavorites.favoriteBackgroundIds
        .map((id) => _backgroundById[id])
        .whereType<_BackgroundItem>()
        .toList();

    final categories = [
      _favoritesCategory,
      ..._groupedStickers.keys,
    ];
    final openedStickers = _openedCategory == null
        ? const <StickerItem>[]
        : _openedCategory == _favoritesCategory
            ? favoriteStickers
            : (_groupedStickers[_openedCategory] ?? const <StickerItem>[]);

    final backgroundCategories = [
      _favoritesCategory,
      ..._backgroundPacks.keys,
    ];
    final openedBackgrounds = _openedBackgroundCategory == null
        ? const <_BackgroundItem>[]
        : _openedBackgroundCategory == _favoritesCategory
            ? favoriteBackgrounds
            : (_backgroundPacks[_openedBackgroundCategory] ?? const <_BackgroundItem>[]);

    final isBackgroundTab = _activeTab == _PickerTab.backgrounds;
    final title = isBackgroundTab
        ? (_openedBackgroundCategory ?? 'بکگراند')
        : (_openedCategory ?? 'استیکر');
    final canGoBack = isBackgroundTab ? _openedBackgroundCategory != null : _openedCategory != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              if (canGoBack)
                IconButton(
                  onPressed: () => setState(() {
                    if (isBackgroundTab) {
                      _openedBackgroundCategory = null;
                    } else {
                      _openedCategory = null;
                    }
                  }),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                ),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isBackgroundTab
              ? (_openedBackgroundCategory == null
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: backgroundCategories.length,
                      itemBuilder: (context, index) {
                        final category = backgroundCategories[index];
                        final isFavCategory = category == _favoritesCategory;
                        final items = isFavCategory
                            ? favoriteBackgrounds
                            : (_backgroundPacks[category] ?? const <_BackgroundItem>[]);
                        final preview = items.isNotEmpty ? items.first : null;
                        return GestureDetector(
                          onTap: () => setState(() => _openedBackgroundCategory = category),
                          child: isFavCategory
                              ? _FavoritesCategoryCard()
                              : _BackgroundCategoryCard(item: preview),
                        );
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: openedBackgrounds.length,
                      itemBuilder: (context, index) {
                        final item = openedBackgrounds[index];
                        final isFavorite = bgFavorites.favoriteBackgroundIds.contains(item.id);
                        return GestureDetector(
                          onTap: () => _showBackgroundSaveSheet(item),
                          child: _BackgroundCard(
                            item: item,
                            isFavorite: isFavorite,
                            onFavoriteTap: () {
                              ref.read(favoriteBackgroundsProvider.notifier).toggleFavorite(item.id);
                            },
                          ),
                        );
                      },
                    ))
              : (_openedCategory == null
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isFavCategory = category == _favoritesCategory;
                        if (isFavCategory) {
                          return GestureDetector(
                            onTap: () => setState(() => _openedCategory = category),
                            child: const _FavoritesCategoryCard(),
                          );
                        }
                        final stickers = _groupedStickers[category] ?? const <StickerItem>[];
                        final preview = stickers.isNotEmpty ? stickers.first.assetPath : null;
                        return GestureDetector(
                          onTap: () => setState(() => _openedCategory = category),
                          child: _StickerCategoryCard(
                            previewAsset: preview,
                            label: category,
                          ),
                        );
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: openedStickers.length,
                      itemBuilder: (context, index) {
                        final sticker = openedStickers[index];
                        final isFavorite = stickerFavorites.favoriteStickerPaths.contains(sticker.assetPath);
                        return GestureDetector(
                          onTap: () => _copyStickerToClipboard(sticker),
                          child: _StickerCard(
                            sticker: sticker,
                            isFavorite: isFavorite,
                            onFavoriteTap: () {
                              ref.read(favoriteStickersProvider.notifier).toggleFavorite(sticker.assetPath);
                            },
                          ),
                        );
                      },
                    )),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(34, 4, 34, 12),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.toolbarBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Expanded(
                    child: _PanelTabButton(
                      icon: Icons.image_outlined,
                      isActive: _activeTab == _PickerTab.backgrounds,
                      onTap: () => setState(() {
                        _activeTab = _PickerTab.backgrounds;
                        _openedCategory = null;
                      }),
                    ),
                  ),
                  Expanded(
                    child: _PanelTabButton(
                      icon: Icons.emoji_emotions_outlined,
                      isActive: _activeTab == _PickerTab.stickers,
                      onTap: () => setState(() {
                        _activeTab = _PickerTab.stickers;
                        _openedBackgroundCategory = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// علاقه‌مندی‌ها — همیشه آیکون قلب، بدون پیش‌نمایش اولین آیتم.
class _FavoritesCategoryCard extends StatelessWidget {
  const _FavoritesCategoryCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          const Expanded(
            child: Center(
              child: Icon(Icons.favorite_rounded, color: Color(0xFFFFD166), size: 40),
            ),
          ),
          const _BottomHeartBar(isActive: true),
        ],
      ),
    );
  }
}

class _StickerCategoryCard extends StatelessWidget {
  final String? previewAsset;
  final String label;

  const _StickerCategoryCard({this.previewAsset, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          Expanded(
            child: previewAsset != null
                ? Image.asset(previewAsset!, fit: BoxFit.contain)
                : const SizedBox.shrink(),
          ),
          Container(
            height: 24,
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2D313A),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Vazir',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundCategoryCard extends StatelessWidget {
  final _BackgroundItem? item;

  const _BackgroundCategoryCard({this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: item?.imagePath != null
            ? Image.asset(
                item!.imagePath!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2D313A)),
              )
            : Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: item?.color ?? const Color(0xFF2D313A),
                  gradient: item?.gradient != null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item!.gradient!,
                        )
                      : null,
                ),
              ),
      ),
    );
  }
}

class _BottomHeartBar extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const _BottomHeartBar({required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 24,
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2D313A),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          isActive ? Icons.favorite : Icons.favorite_border,
          color: isActive ? const Color(0xFFFFD166) : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _StickerCard extends StatelessWidget {
  final StickerItem sticker;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _StickerCard({
    required this.sticker,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              sticker.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.emoji_emotions,
                color: AppColors.textTertiary,
                size: 48,
              ),
            ),
          ),
          _BottomHeartBar(isActive: isFavorite, onTap: onFavoriteTap),
        ],
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  final _BackgroundItem item;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  const _BackgroundCard({
    required this.item,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imagePath != null
                  ? Image.asset(
                      item.imagePath!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2D313A)),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: item.color ?? const Color(0xFF2D313A),
                        gradient: item.gradient != null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: item.gradient!,
                              )
                            : null,
                      ),
                    ),
            ),
          ),
          _BottomHeartBar(isActive: isFavorite, onTap: onFavoriteTap),
        ],
      ),
    );
  }
}

class _PanelTabButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PanelTabButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.toolbarActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : AppColors.toolbarInactiveIcon,
            size: 26,
          ),
        ),
      ),
    );
  }
}
