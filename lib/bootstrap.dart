import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_base_url_provider.dart';
import 'core/api/api_base_url_store.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/environment/app_environment.dart';
import 'core/sync/sync_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.current.assertProductionSafe();

  // Prefer saved LAN URL so physical phones keep working after USB unplug.
  // In production, ignore saved loopback overrides — use compile-time URL.
  final apiBaseUrl = AppEnvironment.current.isProduction
      ? AppEnvironment.current.apiBaseUrl
      : await ApiBaseUrlStore.load();

  final db = AppDatabase();
  await db.ensureOpen();

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
  // Seed after create — load() already filled ApiBaseUrlStore.current.
  container.read(apiBaseUrlProvider.notifier).state = apiBaseUrl;

  container.read(syncServiceProvider).startConnectivityListener();
  await container.read(authControllerProvider.notifier).bootstrap();

  return container;
}
