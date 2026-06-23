import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../widgets/settings_sheet.dart';

/// مسیر /settings همان شیت تنظیمات را نشان می‌دهد (لاگین نکرده = ورود | ثبت نام، لاگین کرده = شماره + خروج)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvasBlue,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.75,
            ),
            child: SettingsSheet(
              onClose: () => context.pop(),
            ),
          ),
        ),
      ),
    );
  }
}
