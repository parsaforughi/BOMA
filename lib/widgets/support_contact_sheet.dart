import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'back_arrow_icon.dart';

/// منوی ارتباط با پشتیبانی — از پایین بالا می‌آید (موقع خرید یا تنظیمات)
class SupportContactSheet extends StatelessWidget {
  const SupportContactSheet({super.key});

  /// نمایش شیت به‌صورت modal از پایین
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SupportContactSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // بازگشت (سمت راست)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                    const Text(
                      'بازگشت',
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
            ),
            const SizedBox(height: 24),
            // عنوان: ارتباط با پشتیبانی + آیکن هدفون
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.headset_mic_outlined,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ارتباط با پشتیبانی',
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
            const SizedBox(height: 24),
            // سه باکس: تلگرام، واتس‌اپ، اینستاگرام (راست به چپ)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _SupportIconBox(
                        onTap: () {},
                        child: Image.asset(
                          'assets/icons/icon_telegram.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.send_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SupportIconBox(
                        onTap: () {},
                        child: Image.asset(
                          'assets/icons/icon_whatsapp.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.chat, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SupportIconBox(
                        onTap: () {},
                        child: Image.asset(
                          'assets/icons/icon_instagram_social.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SupportIconBox extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _SupportIconBox({required this.onTap, required this.child});

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
