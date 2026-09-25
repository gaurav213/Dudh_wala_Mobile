import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_sync_host.dart';
import '../features/settings/presentation/providers/app_prefs_provider.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class DoodhKhataApp extends ConsumerWidget {
  const DoodhKhataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final prefs = ref.watch(appPrefsProvider);
    final lang = prefs.locale.languageCode;

    return NotificationSyncHost(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: prefs.themeMode,
        locale: prefs.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (deviceLocale, supported) {
          for (final locale in supported) {
            if (locale.languageCode == lang) return locale;
          }
          return const Locale('en');
        },
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return KeyedSubtree(
            key: ValueKey('locale-$lang'),
            child: child ?? const SizedBox.shrink(),
          );
        },
        routerConfig: router,
      ),
    );
  }
}
