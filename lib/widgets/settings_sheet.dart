import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';
import '../utils/farsi_utils.dart';
import '../providers/package_info_provider.dart';
import 'back_arrow_icon.dart';

/// شیت تنظیمات: اگر مهمان باشد «ورود | ثبت نام»، اگر لاگین کرده باشد شماره تلفن + خروج
class SettingsSheet extends ConsumerWidget {
  /// وقتی از مسیر /settings باز شده، با این بسته می‌شود؛ وگرنه Navigator.pop
  final VoidCallback? onClose;

  const SettingsSheet({super.key, this.onClose});

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLoggedIn = user != null;

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
            // هدر: تنظیمات + فلش بستن (سمت راست)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _close(context),
                      child: const BackArrowIcon(
                        size: 18,
                        color: Colors.white,
                        pointLeft: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'تنظیمات',
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
            // ارتقای حساب
            _SettingsSheetTile(
              iconWidget: Image.asset(
                'assets/icons/icon_credits_diamond.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.diamond_outlined, size: 24, color: AppColors.warning),
              ),
              iconColor: AppColors.warning,
              title: 'ارتقای حساب',
              subtitle: 'عشق و حال به راه! همه امکانات فعلاً رایگانه ❤️',
              onTap: () {
                _close(context);
                context.push('/premium');
              },
            ),
            const SizedBox(height: 12),
            // ورود | ثبت نام (مهمان) یا شماره + خروج (لاگین‌شده)
            if (!isLoggedIn)
              _SettingsSheetTile(
                icon: Icons.person_outline_rounded,
                iconColor: Colors.white70,
                title: 'ورود | ثبت نام',
                onTap: () {
                  _close(context);
                  context.push('/login');
                },
              )
            else
              _SettingsSheetUserTile(
                phone: toFarsiNumber(user.phone),
                onLogout: () async {
                  final ok = await _showLogoutConfirm(context);
                  if (ok && context.mounted) {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      final router = GoRouter.of(context);
                      _close(context);
                      router.go('/home');
                    }
                  }
                },
              ),
            const SizedBox(height: 12),
            // ارتباط با پشتیبانی
            _SettingsSheetSupportTile(),
            const SizedBox(height: 24),
            ref.watch(packageInfoProvider).when(
                  data: (info) => Text(
                    'نسخه ${toFarsiNumber(info.version)}',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<bool> _showLogoutConfirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'خروج از حساب',
              style: TextStyle(
                fontFamily: 'Vazir',
                color: AppColors.textPrimary,
              ),
            ),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید خارج شوید؟',
              style: TextStyle(
                fontFamily: 'Vazir',
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'لغو',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'خروج',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    color: AppColors.errorLight,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _SettingsSheetTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsSheetTile({
    this.icon,
    this.iconWidget,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  iconWidget ?? Icon(icon, size: 24, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSheetUserTile extends StatelessWidget {
  final String phone;
  final VoidCallback onLogout;

  const _SettingsSheetUserTile({
    required this.phone,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 24,
                color: Colors.white70,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  phone,
                  style: const TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onLogout,
                child: const Text(
                  'خروج',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSheetSupportTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // در RTL با start هدفون راست می‌آید؛ ترتیب: هدفون (راست) سپس نوشته
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.headset_mic_outlined,
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ارتباط با پشتیبانی',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // راست به چپ: تلگرام (راست)، واتس‌اپ، اینستاگرام (چپ)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Expanded(
                      child: _SupportIconBox(
                        onTap: () {},
                        child: Image.asset(
                          'assets/icons/icon_telegram.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SupportIconBox(
                        onTap: () {},
                        child: Image.asset(
                          'assets/icons/icon_whatsapp.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.chat, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SupportIconBox(
                        onTap: () {},
                        child: Image.asset(
                          'assets/icons/icon_instagram_social.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// باکس جدا برای هر آیکون سوشال (Frame 725/726/727): rgba(255,255,255,0.1), radius 10, height 42, padding 0 8
class _SupportIconBox extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _SupportIconBox({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: child),
      ),
    );
  }
}
