import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/formatters/indian_formatters.dart';
import '../../../../core/sync/sync_service.dart';

class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStateProvider);
    final service = ref.watch(syncServiceProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Sync status')),
      body: sync.when(
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Phase'),
              trailing: Text(s.phase.name),
            ),
            ListTile(
              title: const Text('Queue'),
              trailing: Text('${s.queueCount}'),
            ),
            ListTile(
              title: const Text('Last synced'),
              trailing: Text(
                s.lastSyncedAt == null
                    ? 'Never'
                    : formatDateTime(s.lastSyncedAt!),
              ),
            ),
            if (s.lastError != null)
              ListTile(
                title: const Text('Last error'),
                subtitle: Text(s.lastError!),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => service.syncNow(),
              child: const Text('Sync now'),
            ),
          ],
        ),
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Phase'),
              trailing: Text(service.state.phase.name),
            ),
            ListTile(
              title: const Text('Queue'),
              trailing: Text('${service.state.queueCount}'),
            ),
            FilledButton(
              onPressed: () => service.syncNow(),
              child: const Text('Sync now'),
            ),
          ],
        ),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
