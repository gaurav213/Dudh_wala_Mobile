import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/marketplace_models.dart';
import 'models/customer_marketplace_models.dart';

/// Dio-backed data source for the customer-facing marketplace: saved
/// addresses, address-gated farm search, service requests and invitations.
/// Responses are wrapped by the backend as `{ data, meta }`.
class CustomerMarketplaceApi {
  CustomerMarketplaceApi(this._api);

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
  // Addresses
  // ---------------------------------------------------------------------

  Future<List<CustomerAddressModel>> listAddresses() async {
    final res = await _api.get<Map<String, dynamic>>('/customer-addresses');
    return _unwrapList(res).map(CustomerAddressModel.fromJson).toList();
  }

  Future<CustomerAddressModel> createAddress({
    required String label,
    required String addressLine1,
    String? addressLine2,
    required String area,
    required String city,
    required String state,
    required String postalCode,
    String? latitude,
    String? longitude,
    String? locationSource,
    String? locationAccuracyMeters,
    String? deliveryInstructions,
    bool isDefault = false,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/customer-addresses',
      data: {
        'label': label,
        'addressLine1': addressLine1,
        if (addressLine2 != null && addressLine2.isNotEmpty)
          'addressLine2': addressLine2,
        'area': area,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        if (latitude != null && latitude.isNotEmpty) 'latitude': latitude,
        if (longitude != null && longitude.isNotEmpty) 'longitude': longitude,
        if (locationSource != null) 'locationSource': locationSource,
        if (locationAccuracyMeters != null)
          'locationAccuracyMeters': locationAccuracyMeters,
        if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
          'deliveryInstructions': deliveryInstructions,
        'isDefault': isDefault,
      },
    );
    return CustomerAddressModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<CustomerAddressModel> updateAddressLocation({
    required String id,
    required String latitude,
    required String longitude,
    String locationSource = 'CUSTOMER_MAP_PIN',
    String? locationAccuracyMeters,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/customer-addresses/$id/location',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'locationSource': locationSource,
        if (locationAccuracyMeters != null)
          'locationAccuracyMeters': locationAccuracyMeters,
      },
    );
    return CustomerAddressModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<CustomerAddressModel> updateAddress(
      String id, Map<String, dynamic> fields) async {
    final res = await _api
        .patch<Map<String, dynamic>>('/customer-addresses/$id', data: fields);
    return CustomerAddressModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) =>
      _api.delete<void>('/customer-addresses/$id');

  Future<void> setDefaultAddress(String id) =>
      _api.post<void>('/customer-addresses/$id/set-default');

  // ---------------------------------------------------------------------
  // Search & discovery
  // ---------------------------------------------------------------------

  Future<FarmSearchResponse> searchFarms({
    String? addressId,
    String? postalCode,
    String? area,
    String? city,
    String? milkType,
    String? deliveryShift,
    bool includeDiagnostics = false,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/farms/search',
      query: {
        if (addressId != null) 'addressId': addressId,
        if (postalCode != null && postalCode.isNotEmpty)
          'postalCode': postalCode,
        if (area != null && area.isNotEmpty) 'area': area,
        if (city != null && city.isNotEmpty) 'city': city,
        if (milkType != null) 'milkType': milkType,
        if (deliveryShift != null) 'deliveryShift': deliveryShift,
        if (includeDiagnostics) 'includeDiagnostics': true,
        'page': page,
        'limit': limit,
      },
    );
    final body = res.data;
    if (body == null)
      throw const NetworkException('Empty response from server');
    final data = (body['data'] as List?) ?? const [];
    final meta = (body['meta'] as Map<String, dynamic>?) ?? const {};
    final diagnostics = meta['diagnostics'] as Map<String, dynamic>?;
    final reasons = diagnostics == null
        ? null
        : ((diagnostics['reasons'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(FarmSearchDiagnosticReason.fromJson)
            .toList();
    return FarmSearchResponse(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(FarmSearchResultModel.fromJson)
          .toList(),
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      diagnosticReasons: reasons,
    );
  }

  Future<FarmPublicDetailModel> publicFarm(String farmId) async {
    final res = await _api.get<Map<String, dynamic>>('/farms/$farmId/public');
    return FarmPublicDetailModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Service requests
  // ---------------------------------------------------------------------

  Future<ServiceRequestModel> createServiceRequest({
    required String farmId,
    required String addressId,
    required String productId,
    required String quantity,
    required String deliveryShift,
    required String preferredStartDate,
    String scheduleType = 'EVERY_DAY',
    String? deliveryInstructions,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/service-requests',
      data: {
        'farmId': farmId,
        'addressId': addressId,
        'productId': productId,
        'quantity': quantity,
        'deliveryShift': deliveryShift,
        'scheduleType': scheduleType,
        'preferredStartDate': preferredStartDate,
        if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
          'deliveryInstructions': deliveryInstructions,
      },
    );
    return ServiceRequestModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<List<ServiceRequestModel>> myServiceRequests({
    String? status,
    String? farmId,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/service-requests/my',
      query: {
        if (status != null) 'status': status,
        if (farmId != null) 'farmId': farmId,
      },
    );
    return _unwrapList(res).map(ServiceRequestModel.fromJson).toList();
  }

  Future<ServiceRequestModel> getServiceRequest(String id) async {
    final res = await _api.get<Map<String, dynamic>>('/service-requests/$id');
    return ServiceRequestModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<ServiceRequestModel> updateServiceRequest(
    String id, {
    String? quantity,
    String? deliveryShift,
    String? scheduleType,
    String? preferredStartDate,
    String? deliveryInstructions,
    String? addressId,
  }) async {
    final res = await _api.patch<Map<String, dynamic>>(
      '/service-requests/$id',
      data: {
        if (quantity != null) 'quantity': quantity,
        if (deliveryShift != null) 'deliveryShift': deliveryShift,
        if (scheduleType != null) 'scheduleType': scheduleType,
        if (preferredStartDate != null) 'preferredStartDate': preferredStartDate,
        if (deliveryInstructions != null)
          'deliveryInstructions': deliveryInstructions,
        if (addressId != null) 'addressId': addressId,
      },
    );
    return ServiceRequestModel.fromJson(_unwrap(res) as Map<String, dynamic>);
  }

  Future<void> cancelServiceRequest(String id) =>
      _api.post<void>('/service-requests/$id/cancel');

  Future<void> submitFarmReview({
    required String farmId,
    required int rating,
    String? comment,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/farms/$farmId/reviews',
      data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
  }

  // ---------------------------------------------------------------------
  // Invitations (farm-initiated, customer accepts/rejects)
  // ---------------------------------------------------------------------

  Future<List<CustomerInvitationModel>> myInvitations() async {
    final res =
        await _api.get<Map<String, dynamic>>('/customer-invitations/my');
    return _unwrapList(res).map(CustomerInvitationModel.fromJson).toList();
  }

  Future<void> acceptInvitation(String id) =>
      _api.post<void>('/customer-invitations/$id/accept');

  Future<void> rejectInvitation(String id) =>
      _api.post<void>('/customer-invitations/$id/reject');
}
