import 'package:flutter_test/flutter_test.dart';

import 'package:doodh_khata_mobile/app/routes.dart';

void main() {
  group('AppRoutes delivery-staff paths', () {
    test('static paths use the /delivery prefix', () {
      expect(AppRoutes.deliveryDashboard, '/delivery/dashboard');
      expect(AppRoutes.deliveryCustomers, '/delivery/customers');
      expect(AppRoutes.deliveryToday, '/delivery/today');
      expect(AppRoutes.deliveryRunMode, '/delivery/today/run');
      expect(AppRoutes.deliveryExtraRequests, '/delivery/extra-requests');
      expect(AppRoutes.deliveryCollections, '/delivery/collections');
      expect(AppRoutes.deliveryPendingCash, '/delivery/pending-cash');
      expect(AppRoutes.deliveryStaffHistory, '/delivery/history');
      expect(AppRoutes.deliveryReviews, '/delivery/reviews');
      expect(AppRoutes.deliveryNotifications, '/delivery/notifications');
      expect(AppRoutes.deliveryProfile, '/delivery/profile');
    });

    test('deliveryCustomerDetail interpolates the customer id', () {
      expect(AppRoutes.deliveryCustomerDetail('abc-123'),
          '/delivery/customers/abc-123');
    });

    test('deliveryDeliveryDetail interpolates the delivery id', () {
      expect(AppRoutes.deliveryDeliveryDetail('xyz-789'),
          '/delivery/deliveries/xyz-789');
    });

    test('deliveryDeliveryEdit interpolates the delivery id', () {
      expect(AppRoutes.deliveryDeliveryEdit('xyz-789'),
          '/delivery/deliveries/xyz-789/edit');
    });
  });

  group('AppRoutes farm staff / edit-review paths', () {
    test('staff detail paths', () {
      expect(AppRoutes.farmStaffDetail('u1'), '/farm/staff/u1');
      expect(AppRoutes.farmStaffToday('u1'), '/farm/staff/u1/today');
      expect(AppRoutes.farmStaffEdited('u1'), '/farm/staff/u1/edited');
      expect(AppRoutes.farmStaffSettings('u1'), '/farm/staff/u1/settings');
    });

    test('edited and edit-review paths', () {
      expect(AppRoutes.farmDeliveriesEdited, '/farm/deliveries/edited');
      expect(
        AppRoutes.farmDeliveryEditReview('d1'),
        '/farm/deliveries/d1/edit-review',
      );
      expect(
        AppRoutes.farmCustomerDelivery('c1', 'd1'),
        '/farm/customers/c1/deliveries/d1',
      );
      expect(AppRoutes.farmTodayCustomer('c1'), '/farm/today/c1');
      expect(
        AppRoutes.farmTodayCustomer('c1', date: '2026-09-07'),
        '/farm/today/c1?date=2026-09-07',
      );
    });
  });

  group('AppRoutes customer delivery paths', () {
    test('static paths use the /customer prefix', () {
      expect(AppRoutes.customerExtraRequest, '/customer/extra-request');
      expect(AppRoutes.customerBilling, '/customer/billing');
      expect(AppRoutes.customerReviewsReceived, '/customer/reviews/received');
      expect(AppRoutes.customerNotifications, '/customer/notifications');
    });

    test('customerDeliveryDetail interpolates the delivery id', () {
      expect(
          AppRoutes.customerDeliveryDetail('d-1'), '/customer/deliveries/d-1');
    });
  });
}
