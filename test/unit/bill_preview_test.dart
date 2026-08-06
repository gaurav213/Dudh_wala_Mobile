import 'package:doodh_khata_mobile/features/billing/domain/bill_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BillPreview aggregates delivered litres and skips skipped rows', () {
    final preview = BillPreview.fromDeliveries(
      customerId: 'c1',
      periodStart: DateTime(2026, 8, 1),
      periodEnd: DateTime(2026, 8, 31),
      deliveries: [
        {
          'id': 'd1',
          'delivery_date': DateTime(2026, 8, 2),
          'slot': 'morning',
          'quantity_litres': 1.0,
          'rate_per_litre': 60.0,
          'amount': 60.0,
          'status': 'delivered',
        },
        {
          'id': 'd2',
          'delivery_date': DateTime(2026, 8, 3),
          'slot': 'morning',
          'quantity_litres': 1.0,
          'rate_per_litre': 60.0,
          'amount': 60.0,
          'status': 'skipped',
        },
        {
          'id': 'd3',
          'delivery_date': DateTime(2026, 8, 4),
          'slot': 'evening',
          'quantity_litres': 2.0,
          'rate_per_litre': 55.0,
          'amount': 110.0,
          'status': 'delivered',
        },
      ],
    );

    expect(preview.lines, hasLength(2));
    expect(preview.subtotal, 170);
    expect(preview.total, 170);
  });
}
