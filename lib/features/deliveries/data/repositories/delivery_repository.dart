import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/delivery_calc.dart';

class DeliveryRepository {
  DeliveryRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncService _sync;

  Stream<List<Map<String, Object?>>> watchForDate(DateTime date) =>
      _db.watchDeliveriesForDate(date);

  Future<List<Map<String, Object?>>> forDate(DateTime date) =>
      _db.deliveriesForDate(date);

  Future<List<Map<String, Object?>>> inRange(
    DateTime start,
    DateTime end, {
    String? customerId,
  }) =>
      _db.deliveriesInRange(start, end, customerId: customerId);

  Future<String> createLocal({
    required String customerId,
    String? subscriptionId,
    required DateTime deliveryDate,
    required double quantityLitres,
    required double ratePerLitre,
    String slot = 'morning',
    String status = 'pending',
    String? notes,
  }) async {
    final amount = DeliveryCalc.amount(
      quantityLitres: quantityLitres,
      ratePerLitre: ratePerLitre,
    );
    final id = await _db.insertDelivery(
      customerId: customerId,
      subscriptionId: subscriptionId,
      deliveryDate: deliveryDate,
      quantityLitres: quantityLitres,
      ratePerLitre: ratePerLitre,
      slot: slot,
      status: status,
      notes: notes,
    );
    await _sync.enqueue(
      entityType: 'deliveries',
      entityId: id,
      operation: 'create',
      payload: {
        'id': id,
        'customerId': customerId,
        'subscriptionId': subscriptionId,
        'deliveryDate': deliveryDate.toIso8601String(),
        'quantityLitres': quantityLitres,
        'ratePerLitre': ratePerLitre,
        'amount': amount,
        'slot': slot,
        'status': status,
        'notes': notes,
      },
    );
    return id;
  }

  Future<void> markStatus(
    String id, {
    required String status,
    double? quantityLitres,
    String? notes,
  }) async {
    await _db.updateDeliveryStatus(
      id,
      status: status,
      quantityLitres: quantityLitres,
      notes: notes,
    );
    await _sync.enqueue(
      entityType: 'deliveries',
      entityId: id,
      operation: 'update',
      payload: {
        'id': id,
        'status': status,
        'quantityLitres': quantityLitres,
        'notes': notes,
      },
    );
  }
}
