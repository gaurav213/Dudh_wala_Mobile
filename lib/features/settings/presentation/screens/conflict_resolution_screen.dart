import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/widgets/dk_empty.dart';

final _conflictsProvider =
    FutureProvider<List<Map<String, Object?>>>((ref) async {
  return ref.watch(appDatabaseProvider).conflictRows();
});

class ConflictResolutionScreen extends ConsumerWidget {
  const ConflictResolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflicts = ref.watch(_conflictsProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Conflicts')),
      body: conflicts.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const DkEmpty(message: 'No sync conflicts.');
          }
          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final r = rows[i];
              return ListTile(
                title: Text('${r['entity_type']} · ${r['entity_id']}'),
                subtitle: const Text('Choose which version to keep'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await ref.read(appDatabaseProvider).resolveConflict(
                              entityType: r['entity_type'] as String,
                              entityId: r['entity_id'] as String,
                              keepLocal: true,
                            );
                        ref.invalidate(_conflictsProvider);
                      },
                      child: const Text('Local'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref.read(appDatabaseProvider).resolveConflict(
                              entityType: r['entity_type'] as String,
                              entityId: r['entity_id'] as String,
                              keepLocal: false,
                            );
                        ref.invalidate(_conflictsProvider);
                      },
                      child: const Text('Remote'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
