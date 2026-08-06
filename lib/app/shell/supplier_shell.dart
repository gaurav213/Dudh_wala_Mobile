import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';
import '../theme/app_theme.dart';

class SupplierShell extends StatelessWidget {
  const SupplierShell({super.key, required this.child});

  final Widget child;

  int _index(String loc) {
    if (loc.startsWith(AppRoutes.customers)) return 1;
    if (loc.startsWith('/bills') || loc.startsWith(AppRoutes.outstanding)) {
      return 2;
    }
    if (loc.startsWith(AppRoutes.settings) || loc.startsWith(AppRoutes.profile)) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.milkWhite,
        selectedIndex: _index(loc),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go(AppRoutes.supplierHome);
            case 1:
              context.go(AppRoutes.customers);
            case 2:
              context.go(AppRoutes.bills);
            case 3:
              context.go(AppRoutes.settings);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
