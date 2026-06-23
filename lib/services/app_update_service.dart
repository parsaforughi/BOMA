import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../models/app_version_info.dart';

class AppUpdateCheckResult {
  final bool updateRequired;
  final AppVersionInfo? versionInfo;
  final String? currentVersion;
  final int? currentBuildNumber;

  const AppUpdateCheckResult({
    required this.updateRequired,
    this.versionInfo,
    this.currentVersion,
    this.currentBuildNumber,
  });
}

class AppUpdateService {
  AppUpdateService._();

  static final _connectivity = Connectivity();

  static Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  static Future<AppUpdateCheckResult> checkForRequiredUpdate() async {
    if (!AppConfig.hasVersionApi) {
      return const AppUpdateCheckResult(updateRequired: false);
    }

    if (!await hasInternetConnection()) {
      return const AppUpdateCheckResult(updateRequired: false);
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final platform = Platform.isIOS ? 'ios' : 'android';

    try {
      final uri = AppConfig.versionCheckUri(
        platform: platform,
        buildNumber: buildNumber,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return AppUpdateCheckResult(
          updateRequired: false,
          currentVersion: packageInfo.version,
          currentBuildNumber: buildNumber,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = AppVersionInfo.fromJson(json);
      final required = info.updateRequired ||
          (info.forceUpdate &&
              buildNumber > 0 &&
              buildNumber < info.minBuildNumber);

      return AppUpdateCheckResult(
        updateRequired: required,
        versionInfo: info,
        currentVersion: packageInfo.version,
        currentBuildNumber: buildNumber,
      );
    } catch (error, stackTrace) {
      debugPrint('AppUpdateService.checkForRequiredUpdate failed: $error');
      debugPrint('$stackTrace');
      return AppUpdateCheckResult(
        updateRequired: false,
        currentVersion: packageInfo.version,
        currentBuildNumber: buildNumber,
      );
    }
  }
}
