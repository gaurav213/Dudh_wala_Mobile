import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import 'dashboard_back_handler.dart';
import 'home_routes.dart';

/// Wraps screens outside role shells (e.g. shared settings) with dashboard back.
class RoleDashboardBackScope extends ConsumerWidget {
  const RoleDashboardBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).user?.role;
    if (role == null) return child;
    return DashboardBackHandler(
      homeRoute: homeRouteForRole(role),
      child: child,
    );
  }
}
