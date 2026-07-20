import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _localeStorageKey = 'app_locale';
const _supportedLanguageCodes = {'ru', 'en'};
const _defaultLocale = Locale('ru');
const _systemLocaleValue = 'system';

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);

final activeLocaleProvider = Provider<Locale>((ref) {
  final selected = ref.watch(localeControllerProvider).value;
  if (selected != null) {
    return selected;
  }
  for (final locale in PlatformDispatcher.instance.locales) {
    if (_supportedLanguageCodes.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('ru');
});

class LocaleController extends AsyncNotifier<Locale?> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<Locale?> build() async {
    try {
      final languageCode = await _storage.read(key: _localeStorageKey);
      if (languageCode == _systemLocaleValue) {
        return null;
      }
      if (languageCode == null ||
          !_supportedLanguageCodes.contains(languageCode)) {
        return _defaultLocale;
      }
      return Locale(languageCode);
    } on Object {
      return _defaultLocale;
    }
  }

  Future<void> setLocale(Locale? locale) async {
    final languageCode = locale?.languageCode;
    if (languageCode != null &&
        !_supportedLanguageCodes.contains(languageCode)) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported locale');
    }

    state = AsyncData(locale);
    try {
      if (languageCode == null) {
        await _storage.write(key: _localeStorageKey, value: _systemLocaleValue);
      } else {
        await _storage.write(key: _localeStorageKey, value: languageCode);
      }
    } on Object {
      state = AsyncData(locale);
    }
  }
}
