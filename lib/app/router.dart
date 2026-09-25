import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_customer_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/billing/presentation/screens/bill_details_screen.dart';
import '../features/billing/presentation/screens/bills_list_screen.dart';
import '../features/billing/presentation/screens/generate_bill_screen.dart';
import '../features/billing/presentation/screens/outstanding_screen.dart';
import '../features/calendar/presentation/screens/delivery_calendar_screen.dart';
import '../features/customer_marketplace/data/models/customer_marketplace_models.dart';
import '../features/customer_marketplace/presentation/screens/customer_addresses_screen.dart';
import '../features/customer_marketplace/presentation/screens/customer_farm_detail_screen.dart';
import '../features/customer_marketplace/presentation/screens/customer_find_farms_screen.dart';
import '../features/customer_marketplace/presentation/screens/customer_requests_screen.dart';
import '../features/customer_deliveries/presentation/screens/customer_billing_screen.dart';
import '../features/customer_deliveries/presentation/screens/customer_delivery_detail_screen.dart';
import '../features/customer_deliveries/presentation/screens/customer_extra_request_screen.dart';
import '../features/customer_deliveries/presentation/screens/customer_reviews_received_screen.dart';
import '../features/customers/presentation/screens/customer_details_screen.dart';
import '../features/customers/presentation/screens/customer_form_screen.dart';
import '../features/customers/presentation/screens/customers_list_screen.dart';
import '../features/dashboard/presentation/screens/customer_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/supplier_dashboard_screen.dart';
import '../features/deliveries/presentation/screens/delivery_history_screen.dart';
import '../features/deliveries/presentation/screens/todays_deliveries_screen.dart';
import '../features/delivery_staff/data/models/delivery_staff_models.dart';
import '../features/delivery_staff/presentation/screens/delivery_collections_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_customer_detail_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_customers_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_dashboard_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_detail_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_extra_requests_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_history_screen.dart'
    as delivery_staff;
import '../features/delivery_staff/presentation/screens/delivery_pending_cash_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_reviews_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_route_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_run_mode_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_today_screen.dart';
import '../features/farm/presentation/screens/farm_connected_customers_screen.dart';
import '../features/farm/presentation/screens/farm_customer_delivery_detail_screen.dart';
import '../features/farm/presentation/screens/farm_dashboard_screen.dart';
import '../features/farm/presentation/screens/farm_delivery_edit_review_screen.dart';
import '../features/farm/presentation/screens/farm_edited_deliveries_screen.dart';
import '../features/farm/presentation/screens/farm_extra_today_screen.dart';
import '../features/farm/presentation/screens/farm_invitations_screen.dart';
import '../features/farm/presentation/screens/farm_products_screen.dart';
import '../features/farm/presentation/screens/farm_profile_screen.dart';
import '../features/farm/presentation/screens/farm_request_detail_screen.dart';
import '../features/farm/presentation/screens/farm_requests_screen.dart';
import '../features/farm/presentation/screens/farm_service_areas_screen.dart';
import '../features/farm/presentation/screens/farm_staff_detail_screen.dart';
import '../features/farm/presentation/screens/farm_staff_edited_screen.dart';
import '../features/farm/presentation/screens/farm_staff_screen.dart';
import '../features/farm/presentation/screens/farm_staff_settings_screen.dart';
import '../features/farm/presentation/screens/farm_staff_today_screen.dart';
import '../features/farm/presentation/screens/farm_today_deliveries_screen.dart';
import '../features/delivery_staff/presentation/screens/delivery_edit_screen.dart';
import '../features/notifications/presentation/screens/notification_detail_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/payments/presentation/screens/payment_history_screen.dart';
import '../features/payments/presentation/screens/record_payment_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/conflict_resolution_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/sync_status_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/subscriptions/presentation/screens/subscription_form_screen.dart';
import 'navigation/role_dashboard_back_scope.dart';
import 'routes.dart';
import 'navigation/home_routes.dart';
import 'shell/customer_shell.dart';
import 'shell/delivery_shell.dart';
import 'shell/farm_shell.dart';
import 'shell/supplier_shell.dart';
import '../core/feature_flags.dart';

