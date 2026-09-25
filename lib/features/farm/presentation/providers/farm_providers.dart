import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/models/marketplace_models.dart';
import '../../data/farm_api.dart';
import '../../data/models/farm_models.dart';
import '../../data/models/farm_ops_models.dart';

final farmApiProvider = Provider<FarmApi>((ref) {
  return FarmApi(ref.watch(apiClientProvider));
});

String farmDashboardTodayIso() {
  final n = DateTime.now();
  final d = DateTime(n.year, n.month, n.day);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class FarmDashboardDateRange {
  const FarmDashboardDateRange({required this.from, required this.to});

  final String from;
  final String to;

  bool get isSingleDay => from == to;

  @override
  bool operator ==(Object other) =>
      other is FarmDashboardDateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Shared date range for Paisa + milk metrics on the farm dashboard.
final farmDashboardRangeProvider =
    StateProvider.autoDispose<FarmDashboardDateRange>((ref) {
  final t = farmDashboardTodayIso();
  return FarmDashboardDateRange(from: t, to: t);
});

/// The signed-in farm owner's dashboard — also the cheapest way to resolve
/// `farmId` for every other farm-scoped screen.
final farmDashboardProvider = FutureProvider.autoDispose<FarmDashboard>((ref) {
  final range = ref.watch(farmDashboardRangeProvider);
  return ref.watch(farmApiProvider).myDashboard(from: range.from, to: range.to);
});

final farmMediaProvider = FutureProvider.autoDispose
    .family<List<FarmImageItem>, String>((ref, farmId) {
  return ref.watch(farmApiProvider).listMedia(farmId);
});

final currentFarmIdProvider = FutureProvider.autoDispose<String>((ref) async {
  final dashboard = await ref.watch(farmDashboardProvider.future);
  return dashboard.farm.id;
});

final farmDetailProvider = FutureProvider.autoDispose<FarmModel>((ref) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).getFarm(farmId);
});

final farmServiceAreasProvider =
    FutureProvider.autoDispose<List<FarmServiceAreaModel>>((ref) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).listServiceAreas(farmId);
});

final farmProductsProvider =
    FutureProvider.autoDispose<List<FarmProductModel>>((ref) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).listProducts(farmId);
});

final farmStaffMembersProvider =
    FutureProvider.autoDispose<List<FarmMemberModel>>((ref) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).listStaffMembers(farmId);
});

final farmStaffInvitationsProvider =
    FutureProvider.autoDispose<List<FarmStaffInvitationModel>>((ref) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).listStaffInvitations(farmId);
});

/// Status filter for the requests screen; `null` means inbox (pending+accepted).
final farmRequestsStatusFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final farmServiceRequestsProvider =
    FutureProvider.autoDispose<List<ServiceRequestModel>>((ref) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  final status = ref.watch(farmRequestsStatusFilterProvider);
  return ref.watch(farmApiProvider).listServiceRequests(farmId, status: status);
});

final farmServiceRequestDetailProvider = FutureProvider.autoDispose
    .family<ServiceRequestModel, String>((ref, requestId) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).getServiceRequest(farmId, requestId);
});

final farmCustomerInvitationsProvider =
    FutureProvider.autoDispose<List<CustomerInvitationModel>>((ref) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).listCustomerInvitations(farmId);
});

final farmConnectedCustomersProvider =
    FutureProvider.autoDispose<List<ConnectedCustomerModel>>((ref) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).listConnectedCustomers(farmId);
});

/// Invalidates every provider whose data can be affected by a mutation on
/// the farm dashboard's counts (service areas, products, staff, requests,
/// invitations, customers all feed into it).
void invalidateFarmDashboard(WidgetRef ref) {
  ref.invalidate(farmDashboardProvider);
  ref.invalidate(farmTodayMetricsProvider);
}

Future<void> refreshFarmDashboard(WidgetRef ref) async {
  invalidateFarmDashboard(ref);
  try {
    await Future.wait([
      ref.read(farmDashboardProvider.future),
      ref.read(farmTodayMetricsProvider.future),
    ]);
  } catch (_) {}
}

final farmTodayMetricsProvider =
    FutureProvider.autoDispose<FarmTodayMetrics>((ref) {
  final range = ref.watch(farmDashboardRangeProvider);
  return ref.watch(farmApiProvider).farmTodayMetrics(
        from: range.from,
        to: range.to,
      );
});

final farmEditedTodayProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(farmApiProvider).editedDeliveriesToday();
});

final farmStaffDetailProvider = FutureProvider.autoDispose
    .family<StaffDetailModel, String>((ref, staffUserId) async {
  final farmId = await ref.watch(currentFarmIdProvider.future);
  return ref.watch(farmApiProvider).staffDetail(farmId, staffUserId);
});

final farmStaffTodayProvider = FutureProvider.autoDispose.family<
    ({List<StaffTodayDeliveryRow> deliveries, String totalExtra}),
    (String, String)>(
  (ref, args) async {
    final farmId = await ref.watch(currentFarmIdProvider.future);
    return ref
        .watch(farmApiProvider)
        .staffToday(farmId, args.$1, section: args.$2);
  },
);

final farmEditReviewProvider = FutureProvider.autoDispose
    .family<DeliveryEditReviewDetail, String>((ref, deliveryId) {
  return ref.watch(farmApiProvider).editReviewDetail(deliveryId);
});
