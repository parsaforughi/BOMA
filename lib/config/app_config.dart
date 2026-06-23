/// Remote config for BOMA client.
///
/// Railway only hosts the force-update API — not the full app.
/// Set [versionApiBaseUrl] to your Railway URL after deploying [server/].
///
/// `flutter build apk --dart-define=BOMA_VERSION_API=https://...`
class AppConfig {
  AppConfig._();

  static const versionApiBaseUrl = String.fromEnvironment(
    'BOMA_VERSION_API',
    defaultValue: '',
  );

  static bool get hasVersionApi => versionApiBaseUrl.isNotEmpty;

  static Uri versionCheckUri({
    required String platform,
    required int buildNumber,
  }) {
    return Uri.parse(versionApiBaseUrl).replace(
      path: '/api/app/version',
      queryParameters: {
        'platform': platform,
        'build': buildNumber.toString(),
      },
    );
  }
}
