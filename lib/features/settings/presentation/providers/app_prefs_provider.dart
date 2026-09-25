import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kThemeMode = 'prefs.themeMode';
const _kLocale = 'prefs.locale';

/// Supported app locales. Default is English.
const supportedAppLocales = <String>['en', 'hi', 'mr'];

ThemeMode themeModeFromStorage(String? raw) {
  return switch (raw) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light, // default = current light theme
  };
}

String themeModeToStorage(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
  };
}

Locale localeFromStorage(String? raw) {
  final code = supportedAppLocales.contains(raw) ? raw! : 'en';
  return Locale(code);
}

class AppPrefsState {
  const AppPrefsState({
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('en'),
    this.ready = false,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool ready;

  AppPrefsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? ready,
  }) {
    return AppPrefsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      ready: ready ?? this.ready,
    );
  }
}

class AppPrefsController extends StateNotifier<AppPrefsState> {
  AppPrefsController(this._ref) : super(const AppPrefsState()) {
    _load();
  }

  final Ref _ref;
  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = AppPrefsState(
      themeMode: themeModeFromStorage(_prefs!.getString(_kThemeMode)),
      locale: localeFromStorage(_prefs!.getString(_kLocale)),
      ready: true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setString(_kThemeMode, themeModeToStorage(mode));
  }

  Future<void> setLocaleCode(String code) async {
    if (!supportedAppLocales.contains(code)) return;
    // Update UI immediately; profile sync is best-effort in the background.
    state = state.copyWith(locale: Locale(code));
    await _prefs?.setString(_kLocale, code);
    // ignore: unawaited_futures
    _syncLanguageToProfile(code);
  }

  /// Apply server language only when the user has never set a local locale.
  Future<void> applyServerLanguageIfUnset(String? preferredLanguage) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    if (prefs.containsKey(_kLocale)) return;
    final code = preferredLanguage?.toLowerCase();
    if (code == null || !supportedAppLocales.contains(code)) return;
    state = state.copyWith(locale: Locale(code));
    await prefs.setString(_kLocale, code);
  }

  Future<void> _syncLanguageToProfile(String code) async {
    final auth = _ref.read(authControllerProvider);
    if (!auth.isAuthenticated) return;
    try {
      final api = _ref.read(apiClientProvider);
      await api.patch<Map<String, dynamic>>(
        '/auth/profile',
        data: {'preferredLanguage': code},
      );
    } catch (_) {
      // Local pref already applied; profile sync is best-effort.
    }
  }
}

final appPrefsProvider =
    StateNotifierProvider<AppPrefsController, AppPrefsState>((ref) {
  return AppPrefsController(ref);
});
