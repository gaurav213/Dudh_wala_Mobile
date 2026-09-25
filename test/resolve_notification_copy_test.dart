// ponytail: assert-based check — fails if legacy EN body → HI/MR resolve breaks
import 'package:flutter_test/flutter_test.dart';

import 'package:doodh_khata_mobile/features/notifications/presentation/utils/resolve_notification_copy.dart';

void main() {
  test('resolves legacy English notification without messageKey', () {
    final copy = resolveNotificationCopy(
      'mr',
      title: 'Wants milk again',
      body: 'Mahima Haral wants milk on 2026-09-07 again.',
      data: const {'type': 'GENERIC'},
    );
    expect(copy.title, 'पुन्हा दूध हवे');
    expect(copy.body, contains('Mahima Haral'));
    expect(copy.body, contains('2026-09-07'));
  });

  test('resolves by notification type when title unknown', () {
    final copy = resolveNotificationCopy(
      'hi',
      title: 'Something custom',
      body: 'Mahima Haral does not want milk on 2026-09-07.',
      data: const {'type': 'CUSTOMER_NO_MILK_TODAY'},
      type: 'CUSTOMER_NO_MILK_TODAY',
    );
    // type maps to notifCustomerNoMilk; body extract fills name/date
    expect(copy.title, 'एक दिन दूध नहीं');
    expect(copy.body, contains('Mahima Haral'));
  });
}
