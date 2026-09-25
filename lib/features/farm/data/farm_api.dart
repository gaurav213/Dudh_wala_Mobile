import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/marketplace_models.dart';
import '../../../core/utils/json_parsing.dart';
import 'models/farm_models.dart';
import 'models/farm_ops_models.dart';

const _uuid = Uuid();

/// Dio-backed data source for the farm-owner marketplace management
/// screens. Every response is wrapped by the backend's TransformInterceptor
/// as `{ data, meta }`; [_unwrap]/[_unwrapList] strip that envelope.
class FarmApi {
  FarmApi(this._api);

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
    if (data is! List) return const [];
    // Dio JSON maps are not always typed as Map<String, dynamic>.
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Farm profile
  // ---------------------------------------------------------------------

  Future<List<FarmModel>> myFarms() async {
    final res = await _api.get<Map<String, dynamic>>('/farms/my');
    return _unwrapList(res).map(FarmModel.fromJson).toList();
  }

  Future<FarmDashboard> myDashboard({
    String? date,
    String? from,
    String? to,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/my/dashboard',
      query: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (date != null && from == null && to == null) 'date': date,
      },
    );
    return FarmDashboard.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<FarmModel> getFarm(String farmId) async {
    final res = await _api.get<Map<String, dynamic>>('/farms/$farmId');
    return FarmModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<FarmModel> updateFarm(
      String farmId, Map<String, dynamic> fields) async {
    final res =
        await _api.patch<Map<String, dynamic>>('/farms/$farmId', data: fields);
    return FarmModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<List<FarmImageItem>> listMedia(String farmId) async {
    final res = await _api.get<Map<String, dynamic>>('/farms/$farmId/media');
    return _unwrapList(res).map(FarmImageItem.fromJson).toList();
  }

  Future<FarmImageItem> uploadMedia(String farmId, String filePath) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/media',
      data: form,
    );
    return FarmImageItem.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<void> deleteMedia(String farmId, String mediaId) =>
      _api.delete<void>('/farms/$farmId/media/$mediaId');

  // ---------------------------------------------------------------------
  // Service areas
  // ---------------------------------------------------------------------

  Future<List<FarmServiceAreaModel>> listServiceAreas(String farmId) async {
    final res =
        await _api.get<Map<String, dynamic>>('/farms/$farmId/service-areas');
    return _unwrapList(res).map(FarmServiceAreaModel.fromJson).toList();
  }

  Future<FarmServiceAreaModel> createServiceArea(
    String farmId, {
    required String areaName,
    required String city,
    required String state,
    String? postalCode,
    String? serviceRadiusKm,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/service-areas',
      data: {
        'areaName': areaName,
        'city': city,
        'state': state,
        if (postalCode != null && postalCode.isNotEmpty)
          'postalCode': postalCode,
        if (serviceRadiusKm != null && serviceRadiusKm.isNotEmpty)
          'serviceRadiusKm': serviceRadiusKm,
      },
    );
    return FarmServiceAreaModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<void> deleteServiceArea(String farmId, String id) =>
      _api.delete<void>('/farms/$farmId/service-areas/$id');

  Future<void> setServiceAreaActive(String farmId, String id, bool active) =>
      _api.post<void>(
        '/farms/$farmId/service-areas/$id/${active ? 'activate' : 'deactivate'}',
      );

  // ---------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------

  Future<List<FarmProductModel>> listProducts(String farmId) async {
    final res = await _api.get<Map<String, dynamic>>('/farms/$farmId/products');
    return _unwrapList(res).map(FarmProductModel.fromJson).toList();
  }

  Future<FarmProductModel> createProduct(
    String farmId, {
    required String name,
    required String milkType,
    String? description,
    required String currentRatePerLitre,
    required String minimumQuantity,
    String? maximumQuantity,
    required List<String> availableShifts,
    bool isAvailable = true,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/products',
      data: {
        'name': name,
        'milkType': milkType,
        if (description != null && description.isNotEmpty)
          'description': description,
        'currentRatePerLitre': currentRatePerLitre,
        'minimumQuantity': minimumQuantity,
        if (maximumQuantity != null && maximumQuantity.isNotEmpty)
          'maximumQuantity': maximumQuantity,
        'availableShifts': availableShifts,
        'isAvailable': isAvailable,
      },
    );
    return FarmProductModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String farmId, String id) =>
      _api.delete<void>('/farms/$farmId/products/$id');

  Future<void> setProductActive(String farmId, String id, bool active) =>
      _api.post<void>(
        '/farms/$farmId/products/$id/${active ? 'activate' : 'deactivate'}',
      );

  Future<FarmProductModel> changeRate(
    String farmId,
    String id, {
    required String ratePerLitre,
    String? effectiveFrom,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/products/$id/change-rate',
      data: {
        'ratePerLitre': ratePerLitre,
        if (effectiveFrom != null) 'effectiveFrom': effectiveFrom,
      },
    );
    final raw = _unwrap(res);
    final map = raw is Map<String, dynamic>
        ? (raw['product'] is Map
            ? Map<String, dynamic>.from(raw['product'] as Map)
            : Map<String, dynamic>.from(raw))
        : <String, dynamic>{};
    return FarmProductModel.fromJson(map);
  }

  // ---------------------------------------------------------------------
  // Staff
  // ---------------------------------------------------------------------

  Future<List<FarmMemberModel>> listStaffMembers(String farmId) async {
    final res =
        await _api.get<Map<String, dynamic>>('/farms/$farmId/staff/members');
    return _unwrapList(res).map(FarmMemberModel.fromJson).toList();
  }

  Future<List<FarmStaffInvitationModel>> listStaffInvitations(
      String farmId) async {
    final res = await _api
        .get<Map<String, dynamic>>('/farms/$farmId/staff/invitations');
    return _unwrapList(res).map(FarmStaffInvitationModel.fromJson).toList();
  }

  Future<FarmStaffInvitationModel> inviteStaff(
    String farmId, {
    required String mobileNumber,
    String? name,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/staff/invitations',
      data: {
        'mobileNumber': mobileNumber,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    return FarmStaffInvitationModel.fromJson(
        _unwrap(res) as Map<String, dynamic>);
  }

  Future<void> resendStaffInvitation(String farmId, String id) =>
      _api.post<void>('/farms/$farmId/staff/invitations/$id/resend');

  Future<void> cancelStaffInvitation(String farmId, String id) =>
      _api.post<void>('/farms/$farmId/staff/invitations/$id/cancel');

  Future<void> setMemberStatus(
    String farmId,
    String memberId,
    String action, {
    bool force = false,
  }) =>
      _api.post<void>(
        '/farms/$farmId/staff/members/$memberId/$action${force ? '?force=true' : ''}',
      );

  Future<FarmTodayMetrics> farmTodayMetrics({
    String? farmId,
    String? date,
    String? from,
    String? to,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/dashboard/farm/today',
      query: {
        if (farmId != null) 'farmId': farmId,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (date != null && from == null && to == null) 'date': date,
      },
    );
    return FarmTodayMetrics.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<StaffDetailModel> staffDetail(
      String farmId, String staffUserId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/$farmId/staff/$staffUserId',
    );
    return StaffDetailModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<({List<StaffTodayDeliveryRow> deliveries, String totalExtra})>
      staffToday(
    String farmId,
    String staffUserId, {
    String section = 'all',
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/$farmId/staff/$staffUserId/today',
      query: {'section': section},
    );
    final data = _unwrap(res) as Map<String, dynamic>;
    final list = (data['deliveries'] as List? ?? const [])
        .whereType<Map>()
        .map(
            (e) => StaffTodayDeliveryRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (
      deliveries: list,
      totalExtra: asStringOr(data['totalExtraDelivered'], '0'),
    );
  }

  Future<Map<String, dynamic>> staffEditedDeliveries(
    String farmId,
    String staffUserId,
  ) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/$farmId/staff/$staffUserId/edited-deliveries',
    );
    return Map<String, dynamic>.from(_unwrap(res) as Map);
  }

  Future<List<Map<String, dynamic>>> editedDeliveriesToday() async {
    final res =
        await _api.get<Map<String, dynamic>>('/deliveries/edited-today');
    return _unwrapList(res);
  }

  Future<DeliveryEditReviewDetail> editReviewDetail(String deliveryId) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/deliveries/$deliveryId/edit-review',
    );
    return DeliveryEditReviewDetail.fromJson(
        _unwrap(res) as Map<String, dynamic>);
  }

  Future<void> confirmEditReview(String deliveryId, {String? notes}) =>
      _api.post<void>(
        '/deliveries/$deliveryId/edit-review/confirm',
        data: {if (notes != null) 'notes': notes},
      );

  Future<void> flagEditReview(String deliveryId, {String? notes}) =>
      _api.post<void>(
        '/deliveries/$deliveryId/edit-review/flag',
        data: {if (notes != null) 'notes': notes},
      );

  // ---------------------------------------------------------------------
  // Service requests (customer-initiated, farm owner accepts/rejects)
  // ---------------------------------------------------------------------

  Future<List<ServiceRequestModel>> listServiceRequests(
    String farmId, {
    String? status,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/$farmId/service-requests',
      query: {if (status != null) 'status': status},
    );
    return _unwrapList(res).map(ServiceRequestModel.fromJson).toList();
  }

  Future<ServiceRequestModel> getServiceRequest(String farmId, String id) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/$farmId/service-requests/$id',
    );
    return ServiceRequestModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<void> acceptServiceRequest(
    String farmId,
    String id, {
    String? assignedMemberUserId,
  }) =>
      _api.post<void>(
        '/farms/$farmId/service-requests/$id/accept',
        data: {
          if (assignedMemberUserId != null)
            'assignedMemberUserId': assignedMemberUserId,
        },
      );

  Future<void> rejectServiceRequest(
    String farmId,
    String id, {
    String? rejectionReason,
  }) =>
      _api.post<void>(
        '/farms/$farmId/service-requests/$id/reject',
        data: {
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            'rejectionReason': rejectionReason,
        },
      );

  Future<void> cancelServiceRequest(String farmId, String id) =>
      _api.post<void>('/farms/$farmId/service-requests/$id/cancel');


  // ---------------------------------------------------------------------
  // Customer invitations (farm-initiated)
  // ---------------------------------------------------------------------

  Future<List<CustomerInvitationModel>> listCustomerInvitations(
    String farmId, {
    String? status,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/$farmId/customer-invitations',
      query: {if (status != null) 'status': status},
    );
    return _unwrapList(res).map(CustomerInvitationModel.fromJson).toList();
  }

  Future<CustomerInvitationModel> createCustomerInvitation(
    String farmId, {
    required String mobileNumber,
    String? customerName,
    required String productId,
    required String quantity,
    required String deliveryShift,
    required String proposedRate,
    required String preferredStartDate,
    String? deliveryInstructions,
    int? expiresInDays,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/customer-invitations',
      data: {
        'mobileNumber': mobileNumber,
        if (customerName != null && customerName.isNotEmpty)
          'customerName': customerName,
        'productId': productId,
        'quantity': quantity,
        'deliveryShift': deliveryShift,
        'proposedRate': proposedRate,
        'preferredStartDate': preferredStartDate,
        if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
          'deliveryInstructions': deliveryInstructions,
        if (expiresInDays != null) 'expiresInDays': expiresInDays,
      },
    );
    return CustomerInvitationModel.fromJson(
        _unwrap(res) as Map<String, dynamic>);
  }

  Future<void> cancelCustomerInvitation(String farmId, String id) =>
      _api.post<void>('/farms/$farmId/customer-invitations/$id/cancel');

  // ---------------------------------------------------------------------
  // Connected customers
  // ---------------------------------------------------------------------

  Future<List<ConnectedCustomerModel>> listConnectedCustomers(
    String farmId, {
    String? status,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/$farmId/customers',
      query: {if (status != null) 'status': status},
    );
    // Paginated: { data: [...], meta }
    final body = res.data;
    final raw = body?['data'];
    final list = raw is List
        ? raw
        : raw is Map && raw['data'] is List
            ? raw['data'] as List
            : _unwrapList(res);
    return list
        .whereType<Map>()
        .map((e) =>
            ConnectedCustomerModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Farm-managed customer (no app account) + active subscription.
  Future<Map<String, dynamic>> createManagedCustomer(
    String farmId, {
    required String name,
    String? mobileNumber,
    String? address,
    String? notes,
    required String milkType,
    required String quantity,
    required String ratePerLitre,
    required String deliveryShift,
    required String startDate,
    String? scheduleType,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/customers/managed',
      data: {
        'name': name,
        if (mobileNumber != null && mobileNumber.isNotEmpty)
          'mobileNumber': mobileNumber,
        if (address != null && address.isNotEmpty) 'address': address,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'milkType': milkType,
        'quantity': quantity,
        'ratePerLitre': ratePerLitre,
        'deliveryShift': deliveryShift,
        'startDate': startDate,
        if (scheduleType != null) 'scheduleType': scheduleType,
      },
    );
    return Map<String, dynamic>.from(_unwrap(res) as Map);
  }

  // ---------------------------------------------------------------------
  // Farm delivery ops (today list + assign staff)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> todayDeliveries({
    String? date,
    String? from,
    String? to,
    String? status,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/deliveries/today',
      query: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (date != null && from == null && to == null) 'date': date,
        if (status != null) 'status': status,
      },
    );
    return _unwrapList(res);
  }

