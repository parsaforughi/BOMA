import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Auth
  static const String _authKey = 'auth';
  static const String _fontFavKey = 'fav_fonts';
  static const String _stickerFavKey = 'fav_stickers';
  static const String _backgroundFavKey = 'fav_backgrounds';
  static const String _pinnedTextColorsKey = 'pinned_text_colors';
  static const String _pinnedBgColorsKey = 'pinned_bg_colors';
  static const String _customTextColorsKey = 'custom_text_colors';
  static const String _customBgColorsKey = 'custom_bg_colors';
  static const String _languageKey = 'language';
  static const String _historyKey = 'history';
  static const String _customFontsKey = 'custom_fonts';
  static const String _pinnedStyleIdsKey = 'pinned_style_ids';
  static const String _lastSessionKey = 'last_session_v1';

  Future<void> saveAuth(Map<String, dynamic> authData) async {
    await _prefs.setString(_authKey, jsonEncode(authData));
  }

  Map<String, dynamic>? getAuth() {
    final data = _prefs.getString(_authKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> removeAuth() async {
    await _prefs.remove(_authKey);
  }

  // Favorite fonts
  Future<void> saveFavoriteFonts(List<String> fonts) async {
    await _prefs.setString(_fontFavKey, jsonEncode(fonts));
  }

  List<String> getFavoriteFonts() {
    final data = _prefs.getString(_fontFavKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleFavoriteFont(String fontName) async {
    final favorites = getFavoriteFonts();
    if (favorites.contains(fontName)) {
      favorites.remove(fontName);
    } else {
      favorites.add(fontName);
    }
    await saveFavoriteFonts(favorites);
  }

  bool isFontFavorite(String fontName) {
    return getFavoriteFonts().contains(fontName);
  }

  // Custom imported fonts
  Future<void> saveCustomFonts(List<Map<String, dynamic>> fonts) async {
    await _prefs.setString(_customFontsKey, jsonEncode(fonts));
  }

  List<Map<String, dynamic>> getCustomFonts() {
    final data = _prefs.getString(_customFontsKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // Pinned text styles (preset ids)
  Future<void> savePinnedStyleIds(List<String> ids) async {
    await _prefs.setString(_pinnedStyleIdsKey, jsonEncode(ids));
  }

  List<String> getPinnedStyleIds() {
    final data = _prefs.getString(_pinnedStyleIdsKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> togglePinnedStyleId(String id) async {
    final list = getPinnedStyleIds();
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await savePinnedStyleIds(list);
  }

  bool isStylePinned(String id) {
    return getPinnedStyleIds().contains(id);
  }

  // Favorite stickers
  Future<void> saveFavoriteStickers(List<String> stickers) async {
    await _prefs.setString(_stickerFavKey, jsonEncode(stickers));
  }

  List<String> getFavoriteStickers() {
    final data = _prefs.getString(_stickerFavKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleFavoriteSticker(String assetPath) async {
    final favorites = getFavoriteStickers();
    if (favorites.contains(assetPath)) {
      favorites.remove(assetPath);
    } else {
      favorites.add(assetPath);
    }
    await saveFavoriteStickers(favorites);
  }

  bool isStickerFavorite(String assetPath) {
    return getFavoriteStickers().contains(assetPath);
  }

  // Favorite backgrounds (by stable id)
  Future<void> saveFavoriteBackgrounds(List<String> ids) async {
    await _prefs.setString(_backgroundFavKey, jsonEncode(ids));
  }

  List<String> getFavoriteBackgrounds() {
    final data = _prefs.getString(_backgroundFavKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleFavoriteBackground(String id) async {
    final favorites = getFavoriteBackgrounds();
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    await saveFavoriteBackgrounds(favorites);
  }

  bool isBackgroundFavorite(String id) {
    return getFavoriteBackgrounds().contains(id);
  }

  // Pinned colors (ARGB int values)
  Future<void> savePinnedTextColors(List<int> colorValues) async {
    await _prefs.setString(_pinnedTextColorsKey, jsonEncode(colorValues));
  }

  Future<void> savePinnedBgColors(List<int> colorValues) async {
    await _prefs.setString(_pinnedBgColorsKey, jsonEncode(colorValues));
  }

  List<int> getPinnedTextColors() {
    final data = _prefs.getString(_pinnedTextColorsKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<int>();
    } catch (_) {
      return [];
    }
  }

  List<int> getPinnedBgColors() {
    final data = _prefs.getString(_pinnedBgColorsKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<int>();
    } catch (_) {
      return [];
    }
  }

  Future<void> togglePinnedTextColor(int colorValue) async {
    final list = getPinnedTextColors();
    if (list.contains(colorValue)) {
      list.remove(colorValue);
    } else {
      list.add(colorValue);
    }
    await savePinnedTextColors(list);
  }

  Future<void> togglePinnedBgColor(int colorValue) async {
    final list = getPinnedBgColors();
    if (list.contains(colorValue)) {
      list.remove(colorValue);
    } else {
      list.add(colorValue);
    }
    await savePinnedBgColors(list);
  }

  bool isTextColorPinned(int colorValue) {
    return getPinnedTextColors().contains(colorValue);
  }

  bool isBgColorPinned(int colorValue) {
    return getPinnedBgColors().contains(colorValue);
  }

  // Custom colors (ARGB int values)
  List<int> getCustomTextColors() {
    final data = _prefs.getString(_customTextColorsKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<int>();
    } catch (_) {
      return [];
    }
  }

  List<int> getCustomBgColors() {
    final data = _prefs.getString(_customBgColorsKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<int>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomTextColors(List<int> colorValues) async {
    await _prefs.setString(_customTextColorsKey, jsonEncode(colorValues));
  }

  Future<void> saveCustomBgColors(List<int> colorValues) async {
    await _prefs.setString(_customBgColorsKey, jsonEncode(colorValues));
  }

  Future<void> addCustomTextColor(int colorValue) async {
    final list = getCustomTextColors();
    list.remove(colorValue);
    list.insert(0, colorValue);
    if (list.length > 24) list.removeRange(24, list.length);
    await saveCustomTextColors(list);
  }

  Future<void> addCustomBgColor(int colorValue) async {
    final list = getCustomBgColors();
    list.remove(colorValue);
    list.insert(0, colorValue);
    if (list.length > 24) list.removeRange(24, list.length);
    await saveCustomBgColors(list);
  }

  // Language
  Future<void> saveLanguage(String langCode) async {
    await _prefs.setString(_languageKey, langCode);
  }

  String getLanguage() {
    return _prefs.getString(_languageKey) ?? 'fa';
  }

  // History
  Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    await _prefs.setString(_historyKey, jsonEncode(history));
  }

  List<Map<String, dynamic>> getHistory() {
    final data = _prefs.getString(_historyKey);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Last toolbar / panel state so the home screen reopens with options visible.
  Future<void> saveLastSession(Map<String, dynamic> session) async {
    await _prefs.setString(_lastSessionKey, jsonEncode(session));
  }

  Map<String, dynamic>? getLastSession() {
    final data = _prefs.getString(_lastSessionKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
