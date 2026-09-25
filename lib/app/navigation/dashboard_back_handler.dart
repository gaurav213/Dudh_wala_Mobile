import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'home_routes.dart';

/// Android/system back: nested screens → role dashboard; dashboard → exit app.
class DashboardBackHandler extends StatelessWidget {
  const DashboardBackHandler({
    super.key,
    required this.homeRoute,
    required this.child,
  });

  final String homeRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final onHome = isHomeRoute(location, homeRoute);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (onHome) {
          SystemNavigator.pop();
          return;
        }
        context.go(homeRoute);
      },
      child: child,
    );
  }
}
