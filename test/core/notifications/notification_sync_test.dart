import 'package:flutter_test/flutter_test.dart';

import 'package:doodh_khata_mobile/core/notifications/notification_sync.dart';
import 'package:doodh_khata_mobile/features/notifications/data/models/notification_models.dart';

void main() {
  test('unreadNotYetSeen skips read and already-seen ids', () {
    final items = [
      AppNotificationModel(
        recipientId: 'a',
        readAt: null,
        type: 'X',
        title: 't',
        body: 'b',
        route: '/farm/requests',
        data: const {},
        createdAt: null,
      ),
      AppNotificationModel(
        recipientId: 'b',
        readAt: DateTime(2026),
        type: 'X',
        title: 't',
        body: 'b',
        route: null,
        data: const {},
        createdAt: null,
      ),
      AppNotificationModel(
        recipientId: 'c',
        readAt: null,
        type: 'X',
        title: 't',
        body: 'b',
        route: null,
        data: const {},
        createdAt: null,
      ),
    ];
    final fresh = unreadNotYetSeen(items, {'a'});
    expect(fresh.map((n) => n.recipientId), ['c']);
  });

  test('routeFromPayload upgrades list routes with requestId', () {
    expect(
      routeFromPayload(
        '{"route":"/farm/requests","requestId":"abc","type":"MILK_REQUEST"}',
      ),
      '/farm/requests/abc',
    );
    expect(
      routeFromPayload(
        '{"route":"/customer/requests","requestId":"xyz","type":"MILK_REQUEST_ACCEPTED"}',
      ),
      '/customer/requests?focus=xyz',
    );
  });
}
