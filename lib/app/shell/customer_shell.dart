import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../navigation/dashboard_back_handler.dart';
import '../routes.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});

  final Widget child;

  int _index(String loc) {
    if (loc.startsWith(AppRoutes.customerFindFarms)) return 1;
    if (loc.startsWith(AppRoutes.customerBills) ||
        loc.startsWith(AppRoutes.customerBilling)) {
      return 2;
    }
    if (loc.startsWith(AppRoutes.customerRequests) ||
        loc.startsWith(AppRoutes.customerInvitations)) {
      return 3;
    }
    if (loc.startsWith(AppRoutes.customerProfile) ||
        loc.startsWith(AppRoutes.customerPayments) ||
        loc.startsWith(AppRoutes.customerCalendar) ||
        loc.startsWith(AppRoutes.customerHistory) ||
        loc.startsWith(AppRoutes.settings)) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loc = GoRouterState.of(context).uri.toString();
    final selected = _index(loc);

    return DashboardBackHandler(
      homeRoute: AppRoutes.customerDashboard,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: child,
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedIndex: selected.clamp(0, 4),
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go(AppRoutes.customerDashboard);
              case 1:
                context.go(AppRoutes.customerFindFarms);
              case 2:
                context.go(AppRoutes.customerBilling);
              case 3:
                context.go(AppRoutes.customerRequests);
              case 4:
                context.go(AppRoutes.customerProfile);
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront),
              label: l10n.navFarms,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: l10n.navBills,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inbox_outlined),
              selectedIcon: const Icon(Icons.inbox),
              label: l10n.navInbox,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