final _rootKey = GlobalKey<NavigatorState>();

String _homeForRole(UserRole role) => homeRouteForRole(role);

final goRouterProvider = Provider<GoRouter>((ref) {
  // Do NOT watch auth here — recreating GoRouter remounts Splash and can
  // re-trigger bootstrap forever. Refresh via listenable + ref.read instead.
  final refresh = _AuthListenable(ref);
  final auth = ref.read(authControllerProvider);
  final initialLocation = !auth.initialized
      ? AppRoutes.splash
      : (auth.isAuthenticated
          ? _homeForRole(auth.user!.role)
          : AppRoutes.login);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final initializing = !auth.initialized;
      final loggedIn = auth.isAuthenticated;
      final isAuthScreen = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.registerCustomer ||
          loc == AppRoutes.forgotPassword;

      if (initializing) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Splash is not a destination after bootstrap — always leave it.
      if (loc == AppRoutes.splash) {
        return loggedIn ? _homeForRole(auth.user!.role) : AppRoutes.login;
      }

      if (!loggedIn && !isAuthScreen) return AppRoutes.login;
      if (loggedIn && isAuthScreen) {
        return _homeForRole(auth.user!.role);
      }
      // `/customer` is kept only as a backward-compatible alias for the new
      // `/customer/dashboard` marketplace home.
      if (loc == AppRoutes.customerHome) return AppRoutes.customerDashboard;

      // Shared settings are available to every persona.
      final onSharedSettings = loc.startsWith(AppRoutes.settings);

      // Customers must stay inside customer marketplace routes — not the
      // farm-owner / supplier ledger shells.
      if (auth.user?.role == UserRole.customer) {
        final onCustomerRoute = loc.startsWith('/customer') ||
            onSharedSettings ||
            loc.startsWith('/notification-detail');
        if (!onCustomerRoute && !isAuthScreen) {
          return AppRoutes.customerDashboard;
        }
      }
      // TEMP: delivery-staff disabled — restore next update
      if (auth.user?.role == UserRole.deliveryStaff) {
        if (!kDeliveryStaffEnabled) {
          return isAuthScreen ? null : AppRoutes.login;
        }
        final onDeliveryRoute = loc.startsWith('/delivery') ||
            onSharedSettings ||
            loc.startsWith('/notification-detail');
        if (!onDeliveryRoute && !isAuthScreen) {
          return AppRoutes.deliveryDashboard;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerCustomer,
        builder: (_, __) => const RegisterCustomerScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => SupplierShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.supplierHome,
            builder: (_, __) => const SupplierDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.todaysDeliveries,
            builder: (_, __) => const TodaysDeliveriesScreen(),
          ),
          GoRoute(
            path: AppRoutes.deliveryHistory,
            builder: (_, __) => const DeliveryHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            builder: (_, __) => const DeliveryCalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (_, __) => const CustomersListScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (_, __) => const CustomerFormScreen(),
              ),
              GoRoute(
                path: 'form/:id',
                builder: (_, state) => CustomerFormScreen(
                  customerId: state.pathParameters['id'],
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => CustomerDetailsScreen(
                  customerId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.subscriptionForm,
            builder: (_, state) => SubscriptionFormScreen(
              customerId: state.uri.queryParameters['customerId'],
              subscriptionId: state.uri.queryParameters['id'],
            ),
          ),
          GoRoute(
            path: AppRoutes.bills,
            builder: (_, __) => const BillsListScreen(),
            routes: [
              GoRoute(
                path: 'generate',
                builder: (_, state) => GenerateBillScreen(
                  customerId: state.uri.queryParameters['customerId'],
                ),
              ),
              GoRoute(
                path: 'outstanding',
                builder: (_, __) => const OutstandingScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => BillDetailsScreen(
                  billId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.recordPayment,
            builder: (_, state) => RecordPaymentScreen(
              customerId: state.uri.queryParameters['customerId'],
              billId: state.uri.queryParameters['billId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.paymentHistory,
            builder: (_, __) => const PaymentHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
      // Shared settings (all roles) — outside role shells so chrome stays simple.
      GoRoute(
        path: '/notification-detail/:recipientId',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => NotificationDetailScreen(
          recipientId: state.pathParameters['recipientId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RoleDashboardBackScope(
          child: SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'sync',
            builder: (_, __) => const RoleDashboardBackScope(
              child: SyncStatusScreen(),
            ),
          ),
          GoRoute(
            path: 'conflicts',
            builder: (_, __) => const RoleDashboardBackScope(
              child: ConflictResolutionScreen(),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.customerDashboard,
            builder: (_, __) => const CustomerDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerCalendar,
            builder: (_, __) => const DeliveryCalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerHistory,
            builder: (_, __) => const DeliveryHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerBills,
            redirect: (_, __) => AppRoutes.customerBilling,
          ),
          GoRoute(
            path: AppRoutes.customerPayments,
            builder: (_, __) => const PaymentHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerProfile,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerAddresses,
            builder: (_, __) => const CustomerAddressesScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerFindFarms,
            builder: (_, __) => const CustomerFindFarmsScreen(),
            routes: [
              GoRoute(
                path: ':farmId',
                builder: (_, state) {
                  final extra = state.extra;
                  return CustomerFarmDetailScreen(
                    farmId: state.pathParameters['farmId']!,
                    args: extra is CustomerFarmDetailArgs ? extra : null,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.customerRequests,
            builder: (_, state) => CustomerRequestsScreen(
              focusRequestId: state.uri.queryParameters['focus'],
            ),
          ),
          GoRoute(
            path: AppRoutes.customerInvitations,
            redirect: (_, __) => AppRoutes.customerRequests,
          ),
          GoRoute(
            path: '/customer/deliveries/:deliveryId',
            builder: (_, state) {
              final extra = state.extra;
              return CustomerDeliveryDetailScreen(
                deliveryId: state.pathParameters['deliveryId']!,
                initial: extra is DeliveryModel ? extra : null,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.customerExtraRequest,
            builder: (_, state) {
              final extra = state.extra;
              return CustomerExtraRequestScreen(
                args: extra is CustomerExtraRequestArgs ? extra : null,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.customerBilling,
            builder: (_, __) => const CustomerBillingScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerReviewsReceived,
            builder: (_, __) => const CustomerReviewsReceivedScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerNotifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
      // TEMP: delivery-staff disabled — restore next update
      if (kDeliveryStaffEnabled)
        ShellRoute(
          builder: (context, state, child) => DeliveryShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.deliveryDashboard,
              builder: (_, __) => const DeliveryDashboardScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryCustomers,
              builder: (_, __) => const DeliveryCustomersScreen(),
            ),
            GoRoute(
              path: '/delivery/customers/:customerId',
              builder: (_, state) => DeliveryCustomerDetailScreen(
                customerId: state.pathParameters['customerId']!,
              ),
            ),
            GoRoute(
              path: AppRoutes.deliveryToday,
              builder: (_, state) => DeliveryTodayScreen(
                initialFilter: state.uri.queryParameters['filter'],
              ),
            ),
            GoRoute(
              path: '/delivery/deliveries/:deliveryId/edit',
              builder: (_, state) => DeliveryEditScreen(
                deliveryId: state.pathParameters['deliveryId']!,
              ),
            ),
            GoRoute(
              path: '/delivery/deliveries/:deliveryId',
              builder: (_, state) {
                final extra = state.extra;
                return DeliveryDetailScreen(
                  deliveryId: state.pathParameters['deliveryId']!,
                  initial: extra is DeliveryModel ? extra : null,
                );
              },
            ),
            GoRoute(
              path: AppRoutes.deliveryRunMode,
              builder: (_, __) => const DeliveryRunModeScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryRoute,
              builder: (_, __) => const DeliveryRouteScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryExtraRequests,
              builder: (_, __) => const DeliveryExtraRequestsScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryCollections,
              builder: (_, __) => const DeliveryCollectionsScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryPendingCash,
              builder: (_, __) => const DeliveryPendingCashScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryStaffHistory,
              builder: (_, __) => const delivery_staff.DeliveryHistoryScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryReviews,
              builder: (_, __) => const DeliveryReviewsScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryNotifications,
              builder: (_, __) => const NotificationsScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveryProfile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ShellRoute(
        builder: (context, state, child) => FarmShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.farmDashboard,
            builder: (_, __) => const FarmDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.farmProfile,
            builder: (_, __) => const FarmProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.farmServiceAreas,
            builder: (_, __) => const FarmServiceAreasScreen(),
          ),
          GoRoute(
            path: AppRoutes.farmProducts,
            builder: (_, __) => const FarmProductsScreen(),
          ),
          // TEMP: delivery-staff disabled — restore next update
          if (kDeliveryStaffEnabled) ...[
            GoRoute(
              path: AppRoutes.farmStaff,
              builder: (_, __) => const FarmStaffScreen(),
            ),
            GoRoute(
              path: '/farm/staff/:staffUserId',
              builder: (_, state) => FarmStaffDetailScreen(
                staffUserId: state.pathParameters['staffUserId']!,
              ),
            ),
            GoRoute(
              path: '/farm/staff/:staffUserId/today',
              builder: (_, state) => FarmStaffTodayScreen(
                staffUserId: state.pathParameters['staffUserId']!,
                section: state.uri.queryParameters['section'] ?? 'all',
              ),
            ),
            GoRoute(
              path: '/farm/staff/:staffUserId/edited',
              builder: (_, state) => FarmStaffEditedScreen(
                staffUserId: state.pathParameters['staffUserId']!,
              ),
            ),
            GoRoute(
              path: '/farm/staff/:staffUserId/settings',
              builder: (_, state) => FarmStaffSettingsScreen(
                staffUserId: state.pathParameters['staffUserId']!,
              ),
            ),
          ],
          GoRoute(
            path: '/farm/requests/:requestId',
            builder: (_, state) => FarmRequestDetailScreen(
              requestId: state.pathParameters['requestId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.farmRequests,
            builder: (_, __) => const FarmRequestsScreen(),
          ),
          GoRoute(
            path: AppRoutes.farmInvitations,
            builder: (_, __) => const FarmInvitationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.farmCustomers,
            builder: (_, __) => const FarmConnectedCustomersScreen(),
          ),
          GoRoute(
            path: AppRoutes.farmToday,
            builder: (_, __) => const FarmTodayDeliveriesScreen(),
          ),
          GoRoute(
            path: AppRoutes.farmNotifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/farm/today/:customerId',
            builder: (_, state) => FarmCustomerDeliveryDetailScreen(
              customerId: state.pathParameters['customerId']!,
              initialDateIso: state.uri.queryParameters['date'],
            ),
          ),
          GoRoute(
            path: AppRoutes.farmDeliveriesEdited,
            builder: (_, __) => const FarmEditedDeliveriesScreen(),
          ),
          GoRoute(
            path: AppRoutes.farmExtraToday,
            builder: (_, __) => const FarmExtraTodayScreen(),
          ),
          GoRoute(
            path: '/farm/deliveries/:deliveryId/edit-review',
            builder: (_, state) => FarmDeliveryEditReviewScreen(
              deliveryId: state.pathParameters['deliveryId']!,
            ),
          ),
          GoRoute(
            path: '/farm/customers/:customerId/deliveries/:deliveryId',
            builder: (_, state) => FarmDeliveryEditReviewScreen(
              deliveryId: state.pathParameters['deliveryId']!,
            ),
          ),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
