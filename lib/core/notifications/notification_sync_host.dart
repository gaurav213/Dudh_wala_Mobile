import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'notification_sync.dart';

/// Starts free inbox polling after login and applies pending notification routes.
class NotificationSyncHost extends ConsumerStatefulWidget {
  const NotificationSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationSyncHost> createState() =>
      _NotificationSyncHostState();
}

class _NotificationSyncHostState extends ConsumerState<NotificationSyncHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authControllerProvider).isAuthenticated) {
        ref.read(notificationSyncServiceProvider).start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) {
        ref.read(notificationSyncServiceProvider).start();
      } else {
        ref.read(notificationSyncServiceProvider).stop();
      }
    });

    ref.listen<String?>(pendingNotificationRouteProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      final auth = ref.read(authControllerProvider);
      if (!auth.isAuthenticated || !auth.initialized) return;
      ref.read(goRouterProvider).go(next);
      ref.read(pendingNotificationRouteProvider.notifier).state = null;
    });

    return widget.child;
  }
}
