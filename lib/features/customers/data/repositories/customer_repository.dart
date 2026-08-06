import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';

class CustomerRepository {
  CustomerRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncService _sync;

  Stream<List<Map<String, Object?>>> watchAll() => _db.watchCustomers();

  Future<Map<String, Object?>?> get(String id) => _db.getCustomer(id);

  Future<String> create({
    required String supplierId,
    required String name,
    required String phone,
    String? address,
    double defaultRatePerLitre = 0,
    String? notes,
  }) async {
    final id = await _db.insertCustomer(
      supplierId: supplierId,
      name: name,
      phone: phone,
      address: address,
      defaultRatePerLitre: defaultRatePerLitre,
      notes: notes,
    );
    await _sync.enqueue(
      entityType: 'customers',
      entityId: id,
      operation: 'create',
      payload: {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'defaultRatePerLitre': defaultRatePerLitre,
        'notes': notes,
      },
    );
    return id;
  }

  Future<void> update(String id, Map<String, Object?> fields) async {
    await _db.updateCustomer(id, fields);
    await _sync.enqueue(
      entityType: 'customers',
      entityId: id,
      operation: 'update',
      payload: {'id': id, ...fields.map((k, v) => MapEntry(k, v))},
    );
  }
}
