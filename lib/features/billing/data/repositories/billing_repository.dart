import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/bill_preview.dart';

class BillingRepository {
  BillingRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncService _sync;

  Future<List<Map<String, Object?>>> list({String? customerId}) =>
      _db.listBills(customerId: customerId);

  Future<Map<String, Object?>?> get(String id) => _db.getBill(id);

  Future<List<Map<String, Object?>>> items(String billId) =>
      _db.billItems(billId);

  Future<List<Map<String, Object?>>> outstanding() => _db.outstandingBills();

  Future<BillPreview> preview({
    required String customerId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final deliveries = await _db.deliveriesInRange(
      periodStart,
      periodEnd,
      customerId: customerId,
    );
    return BillPreview.fromDeliveries(
      customerId: customerId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      deliveries: deliveries,
    );
  }

  Future<String> generateFromPreview(BillPreview preview, {required String billNumber}) async {
    final id = await _db.insertBill(
      customerId: preview.customerId,
      billNumber: billNumber,
      periodStart: preview.periodStart,
      periodEnd: preview.periodEnd,
      subtotal: preview.subtotal,
      adjustments: preview.adjustments,
      items: [
        for (final line in preview.lines)
          {
            'delivery_id': line.deliveryId,
            'item_date': line.date,
            'description': line.description,
            'quantity_litres': line.quantityLitres,
            'rate_per_litre': line.ratePerLitre,
            'amount': line.amount,
          },
      ],
    );
    await _sync.enqueue(
      entityType: 'bills',
      entityId: id,
      operation: 'create',
      payload: {
        'id': id,
        'customerId': preview.customerId,
        'billNumber': billNumber,
        'subtotal': preview.subtotal,
        'total': preview.total,
      },
    );
    return id;
  }
}
