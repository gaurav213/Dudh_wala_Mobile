import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/widgets/confirm_logout.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../l10n/app_localizations.dart';
import '../branding/brand_logo.dart';
import '../navigation/dashboard_back_handler.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../../core/widgets/notification_bell_action.dart';

class _DeliveryDestination {
  const _DeliveryDestination(
      this.path, this.icon, this.selectedIcon, this.labelOf);

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) labelOf;
}

final _deliveryDestinations = <_DeliveryDestination>[
  _DeliveryDestination(
    AppRoutes.deliveryDashboard,
    Icons.dashboard_outlined,
    Icons.dashboard,
    (l) => l.navDashboard,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryToday,
    Icons.local_shipping_outlined,
    Icons.local_shipping,
    (l) => l.navTodaysDeliveries,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryCustomers,
    Icons.people_outline,
    Icons.people,
    (l) => l.navCustomers,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryExtraRequests,
    Icons.add_shopping_cart_outlined,
    Icons.add_shopping_cart,
    (l) => l.navExtraRequests,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryCollections,
    Icons.payments_outlined,
    Icons.payments,
    (l) => l.navCollections,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryPendingCash,
    Icons.fact_check_outlined,
    Icons.fact_check,
    (l) => l.navPendingCash,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryStaffHistory,
    Icons.history,
    Icons.history,
    (l) => l.navHistory,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryReviews,
    Icons.star_outline,
    Icons.star,
    (l) => l.navRateCustomers,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryNotifications,
    Icons.notifications_outlined,
    Icons.notifications,
    (l) => l.navNotifications,
  ),
  _DeliveryDestination(
    AppRoutes.deliveryProfile,
    Icons.person_outline,
    Icons.person,
    (l) => l.navProfile,
  ),
  _DeliveryDestination(
    AppRoutes.settings,
    Icons.settings_outlined,
    Icons.settings,
    (l) => l.navSettings,
  ),
];

class DeliveryShell extends ConsumerWidget {
  const DeliveryShell({super.key, required this.child});

  final Widget child;

  int _index(String loc) {
    if (loc.startsWith(AppRoutes.deliveryRunMode) ||
        loc.startsWith('/delivery/deliveries/') ||
        loc.startsWith(AppRoutes.deliveryToday)) {
      return 1;
    }
    final i = _deliveryDestinations.indexWhere((d) => loc.startsWith(d.path));
    return i == -1 ? 0 : i;
  }

  /// Drawer destinations keep the shell title. Nested detail screens use their own AppBar + back.
  bool _showsShellAppBar(String loc) {
    final path = Uri.tryParse(loc)?.path ?? loc;
    if (path == AppRoutes.deliveryToday ||
        path == AppRoutes.deliveryRunMode ||
        path == AppRoutes.deliveryRoute) {
      // Today list keeps shell; run/route bring their own AppBar.
      return path == AppRoutes.deliveryToday;
    }
    for (final d in _deliveryDestinations) {
      if (path == d.path) return true;
      // Deeper than a destination root → screen owns the header.
      if (path.startsWith('${d.path}/')) return false;
    }
    return !path.startsWith('/delivery/deliveries/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loc = GoRouterState.of(context).uri.toString();
    final selected = _index(loc);
    final current = _deliveryDestinations[selected];
    final showShellAppBar = _showsShellAppBar(loc);
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unread = unreadAsync.maybeWhen(data: (n) => n, orElse: () => 0);

    return DashboardBackHandler(
      homeRoute: AppRoutes.deliveryDashboard,
      child: Scaffold(
        backgroundColor: Dk.of(context).cream,
        appBar: showShellAppBar
            ? AppBar(
                title: Text(current.labelOf(l10n)),
                actions: [
                  NotificationBellAction(
                      route: AppRoutes.deliveryNotifications),
                ],
              )
            : null,
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.leaf),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const BrandLogo(
                        variant: BrandLogoVariant.onDark,
                        height: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.deliveryShellTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final d in _deliveryDestinations)
                        ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                d.path == current.path
                                    ? d.selectedIcon
                                    : d.icon,
                                color: d.path == current.path
                                    ? AppColors.leaf
                                    : Dk.of(context).muted,
                              ),
                              if (d.path == AppRoutes.deliveryNotifications &&
                                  unread > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(d.labelOf(l10n)),
                          selected: d.path == current.path,
                          selectedTileColor: Dk.of(context).foam,
                          onTap: () {
                            Navigator.of(context).pop();
                            if (d.path == AppRoutes.settings) {
                              context.push(d.path);
                            } else {
                              context.go(d.path);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: Text(l10n.logOut),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await confirmAndLogout(context, ref);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        body: child,
      ),
    );
  }
}
