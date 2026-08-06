import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';

class PaymentRepository {
  PaymentRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncService _sync;

  Future<List<Map<String, Object?>>> list({String? customerId}) =>
      _db.listPayments(customerId: customerId);

  Future<String> record({
    required String customerId,
    String? billId,
    required double amount,
    String method = 'cash',
    DateTime? paidAt,
    String? notes,
  }) async {
    final id = await _db.insertPayment(
      customerId: customerId,
      billId: billId,
      amount: amount,
      method: method,
      paidAt: paidAt,
      notes: notes,
    );
    await _sync.enqueue(
      entityType: 'payments',
      entityId: id,
      operation: 'create',
      payload: {
        'id': id,
        'customerId': customerId,
        'billId': billId,
        'amount': amount,
        'method': method,
      },
    );
    return id;
  }
}
