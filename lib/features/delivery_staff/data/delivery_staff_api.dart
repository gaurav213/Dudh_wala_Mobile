import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import 'models/delivery_staff_models.dart';

const _uuid = Uuid();

/// Dio-backed data source for the delivery-staff shell: dashboard, assigned
/// customers, today's run, per-delivery actions, extra-request review and
/// cash collection. Responses are wrapped by the backend as `{ data, meta }`.
class DeliveryStaffApi {
  DeliveryStaffApi(this._api);

  final ApiClient _api;

  Object? _unwrap(Response<Map<String, dynamic>> res) {
    final body = res.data;
    if (body == null) {
      throw const NetworkException('Empty response from server');
    }
    return body.containsKey('data') ? body['data'] : body;
  }

  List<Map<String, dynamic>> _unwrapList(Response<Map<String, dynamic>> res) {
    final data = _unwrap(res);
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  // ---------------------------------------------------------------------
  // Dashboard / customers
  // ---------------------------------------------------------------------

  Future<DeliveryStaffDashboard> dashboard() async {
    final res =
        await _api.get<Map<String, dynamic>>('/delivery-staff/dashboard');
    return DeliveryStaffDashboard.fromJson(
        _unwrap(res) as Map<String, dynamic>);
  }

  Future<List<StaffCustomerSummary>> customers() async {
    final res =
        await _api.get<Map<String, dynamic>>('/delivery-staff/customers');
    return _unwrapList(res).map(StaffCustomerSummary.fromJson).toList();
  }

  Future<StaffCustomerDetail> customerDetail(String customerId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/delivery-staff/customers/$customerId',
    );
    return StaffCustomerDetail.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<BillingSummaryModel> billingSummary(String customerId,
      {String? farmId}) async {
    final path = farmId != null
        ? '/farms/$farmId/customers/$customerId/billing-summary'
        : '/customers/$customerId/billing-summary';
    final res = await _api.get<Map<String, dynamic>>(path);
    return BillingSummaryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Today's deliveries & per-delivery ops
  // ---------------------------------------------------------------------

  Future<List<DeliveryModel>> todayDeliveries(
      {String? status, String? shift}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/deliveries/today',
      query: {
        if (status != null) 'status': status,
        if (shift != null) 'shift': shift,
      },
    );
    return _unwrapList(res).map(DeliveryModel.fromJson).toList();
  }

  Future<DeliveryRouteToday> routeToday({
    double? latitude,
    double? longitude,
    String? farmId,
    String? shift,
    bool includeCompleted = true,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/delivery-staff/route/today',
      query: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (farmId != null) 'farmId': farmId,
        if (shift != null) 'shift': shift,
        'includeCompleted': includeCompleted ? 'true' : 'false',
      },
    );
    return DeliveryRouteToday.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<void> updateAddressLocation({
    required String addressId,
    required double latitude,
    required double longitude,
    String? locationSource,
    double? accuracyMeters,
    bool markVerified = true,
  }) async {
    await _api.patch<Map<String, dynamic>>(
      '/customer-addresses/$addressId/location',
      data: {
        'latitude': latitude.toStringAsFixed(7),
        'longitude': longitude.toStringAsFixed(7),
        if (locationSource != null) 'locationSource': locationSource,
        if (accuracyMeters != null)
          'locationAccuracyMeters': accuracyMeters.toStringAsFixed(2),
        'markVerified': markVerified,
      },
    );
  }

  Future<void> confirmAddressLocation(String addressId) async {
    await _api.post<Map<String, dynamic>>(
        '/customer-addresses/$addressId/confirm-location');
  }

  Future<DeliveryModel> deliveryDetail(String id) async {
    final res = await _api.get<Map<String, dynamic>>('/deliveries/$id');
    return DeliveryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<List<DeliveryEventModel>> deliveryEvents(String id) async {
    final res = await _api.get<Map<String, dynamic>>('/deliveries/$id/events');
    return _unwrapList(res).map(DeliveryEventModel.fromJson).toList();
  }

  Future<List<DeliveryModel>> deliveriesInRange({
    String? dateFrom,
    String? dateTo,
    String? customerId,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/deliveries',
      query: {
        'page': page,
        'limit': limit,
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
        if (customerId != null) 'customerId': customerId,
        if (status != null) 'status': status,
      },
    );
    return _unwrapList(res).map(DeliveryModel.fromJson).toList();
  }

  Future<DeliveryModel> outForDelivery(String id) async {
    final res = await _api
        .post<Map<String, dynamic>>('/deliveries/$id/out-for-delivery');
    return DeliveryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<DeliveryModel> addExtra(String id,
      {required String extraQuantity, String? reason}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/deliveries/$id/add-extra',
      data: {
        'extraQuantity': extraQuantity,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return DeliveryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  /// Creates today's delivery when none is scheduled, then adds staff extra.
  Future<DeliveryModel> createAdHocExtra({
    required String subscriptionId,
    required String extraQuantity,
    String? reason,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/deliveries/ad-hoc-extra',
      data: {
        'subscriptionId': subscriptionId,
        'extraQuantity': extraQuantity,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return DeliveryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<DeliveryModel> cancel(String id, {String? notes}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/deliveries/$id/cancelled',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return DeliveryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<DeliveryModel> markDelivered(
    String id, {
    String? finalDeliveredQuantity,
    String? notes,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/deliveries/$id/delivered',
      data: {
        if (finalDeliveredQuantity != null)
          'finalDeliveredQuantity': finalDeliveredQuantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return DeliveryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<DeliveryModel> editDelivery(
    String id, {
    String? finalDeliveredQuantity,
    String? staffExtraQuantity,
    String? deliveryNotes,
    required String editReason,
    String? editNote,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/deliveries/$id/edit',
      data: {
        if (finalDeliveredQuantity != null)
          'finalDeliveredQuantity': finalDeliveredQuantity,
        if (staffExtraQuantity != null)
          'staffExtraQuantity': staffExtraQuantity,
        if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
        'editReason': editReason,
        if (editNote != null && editNote.isNotEmpty) 'editNote': editNote,
      },
    );
    final data = _unwrap(res);
    final delivery = data is Map && data['delivery'] is Map
        ? Map<String, dynamic>.from(data['delivery'] as Map)
        : Map<String, dynamic>.from(data as Map);
    return DeliveryModel.fromJson(delivery);
  }

  Future<DeliveryModel> skip(String id, {String? notes}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/deliveries/$id/skipped',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return DeliveryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<DeliveryModel> fail(String id, {String? notes}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/deliveries/$id/failed',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return DeliveryModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Extra requests (staff review)
  // ---------------------------------------------------------------------

  Future<List<ExtraRequestModel>> assignedExtraRequests() async {
    final res = await _api
        .get<Map<String, dynamic>>('/delivery-extra-requests/assigned');
    return _unwrapList(res).map(ExtraRequestModel.fromJson).toList();
  }

  Future<ExtraRequestModel> acceptExtraRequest(String id,
      {String? notes}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/delivery-extra-requests/$id/accept',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return ExtraRequestModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<ExtraRequestModel> rejectExtraRequest(String id,
      {String? notes}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/delivery-extra-requests/$id/reject',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return ExtraRequestModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Collections (cash)
  // ---------------------------------------------------------------------

  Future<PaymentModel> recordCashPayment({
    required String customerId,
    String? farmId,
    String? billId,
    required String amount,
    required String purpose,
    required String paymentDate,
    String? notes,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/payments/cash',
      data: {
        'customerId': customerId,
        if (farmId != null) 'farmId': farmId,
        if (billId != null) 'billId': billId,
        'amount': amount,
        'purpose': purpose,
        'paymentDate': paymentDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'clientReferenceId': _uuid.v4(),
      },
    );
    return PaymentModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<List<PaymentModel>> pendingCash() async {
    final res =
        await _api.get<Map<String, dynamic>>('/delivery-staff/pending-cash');
    return _unwrapList(res).map(PaymentModel.fromJson).toList();
  }

  Future<PaymentModel> confirmCash(String paymentId) async {
    final res =
        await _api.post<Map<String, dynamic>>('/payments/$paymentId/confirm');
    return PaymentModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<PaymentModel> rejectCash(String paymentId, {String? notes}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/payments/$paymentId/reject',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return PaymentModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Reviews (staff rating a customer)
  // ---------------------------------------------------------------------

  Future<Map<String, dynamic>> createReview({
    required String farmId,
    required String customerUserId,
    String? deliveryId,
    String? subscriptionId,
    required int rating,
    int? communicationRating,
    int? addressAccuracyRating,
    int? paymentReliabilityRating,
    String? comment,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/customer-reviews',
      data: {
        'farmId': farmId,
        'customerUserId': customerUserId,
        if (deliveryId != null) 'deliveryId': deliveryId,
        if (subscriptionId != null) 'subscriptionId': subscriptionId,
        'rating': rating,
        if (communicationRating != null)
          'communicationRating': communicationRating,
        if (addressAccuracyRating != null)
          'addressAccuracyRating': addressAccuracyRating,
        if (paymentReliabilityRating != null)
          'paymentReliabilityRating': paymentReliabilityRating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return (_unwrap(res) as Map<String, dynamic>?) ?? const {};
  }
}
