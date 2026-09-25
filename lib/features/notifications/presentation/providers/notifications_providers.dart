import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../data/models/notification_detail_models.dart';
import '../../data/models/notification_models.dart';
import '../../data/notifications_api.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(apiClientProvider));
});

final notificationsListProvider =
    FutureProvider.autoDispose<List<AppNotificationModel>>((ref) {
  return ref.watch(notificationsApiProvider).list();
});

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationsApiProvider).unreadCount();
});

final notificationDetailProvider =
    FutureProvider.autoDispose.family<NotificationDetailModel, String>(
  (ref, recipientId) {
    return ref.watch(notificationsApiProvider).detail(recipientId);
  },
);

void invalidateNotifications(WidgetRef ref) {
  ref.invalidate(notificationsListProvider);
  ref.invalidate(unreadNotificationCountProvider);
}
