import 'package:shared_preferences/shared_preferences.dart';

import '../environment/app_environment.dart';

/// Runtime API host — survives USB unplug / app restart.
///
/// Phone must reach the Mac over Wi‑Fi or hotspot (`http://<lan-ip>:3000/api/v1`).
/// Do not rely on `adb reverse` / `127.0.0.1` for physical devices.
class ApiBaseUrlStore {
  ApiBaseUrlStore._();

  static const prefsKey = 'prefs.apiBaseUrl';
  static String? _cached;

  static String get current =>
      _cached ?? AppEnvironment.current.apiBaseUrl;

  static String normalize(String raw) {
    var url = raw.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.contains('/api/')) {
      url = '$url/api/v1';
    }
    return url;
  }

  static bool looksLikeLoopback(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host == '127.0.0.1' ||
        host == 'localhost' ||
        host == '10.0.2.2' ||
        host == '::1';
  }

  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefsKey)?.trim();
    if (saved != null && saved.isNotEmpty) {
      _cached = normalize(saved);
      return _cached!;
    }

    final builtIn = normalize(AppEnvironment.current.apiBaseUrl);
    // Seed LAN builds into prefs so later cold starts don't fall back to
    // 127.0.0.1 after a rebuild without --dart-define.
    if (!looksLikeLoopback(builtIn)) {
      await prefs.setString(prefsKey, builtIn);
    }
    _cached = builtIn;
    return builtIn;
  }

  static Future<String> save(String raw) async {
    final url = normalize(raw);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, url);
    _cached = url;
    return url;
  }
}
