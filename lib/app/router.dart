import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/billing/presentation/screens/customer_bills_screen.dart';
import '../features/billing/presentation/screens/bill_details_screen.dart';
import '../features/billing/presentation/screens/bills_list_screen.dart';
import '../features/billing/presentation/screens/generate_bill_screen.dart';
import '../features/billing/presentation/screens/outstanding_screen.dart';
import '../features/calendar/presentation/screens/delivery_calendar_screen.dart';
import '../features/customers/presentation/screens/customer_details_screen.dart';
import '../features/customers/presentation/screens/customer_form_screen.dart';
import '../features/customers/presentation/screens/customers_list_screen.dart';
import '../features/dashboard/presentation/screens/customer_dashboard_screen.dart';
import '../features/dashboard/presentation/screens/supplier_dashboard_screen.dart';
import '../features/deliveries/presentation/screens/delivery_history_screen.dart';
import '../features/deliveries/presentation/screens/todays_deliveries_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/payments/presentation/screens/payment_history_screen.dart';
import '../features/payments/presentation/screens/record_payment_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/conflict_resolution_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/sync_status_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/subscriptions/presentation/screens/subscription_form_screen.dart';
import 'routes.dart';
import 'shell/customer_shell.dart';
import 'shell/supplier_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final initializing = !auth.initialized;
      final loggedIn = auth.isAuthenticated;
      final isPublic = loc == AppRoutes.splash ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword;

      if (initializing) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }
      if (!loggedIn && !isPublic) return AppRoutes.login;
      if (loggedIn &&
          (loc == AppRoutes.login ||
              loc == AppRoutes.register ||
              loc == AppRoutes.splash)) {
        return auth.user!.role == UserRole.customer
            ? AppRoutes.customerHome
            : AppRoutes.supplierHome;
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
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'sync',
                builder: (_, __) => const SyncStatusScreen(),
              ),
              GoRoute(
                path: 'conflicts',
                builder: (_, __) => const ConflictResolutionScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.customerHome,
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
            builder: (_, __) => const CustomerBillsScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerPayments,
            builder: (_, __) => const PaymentHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerProfile,
            builder: (_, __) => const ProfileScreen(),
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
