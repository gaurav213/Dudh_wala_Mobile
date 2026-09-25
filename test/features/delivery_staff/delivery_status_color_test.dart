import 'package:flutter_test/flutter_test.dart';

import 'package:doodh_khata_mobile/app/theme/app_theme.dart';
import 'package:doodh_khata_mobile/features/delivery_staff/data/models/delivery_staff_models.dart';
import 'package:doodh_khata_mobile/features/delivery_staff/presentation/widgets/delivery_tile.dart';

void main() {
  group('deliveryStatusColor', () {
    test('maps known statuses to the expected colors', () {
      expect(deliveryStatusColor('DELIVERED'), AppColors.success);
      expect(deliveryStatusColor('OUT_FOR_DELIVERY'), AppColors.teal);
      expect(deliveryStatusColor('SKIPPED'), AppColors.danger);
      expect(deliveryStatusColor('FAILED'), AppColors.danger);
      expect(deliveryStatusColor('DISPUTED'), AppColors.danger);
      expect(deliveryStatusColor('PENDING'), AppColors.warning);
      expect(deliveryStatusColor('SOMETHING_UNKNOWN'), AppColors.warning);
    });
  });

  group('DeliveryModel.fromJson', () {
    test('derives open/closed/delivered flags from status', () {
      final pending = DeliveryModel.fromJson({
        'id': '1',
        'customerId': 'c1',
        'subscriptionId': 's1',
        'deliveryDate': '2026-08-07',
        'status': 'PENDING',
      });
      expect(pending.isOpen, isTrue);
      expect(pending.isClosed, isFalse);
      expect(pending.isDelivered, isFalse);

      final delivered = DeliveryModel.fromJson({
        'id': '2',
        'customerId': 'c1',
        'subscriptionId': 's1',
        'deliveryDate': '2026-08-07',
        'status': 'DELIVERED',
      });
      expect(delivered.isOpen, isFalse);
      expect(delivered.isClosed, isTrue);
      expect(delivered.isDelivered, isTrue);
    });

    test(
        'sums scheduled + customer + staff extra when expectedQuantity is missing',
        () {
      final d = DeliveryModel.fromJson({
        'id': '1',
        'customerId': 'c1',
        'subscriptionId': 's1',
        'deliveryDate': '2026-08-07',
        'scheduledQuantity': '1.000',
        'customerExtraQuantity': '0.500',
        'staffExtraQuantity': '0.250',
      });
      expect(d.expectedQuantity, '1.75');
    });
  });
}
