import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../data/delivery_staff_api.dart';
import '../../data/models/delivery_staff_models.dart';

final deliveryStaffApiProvider = Provider<DeliveryStaffApi>((ref) {
  return DeliveryStaffApi(ref.watch(apiClientProvider));
});

final deliveryStaffDashboardProvider =
    FutureProvider.autoDispose<DeliveryStaffDashboard>((ref) {
  return ref.watch(deliveryStaffApiProvider).dashboard();
});

final deliveryStaffCustomersProvider =
    FutureProvider.autoDispose<List<StaffCustomerSummary>>((ref) {
  return ref.watch(deliveryStaffApiProvider).customers();
});

final deliveryStaffCustomerDetailProvider = FutureProvider.autoDispose
    .family<StaffCustomerDetail, String>((ref, customerId) {
  return ref.watch(deliveryStaffApiProvider).customerDetail(customerId);
});

/// Always loads the full today list; filtering/search/sort happen in the UI
/// so open stops can stay on top after a delivery is completed.
final todayDeliveriesProvider =
    FutureProvider.autoDispose<List<DeliveryModel>>((ref) {
  return ref.watch(deliveryStaffApiProvider).todayDeliveries();
});

final deliveryDetailProvider =
    FutureProvider.autoDispose.family<DeliveryModel, String>((ref, id) {
  return ref.watch(deliveryStaffApiProvider).deliveryDetail(id);
});

final deliveryEventsProvider = FutureProvider.autoDispose
    .family<List<DeliveryEventModel>, String>((ref, id) {
  return ref.watch(deliveryStaffApiProvider).deliveryEvents(id);
});

final assignedExtraRequestsProvider =
    FutureProvider.autoDispose<List<ExtraRequestModel>>((ref) {
  return ref.watch(deliveryStaffApiProvider).assignedExtraRequests();
});

final deliveryPendingCashProvider =
    FutureProvider.autoDispose<List<PaymentModel>>((ref) {
  return ref.watch(deliveryStaffApiProvider).pendingCash();
});

/// Recent deliveries (last 14 days) for the History screen.
final deliveryHistoryProvider =
    FutureProvider.autoDispose<List<DeliveryModel>>((ref) {
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 14));
  return ref.watch(deliveryStaffApiProvider).deliveriesInRange(
        dateFrom: localDateIso(from),
        dateTo: localDateIso(now),
        limit: 200,
      );
});

/// Invalidates every provider whose data is affected by a delivery/extra
/// mutation — dashboard counters, the today list, and the affected detail.
void invalidateDeliveryStaffData(WidgetRef ref, {String? deliveryId}) {
  ref.invalidate(deliveryStaffDashboardProvider);
  ref.invalidate(todayDeliveriesProvider);
  ref.invalidate(deliveryStaffCustomersProvider);
  ref.invalidate(deliveryPendingCashProvider);
  ref.invalidate(assignedExtraRequestsProvider);
  if (deliveryId != null) {
    ref.invalidate(deliveryDetailProvider(deliveryId));
    ref.invalidate(deliveryEventsProvider(deliveryId));
  }
}

/// Invalidate + wait so action buttons update before the user can tap again.
Future<void> refreshDeliveryStaffData(
  WidgetRef ref, {
  String? deliveryId,
}) async {
  invalidateDeliveryStaffData(ref, deliveryId: deliveryId);
  try {
    await Future.wait([
      ref.read(todayDeliveriesProvider.future),
      ref.read(deliveryStaffDashboardProvider.future),
      if (deliveryId != null)
        ref.read(deliveryDetailProvider(deliveryId).future),
    ]);
  } catch (_) {}
}
