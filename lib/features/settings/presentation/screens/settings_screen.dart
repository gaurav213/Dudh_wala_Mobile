import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/app_environment.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = AppEnvironment.current;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Environment'),
            subtitle: Text(env.env.name),
          ),
          ListTile(
            title: const Text('API base URL'),
            subtitle: Text(env.apiBaseUrl),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync status'),
            onTap: () => context.push(AppRoutes.syncStatus),
          ),
          ListTile(
            leading: const Icon(Icons.merge_type),
            title: const Text('Conflict resolution'),
            onTap: () => context.push(AppRoutes.conflicts),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => context.push(AppRoutes.profile),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Log out'),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
