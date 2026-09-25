import '../../features/auth/domain/entities/user_entity.dart';
import '../../core/feature_flags.dart';
import '../routes.dart';

/// Role home used for bottom-nav shells and Android back-to-dashboard.
String homeRouteForRole(UserRole role) {
  return switch (role) {
    UserRole.customer => AppRoutes.customerDashboard,
    UserRole.farmOwner => AppRoutes.farmDashboard,
    // TEMP: delivery-staff disabled — restore next update
    UserRole.deliveryStaff =>
        kDeliveryStaffEnabled ? AppRoutes.deliveryDashboard : AppRoutes.login,
    UserRole.platformOwner => AppRoutes.supplierHome,
  };
}

bool isHomeRoute(String location, String homeRoute) {
  final path = Uri.tryParse(location)?.path ?? location;
  return path == homeRoute;
}
