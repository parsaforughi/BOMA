import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_version_info.dart';
import '../../theme/colors.dart';

class ForceUpdateScreen extends StatelessWidget {
  final AppVersionInfo versionInfo;
  final String? currentVersion;

  const ForceUpdateScreen({
    super.key,
    required this.versionInfo,
    this.currentVersion,
  });

  Future<void> _openStore() async {
    final url = versionInfo.storeUrl.trim();
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.blueAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      size: 44,
                      color: AppColors.blueLight,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'به‌روزرسانی الزامی',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    versionInfo.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 15,
                      height: 1.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (currentVersion != null &&
                      versionInfo.latestVersion.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'نسخه فعلی: $currentVersion  →  نسخه جدید: ${versionInfo.latestVersion}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _openStore,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'به‌روزرسانی از فروشگاه',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
