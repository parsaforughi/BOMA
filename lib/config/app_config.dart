/// Remote config for BOMA client.
///
/// After deploying [server/] to Railway, set [apiBaseUrl] to your
/// public URL, e.g. `https://boma-api.up.railway.app`.
///
/// Override at build time:
/// `flutter build apk --dart-define=BOMA_API=https://...`
class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'BOMA_API',
    defaultValue: '',
  );

  static bool get hasApi => apiBaseUrl.isNotEmpty;
  static bool get hasVersionApi => hasApi;

  static Uri versionCheckUri({
    required String platform,
    required int buildNumber,
  }) {
    return Uri.parse(apiBaseUrl).replace(
      path: '/api/app/version',
      queryParameters: {
        'platform': platform,
        'build': buildNumber.toString(),
      },
    );
  }

  static Uri sendOtpUri() =>
      Uri.parse(apiBaseUrl).replace(path: '/api/auth/send-otp');

  static Uri verifyOtpUri() =>
      Uri.parse(apiBaseUrl).replace(path: '/api/auth/verify-otp');
}
