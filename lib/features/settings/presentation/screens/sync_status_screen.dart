import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../l10n/app_localizations.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStateProvider);
    final service = ref.watch(syncServiceProvider);
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).syncStatus)),
      body: sync.when(
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context).phase),
              trailing: Text(s.phase.name),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context).queue),
              trailing: Text("${s.queueCount}"),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context).lastSynced),
              trailing: Text(
                s.lastSyncedAt == null
                    ? 'Never'
                    : formatDateTime(s.lastSyncedAt!),
              ),
            ),
            if (s.lastError != null)
              ListTile(
                title: Text(AppLocalizations.of(context).lastError),
                subtitle: Text(s.lastError!),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => service.syncNow(),
              child: Text(AppLocalizations.of(context).syncNow),
            ),
          ],
        ),
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context).phase),
              trailing: Text(service.state.phase.name),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context).queue),
              trailing: Text("${service.state.queueCount}"),
            ),
            FilledButton(
              onPressed: () => service.syncNow(),
              child: Text(AppLocalizations.of(context).syncNow),
            ),
          ],
        ),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
