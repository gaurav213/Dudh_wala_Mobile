import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/widgets/confirm_logout.dart';
import '../../features/farm/presentation/providers/farm_providers.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/dashboard_back_handler.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../../core/widgets/notification_bell_action.dart';

class FarmShell extends ConsumerWidget {
  const FarmShell({super.key, required this.child});

  final Widget child;

  int _index(String loc) {
    if (loc.startsWith(AppRoutes.farmToday)) return 1;
    if (loc.startsWith(AppRoutes.farmCustomers)) return 2;
    if (loc.startsWith(AppRoutes.farmRequests)) return 3;
    if (loc.startsWith(AppRoutes.farmProfile) ||
        loc.startsWith(AppRoutes.farmProducts) ||
        loc.startsWith(AppRoutes.farmServiceAreas) ||
        loc.startsWith(AppRoutes.farmInvitations) ||
        loc.startsWith(AppRoutes.settings)) {
      return 4;
    }
    // Dashboard and anything else → Home
    return 0;
  }

  String _title(String loc, AppLocalizations l10n) {
    if (loc.startsWith(AppRoutes.farmToday)) return l10n.navTodaysDeliveries;
    if (loc.startsWith(AppRoutes.farmCustomers)) return l10n.navCustomers;
    if (loc.startsWith(AppRoutes.farmRequests)) return l10n.navRequests;
    if (loc.startsWith(AppRoutes.farmProfile)) return l10n.navFarmProfile;
    if (loc.startsWith(AppRoutes.farmProducts)) return l10n.navProducts;
    if (loc.startsWith(AppRoutes.farmServiceAreas)) {
      return l10n.navServiceAreas;
    }
    if (loc.startsWith(AppRoutes.farmInvitations)) return l10n.navInvitations;
    if (loc.startsWith(AppRoutes.settings)) return l10n.navSettings;
    return l10n.navDashboard;
  }

  /// Root tabs use the shell AppBar. Nested screens bring their own AppBar + back.
  bool _showsShellAppBar(String loc) {
    final path = Uri.tryParse(loc)?.path ?? loc;
    switch (path) {
      case AppRoutes.farmDashboard:
      case AppRoutes.farmToday:
      case AppRoutes.farmCustomers:
      case AppRoutes.farmRequests:
      case AppRoutes.farmProfile:
      case AppRoutes.farmProducts:
      case AppRoutes.farmServiceAreas:
      case AppRoutes.farmInvitations:
      case AppRoutes.farmStaff:
      case AppRoutes.farmNotifications:
      case AppRoutes.settings:
        return true;
      default:
        return false;
    }
  }

  void _showMore(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Dk.of(context).milkWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget tile({
          required IconData icon,
          required String label,
          required VoidCallback onTap,
        }) {
          return ListTile(
            leading: Icon(icon, color: AppColors.leaf),
            title: Text(label),
            onTap: () {
              Navigator.of(ctx).pop();
              onTap();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              tile(
                icon: Icons.storefront_outlined,
                label: l10n.navFarmProfile,
                onTap: () => context.go(AppRoutes.farmProfile),
              ),
              tile(
                icon: Icons.water_drop_outlined,
                label: l10n.navProducts,
                onTap: () => context.go(AppRoutes.farmProducts),
              ),
              tile(
                icon: Icons.map_outlined,
                label: l10n.navServiceAreas,
                onTap: () => context.go(AppRoutes.farmServiceAreas),
              ),
              tile(
                icon: Icons.mail_outline,
                label: l10n.navInvitations,
                onTap: () => context.go(AppRoutes.farmInvitations),
              ),
              tile(
                icon: Icons.settings_outlined,
                label: l10n.navSettings,
                onTap: () => context.push(AppRoutes.settings),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: Text(l10n.logOut),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await confirmAndLogout(context, ref);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loc = GoRouterState.of(context).uri.toString();
    final selected = _index(loc);
    final showShellAppBar = _showsShellAppBar(loc);
    final pendingRequests = ref.watch(farmDashboardProvider).maybeWhen(
          data: (d) => d.counts.pendingServiceRequests,
          orElse: () => 0,
        );

    return DashboardBackHandler(
      homeRoute: AppRoutes.farmDashboard,
      child: Scaffold(
        backgroundColor: Dk.of(context).cream,
        appBar: showShellAppBar
            ? AppBar(
                automaticallyImplyLeading: false,
                title: Text(_title(loc, l10n)),
                actions: [
                  NotificationBellAction(
                    route: AppRoutes.farmNotifications,
                    popupOnly: true,
                    extraBadgeCount: pendingRequests,
                  ),
                ],
              )
            : null,
        body: child,
        bottomNavigationBar: NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedIndex: selected.clamp(0, 4),
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go(AppRoutes.farmDashboard);
              case 1:
                context.go(AppRoutes.farmToday);
              case 2:
                context.go(AppRoutes.farmCustomers);
              case 3:
                context.go(AppRoutes.farmRequests);
              case 4:
                _showMore(context, ref);
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_shipping_outlined),
              selectedIcon: const Icon(Icons.local_shipping),
              label: l10n.datesToday,
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people),
              label: l10n.navCustomers,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: pendingRequests > 0,
                label: Text("$pendingRequests"),
                child: const Icon(Icons.move_to_inbox_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: pendingRequests > 0,
                label: Text("$pendingRequests"),
                child: const Icon(Icons.move_to_inbox),
              ),
              label: l10n.navRequests,
            ),
            NavigationDestination(
              icon: const Icon(Icons.more_horiz),
              selectedIcon: const Icon(Icons.more_horiz),
              label: l10n.more,
            ),
          ],
        ),
      ),
    );
  }
}
