import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap.dart';
import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Keep system bars brand-green during startup — never flash black.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.leaf,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.leaf,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
      }
    };

    ProviderContainer container;
    try {
      container = await bootstrap();
    } catch (e, st) {
      // Root cause of black/red hang: bootstrap threw (e.g. SQLite migrate)
      // before runApp — user saw only native splash forever.
      if (kDebugMode) {
        debugPrint('Bootstrap failed: $e\n$st');
      }
      runApp(_BootstrapErrorApp(error: '$e'));
      return;
    }

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const DoodhKhataApp(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught zone error: $error\n$stack');
    }
  });
}

/// Shown only when bootstrap cannot start the real app.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).couldNotStartApp,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    // Soft retry: reopen DB path if migration was the issue.
                    try {
                      final db = AppDatabase();
                      await db.ensureOpen();
                      final container = ProviderContainer(
                        overrides: [appDatabaseProvider.overrideWithValue(db)],
                      );
                      runApp(
                        UncontrolledProviderScope(
                          container: container,
                          child: const DoodhKhataApp(),
                        ),
                      );
                    } catch (e) {
                      // Stay on this screen; user can force-stop.
                    }
                  },
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
