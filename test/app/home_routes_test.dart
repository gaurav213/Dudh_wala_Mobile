import 'package:doodh_khata_mobile/app/navigation/home_routes.dart';
import 'package:doodh_khata_mobile/app/routes.dart';
import 'package:doodh_khata_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('homeRouteForRole', () {
    test('maps each role to its dashboard route', () {
      expect(homeRouteForRole(UserRole.customer), AppRoutes.customerDashboard);
      expect(homeRouteForRole(UserRole.farmOwner), AppRoutes.farmDashboard);
      expect(
        homeRouteForRole(UserRole.deliveryStaff),
        AppRoutes.login, // staff disabled via kDeliveryStaffEnabled
      );
      expect(homeRouteForRole(UserRole.platformOwner), AppRoutes.supplierHome);
    });
  });

  group('isHomeRoute', () {
    const home = AppRoutes.farmDashboard;

    test('matches exact home path', () {
      expect(isHomeRoute(home, home), isTrue);
    });

    test('ignores nested paths', () {
      expect(isHomeRoute('$home/c1', home), isFalse);
      expect(isHomeRoute('/farm/profile', home), isFalse);
    });
  });
}
