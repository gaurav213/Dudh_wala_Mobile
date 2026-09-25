enum AppEnv { development, staging, production }

class AppEnvironment {
  const AppEnvironment({
    required this.env,
    required this.apiBaseUrl,
    required this.enableApiLogs,
  });

  final AppEnv env;
  final String apiBaseUrl;
  final bool enableApiLogs;

  /// Built from `--dart-define` values. Not `const` because `_parseEnv`
  /// cannot run inside a constant expression on newer Dart SDKs.
  static final AppEnvironment current = AppEnvironment(
    env: _parseEnv(
      const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    ),
    // Dev default is loopback HTTP (simulator). Production builds MUST pass
    // --dart-define=API_BASE_URL=https://…/api/v1 (see dart_defines/).
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:3000/api/v1',
    ),
    enableApiLogs:
        const bool.fromEnvironment('ENABLE_API_LOGS', defaultValue: false),
  );

  bool get isDev => env == AppEnv.development;
  bool get isProduction => env == AppEnv.production;

  /// Call at startup. Throws in production when API URL is not HTTPS.
  void assertProductionSafe() {
    if (!isProduction) return;
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError(
        'Production builds require --dart-define=APP_ENV=production and '
        '--dart-define=API_BASE_URL=https://<your-api-host>/api/v1. '
        'Got: $apiBaseUrl',
      );
    }
  }

  static AppEnv _parseEnv(String value) {
    switch (value.toLowerCase()) {
      case 'staging':
        return AppEnv.staging;
      case 'production':
      case 'prod':
        return AppEnv.production;
      default:
        return AppEnv.development;
    }
  }
}
