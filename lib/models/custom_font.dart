import 'font_item.dart';

/// فونت واردشده توسط کاربر (فایل TTF/OTF در documents).
class CustomFont {
  final String id;
  final String displayName;
  final String family;
  final String fileName;

  const CustomFont({
    required this.id,
    required this.displayName,
    required this.family,
    required this.fileName,
  });

  String get storageName => 'custom_$id';

  FontItem toFontItem() {
    return FontItem(
      name: storageName,
      displayName: displayName,
      family: family,
      category: FontCategory.standard,
      language: FontLanguage.persian,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'family': family,
        'fileName': fileName,
      };

  factory CustomFont.fromJson(Map<String, dynamic> json) {
    return CustomFont(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      family: json['family'] as String,
      fileName: json['fileName'] as String,
    );
  }
}
