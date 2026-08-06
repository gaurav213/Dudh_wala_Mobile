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

  static const AppEnvironment current = AppEnvironment(
    env: _parseEnv(
      String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    ),
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000/api/v1',
    ),
    enableApiLogs: bool.fromEnvironment('ENABLE_API_LOGS', defaultValue: true),
  );

  bool get isDev => env == AppEnv.development;

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
