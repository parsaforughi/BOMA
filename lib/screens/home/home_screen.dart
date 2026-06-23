import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../services/canvas_state.dart';
import '../../services/auth_service.dart';
import '../../services/draft_service.dart';
import '../../services/font_service.dart';
import '../../services/export_service.dart';
import '../../models/font_item.dart';
import '../../models/text_style_preset.dart';
import '../../utils/farsi_utils.dart';
import '../../widgets/text_canvas.dart';
import '../../widgets/toolbar.dart';
import '../../widgets/style_picker.dart';
import '../../widgets/color_picker.dart';
import '../../widgets/bottom_container.dart';
import '../../widgets/sticker_picker.dart';
import '../../providers/sticker_drag_provider.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/history_sheet.dart';
import '../../widgets/back_arrow_icon.dart';
import '../../providers/pinned_colors_provider.dart';
import '../../providers/custom_colors_provider.dart';
import '../../providers/custom_fonts_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _textExportKey = GlobalKey();
  final GlobalKey _trashZoneKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  Timer? _autoSaveDraftTimer;
  Timer? _persistSessionTimer;
  String? _lastAutoSavedDraftJson;
  bool _sessionRestored = false;

  ToolbarTab? _activeTab = ToolbarTab.font;
  // Sidebar slider: 12..80, inverted so drag UP = bigger (fontSize = 92 - value)
  static const double _fontSizeMin = 12, _fontSizeMax = 80;
  double _fontSizeSliderValue = 92 - 28; // 64 → displayed fontSize 28
  bool _showFontSizeValue = false;

  // Overlay states
  bool _showSaveSheet = false;
  bool _showTextControls = false;
  bool _showStickerPicker = false;

  // Font panel state
  int _fontCategoryIndex = 0; // 0=همه, 1=علاقه‌مندی‌ها, 2=رسمی, 3=فانتزی, 4=ساده, 5=وارد شده‌ها
  FontLanguage _selectedFontLanguage = FontLanguage.all;

  // پین رنگ: موقع long-press روی رنگ این مقدار ست می‌شود تا پاپ‌آپ ستاره نشان داده شود
  Color? _pinPopoverColor;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreLastSession());
  }

  Future<void> _restoreLastSession() async {
    if (!mounted || _sessionRestored) return;
    _sessionRestored = true;

    final storage = ref.read(storageServiceProvider);
    final notifier = ref.read(canvasProvider.notifier);
    final autoDraft = findAutoSavedDraft(storage);

    if (autoDraft != null) {
      final restored = draftMapToCanvasState(autoDraft);
      notifier.loadState(restored);
      _textController.text = restored.text;
      _fontSizeSliderValue =
          (92 - restored.fontSize).clamp(_fontSizeMin, _fontSizeMax);
    } else {
      const presets = TextStylePreset.pishraftePresets;
      if (presets.isNotEmpty) {
        notifier.applyPreset(presets.first);
      }
    }

    final session = storage.getLastSession();
    if (session != null) {
      final tabName = session['activeTab'] as String?;
      final tab = switch (tabName) {
        'style' => ToolbarTab.style,
        'color' => ToolbarTab.color,
        'create' => ToolbarTab.create,
        'font' => ToolbarTab.font,
        _ => ToolbarTab.font,
      };
      final fontCat = session['fontCategoryIndex'];
      if (mounted) {
        setState(() {
          _activeTab = tab == ToolbarTab.create ? ToolbarTab.font : tab;
          if (fontCat is int && fontCat >= 0 && fontCat <= 5) {
            _fontCategoryIndex = fontCat;
          }
        });
      }
    } else if (mounted) {
      setState(() => _activeTab = ToolbarTab.font);
    }

    final canvas = ref.read(canvasProvider);
    if (canvas.activePreset == null) {
      const presets = TextStylePreset.pishraftePresets;
      if (presets.isNotEmpty) {
        notifier.applyPreset(presets.first);
      }
    }
  }

  void _schedulePersistSession() {
    _persistSessionTimer?.cancel();
    _persistSessionTimer = Timer(const Duration(milliseconds: 400), () {
      _persistSessionNow();
    });
  }

  Future<void> _persistSessionNow() async {
    final canvas = ref.read(canvasProvider);
    final storage = ref.read(storageServiceProvider);
    await storage.saveLastSession({
      'fontFamily': canvas.fontFamily,
      'presetId': canvas.activePreset?.id,
      'activeTab': _activeTab?.name ?? 'font',
      'fontCategoryIndex': _fontCategoryIndex,
    });
  }

  void _onTextChanged() {
    ref.read(canvasProvider.notifier).setText(_textController.text);
  }

  bool _shouldAutoSaveDraft(CanvasState state) {
    const defaultState = CanvasState();
    return state.text.trim().isNotEmpty ||
        state.stickers.isNotEmpty ||
        state.fontFamily != defaultState.fontFamily ||
        state.fontSize != defaultState.fontSize ||
        state.letterSpacing != defaultState.letterSpacing ||
        state.wordSpacing != defaultState.wordSpacing ||
        state.lineHeight != defaultState.lineHeight ||
        state.opacity != defaultState.opacity ||
        state.fontWeight != defaultState.fontWeight ||
        state.textAlign != defaultState.textAlign ||
        state.textColor != defaultState.textColor ||
        state.backgroundColor != defaultState.backgroundColor ||
        state.backgroundGradient != null ||
        state.activePreset != null ||
        state.strokeColor != null ||
        state.strokeWidth != defaultState.strokeWidth ||
        state.shadowColor != null ||
        state.shadowBlur != defaultState.shadowBlur ||
        state.hasBubble != defaultState.hasBubble ||
        state.bubbleColor != defaultState.bubbleColor ||
        state.bubbleGradient != defaultState.bubbleGradient ||
        state.gradientColors != null;
  }

  void _scheduleAutoSaveDraft(CanvasState state) {
    _autoSaveDraftTimer?.cancel();
    if (!_shouldAutoSaveDraft(state)) return;
    _autoSaveDraftTimer = Timer(const Duration(milliseconds: 800), () {
      _saveAutoDraftNow(state);
    });
  }

  Future<void> _saveAutoDraftNow(CanvasState state) async {
    if (!_shouldAutoSaveDraft(state)) return;
    final draft = canvasToDraftMap(state);
    final draftJson = jsonEncode(draft);
    if (draftJson == _lastAutoSavedDraftJson) return;
    _lastAutoSavedDraftJson = draftJson;
    final storage = ref.read(storageServiceProvider);
    await upsertAutoDraft(storage, draft);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _autoSaveDraftTimer?.cancel();
    _persistSessionTimer?.cancel();
    _saveAutoDraftNow(ref.read(canvasProvider));
    _persistSessionNow();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _onTabSelected(ToolbarTab tab) {
    setState(() {
      // First tab (left) = تنظیمات متن (text settings), not save
      if (tab == ToolbarTab.create) {
        _showTextControls = !_showTextControls;
        _showSaveSheet = false;
        _activeTab = _showTextControls ? ToolbarTab.create : ToolbarTab.font;
        _schedulePersistSession();
        return;
      }
      if (_activeTab == tab) {
        _activeTab = ToolbarTab.font;
      } else {
        _activeTab = tab;
      }
      _showSaveSheet = false;
      _showTextControls = false;
      _schedulePersistSession();
    });
  }

  void _dismissOverlays() {
    setState(() {
      _showSaveSheet = false;
      _showTextControls = false;
      _showStickerPicker = false;
      _activeTab = ToolbarTab.font;
      _schedulePersistSession();
    });
  }

  /// با زدن روی مربع بالا: رنگ پس‌زمینه بین رنگ‌های ثابت و گرادیان چرخشی عوض می‌شود، بدون باز شدن نوار
  void _cycleBackgroundColor() {
    final canvas = ref.read(canvasProvider);
    final notifier = ref.read(canvasProvider.notifier);
    const solids = AppColors.topBarBackgroundColors;
    const total = 7; // 5 solids + Orange gradient + Banafsh gradient
    int current = 0;
    if (canvas.backgroundGradient != null) {
      if (listEquals(canvas.backgroundGradient, AppColors.topBarOrangeGradient) &&
          listEquals(canvas.backgroundGradientStops, AppColors.topBarOrangeGradientStops)) {
        current = 5;
      } else if (listEquals(canvas.backgroundGradient, AppColors.topBarBanafshGradient) &&
          listEquals(canvas.backgroundGradientStops, AppColors.topBarBanafshGradientStops)) {
        current = 6;
      }
    } else {
      final i = solids.indexOf(canvas.backgroundColor);
      if (i >= 0) current = i;
    }
    final next = (current + 1) % total;
    if (next < solids.length) {
      notifier.setBackgroundColor(solids[next]);
    } else if (next == 5) {
      notifier.setBackgroundGradient(
        AppColors.topBarOrangeGradient,
        AppColors.topBarOrangeGradientStops,
      );
    } else {
      notifier.setBackgroundGradient(
        AppColors.topBarBanafshGradient,
        AppColors.topBarBanafshGradientStops,
      );
    }
  }

  void _onCanvasTap() {
    if (_activeTab != null || _showSaveSheet || _showTextControls) {
      _dismissOverlays();
      _textFocusNode.unfocus();
      return;
    }

    // اگر کیبورد باز است، با تپ روی صفحه جمع شود.
    if (_textFocusNode.hasFocus) {
      _textFocusNode.unfocus();
      return;
    } else {
      // Only request focus when not already focused; defer to next frame so keyboard stays up
      if (!_textFocusNode.hasFocus) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_textFocusNode.hasFocus) {
            _textFocusNode.requestFocus();
          }
        });
      }
    }
  }

  Future<void> _saveToGallery() async {
    final bytes = await ExportService.captureWidget(_canvasKey);
    if (bytes != null) {
      final success = await ExportService.saveToGallery(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'با موفقیت ذخیره شد' : 'خطا در ذخیره',
              style: const TextStyle(fontFamily: 'Vazir'),
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _copyToInstagram() async {
    final canvas = ref.read(canvasProvider);
    if (canvas.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اول متن بنویس',
            style: TextStyle(fontFamily: 'Vazir'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _dismissOverlays();
    await SchedulerBinding.instance.endOfFrame;

    final bytes = await ExportService.captureWidget(_textExportKey, pixelRatio: 3.0);
    if (!mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطا در ساخت تصویر',
            style: TextStyle(fontFamily: 'Vazir'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ExportService.copyImageToClipboard(bytes);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'استایل متن کپی شد — در استوری اینستاگرام Paste بزن'
              : 'خطا در کپی',
          style: const TextStyle(fontFamily: 'Vazir'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<CanvasState>(canvasProvider, (prev, next) {
      if (prev == null) return;
      if (next.fontFamily != prev.fontFamily && mounted) setState(() {});
      // وقتی از تاریخچه یک پیش‌نویس لود می‌شود، متن و اسلایدر سایز را هم به‌روز کن
      if (next.text != prev.text && next.text != _textController.text && mounted) {
        _textController.text = next.text;
        _textController.selection = TextSelection.collapsed(offset: next.text.length);
        setState(() {});
      }
      if (next.fontSize != prev.fontSize && mounted) {
        _fontSizeSliderValue = (92 - next.fontSize).clamp(_fontSizeMin, _fontSizeMax);
        setState(() {});
      }
      _scheduleAutoSaveDraft(next);
      _schedulePersistSession();
    });
    ref.listen<StickerDragState>(stickerDragProvider, (prev, next) {
      if (!next.panEnded || next.draggingIndex == null || next.globalPosition == null) return;
      final box = _trashZoneKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        final origin = box.localToGlobal(Offset.zero);
        final rect = Rect.fromLTWH(origin.dx, origin.dy, box.size.width, box.size.height);
        if (rect.contains(next.globalPosition!)) {
          ref.read(canvasProvider.notifier).removeSticker(next.draggingIndex!);
        }
      }
      ref.read(stickerDragProvider.notifier).clear();
    });
    final canvas = ref.watch(canvasProvider);
    final stickerDrag = ref.watch(stickerDragProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    final hasOverlay = _showSaveSheet || _showTextControls || _showStickerPicker;
    // Font tab shows inline panel (not BottomContainer)
    final showFontPanel = _activeTab == ToolbarTab.font;
    // Style and font tabs show inline panels; color tab uses horizontal strip only
    final showBottomPanel = _activeTab == ToolbarTab.style;
    final showColorStrip = _activeTab == ToolbarTab.color;
    final bgIndicatorColor = canvas.backgroundGradient != null && canvas.backgroundGradient!.isNotEmpty
        ? canvas.backgroundGradient!.first
        : canvas.backgroundColor;

    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Layer 0: Canvas (full screen). translucent تا لمس وسط (متنت رو بنویس) به onTap برسد و کیبورد باز شود ──
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onCanvasTap,
              child: TextCanvas(
                key: ValueKey<String>(canvas.fontFamily),
                canvasKey: _canvasKey,
                showStickers: false,
              ),
            ),
          ),

          // Offscreen styled-text capture for Instagram clipboard (transparent PNG).
          Positioned(
            left: -10000,
            top: 0,
            child: RepaintBoundary(
              key: _textExportKey,
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width - 64,
                    ),
                    child: const CanvasStyledText(),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 1: TextField واقعی — تپ مستقیم = کیبورد همیشه. استیکرها لایهٔ بعد (بالا) پس درگ کار می‌کند ──
          Positioned(
            left: 48,
            right: 32,
            top: 80,
            bottom: 80,
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Center(
                  child: TextField(
                    key: const Key('main_text_field'),
                    controller: _textController,
                    focusNode: _textFocusNode,
                    maxLines: null,
                    minLines: 1,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    cursorColor: Colors.white,
                    cursorWidth: 2,
                    style: TextStyle(
                      fontFamily: canvas.fontFamily,
                      fontFamilyFallback: const ['Vazir'],
                      fontSize: canvas.fontSize.clamp(16, 72),
                      color: Colors.transparent,
                      height: 1.5,
                    ),
                      decoration: InputDecoration(
                        hintText: _selectedFontLanguage.placeholderHint,
                      hintStyle: TextStyle(
                        fontFamily: canvas.fontFamily,
                        fontFamilyFallback: const ['Vazir'],
                        fontSize: canvas.fontSize.clamp(16, 40),
                        color: Colors.white54,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 1b: استیکرها بالای TextField — تپ خالی به فیلد می‌رسد، درگ استیکر اینجا ──
          Positioned.fill(
            child: const StickerOverlay(),
          ),

          // ── Layer 2b: سطل زباله وقتی استیکر درگ می‌شود (دراپ روی سطل = حذف) ──
          // IgnorePointer تا درگ به استیکر برسد و لایه سطل لمس را نگیرد
          if (stickerDrag.isDragging) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: IgnorePointer(
                child: Center(
                  child: _buildTrashZone(context, stickerDrag),
                ),
              ),
            ),
          ],

          // ── Layer 3: Top gradient (111px, from Figma) ──────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: 111,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.49, 1.0],
                    colors: [
                      Color(0x99000000), // black 60%
                      Color(0x33000000), // black 20%
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 4: Top bar ───────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16, right: 16,
            child: _buildTopBar(bgIndicatorColor),
          ),

          // ── Layer 5: سایدبار چپ — همیشه نمایش؛ موقع کیبورد نسخهٔ کوتاه در مرکز ناحیهٔ visible ──
          if (!showBottomPanel && !hasOverlay)
            Positioned(
              left: 16,
              top: isKeyboardOpen
                  ? (MediaQuery.sizeOf(context).height - bottomInset - _verticalSliderHeight(compact: true)) / 2
                  : (MediaQuery.sizeOf(context).height - _verticalSliderHeight(compact: false)) / 2,
              child: _buildVerticalSlider(compact: isKeyboardOpen),
            ),

          // ── Layer 6: Bottom section — با resizeToAvoidBottomInset بدنه از پایین جمع شده، پس bottom:0 همون بالای کیبورد است؛ bottomInset فاصله می‌ساخت ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBottomPanel) const StylePickerPanel(),
                  if (showColorStrip) _buildColorStrip(),
                  if (showFontPanel) _buildFontPanel(),
                  if (!isKeyboardOpen)
                    BottomToolbar(
                      activeTab: _activeTab,
                      onTabSelected: _onTabSelected,
                      onTabLongPress: (tab) {
                        if (tab == ToolbarTab.font) {
                          final canvas = ref.read(canvasProvider);
                          final list = FontItem.allFonts
                              .where((f) => f.family == canvas.fontFamily);
                          final fontItem = list.isEmpty ? null : list.first;
                          if (fontItem != null) {
                            ref.read(fontProvider.notifier).toggleFavorite(fontItem.name);
                          }
                        }
                      },
                    ),
                  if (isKeyboardOpen) _buildKeyboardBar(),
                ],
              ),
            ),
          ),

          // ── Layer 7: Overlay dim ───────────────────────────────
          if (hasOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissOverlays,
                child: Container(color: AppColors.overlay25),
              ),
            ),

          // ── Layer 8: Save sheet ────────────────────────────────
          if (_showSaveSheet)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _buildSaveSheet(),
            ),

          // ── Layer 9: Text controls sheet ───────────────────────
          if (_showTextControls)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _buildTextControlsSheet(),
            ),

          // ── Layer 10: Sticker picker sheet (مثل تصویر: از پایین، دستهٔ کشی، گرید استیکرها) ──
          if (_showStickerPicker)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: BottomContainer(
                onDismiss: () => setState(() => _showStickerPicker = false),
                maxHeightFraction: 0.65,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: const StickerPickerPanel(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOP BAR  (Figma: Frame 545 left, Frame 8 right, y:48)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopBar(Color bgIndicatorColor) {
    // از راست به چپ: کپی متن (راست‌ترین) ← استیکر ← تاریخچه ← رنگ ← کردیت ← تنظیمات (چپ‌ترین)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          _CopyTextButton(
            onTap: () {
              setState(() {
                _showSaveSheet = true;
                _showTextControls = false;
                _showStickerPicker = false;
                _activeTab = ToolbarTab.font;
              });
            },
          ),
          const SizedBox(width: 8),
          _TopBarStickerButton(
            onTap: () {
              setState(() {
                _showStickerPicker = true;
                _showSaveSheet = false;
                _showTextControls = false;
                _activeTab = ToolbarTab.font;
              });
            },
          ),
          const SizedBox(width: 8),
          _TopBarIconButton(
            icon: Icons.history_rounded,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => const HistorySheet(),
              );
            },
          ),
          const SizedBox(width: 8),
          _ColorIndicator(
            color: bgIndicatorColor,
            onTap: _cycleBackgroundColor,
          ),
          const Spacer(),
          _CounterPill(
            onTap: () => context.push('/premium'),
          ),
          const SizedBox(width: 8),
          _TopBarIconButton(
            icon: Icons.settings_outlined,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => const SettingsSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TRASH ZONE (وقتی استیکر درگ می‌شود؛ دراپ روی سطل = حذف)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTrashZone(BuildContext context, StickerDragState stickerDrag) {
    bool isOverTrash = false;
    final box = _trashZoneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && stickerDrag.globalPosition != null) {
      final origin = box.localToGlobal(Offset.zero);
      final rect = Rect.fromLTWH(origin.dx, origin.dy, box.size.width, box.size.height);
      isOverTrash = rect.contains(stickerDrag.globalPosition!);
    }
    final size = isOverTrash ? 64.0 : 56.0;
    final borderColor = isOverTrash ? AppColors.error : Colors.white24;
    final borderWidth = isOverTrash ? 3.0 : 2.0;
    return Container(
      key: _trashZoneKey,
      width: size + 24,
      height: size + 24,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Icon(
          Icons.delete_outline,
          color: isOverTrash ? AppColors.error : Colors.white70,
          size: 32,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // VERTICAL SLIDER  (Figma: Component 1, x:16, y:329, 20x258)
  // Track: 20x234 full | نسخه کیبورد: کوتاه‌تر (track 100)
  // ═══════════════════════════════════════════════════════════════════

  static const double _sliderTrackFull = 234;
  static const double _sliderTrackCompact = 100;

  double _verticalSliderHeight({required bool compact}) {
    final trackH = compact ? _sliderTrackCompact : _sliderTrackFull;
    return 14 + 4 + trackH; // label + gap + track
  }

  Widget _buildVerticalSlider({bool compact = false}) {
    final trackHeight = compact ? _sliderTrackCompact : _sliderTrackFull;
    final fontSize = (92 - _fontSizeSliderValue).clamp(_fontSizeMin, _fontSizeMax);
    final sizeProgress = ((fontSize - _fontSizeMin) / (_fontSizeMax - _fontSizeMin)).clamp(0.0, 1.0);
    final trackThickness = (compact ? 4.0 : 5.0) + sizeProgress * (compact ? 12.0 : 15.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: _showFontSizeValue ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: Text(
            fontSize.toInt().toString(),
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: compact ? 18 : 22,
          height: trackHeight,
          child: RotatedBox(
            quarterTurns: -1,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: trackThickness, end: trackThickness),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              builder: (context, animatedTrackThickness, child) {
                return SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white.withValues(alpha: 0.4),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.4),
                    thumbColor: Colors.white,
                    overlayColor: Colors.transparent,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: compact ? 8 : 10),
                    trackHeight: animatedTrackThickness,
                    trackShape: const RoundedRectSliderTrackShape(),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: child!,
                );
              },
              child: Slider(
                  value: _fontSizeSliderValue,
                  min: _fontSizeMin,
                  max: _fontSizeMax,
                  onChangeStart: (_) {
                    setState(() => _showFontSizeValue = true);
                  },
                  onChanged: (v) {
                    setState(() => _fontSizeSliderValue = v);
                    ref.read(canvasProvider.notifier).setFontSize(92 - v);
                  },
                  onChangeEnd: (_) {
                    setState(() => _showFontSizeValue = false);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FONT PANEL  (category chips + font cards, inline above toolbar)
  // ═══════════════════════════════════════════════════════════════════

  /// پنل فونت: اندازه‌های بزرگ‌تر برای خوانایی (chips 36px, cards 80×88)
  Widget _buildFontPanel() {
    final fontState = ref.watch(fontProvider);
    final canvasState = ref.watch(canvasProvider);
    final fonts = _getFilteredFonts(fontState);
    final pinnedFonts = fonts.where((f) => fontState.favoriteFonts.contains(f.name)).toList();
    final unpinnedFonts = fonts.where((f) => !fontState.favoriteFonts.contains(f.name)).toList();
    final showPinnedDivider = _fontCategoryIndex != 1 && pinnedFonts.isNotEmpty && unpinnedFonts.isNotEmpty;
    final items = <Object>[...pinnedFonts];
    if (showPinnedDivider) items.add('__divider__');
    items.addAll(unpinnedFonts);

    return ClipRect(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 148),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Chips: اول گزینش (فیلتر زبان)، بعد دسته‌های فونت ──
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _LanguageDropdownChip(
                    selectedLanguage: _selectedFontLanguage,
                    onSelected: (lang) => setState(() => _selectedFontLanguage = lang),
                  ),
                  _GlassChip(
                    label: 'علاقه‌مندی‌ها',
                    isActive: _fontCategoryIndex == 1,
                    onTap: () {
                      setState(() => _fontCategoryIndex = 1);
                      _schedulePersistSession();
                    },
                  ),
                  _GlassChip(
                    label: 'رسمی',
                    isActive: _fontCategoryIndex == 2,
                    onTap: () {
                      setState(() => _fontCategoryIndex = 2);
                      _schedulePersistSession();
                    },
                  ),
                  _GlassChip(
                    label: 'فانتزی',
                    isActive: _fontCategoryIndex == 3,
                    onTap: () {
                      setState(() => _fontCategoryIndex = 3);
                      _schedulePersistSession();
                    },
                  ),
                  _GlassChip(
                    label: 'ساده',
                    isActive: _fontCategoryIndex == 4,
                    onTap: () {
                      setState(() => _fontCategoryIndex = 4);
                      _schedulePersistSession();
                    },
                  ),
                  _GlassChip(
                    label: 'وارد شده‌ها',
                    isActive: _fontCategoryIndex == 5,
                    onTap: () {
                      setState(() => _fontCategoryIndex = 5);
                      _schedulePersistSession();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── کارت‌های فونت: 80×88، فونت 14 ──
            SizedBox(
              height: 88,
              child: fonts.isEmpty && _fontCategoryIndex == 1
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _AddFontCard(onTap: _importCustomFont),
                        const SizedBox(width: 12),
                        _FontPanelEmptyHint(
                          message: 'هنوز فونتی نشان نداده‌ای',
                          actionLabel: 'مشاهده همه فونت‌ها',
                          onAction: () {
                            setState(() => _fontCategoryIndex = 0);
                            _schedulePersistSession();
                          },
                        ),
                      ],
                    )
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _AddFontCard(onTap: _importCustomFont),
                    );
                  }
                  final item = items[index - 1];
                  if (item is String && item == '__divider__') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 1,
                        height: 64,
                        color: AppColors.border,
                      ),
                    );
                  }
                  final font = item as FontItem;
                  final isSelected = canvasState.fontFamily == font.family;
                  final isFav = fontState.favoriteFonts.contains(font.name);
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FontCard(
                      fontItem: font,
                      isSelected: isSelected,
                      isFavorite: isFav,
                      onTap: () {
                        ref.read(canvasProvider.notifier).setFont(font.family);
                        ref.read(fontProvider.notifier).selectFont(font.name);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      onFavTap: () {
                        ref.read(fontProvider.notifier).toggleFavorite(font.name);
                      },
                      onLongPress: () {
                        ref.read(fontProvider.notifier).toggleFavorite(font.name);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Future<void> _importCustomFont() async {
    final fontItem = await ref.read(customFontsProvider.notifier).importFont();
    if (!mounted) return;
    if (fontItem == null) return;

    setState(() => _fontCategoryIndex = 5);
    ref.read(canvasProvider.notifier).setFont(fontItem.family);
    ref.read(fontProvider.notifier).selectFont(fontItem.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'فونت «${fontItem.displayName}» اضافه شد',
          style: const TextStyle(fontFamily: 'Vazir'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<FontItem> _getFilteredFonts(FontState fontState) {
    final customItems =
        ref.watch(customFontsProvider).map((c) => c.toFontItem()).toList();
    final allWithCustom = [...FontItem.allFonts, ...customItems];

    List<FontItem> list;
    switch (_fontCategoryIndex) {
      case 1:
        list = allWithCustom
            .where((f) => fontState.favoriteFonts.contains(f.name))
            .toList();
        break;
      case 2:
        list = FontItem.allFonts.where((f) => f.category == FontCategory.formal).toList();
        break;
      case 3:
        list = FontItem.allFonts.where((f) => f.category == FontCategory.fancy).toList();
        break;
      case 4:
        list = FontItem.allFonts.where((f) => f.category == FontCategory.standard).toList();
        break;
      case 5:
        list = customItems;
        break;
      default:
        list = allWithCustom;
    }
    // فیلتر بر اساس زبان انتخاب‌شده
    if (_selectedFontLanguage != FontLanguage.all) {
      list = list.where((f) => f.language == _selectedFontLanguage).toList();
    }
    return list;
  }

  // ═══════════════════════════════════════════════════════════════════
  // BOTTOM PANEL (Style / Color — uses BottomContainer)
  // ═══════════════════════════════════════════════════════════════════

  /// Two-row color strip: row 1 text color, row 2 background color
  Widget _buildColorStrip() {
    const double stripHeight = 142;
    const double gap = 12;
    const double circleSize = 40;
    const double borderWidth = 1.5;

    final canvas = ref.watch(canvasProvider);
    final notifier = ref.read(canvasProvider.notifier);

    final customTextColors = ref.watch(customTextColorsProvider).map((v) => Color(v)).toList();
    const textSolidColors = AppColors.presetColors;
    const textGradients = AppColors.bgGradientCircles;
    final customBgColors = ref.watch(customBgColorsProvider).map((v) => Color(v)).toList();
    const bgSolidColors = AppColors.presetColors;
    final pinnedTextColorValues = ref.watch(pinnedTextColorsProvider);
    final pinnedBgColorValues = ref.watch(pinnedBgColorsProvider);
    final pinnedTextColors = textSolidColors.where((c) => pinnedTextColorValues.contains(c.value)).toList();
    final otherTextColors = textSolidColors.where((c) => !pinnedTextColorValues.contains(c.value)).toList();
    final pinnedBgColors = bgSolidColors.where((c) => pinnedBgColorValues.contains(c.value)).toList();
    final otherBgColors = bgSolidColors.where((c) => !pinnedBgColorValues.contains(c.value)).toList();

    return Container(
      height: stripHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(width: gap),
                const _ColorStripTypeBadge(label: 'T'),
                Expanded(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (Rect rect) {
                      return const LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [Colors.transparent, Colors.white],
                        stops: [0.0, 0.04],
                      ).createShader(rect);
                    },
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                  SizedBox(width: gap),
                  _ColorStripEyedropperSwatch(
                    size: circleSize,
                    borderWidth: borderWidth,
                    onTap: () => _openEyedropperSheet(notifier),
                  ),
                  ...customTextColors.map((color) {
                    final isSelected = canvas.textColor == color;
                    return [
                      SizedBox(width: gap),
                      _ColorStripSwatch(
                        size: circleSize,
                        borderWidth: borderWidth,
                        color: color,
                        isSelected: isSelected,
                        onTap: () {
                          notifier.clearGradientColors();
                          notifier.setTextColor(color);
                        },
                        onLongPress: null,
                        showPinPopover: false,
                      ),
                    ];
                  }).expand((e) => e),
                  if (customTextColors.isNotEmpty) ...[
                    SizedBox(width: gap),
                    Container(width: 1, height: 24, color: AppColors.border),
                  ],
                  ...pinnedTextColors.map((color) {
                    final isSelected = canvas.textColor == color;
                    final showPinPopover = _pinPopoverColor == color;
                    return [
                      SizedBox(width: gap),
                      _ColorStripSwatch(
                        size: circleSize,
                        borderWidth: borderWidth,
                        color: color,
                        isSelected: isSelected,
                        onTap: () {
                          notifier.clearGradientColors();
                          notifier.setTextColor(color);
                        },
                        onLongPress: () async {
                          setState(() => _pinPopoverColor = color);
                          await ref.read(pinnedTextColorsProvider.notifier).toggleColor(color);
                          if (mounted) {
                            Future.delayed(const Duration(milliseconds: 400), () {
                              if (mounted) setState(() => _pinPopoverColor = null);
                            });
                          }
                        },
                        showPinPopover: showPinPopover,
                      ),
                    ];
                  }).expand((e) => e),
                  if (pinnedTextColors.isNotEmpty && otherTextColors.isNotEmpty) ...[
                    SizedBox(width: gap),
                    Container(width: 1, height: 24, color: AppColors.border),
                  ],
                  ...otherTextColors.map((color) {
                    final isSelected = canvas.textColor == color;
                    final showPinPopover = _pinPopoverColor == color;
                    return [
                      SizedBox(width: gap),
                      _ColorStripSwatch(
                        size: circleSize,
                        borderWidth: borderWidth,
                        color: color,
                        isSelected: isSelected,
                        onTap: () {
                          notifier.clearGradientColors();
                          notifier.setTextColor(color);
                        },
                        onLongPress: () async {
                          setState(() => _pinPopoverColor = color);
                          await ref.read(pinnedTextColorsProvider.notifier).toggleColor(color);
                          if (mounted) {
                            Future.delayed(const Duration(milliseconds: 400), () {
                              if (mounted) setState(() => _pinPopoverColor = null);
                            });
                          }
                        },
                        showPinPopover: showPinPopover,
                      ),
                    ];
                  }).expand((e) => e),
                  if (otherTextColors.isNotEmpty && textGradients.isNotEmpty) ...[
                    SizedBox(width: gap),
                    Container(width: 1, height: 24, color: AppColors.border),
                  ],
                  ...List.generate(textGradients.length, (idx) {
                    final g = textGradients[idx];
                    return [
                      if (idx > 0) SizedBox(width: gap),
                      _ColorStripSwatch(
                        size: circleSize,
                        borderWidth: borderWidth,
                        isSelected: canvas.gradientColors != null &&
                            listEquals(canvas.gradientColors, g),
                        gradient: g,
                        onTap: () => notifier.setGradientColors(g),
                      ),
                    ];
                  }).expand((e) => e),
                  SizedBox(width: gap),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (canvas.hasBubble) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(width: gap),
                  const _ColorStripTypeBadge(icon: Icons.water_drop),
                  Expanded(
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (Rect rect) {
                        return const LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Colors.transparent, Colors.white],
                          stops: [0.0, 0.04],
                        ).createShader(rect);
                      },
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                    SizedBox(width: gap),
                    _ColorStripEyedropperSwatch(
                      size: circleSize,
                      borderWidth: borderWidth,
                      onTap: () => _openBubbleEyedropperSheet(notifier),
                    ),
                    ...customBgColors.map((color) {
                      final isSelected = canvas.bubbleColor == color;
                      return [
                        SizedBox(width: gap),
                        _ColorStripSwatch(
                          size: circleSize,
                          borderWidth: borderWidth,
                          color: color,
                          isSelected: isSelected,
                          onTap: () => notifier.setBubble(true, color: color),
                          onLongPress: null,
                          showPinPopover: false,
                        ),
                      ];
                    }).expand((e) => e),
                    if (customBgColors.isNotEmpty) ...[
                      SizedBox(width: gap),
                      Container(width: 1, height: 24, color: AppColors.border),
                    ],
                    ...pinnedBgColors.map((color) {
                      final isSelected = canvas.bubbleColor == color;
                      return [
                        SizedBox(width: gap),
                        _ColorStripSwatch(
                          size: circleSize,
                          borderWidth: borderWidth,
                          color: color,
                          isSelected: isSelected,
                          onTap: () => notifier.setBubble(true, color: color),
                          onLongPress: () async {
                            setState(() => _pinPopoverColor = color);
                            await ref.read(pinnedBgColorsProvider.notifier).toggleColor(color);
                            if (mounted) {
                              Future.delayed(const Duration(milliseconds: 400), () {
                                if (mounted) setState(() => _pinPopoverColor = null);
                              });
                            }
                          },
                          showPinPopover: false,
                        ),
                      ];
                    }).expand((e) => e),
                    if (pinnedBgColors.isNotEmpty && otherBgColors.isNotEmpty) ...[
                      SizedBox(width: gap),
                      Container(width: 1, height: 24, color: AppColors.border),
                    ],
                    ...otherBgColors.map((color) {
                      final isSelected = canvas.bubbleColor == color;
                      return [
                        SizedBox(width: gap),
                        _ColorStripSwatch(
                          size: circleSize,
                          borderWidth: borderWidth,
                          color: color,
                          isSelected: isSelected,
                          onTap: () => notifier.setBubble(true, color: color),
                          onLongPress: () async {
                            setState(() => _pinPopoverColor = color);
                            await ref.read(pinnedBgColorsProvider.notifier).toggleColor(color);
                            if (mounted) {
                              Future.delayed(const Duration(milliseconds: 400), () {
                                if (mounted) setState(() => _pinPopoverColor = null);
                              });
                            }
                          },
                          showPinPopover: false,
                        ),
                      ];
                    }).expand((e) => e),
                    SizedBox(width: gap),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openEyedropperSheet(CanvasNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: AppColors.sheetBg,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dragIndicator,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const BackArrowIcon(
                          size: 22,
                          color: Colors.white,
                          pointLeft: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'رنگ‌ها',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ColorPickerPanel(
                  onColorChanged: (color) {
                    notifier.clearGradientColors();
                    notifier.setTextColor(color);
                  },
                  onGradientSelected: (gradient) {
                    notifier.setGradientColors(gradient);
                  },
                  selectedGradient: ref.watch(canvasProvider).gradientColors,
                  onAddColor: (color) async {
                    await ref.read(customTextColorsProvider.notifier).addColor(color);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBubbleEyedropperSheet(CanvasNotifier notifier) {
    final canvas = ref.read(canvasProvider);
    final initialColor = canvas.bubbleColor ?? canvas.textColor;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: AppColors.sheetBg,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.dragIndicator,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const BackArrowIcon(
                          size: 22,
                          color: Colors.white,
                          pointLeft: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'رنگ بک‌گراند متن',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ColorPickerPanel(
                  initialColor: initialColor,
                  onColorChanged: (color) => notifier.setBubble(true, color: color),
                  onGradientSelected: (gradient) => notifier.setBubbleGradient(gradient),
                  selectedGradient: ref.watch(canvasProvider).bubbleGradient,
                  onAddColor: (color) async {
                    await ref.read(customBgColorsProvider.notifier).addColor(color);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // KEYBOARD DONE BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildKeyboardBar() {
    return const SizedBox.shrink();
  }

  // ═══════════════════════════════════════════════════════════════════
  // SAVE / EXPORT SHEET
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSaveSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 135, height: 5,
                decoration: BoxDecoration(
                  color: AppColors.dragIndicator,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 32),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SaveItem(
                      icon: Icons.download_rounded,
                      label: 'ذخیره در گالری',
                      onTap: () { _dismissOverlays(); _saveToGallery(); },
                    ),
                    _SaveItem(
                      iconWidget: Image.asset(
                        'assets/icons/icon_instagram.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.camera_alt_outlined, size: 24, color: Colors.white),
                      ),
                      label: 'استوری اینستاگرام',
                      onTap: _copyToInstagram,
                      noBackground: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TEXT CONTROLS SHEET
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTextControlsSheet() {
    final canvas = ref.watch(canvasProvider);
    final notifier = ref.read(canvasProvider.notifier);
    final screenH = MediaQuery.sizeOf(context).height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: screenH * 0.55),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber
              Container(
                width: 135,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.dragIndicator,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 16),
              // فقط «تنظیمات متن» سمت راست
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _dismissOverlays,
                      child: const BackArrowIcon(size: 16, color: Colors.white, pointLeft: false),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'تنظیمات متن',
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // آیکون‌های تراز سمت راست (مثل عکس)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _AlignOption(
                      icon: Icons.format_align_right,
                      isActive: canvas.textAlign == TextAlign.right,
                      onTap: () => notifier.setTextAlign(TextAlign.right),
                    ),
                    const SizedBox(width: 8),
                    _AlignOption(
                      icon: Icons.format_align_center,
                      isActive: canvas.textAlign == TextAlign.center,
                      onTap: () => notifier.setTextAlign(TextAlign.center),
                    ),
                    const SizedBox(width: 8),
                    _AlignOption(
                      icon: Icons.format_align_left,
                      isActive: canvas.textAlign == TextAlign.left,
                      onTap: () => notifier.setTextAlign(TextAlign.left),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Sliders like image: line spacing, font size (Ab), letter spacing, word spacing, opacity
              _FigmaSliderRow(
                icon: Icons.format_line_spacing,
                value: canvas.lineHeight,
                min: 0.8,
                max: 3.0,
                displayValue: canvas.lineHeight.toStringAsFixed(1),
                onChanged: (v) => notifier.setLineHeight(v),
              ),
              const SizedBox(height: 16),
              _FigmaSliderRow(
                icon: Icons.text_fields_rounded,
                value: canvas.fontSize,
                min: 12,
                max: 80,
                displayValue: canvas.fontSize.toStringAsFixed(1),
                onChanged: (v) {
                  setState(() => _fontSizeSliderValue = 92 - v);
                  notifier.setFontSize(v);
                },
              ),
              const SizedBox(height: 16),
              _FigmaSliderRow(
                icon: Icons.space_bar,
                value: canvas.letterSpacing,
                min: -10,
                max: 20,
                displayValue: canvas.letterSpacing.toStringAsFixed(1),
                onChanged: (v) => notifier.setLetterSpacing(v),
              ),
              const SizedBox(height: 16),
              _FigmaSliderRow(
                icon: Icons.horizontal_distribute,
                value: canvas.wordSpacing,
                min: -5,
                max: 30,
                displayValue: canvas.wordSpacing.toStringAsFixed(1),
                onChanged: (v) => notifier.setWordSpacing(v),
              ),
              const SizedBox(height: 16),
              _FigmaSliderRow(
                icon: Icons.opacity,
                value: canvas.opacity,
                min: 0,
                max: 1,
                displayValue: canvas.opacity.toStringAsFixed(1),
                onChanged: (v) => notifier.setOpacity(v),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// COLOR STRIP SWATCH (circle with white border for color strip)
// ─────────────────────────────────────────────────────────────────────

class _ColorStripSwatch extends StatelessWidget {
  final double size;
  final double borderWidth;
  final Color? color;
  final List<Color>? gradient;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showPinPopover;

  const _ColorStripSwatch({
    required this.size,
    required this.borderWidth,
    this.color,
    this.gradient,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    this.showPinPopover = false,
  }) : assert(color != null || gradient != null);

  @override
  Widget build(BuildContext context) {
    void handleLongPress() {
      if (onLongPress != null) onLongPress!();
    }

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: Colors.white,
          width: borderWidth,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: isSelected && color != null
          ? const Icon(Icons.check, size: 20, color: Colors.white)
          : null,
    );

    if (showPinPopover && color != null) {
      return SizedBox(
        width: size + 16,
        height: size + 48,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: size + 16,
                height: size + 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.26),
                  borderRadius: BorderRadius.circular((size + 16) / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(Icons.push_pin_rounded, size: 22, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                onLongPress: handleLongPress,
                child: circle,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: handleLongPress,
      child: circle,
    );
  }
}

class _ColorStripTypeBadge extends StatelessWidget {
  final String? label;
  final IconData? icon;

  const _ColorStripTypeBadge({this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.buttonDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 22, color: Colors.white)
            : Text(
                label ?? '',
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _ColorStripEyedropperSwatch extends StatelessWidget {
  final double size;
  final double borderWidth;
  final VoidCallback onTap;

  const _ColorStripEyedropperSwatch({
    required this.size,
    required this.borderWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(Icons.colorize, color: Colors.black, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TOP BAR COMPONENTS
// ─────────────────────────────────────────────────────────────────────

/// 40x40 icon button: bg #002032@60%, cornerRadius 10
class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}

/// دکمه استیکر: همان سایز 40x40، آیکون 24x24
class _TopBarStickerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TopBarStickerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Image.asset(
            'assets/icons/icon_sticker.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

/// Counter pill (Frame 502): کردیت‌ها – آیکون الماس + ∞ (نامحدود)
class _CounterPill extends StatelessWidget {
  final VoidCallback onTap;
  const _CounterPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 0,
              offset: Offset.zero,
              spreadRadius: 0,
              blurStyle: BlurStyle.inner,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.25),
              blurRadius: 0,
              offset: Offset.zero,
              spreadRadius: 0,
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/icon_credits_diamond.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              '∞',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// آیکون رنگ: با حاشیه سفید تا روی پس‌زمینه آبی هم دیده شود
class _ColorIndicator extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _ColorIndicator({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// White "کپی متن" button: 68x36, white bg, cornerRadius 10
class _CopyTextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CopyTextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text('کپی', style: TextStyle(
            fontFamily: 'Vazir', fontSize: 13,
            color: AppColors.textDark, fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// FONT PANEL COMPONENTS
// ─────────────────────────────────────────────────────────────────────

/// Glassmorphic chip: grey@20%, blur 35, cornerRadius 16, h:28
class _GlassChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailing;
  const _GlassChip({
    required this.label, required this.isActive,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.25)
                : AppColors.glassGrey20,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(color: Colors.white, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(
                fontFamily: 'Vazir', fontSize: 14, color: Colors.white,
              )),
              if (trailing != null) ...[
                const SizedBox(width: 2),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// دکمهٔ فیلتر / گزینش زبان — با تپ، شیت «انتخاب زبان» از پایین باز می‌شود
class _LanguageDropdownChip extends StatelessWidget {
  final FontLanguage selectedLanguage;
  final ValueChanged<FontLanguage> onSelected;

  const _LanguageDropdownChip({
    required this.selectedLanguage,
    required this.onSelected,
  });

  void _openLanguageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 135,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.dragIndicator,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 20),
              // هدر: فلش بستن + عنوان «انتخاب زبان» — سمت راست (در RTL، start = راست)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const BackArrowIcon(
                          size: 18,
                          color: Colors.white,
                          pointLeft: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'انتخاب زبان',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // گزینه‌ها: همه، فارسی، انگلیسی، عربی
              ...FontLanguage.values.map((lang) {
                final isSelected = lang == selectedLanguage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onSelected(lang);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.keyboardBlue.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.keyboardBlue,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Text(
                          lang.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 16,
                            color: isSelected
                                ? AppColors.keyboardBlue
                                : Colors.white,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _openLanguageSheet(context),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.glassGrey20,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_list_rounded,
                  size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                selectedLanguage.label,
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// کارت فونت: 80×88، فونت نام 14، آیکون‌ها بزرگ‌تر
class _FontCard extends StatelessWidget {
  final FontItem fontItem;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavTap;
  final VoidCallback? onLongPress;
  const _FontCard({
    required this.fontItem, required this.isSelected,
    required this.isFavorite, required this.onTap, required this.onFavTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.buttonDarkLight,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: Colors.white, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              fontItem.displayName,
              style: TextStyle(
                fontFamily: fontItem.family,
                fontSize: 14,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onFavTap,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: isFavorite ? Colors.redAccent : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// کارت «افزودن فونت»: 80×88
class _FontPanelEmptyHint extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _FontPanelEmptyHint({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.buttonDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 13,
                color: AppColors.blueLight,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFontCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFontCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.buttonDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 22, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(height: 6),
            Text('افزودن\nفونت',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazir', fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SAVE SHEET / TEXT CONTROLS COMPONENTS
// ─────────────────────────────────────────────────────────────────────

class _SaveItem extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback onTap;
  final bool isGradient;
  /// وقتی true باشد فقط آیکون بدون دایره/پس‌زمینه نمایش داده می‌شود (مثلاً لوگوی اینستاگرام).
  final bool noBackground;
  const _SaveItem({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onTap,
    this.isGradient = false,
    this.noBackground = false,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: noBackground
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGradient ? null : Colors.white.withValues(alpha: 0.1),
                    gradient: isGradient
                        ? const LinearGradient(colors: [
                            Color(0xFFFFC107),
                            Color(0xFFE91E63),
                            Color(0xFF9C27B0),
                          ])
                        : null,
                  ),
            child: Center(
              child: iconWidget != null
                  ? SizedBox(
                      width: noBackground ? 30 : 28,
                      height: noBackground ? 30 : 28,
                      child: iconWidget,
                    )
                  : Icon(icon!, size: 24, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontFamily: 'Vazir', fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}

class _AlignOption extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _AlignOption({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: isActive ? AppColors.glassWhite10 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: isActive ? Colors.white : Colors.white54),
        ),
      ),
    );
  }
}

/// Figma slider row: value text + slider (track white@10%, fill white,
/// thumb blue #0095FD 12px) + icon
class _FigmaSliderRow extends StatelessWidget {
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;
  const _FigmaSliderRow({
    required this.icon, required this.value, required this.min,
    required this.max, required this.displayValue, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(displayValue, textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'Vazir', fontSize: 11, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                thumbColor: AppColors.sliderBlue,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max), min: min, max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 22, color: Colors.white54),
        ],
      ),
    );
  }
}
