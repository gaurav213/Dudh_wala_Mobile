import 'package:doodh_khata_mobile/core/database/app_database.dart';
import 'package:doodh_khata_mobile/core/sync/sync_service.dart';
import 'package:doodh_khata_mobile/features/deliveries/data/repositories/delivery_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createLocal writes delivery and enqueues sync', () async {
    final db = await AppDatabase.memory();
    addTearDown(db.close);

    await db.insertCustomer(
      supplierId: 'sup-1',
      name: 'Ramesh',
      phone: '9876543210',
      id: 'cust-1',
      defaultRatePerLitre: 60,
    );

    final sync = _FakeSync();
    final repo = DeliveryRepository(db, sync);
    final id = await repo.createLocal(
      customerId: 'cust-1',
      deliveryDate: DateTime(2026, 8, 6),
      quantityLitres: 2,
      ratePerLitre: 60,
      status: 'delivered',
    );

    final row = await db.getDelivery(id);
    expect(row, isNotNull);
    expect(row!['amount'], 120);
    expect(row['sync_status'], 'PENDING');
    expect(sync.enqueued, 1);
    expect(sync.lastEntityType, 'deliveries');
  });
}

class _FakeSync implements SyncService {
  int enqueued = 0;
  String? lastEntityType;

  @override
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    enqueued++;
    lastEntityType = entityType;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
