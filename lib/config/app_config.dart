/// Remote config for BOMA client.
///
/// `flutter build apk --dart-define=BOMA_API_BASE=https://YOUR-APP.up.railway.app`
class AppConfig {
  AppConfig._();

  /// Base URL for the BOMA backend (OTP auth + version API).
  /// When empty the app falls back to offline/mock mode.
  static const apiBase = String.fromEnvironment(
    'BOMA_API_BASE',
    defaultValue: '',
  );

  static bool get hasApi => apiBase.isNotEmpty;

  static Uri authUri(String path) => Uri.parse('$apiBase$path');

  static Uri versionCheckUri({
    required String platform,
    required int buildNumber,
  }) {
    return Uri.parse(apiBase).replace(
      path: '/api/app/version',
      queryParameters: {
        'platform': platform,
        'build': buildNumber.toString(),
      },
    );
  }

  /// Keep backwards-compat: if BOMA_VERSION_API is set separately, honour it.
  static const _legacyVersionApi = String.fromEnvironment(
    'BOMA_VERSION_API',
    defaultValue: '',
  );

  static bool get hasVersionApi =>
      apiBase.isNotEmpty || _legacyVersionApi.isNotEmpty;

  static Uri resolvedVersionCheckUri({
    required String platform,
    required int buildNumber,
  }) {
    final base = apiBase.isNotEmpty ? apiBase : _legacyVersionApi;
    return Uri.parse(base).replace(
      path: '/api/app/version',
      queryParameters: {
        'platform': platform,
        'build': buildNumber.toString(),
      },
    );
  }
}
