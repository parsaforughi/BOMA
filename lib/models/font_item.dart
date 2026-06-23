enum FontCategory { standard, fancy, formal }

/// برای فیلتر و placeholder: همه | فارسی | عربی | انگلیسی
enum FontLanguage {
  all,
  persian,
  arabic,
  english,
}

extension FontLanguageExt on FontLanguage {
  String get label {
    switch (this) {
      case FontLanguage.all:
        return 'همه';
      case FontLanguage.persian:
        return 'فارسی';
      case FontLanguage.arabic:
        return 'عربی';
      case FontLanguage.english:
        return 'انگلیسی';
    }
  }

  /// متن placeholder فیلد اصلی بر اساس زبان
  String get placeholderHint {
    switch (this) {
      case FontLanguage.all:
      case FontLanguage.persian:
        return 'متنت رو بنویس ...';
      case FontLanguage.arabic:
        return 'النص ...';
      case FontLanguage.english:
        return 'Text';
    }
  }
}

class FontItem {
  final String name;
  final String displayName;
  final String family;
  final FontCategory category;
  final FontLanguage language;
  final bool isPro;

  const FontItem({
    required this.name,
    required this.displayName,
    required this.family,
    this.category = FontCategory.standard,
    this.language = FontLanguage.persian,
    this.isPro = false,
  });

  static const List<FontItem> allFonts = [
    FontItem(name: 'Vazir', displayName: 'وزیر', family: 'Vazir', category: FontCategory.standard),
    FontItem(name: 'Shabnam', displayName: 'شبنم', family: 'Shabnam', category: FontCategory.standard),
    FontItem(name: 'Sahel', displayName: 'ساحل', family: 'Sahel', category: FontCategory.standard),
    FontItem(name: 'Samim', displayName: 'صمیم', family: 'Samim', category: FontCategory.standard),
    FontItem(name: 'Dirooz', displayName: 'دیروز', family: 'Dirooz', category: FontCategory.fancy),
    FontItem(name: 'Parastoo', displayName: 'پرستو', family: 'Parastoo', category: FontCategory.standard),
    FontItem(name: 'IranNastaliq', displayName: 'نستعلیق', family: 'IranNastaliq', category: FontCategory.formal),
    FontItem(name: 'Lalezar', displayName: 'لاله‌زار', family: 'Lalezar', category: FontCategory.fancy),
    FontItem(name: 'BTraffic', displayName: 'ترافیک', family: 'BTraffic', category: FontCategory.standard),
    FontItem(name: 'Afsaneh', displayName: 'افسانه', family: 'Afsaneh', category: FontCategory.fancy),
    FontItem(name: 'AMosalas', displayName: 'مثلث', family: 'AMosalas', category: FontCategory.fancy),
    FontItem(name: 'DigiGhaf', displayName: 'دیجی قاف', family: 'DigiGhaf', category: FontCategory.fancy, isPro: true),
    FontItem(name: 'DigiLalezar', displayName: 'دیجی لاله‌زار', family: 'DigiLalezar', category: FontCategory.fancy, isPro: true),
    FontItem(name: 'Parvaz', displayName: 'پرواز', family: 'Parvaz', category: FontCategory.fancy),
    FontItem(name: 'Amine', displayName: 'انیمه', family: 'Amine', category: FontCategory.fancy),
    FontItem(name: 'GAseman', displayName: 'آسمان', family: 'GAseman', category: FontCategory.fancy),
  ];
}