  Future<Map<String, dynamic>> recordCashPayment({
    required String customerId,
    String? farmId,
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
        'amount': amount,
        'purpose': purpose,
        'paymentDate': paymentDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'clientReferenceId': _uuid.v4(),
      },
    );
    return Map<String, dynamic>.from(_unwrap(res) as Map);
  }

  /// Create or refresh this month’s bill from delivered milk till today.
  Future<Map<String, dynamic>> generateMonthBill({
    required String customerId,
    required String billingMonth,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/bills/generate',
      data: {
        'customerId': customerId,
        'billingMonth': billingMonth,
      },
    );
    return Map<String, dynamic>.from(_unwrap(res) as Map);
  }

  Future<Map<String, dynamic>> generateDailyList(
    String farmId, {
    required String date,
    String? deliveryShift,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/deliveries/generate-daily-list',
      data: {
        'date': date,
        if (deliveryShift != null) 'deliveryShift': deliveryShift,
      },
    );
    return Map<String, dynamic>.from(_unwrap(res) as Map);
  }

  Future<Map<String, dynamic>> dailyListStatus(String farmId,
      {String? date}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/$farmId/deliveries/daily-list-status',
      query: {if (date != null) 'date': date},
    );
    return Map<String, dynamic>.from(_unwrap(res) as Map);
  }

  Future<Map<String, dynamic>> updateDeliverySettings(
    String farmId, {
    bool? autoGenerateDailyList,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/farms/$farmId/delivery-settings',
      data: {
        if (autoGenerateDailyList != null)
          'autoGenerateDailyList': autoGenerateDailyList,
      },
    );
    return Map<String, dynamic>.from(_unwrap(res) as Map);
  }

  Future<void> outForDelivery(String deliveryId) =>
      _api.post<void>('/deliveries/$deliveryId/out-for-delivery');

  Future<void> markDelivered(String deliveryId,
          {String? finalDeliveredQuantity}) =>
      _api.post<void>(
        '/deliveries/$deliveryId/delivered',
        data: {
          if (finalDeliveredQuantity != null)
            'finalDeliveredQuantity': finalDeliveredQuantity,
        },
      );

  Future<Map<String, dynamic>> addExtra(
    String deliveryId, {
    required String extraQuantity,
    String? reason,
    bool replace = false,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/deliveries/$deliveryId/add-extra',
      data: {
        'extraQuantity': extraQuantity,
        if (replace) 'replace': true,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return Map<String, dynamic>.from(_unwrap(res) as Map);
  }

  Future<void> skipDelivery(String deliveryId, {String? notes}) =>
      _api.post<void>(
        '/deliveries/$deliveryId/skipped',
        data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
      );

  /// Farm cannot deliver today — one customer (`customerId`) or all open stops.
  Future<Map<String, dynamic>> skipTodayDeliveries(
    String farmId, {
    String? customerId,
    String? date,
    String? notes,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/deliveries/skip-today',
      data: {
        if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
        if (date != null && date.isNotEmpty) 'date': date,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final data = _unwrap(res);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<void> failDelivery(String deliveryId) =>
      _api.post<void>('/deliveries/$deliveryId/failed');

  Future<void> assignDeliveryPerson(
    String subscriptionId, {
    String? assignedDeliveryUserId,
  }) =>
      _api.post<void>(
        '/subscriptions/$subscriptionId/assign-delivery',
        data: {'assignedDeliveryUserId': assignedDeliveryUserId},
      );
}
