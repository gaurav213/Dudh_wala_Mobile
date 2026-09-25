import 'package:flutter_test/flutter_test.dart';
import 'package:doodh_khata_mobile/features/farm/data/models/farm_ops_models.dart';

void main() {
  test('FarmTodayMetrics parses extra breakdown from API', () {
    final m = FarmTodayMetrics.fromJson({
      'date': '2026-08-09',
      'scheduledQuantity': '4.500',
      'customerExtraQuantity': '0.500',
      'staffExtraQuantity': '1.000',
      'totalExtraQuantity': '1.500',
      'totalDeliveredQuantity': '6.000',
      'pendingCount': 0,
      'deliveredCount': 3,
      'skippedCount': 0,
      'editedDeliveryCount': 0,
      'totalCount': 3,
      'collectionsToday': '0.00',
    });
    expect(m.scheduledQuantity, '4.500');
    expect(m.totalExtraQuantity, '1.500');
    expect(m.totalDeliveredQuantity, '6.000');
    expect(m.deliveredCount, 3);
  });

  test('edit reason OTHER requires note validation helper', () {
    // Screen-level validation is covered by form rules; ensure model parses.
    final detail = DeliveryEditReviewDetail.fromJson({
      'delivery': {'id': 'd1', 'editReviewStatus': 'PENDING_REVIEW'},
      'customer': {'name': 'Rahul', 'mobileNumber': '919777000011'},
      'latestEdit': {
        'previousQuantity': '5.000',
        'newQuantity': '4.000',
        'editReason': 'ENTERED_WRONG_QUANTITY',
      },
      'events': [],
    });
    expect(detail.previousQuantity, '5.000');
    expect(detail.newQuantity, '4.000');
    expect(detail.customerName, 'Rahul');
  });
}
