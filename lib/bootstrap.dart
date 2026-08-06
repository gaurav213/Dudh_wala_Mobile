import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/sync/sync_service.dart';

Future<ProviderContainer> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  await db.ensureOpen();

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
  );

  container.read(syncServiceProvider).startConnectivityListener();

  return container;
}
