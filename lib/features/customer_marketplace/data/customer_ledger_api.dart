import '../../../core/api/api_client.dart';
import '../../../core/utils/json_parsing.dart';

/// Customer-scoped ledger reads from `GET /me/*` (not the farm-owner SQLite ledger).
class CustomerLedgerApi {
  CustomerLedgerApi(this._api);

  final ApiClient _api;

  Future<List<Map<String, Object?>>> bills(
      {int page = 1, int limit = 50}) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/me/bills',
      query: {'page': page, 'limit': limit},
    );
    return _mapList(res.data, _mapBill);
  }

  Future<List<Map<String, Object?>>> payments({
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/me/payments',
      query: {'page': page, 'limit': limit},
    );
    return _mapList(res.data, _mapPayment);
  }

  Future<List<Map<String, Object?>>> deliveries({
    int page = 1,
    int limit = 50,
    String? dateFrom,
    String? dateTo,
  }) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/me/deliveries',
      query: {
        'page': page,
        'limit': limit,
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
      },
    );
    return _mapList(res.data, _mapDelivery);
  }

  List<Map<String, Object?>> _mapList(
    Map<String, dynamic>? body,
    Map<String, Object?> Function(Map<String, dynamic>) mapRow,
  ) {
    final root = body ?? const <String, dynamic>{};
    final raw = root['data'] ?? root;
    final list = raw is List
        ? raw
        : (raw is Map && raw['data'] is List)
            ? raw['data'] as List
            : const [];
    return list
        .whereType<Map>()
        .map((e) => mapRow(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, Object?> _mapBill(Map<String, dynamic> json) {
    final month = asStringOrNull(json['billingMonth']) ??
        asStringOrNull(json['billing_month']);
    return {
      'id': asStringOr(json['id']),
      'bill_number': asStringOr(
        json['billNumber'] ?? json['bill_number'],
        month ?? 'Bill',
      ),
      'period_start': month,
      'period_end': month,
      'total': asStringOr(
          json['totalAmount'] ?? json['total_amount'] ?? json['total'], '0'),
      'status': asStringOr(json['status'], '—'),
      'notes': asStringOrNull(json['notes']),
    };
  }

  Map<String, Object?> _mapPayment(Map<String, dynamic> json) {
    final paid = json['paymentDate'] ?? json['payment_date'] ?? json['paidAt'];
    return {
      'id': asStringOr(json['id']),
      'amount': asStringOr(json['amount'], '0'),
      'paid_at': paid is String ? DateTime.tryParse(paid) : paid,
      'method':
          asStringOr(json['paymentMethod'] ?? json['payment_method'], '—'),
      'status': asStringOr(json['status'], 'CONFIRMED'),
      'notes': asStringOrNull(json['notes']),
    };
  }

  Map<String, Object?> _mapDelivery(Map<String, dynamic> json) {
    final date = json['deliveryDate'] ?? json['delivery_date'];
    return {
      'id': asStringOr(json['id']),
      'delivery_date': date is String ? DateTime.tryParse(date) : date,
      'quantity_litres': asStringOr(json['quantity'], '0'),
      'amount': asStringOr(json['amount'], '0'),
      'status': asStringOr(json['status'], '—'),
      'customer_name': asStringOrNull(json['customerName']) ?? 'Your delivery',
      'notes': asStringOrNull(json['deliveryNotes'] ?? json['delivery_notes'] ?? json['notes']),
      'deliveryNotes': asStringOrNull(json['deliveryNotes'] ?? json['delivery_notes']),
    };
  }
}
