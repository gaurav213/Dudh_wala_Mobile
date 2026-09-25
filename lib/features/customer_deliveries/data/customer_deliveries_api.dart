import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../delivery_staff/data/models/delivery_staff_models.dart';
import 'models/customer_review_model.dart';

const _uuid = Uuid();

/// Customer-facing reads/actions on their own deliveries. `/me/deliveries`
/// returns raw `MilkDelivery` rows (same shape delivery-staff endpoints use),
/// so [DeliveryModel] is reused here rather than duplicating a parser.
class CustomerDeliveriesApi {
  CustomerDeliveriesApi(this._api);

  final ApiClient _api;

  Object? _unwrap(Response<Map<String, dynamic>> res) {
    final body = res.data;
    if (body == null)
      throw const NetworkException('Empty response from server');
    return body.containsKey('data') ? body['data'] : body;
  }

  List<Map<String, dynamic>> _unwrapList(Response<Map<String, dynamic>> res) {
    final data = _unwrap(res);
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  /// `/me/deliveries` supports optional dateFrom / dateTo (YYYY-MM-DD).
  Future<List<DeliveryModel>> recentDeliveries({
    int limit = 60,
    String? dateFrom,
    String? dateTo,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/me/deliveries',
      query: {
        'page': 1,
        'limit': limit,
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
      },
    );
    return _unwrapList(res).map(DeliveryModel.fromJson).toList();
  }

  Future<List<DeliveryEventModel>> deliveryEvents(String id) async {
    final res = await _api.get<Map<String, dynamic>>('/deliveries/$id/events');
    return _unwrapList(res).map(DeliveryEventModel.fromJson).toList();
  }

  Future<void> confirm(String deliveryId, {String? notes}) =>
      _api.post<Map<String, dynamic>>(
        '/deliveries/$deliveryId/customer-confirm',
        data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
      );

  /// Customer tells the farm they don't want milk for this delivery (today).
  Future<void> skipToday(String deliveryId, {String? notes}) =>
      _api.post<Map<String, dynamic>>(
        '/deliveries/$deliveryId/customer-skip-today',
        data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
      );

  /// Skip milk for a calendar day (works even if farm list not generated yet).
  Future<Map<String, dynamic>> skipDay(String date, {String? notes}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/me/skip-day',
      data: {
        'date': date,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final data = _unwrap(res);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// Undo a customer “no milk” day — restores PENDING and notifies the farm.
  Future<Map<String, dynamic>> unskipDay(String date, {String? notes}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/me/unskip-day',
      data: {
        'date': date,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final data = _unwrap(res);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<void> markReceived(String deliveryId, {String? notes}) =>
      _api.post<Map<String, dynamic>>(
        '/deliveries/$deliveryId/customer-mark-received',
        data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
      );

  /// Reports a delivery problem. The backend records the same issue
  /// regardless of which of the two `customer-*` routes is hit, so this
  /// always calls `customer-not-received` and lets [issueType] describe the
  /// real problem (NOT_RECEIVED, WRONG_QUANTITY, WRONG_PRODUCT,
  /// QUALITY_ISSUE, OTHER).
  Future<void> reportIssue(
    String deliveryId, {
    required String issueType,
    String? description,
  }) =>
      _api.post<Map<String, dynamic>>(
        '/deliveries/$deliveryId/customer-not-received',
        data: {
          'issueType': issueType,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );

  Future<List<Map<String, dynamic>>> myExtraRequests() async {
    final res =
        await _api.get<Map<String, dynamic>>('/delivery-extra-requests/my');
    return _unwrapList(res);
  }

  Future<void> createExtraRequest({
    required String subscriptionId,
    required String deliveryDate,
    required String requestedQuantity,
    String? notes,
  }) =>
      _api.post<Map<String, dynamic>>(
        '/delivery-extra-requests',
        data: {
          'subscriptionId': subscriptionId,
          'deliveryDate': deliveryDate,
          'requestedQuantity': requestedQuantity,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

  Future<void> cancelExtraRequest(String id) =>
      _api.post<Map<String, dynamic>>('/delivery-extra-requests/$id/cancel');

  /// Authoritative backend summary (do not recompute on client).
  Future<Map<String, dynamic>> billingSummary() async {
    final res = await _api.get<Map<String, dynamic>>('/me/billing-summary');
    final data = _unwrap(res);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// Customer reports cash already given to staff, with a photo proof.
  Future<Map<String, dynamic>> claimCash({
    required String amount,
    required String proofPath,
    String? notes,
    String? farmId,
  }) async {
    final form = FormData.fromMap({
      'amount': amount,
      'clientReferenceId': _uuid.v4(),
      if (farmId != null && farmId.isNotEmpty) 'farmId': farmId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'proof': await MultipartFile.fromFile(
        proofPath,
        filename: proofPath.split(RegExp(r'[/\\]')).last,
      ),
    });
    try {
      final res = await _api.raw.post<Map<String, dynamic>>(
        '/me/payments/cash-claim',
        data: form,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
      final data = _unwrap(res);
      if (data is Map<String, dynamic>) return data;
      return {};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      var message = e.message ?? 'Network error';
      if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      }
      throw NetworkException(message, code: status?.toString(), cause: e);
    }
  }

  Future<List<Map<String, dynamic>>> myBills({int limit = 100}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/me/bills',
      query: {'page': 1, 'limit': limit},
    );
    return _unwrapList(res);
  }

  Future<List<CustomerReviewModel>> myReviews(String userId) async {
    final res =
        await _api.get<Map<String, dynamic>>('/customers/$userId/reviews');
    return _unwrapList(res).map(CustomerReviewModel.fromJson).toList();
  }
}
