import 'package:flutter_test/flutter_test.dart';

void main() {
  group('billing summary parsing', () {
    test('reads billTillToday from backend summary map', () {
      final summary = {
        'todaysAmount': '180.00',
        'monthDeliveredDays': 7,
        'monthTotalQuantity': '12.500',
        'billTillToday': '450.00',
        'outstandingBalance': '450.00',
      };
      final amount = num.tryParse('${summary['billTillToday']}') ?? 0;
      expect(amount, 450);
    });
  });
}
