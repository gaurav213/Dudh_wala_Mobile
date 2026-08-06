import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';
import '../theme/app_theme.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});

  final Widget child;

  int _index(String loc) {
    if (loc.startsWith(AppRoutes.customerCalendar) ||
        loc.startsWith(AppRoutes.customerHistory)) {
      return 1;
    }
    if (loc.startsWith(AppRoutes.customerBills) ||
        loc.startsWith(AppRoutes.customerPayments)) {
      return 2;
    }
    if (loc.startsWith(AppRoutes.customerProfile)) return 3;
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
              context.go(AppRoutes.customerHome);
            case 1:
              context.go(AppRoutes.customerCalendar);
            case 2:
              context.go(AppRoutes.customerBills);
            case 3:
              context.go(AppRoutes.customerProfile);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
