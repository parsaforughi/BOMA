import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';
import '../services/canvas_state.dart';
import '../services/draft_service.dart';
import '../l10n/app_localizations.dart';
import 'back_arrow_icon.dart';

/// شیت تاریخچه: لیست پیش‌نویس‌ها (حداکثر ۱۰)، ذخیره پیش‌نویس فعلی، و بارگذاری با تپ.
class HistorySheet extends ConsumerStatefulWidget {
  const HistorySheet({super.key});

  @override
  ConsumerState<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends ConsumerState<HistorySheet> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final canvasState = ref.watch(canvasProvider);
    final l10n = AppLocalizations.of(context);
    final historyTitle = l10n?.history ?? 'تاریخچه';
    final noHistoryText = l10n?.noHistory ?? 'تاریخچه‌ای وجود ندارد';
    final saveDraftLabel = l10n?.saveCurrentDraft ?? 'ذخیره پیش‌نویس فعلی';
    final drafts = storage.getHistory();

    return Container(
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
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const BackArrowIcon(
                            size: 18,
                            color: Colors.white,
                            pointLeft: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          historyTitle,
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // دکمه ذخیره پیش‌نویس فعلی
                    TextButton(
                      onPressed: () async {
                        final map = canvasToDraftMap(canvasState);
                        await addDraft(storage, map);
                        setState(() {});
                      },
                      child: Text(
                        saveDraftLabel,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
                          color: AppColors.blueLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: drafts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        noHistoryText,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: drafts.length,
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        final preview = (draft['text'] as String?)?.trim().isEmpty ?? true
                            ? '—'
                            : (draft['text'] as String? ?? '—');
                        final previewShort = preview.length > 40 ? '${preview.substring(0, 40)}…' : preview;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                try {
                                  final state = draftMapToCanvasState(draft);
                                  ref.read(canvasProvider.notifier).loadState(state);
                                } catch (_) {}
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Text(
                                  previewShort,
                                  style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
