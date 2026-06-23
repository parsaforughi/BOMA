class AppVersionInfo {
  final int minBuildNumber;
  final int latestBuildNumber;
  final String latestVersion;
  final bool forceUpdate;
  final bool updateRequired;
  final String message;
  final String storeUrl;

  const AppVersionInfo({
    required this.minBuildNumber,
    required this.latestBuildNumber,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateRequired,
    required this.message,
    required this.storeUrl,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      minBuildNumber: _asInt(json['minBuildNumber']),
      latestBuildNumber: _asInt(json['latestBuildNumber']),
      latestVersion: json['latestVersion']?.toString() ?? '',
      forceUpdate: json['forceUpdate'] == true,
      updateRequired: json['updateRequired'] == true,
      message: json['message']?.toString() ??
          'نسخه جدید بوما منتشر شده. برای ادامه، اپ را به‌روزرسانی کنید.',
      storeUrl: json['storeUrl']?.toString() ?? '',
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
