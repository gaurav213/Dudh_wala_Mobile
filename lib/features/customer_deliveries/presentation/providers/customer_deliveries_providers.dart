import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../delivery_staff/data/models/delivery_staff_models.dart';
import '../../data/customer_deliveries_api.dart';
import '../../data/models/customer_review_model.dart';

final customerDeliveriesApiProvider = Provider<CustomerDeliveriesApi>((ref) {
  return CustomerDeliveriesApi(ref.watch(apiClientProvider));
});

final customerRecentDeliveriesProvider =
    FutureProvider.autoDispose<List<DeliveryModel>>((ref) {
  return ref.watch(customerDeliveriesApiProvider).recentDeliveries();
});

/// Today's delivery(s) — server-filtered by date (not “load everything then filter”).
final customerTodaysDeliveriesProvider =
    FutureProvider.autoDispose<List<DeliveryModel>>((ref) async {
  final today = localDateIso();
  return ref.watch(customerDeliveriesApiProvider).recentDeliveries(
        dateFrom: today,
        dateTo: today,
        limit: 20,
      );
});

final customerDeliveryEventsProvider = FutureProvider.autoDispose
    .family<List<DeliveryEventModel>, String>((ref, id) {
  return ref.watch(customerDeliveriesApiProvider).deliveryEvents(id);
});

final customerMyExtraRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(customerDeliveriesApiProvider).myExtraRequests();
});

final customerBillsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(customerDeliveriesApiProvider).myBills();
});

final customerBillTillTodayProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(customerDeliveriesApiProvider).billingSummary();
});

final customerMyReviewsProvider =
    FutureProvider.autoDispose<List<CustomerReviewModel>>((ref) async {
  final userId = ref.watch(authControllerProvider).user?.id;
  if (userId == null) return const [];
  return ref.watch(customerDeliveriesApiProvider).myReviews(userId);
});

void invalidateCustomerDeliveryData(WidgetRef ref, {String? deliveryId}) {
  ref.invalidate(customerRecentDeliveriesProvider);
  ref.invalidate(customerTodaysDeliveriesProvider);
  if (deliveryId != null) {
    ref.invalidate(customerDeliveryEventsProvider(deliveryId));
  }
}

/// Invalidate and wait for today's list so buttons disappear immediately.
Future<void> refreshCustomerDeliveryData(
  WidgetRef ref, {
  String? deliveryId,
}) async {
  invalidateCustomerDeliveryData(ref, deliveryId: deliveryId);
  await ref.read(customerTodaysDeliveriesProvider.future);
}
