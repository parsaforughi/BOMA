import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// در هر بار باز شدن اپ صدا زده می‌شود تا بازدید روزانه ثبت شود.
class AnalyticsService {
  AnalyticsService._();

  /// بدون نیاز به login — فقط شمارش open (از splash)
  static Future<void> open() async {
    if (!AppConfig.hasApi) return;
    try {
      await http.post(
        AppConfig.authUri('/api/analytics/open'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[Analytics] open failed: $e');
    }
  }

  /// با token — شمارش open + کاربر یکتا
  static Future<void> ping({required String? token}) async {
    if (!AppConfig.hasApi) return;
    if (token == null) {
      return open();
    }
    try {
      await http.post(
        AppConfig.authUri('/api/analytics/ping'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[Analytics] ping failed: $e');
    }
  }
}
