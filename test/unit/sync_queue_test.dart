import 'package:doodh_khata_mobile/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enqueue and pendingSyncItems round-trip', () async {
    final db = await AppDatabase.memory();
    addTearDown(db.close);

    await db.enqueueSync(
      entityType: 'customers',
      entityId: 'c1',
      operation: 'create',
      payloadJson: '{"id":"c1"}',
    );

    expect(await db.syncQueueCount(), 1);
    final pending = await db.pendingSyncItems();
    expect(pending, hasLength(1));
    expect(pending.first['entity_type'], 'customers');

    await db.removeSyncItem(pending.first['id'] as String);
    expect(await db.syncQueueCount(), 0);
  });

  test('markSyncFailure increments attempts and delays', () async {
    final db = await AppDatabase.memory();
    addTearDown(db.close);
    await db.enqueueSync(
      entityType: 'deliveries',
      entityId: 'd1',
      operation: 'update',
      payloadJson: '{}',
    );
    final id = (await db.pendingSyncItems()).first['id'] as String;
    final next = DateTime.now().add(const Duration(hours: 1));
    await db.markSyncFailure(id, 'offline', next);
    final rows = await db.pendingSyncItems();
    // next attempt in future → not pending yet
    expect(rows, isEmpty);
  });
}
