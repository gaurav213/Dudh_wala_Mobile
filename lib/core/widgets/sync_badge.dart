import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_service.dart';
import '../../app/theme/app_theme.dart';

class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncStateProvider);
    return sync.when(
      data: (s) {
        final color = switch (s.phase) {
          SyncPhase.error => AppColors.danger,
          SyncPhase.pushing || SyncPhase.pulling => AppColors.warning,
          _ => s.queueCount > 0 ? AppColors.warning : AppColors.success,
        };
        return IconButton(
          tooltip: s.queueCount > 0
              ? '${s.queueCount} pending'
              : 'Synced',
          onPressed: () =>
              ref.read(syncServiceProvider).syncNow(),
          icon: Icon(Icons.sync, color: color),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Icon(Icons.sync_problem, color: AppColors.danger),
    );
  }
}
