import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';
import 'auth_service.dart';

class AppLocaleState {
  final Locale locale;

  const AppLocaleState({this.locale = const Locale('fa')});

  bool get isRtl => locale.languageCode == 'fa' || locale.languageCode == 'ar';
}

class AppLocaleNotifier extends StateNotifier<AppLocaleState> {
  final StorageService _storage;

  AppLocaleNotifier(this._storage) : super(const AppLocaleState()) {
    _loadLocale();
  }

  void _loadLocale() {
    final langCode = _storage.getLanguage();
    state = AppLocaleState(locale: Locale(langCode));
  }

  Future<void> setLocale(String langCode) async {
    await _storage.saveLanguage(langCode);
    state = AppLocaleState(locale: Locale(langCode));
  }
}

final localeProvider = StateNotifierProvider<AppLocaleNotifier, AppLocaleState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AppLocaleNotifier(storage);
});
