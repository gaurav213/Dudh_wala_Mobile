import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncService _sync;

  Future<List<Map<String, Object?>>> list({String? customerId}) =>
      _db.listSubscriptions(customerId: customerId);

  Future<String> create(Map<String, Object?> row) async {
    final id = await _db.insertSubscription(row);
    await _sync.enqueue(
      entityType: 'subscriptions',
      entityId: id,
      operation: 'create',
      payload: {
        'id': id,
        ...row.map(
            (k, v) => MapEntry(k, v is DateTime ? v.toIso8601String() : v)),
      },
    );
    return id;
  }

  Future<void> update(String id, Map<String, Object?> fields) async {
    await _db.updateSubscription(id, fields);
    await _sync.enqueue(
      entityType: 'subscriptions',
      entityId: id,
      operation: 'update',
      payload: {'id': id, ...fields},
    );
  }
}
