import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'sync_status.dart';

/// Offline-first SQLite database (sqlite3 + Drift table definitions).
///
/// [tables.dart] holds Drift [Table] classes as the schema source of truth
/// for future `build_runner` codegen. Runtime uses sqlite3 so the app
/// compiles and runs before codegen.
class AppDatabase {
  AppDatabase({Database? database}) : _injected = database;

  final Database? _injected;
  Database? _db;
  bool _opened = false;
  static const _uuid = Uuid();

  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('Database not opened. Call ensureOpen() first.');
    }
    return d;
  }

  Future<void> ensureOpen() async {
    if (_opened) return;
    if (_injected != null) {
      _db = _injected;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'doodh_khata.sqlite');
      _db = sqlite3.open(path);
    }
    _migrate();
    _opened = true;
  }

  /// In-memory DB for unit tests.
  static Future<AppDatabase> memory() async {
    final db = AppDatabase(database: sqlite3.openInMemory());
    await db.ensureOpen();
    return db;
  }

  Future<void> close() async {
    _db?.dispose();
    _db = null;
    _opened = false;
  }

  Future<void> clearUserData() async {
    db.execute('DELETE FROM payments');
    db.execute('DELETE FROM bill_items');
    db.execute('DELETE FROM bills');
    db.execute('DELETE FROM deliveries');
    db.execute('DELETE FROM subscriptions');
    db.execute('DELETE FROM customers');
    db.execute('DELETE FROM sync_queue');
    db.execute('DELETE FROM sync_metadata');
    db.execute('DELETE FROM app_users');
  }

  void _migrate() {
    db.execute('''
CREATE TABLE IF NOT EXISTS app_users (
  id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  role TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'SYNCED',
  updated_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS customers (
  id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  supplier_id TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT,
  default_rate_per_litre REAL NOT NULL DEFAULT 0,
  notes TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  sync_status TEXT NOT NULL DEFAULT 'PENDING',
  updated_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS subscriptions (
  id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  customer_id TEXT NOT NULL,
  product_type TEXT NOT NULL DEFAULT 'milk',
  quantity_litres REAL NOT NULL,
  rate_per_litre REAL NOT NULL,
  frequency TEXT NOT NULL,
  delivery_slot TEXT NOT NULL DEFAULT 'morning',
  start_date INTEGER NOT NULL,
  end_date INTEGER,
  is_active INTEGER NOT NULL DEFAULT 1,
  sync_status TEXT NOT NULL DEFAULT 'PENDING',
  updated_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS deliveries (
  id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  customer_id TEXT NOT NULL,
  subscription_id TEXT,
  delivery_date INTEGER NOT NULL,
  slot TEXT NOT NULL DEFAULT 'morning',
  quantity_litres REAL NOT NULL,
  rate_per_litre REAL NOT NULL,
  amount REAL NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  notes TEXT,
  sync_status TEXT NOT NULL DEFAULT 'PENDING',
  updated_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS bills (
  id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  customer_id TEXT NOT NULL,
  bill_number TEXT NOT NULL,
  period_start INTEGER NOT NULL,
  period_end INTEGER NOT NULL,
  subtotal REAL NOT NULL,
  adjustments REAL NOT NULL DEFAULT 0,
  total REAL NOT NULL,
  paid_amount REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'draft',
  sync_status TEXT NOT NULL DEFAULT 'PENDING',
  updated_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS bill_items (
  id TEXT PRIMARY KEY NOT NULL,
  bill_id TEXT NOT NULL,
  delivery_id TEXT,
  item_date INTEGER NOT NULL,
  description TEXT NOT NULL,
  quantity_litres REAL NOT NULL,
  rate_per_litre REAL NOT NULL,
  amount REAL NOT NULL
);
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  customer_id TEXT NOT NULL,
  bill_id TEXT,
  amount REAL NOT NULL,
  method TEXT NOT NULL DEFAULT 'cash',
  paid_at INTEGER NOT NULL,
  notes TEXT,
  sync_status TEXT NOT NULL DEFAULT 'PENDING',
  updated_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS sync_queue (
  id TEXT PRIMARY KEY NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  next_attempt_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE IF NOT EXISTS sync_metadata (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
''');
  }

  int _ms(DateTime d) => d.millisecondsSinceEpoch;
  DateTime _dt(Object? v) =>
      DateTime.fromMillisecondsSinceEpoch(v as int, isUtc: false);
  bool _bool(Object? v) => (v as int) == 1;

  List<Map<String, Object?>> _rows(ResultSet rs) {
    return [for (final row in rs) Map<String, Object?>.from(row)];
  }

  // ── App users ────────────────────────────────────────────────

  Future<void> upsertAppUser(Map<String, Object?> row) async {
    final now = DateTime.now();
    db.execute(
      '''
INSERT OR REPLACE INTO app_users
(id, remote_id, name, phone, email, role, sync_status, updated_at, created_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        row['id'],
        row['remote_id'],
        row['name'],
        row['phone'],
        row['email'],
        row['role'],
        row['sync_status'] ?? SyncStatus.synced.value,
        _ms(row['updated_at'] as DateTime? ?? now),
        _ms(row['created_at'] as DateTime? ?? now),
      ],
    );
  }

  Future<Map<String, Object?>?> getAppUser() async {
    final rows = _rows(db.select('SELECT * FROM app_users LIMIT 1'));
    if (rows.isEmpty) return null;
    return _mapUser(rows.first);
  }

  Map<String, Object?> _mapUser(Map<String, Object?> r) => {
        'id': r['id'],
        'remote_id': r['remote_id'],
        'name': r['name'],
        'phone': r['phone'],
        'email': r['email'],
        'role': r['role'],
        'sync_status': r['sync_status'],
        'updated_at': _dt(r['updated_at']),
        'created_at': _dt(r['created_at']),
      };

  // ── Customers ────────────────────────────────────────────────

  Future<String> insertCustomer({
    required String supplierId,
    required String name,
    required String phone,
    String? address,
    double defaultRatePerLitre = 0,
    String? notes,
    String? id,
  }) async {
    final now = DateTime.now();
    final localId = id ?? _uuid.v4();
    db.execute(
      '''
INSERT INTO customers
(id, remote_id, supplier_id, name, phone, address, default_rate_per_litre,
 notes, is_active, sync_status, updated_at, created_at)
VALUES (?, NULL, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
''',
      [
        localId,
        supplierId,
        name,
        phone,
        address,
        defaultRatePerLitre,
        notes,
        SyncStatus.pending.value,
        _ms(now),
        _ms(now),
      ],
    );
    return localId;
  }

  Future<void> updateCustomer(String id, Map<String, Object?> fields) async {
    final now = DateTime.now();
    db.execute(
      '''
UPDATE customers SET
  name = COALESCE(?, name),
  phone = COALESCE(?, phone),
  address = COALESCE(?, address),
  default_rate_per_litre = COALESCE(?, default_rate_per_litre),
  notes = COALESCE(?, notes),
  is_active = COALESCE(?, is_active),
  sync_status = ?,
  updated_at = ?
WHERE id = ?
''',
      [
        fields['name'],
        fields['phone'],
        fields['address'],
        fields['default_rate_per_litre'],
        fields['notes'],
        fields.containsKey('is_active')
            ? ((fields['is_active'] as bool) ? 1 : 0)
            : null,
        SyncStatus.pending.value,
        _ms(now),
        id,
      ],
    );
  }

  Future<List<Map<String, Object?>>> watchCustomersSnapshot() async {
    final rows = _rows(db.select(
      'SELECT * FROM customers WHERE is_active = 1 ORDER BY name COLLATE NOCASE',
    ));
    return rows.map(_mapCustomer).toList();
  }

  Stream<List<Map<String, Object?>>> watchCustomers() async* {
    yield await watchCustomersSnapshot();
    // ponytail: polling stream; Drift table watch after full codegen
    yield* Stream.periodic(const Duration(milliseconds: 800))
        .asyncMap((_) => watchCustomersSnapshot());
  }

  Future<Map<String, Object?>?> getCustomer(String id) async {
    final rows = _rows(db.select(
      'SELECT * FROM customers WHERE id = ?',
      [id],
    ));
    if (rows.isEmpty) return null;
    return _mapCustomer(rows.first);
  }

  Map<String, Object?> _mapCustomer(Map<String, Object?> r) => {
        'id': r['id'],
        'remote_id': r['remote_id'],
        'supplier_id': r['supplier_id'],
        'name': r['name'],
        'phone': r['phone'],
        'address': r['address'],
        'default_rate_per_litre': r['default_rate_per_litre'],
        'notes': r['notes'],
        'is_active': _bool(r['is_active']),
        'sync_status': r['sync_status'],
        'updated_at': _dt(r['updated_at']),
        'created_at': _dt(r['created_at']),
      };

  // ── Subscriptions ────────────────────────────────────────────

  Future<String> insertSubscription(Map<String, Object?> row) async {
    final now = DateTime.now();
    final id = (row['id'] as String?) ?? _uuid.v4();
    db.execute(
      '''
INSERT INTO subscriptions
(id, remote_id, customer_id, product_type, quantity_litres, rate_per_litre,
 frequency, delivery_slot, start_date, end_date, is_active, sync_status,
 updated_at, created_at)
VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
''',
      [
        id,
        row['customer_id'],
        row['product_type'] ?? 'milk',
        row['quantity_litres'],
        row['rate_per_litre'],
        row['frequency'],
        row['delivery_slot'] ?? 'morning',
        _ms(row['start_date'] as DateTime),
        row['end_date'] == null ? null : _ms(row['end_date'] as DateTime),
        SyncStatus.pending.value,
        _ms(now),
        _ms(now),
      ],
    );
    return id;
  }

  Future<void> updateSubscription(String id, Map<String, Object?> fields) async {
    final now = DateTime.now();
    db.execute(
      '''
UPDATE subscriptions SET
  quantity_litres = COALESCE(?, quantity_litres),
  rate_per_litre = COALESCE(?, rate_per_litre),
  frequency = COALESCE(?, frequency),
  delivery_slot = COALESCE(?, delivery_slot),
  end_date = COALESCE(?, end_date),
  is_active = COALESCE(?, is_active),
  sync_status = ?,
  updated_at = ?
WHERE id = ?
''',
      [
        fields['quantity_litres'],
        fields['rate_per_litre'],
        fields['frequency'],
        fields['delivery_slot'],
        fields['end_date'] == null
            ? null
            : _ms(fields['end_date'] as DateTime),
        fields.containsKey('is_active')
            ? ((fields['is_active'] as bool) ? 1 : 0)
            : null,
        SyncStatus.pending.value,
        _ms(now),
        id,
      ],
    );
  }

  Future<List<Map<String, Object?>>> listSubscriptions({
    String? customerId,
  }) async {
    final rows = customerId == null
        ? _rows(db.select(
            'SELECT * FROM subscriptions WHERE is_active = 1 ORDER BY start_date DESC',
          ))
        : _rows(db.select(
            'SELECT * FROM subscriptions WHERE customer_id = ? AND is_active = 1 ORDER BY start_date DESC',
            [customerId],
          ));
    return rows.map(_mapSubscription).toList();
  }

  Map<String, Object?> _mapSubscription(Map<String, Object?> r) => {
        'id': r['id'],
        'remote_id': r['remote_id'],
        'customer_id': r['customer_id'],
        'product_type': r['product_type'],
        'quantity_litres': r['quantity_litres'],
        'rate_per_litre': r['rate_per_litre'],
        'frequency': r['frequency'],
        'delivery_slot': r['delivery_slot'],
        'start_date': _dt(r['start_date']),
        'end_date': r['end_date'] == null ? null : _dt(r['end_date']),
        'is_active': _bool(r['is_active']),
        'sync_status': r['sync_status'],
        'updated_at': _dt(r['updated_at']),
        'created_at': _dt(r['created_at']),
      };

  // ── Deliveries ───────────────────────────────────────────────

  Future<String> insertDelivery({
    required String customerId,
    String? subscriptionId,
    required DateTime deliveryDate,
    required double quantityLitres,
    required double ratePerLitre,
    String slot = 'morning',
    String status = 'pending',
    String? notes,
    String? id,
  }) async {
    final now = DateTime.now();
    final localId = id ?? _uuid.v4();
    final amount = quantityLitres * ratePerLitre;
    final day = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);
    db.execute(
      '''
INSERT INTO deliveries
(id, remote_id, customer_id, subscription_id, delivery_date, slot,
 quantity_litres, rate_per_litre, amount, status, notes, sync_status,
 updated_at, created_at)
VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        localId,
        customerId,
        subscriptionId,
        _ms(day),
        slot,
        quantityLitres,
        ratePerLitre,
        amount,
        status,
        notes,
        SyncStatus.pending.value,
        _ms(now),
        _ms(now),
      ],
    );
    return localId;
  }

  Future<void> updateDeliveryStatus(
    String id, {
    required String status,
    double? quantityLitres,
    String? notes,
  }) async {
    final now = DateTime.now();
    final existing = await getDelivery(id);
    if (existing == null) return;
    final qty =
        quantityLitres ?? (existing['quantity_litres'] as num).toDouble();
    final rate = (existing['rate_per_litre'] as num).toDouble();
    db.execute(
      '''
UPDATE deliveries SET
  status = ?,
  quantity_litres = ?,
  amount = ?,
  notes = COALESCE(?, notes),
  sync_status = ?,
  updated_at = ?
WHERE id = ?
''',
      [
        status,
        qty,
        qty * rate,
        notes,
        SyncStatus.pending.value,
        _ms(now),
        id,
      ],
    );
  }

  Future<Map<String, Object?>?> getDelivery(String id) async {
    final rows = _rows(db.select(
      'SELECT * FROM deliveries WHERE id = ?',
      [id],
    ));
    if (rows.isEmpty) return null;
    return _mapDelivery(rows.first);
  }

  Future<List<Map<String, Object?>>> deliveriesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = _rows(db.select(
      '''
SELECT d.*, c.name AS customer_name
FROM deliveries d
JOIN customers c ON c.id = d.customer_id
WHERE d.delivery_date >= ? AND d.delivery_date < ?
ORDER BY c.name COLLATE NOCASE
''',
      [_ms(start), _ms(end)],
    ));
    return rows.map((r) {
      final m = _mapDelivery(r);
      m['customer_name'] = r['customer_name'];
      return m;
    }).toList();
  }

  Stream<List<Map<String, Object?>>> watchDeliveriesForDate(
    DateTime date,
  ) async* {
    yield await deliveriesForDate(date);
    yield* Stream.periodic(const Duration(milliseconds: 800))
        .asyncMap((_) => deliveriesForDate(date));
  }

  Future<List<Map<String, Object?>>> deliveriesInRange(
    DateTime start,
    DateTime end, {
    String? customerId,
  }) async {
    final s = DateTime(start.year, start.month, start.day);
    final e =
        DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
    final rows = customerId == null
        ? _rows(db.select(
            '''
SELECT * FROM deliveries
WHERE delivery_date >= ? AND delivery_date < ?
ORDER BY delivery_date
''',
            [_ms(s), _ms(e)],
          ))
        : _rows(db.select(
            '''
SELECT * FROM deliveries
WHERE customer_id = ? AND delivery_date >= ? AND delivery_date < ?
ORDER BY delivery_date
''',
            [customerId, _ms(s), _ms(e)],
          ));
    return rows.map(_mapDelivery).toList();
  }

  Map<String, Object?> _mapDelivery(Map<String, Object?> r) => {
        'id': r['id'],
        'remote_id': r['remote_id'],
        'customer_id': r['customer_id'],
        'subscription_id': r['subscription_id'],
        'delivery_date': _dt(r['delivery_date']),
        'slot': r['slot'],
        'quantity_litres': r['quantity_litres'],
        'rate_per_litre': r['rate_per_litre'],
        'amount': r['amount'],
        'status': r['status'],
        'notes': r['notes'],
        'sync_status': r['sync_status'],
        'updated_at': _dt(r['updated_at']),
        'created_at': _dt(r['created_at']),
      };

  // ── Bills ────────────────────────────────────────────────────

  Future<String> insertBill({
    required String customerId,
    required String billNumber,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double subtotal,
    double adjustments = 0,
    required List<Map<String, Object?>> items,
    String status = 'issued',
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final total = subtotal + adjustments;
    db.execute(
      '''
INSERT INTO bills
(id, remote_id, customer_id, bill_number, period_start, period_end,
 subtotal, adjustments, total, paid_amount, status, sync_status,
 updated_at, created_at)
VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?)
''',
      [
        id,
        customerId,
        billNumber,
        _ms(periodStart),
        _ms(periodEnd),
        subtotal,
        adjustments,
        total,
        status,
        SyncStatus.pending.value,
        _ms(now),
        _ms(now),
      ],
    );
    for (final item in items) {
      db.execute(
        '''
INSERT INTO bill_items
(id, bill_id, delivery_id, item_date, description, quantity_litres,
 rate_per_litre, amount)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''',
        [
          _uuid.v4(),
          id,
          item['delivery_id'],
          _ms(item['item_date'] as DateTime),
          item['description'],
          item['quantity_litres'],
          item['rate_per_litre'],
          item['amount'],
        ],
      );
    }
    return id;
  }

  Future<List<Map<String, Object?>>> listBills({String? customerId}) async {
    final rows = customerId == null
        ? _rows(db.select('SELECT * FROM bills ORDER BY created_at DESC'))
        : _rows(db.select(
            'SELECT * FROM bills WHERE customer_id = ? ORDER BY created_at DESC',
            [customerId],
          ));
    return rows.map(_mapBill).toList();
  }

  Future<Map<String, Object?>?> getBill(String id) async {
    final rows = _rows(db.select('SELECT * FROM bills WHERE id = ?', [id]));
    if (rows.isEmpty) return null;
    return _mapBill(rows.first);
  }

  Future<List<Map<String, Object?>>> billItems(String billId) async {
    final rows = _rows(db.select(
      'SELECT * FROM bill_items WHERE bill_id = ? ORDER BY item_date',
      [billId],
    ));
    return rows
        .map(
          (r) => {
            'id': r['id'],
            'bill_id': r['bill_id'],
            'delivery_id': r['delivery_id'],
            'item_date': _dt(r['item_date']),
            'description': r['description'],
            'quantity_litres': r['quantity_litres'],
            'rate_per_litre': r['rate_per_litre'],
            'amount': r['amount'],
          },
        )
        .toList();
  }

  Future<List<Map<String, Object?>>> outstandingBills() async {
    final rows = _rows(db.select(
      '''
SELECT b.*, c.name AS customer_name,
       (b.total - b.paid_amount) AS due
FROM bills b
JOIN customers c ON c.id = b.customer_id
WHERE b.paid_amount < b.total
ORDER BY b.period_end
''',
    ));
    return rows.map((r) {
      final m = _mapBill(r);
      m['customer_name'] = r['customer_name'];
      m['due'] = r['due'];
      return m;
    }).toList();
  }

  Map<String, Object?> _mapBill(Map<String, Object?> r) => {
        'id': r['id'],
        'remote_id': r['remote_id'],
        'customer_id': r['customer_id'],
        'bill_number': r['bill_number'],
        'period_start': _dt(r['period_start']),
        'period_end': _dt(r['period_end']),
        'subtotal': r['subtotal'],
        'adjustments': r['adjustments'],
        'total': r['total'],
        'paid_amount': r['paid_amount'],
        'status': r['status'],
        'sync_status': r['sync_status'],
        'updated_at': _dt(r['updated_at']),
        'created_at': _dt(r['created_at']),
      };

  // ── Payments ─────────────────────────────────────────────────

  Future<String> insertPayment({
    required String customerId,
    String? billId,
    required double amount,
    String method = 'cash',
    DateTime? paidAt,
    String? notes,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    db.execute(
      '''
INSERT INTO payments
(id, remote_id, customer_id, bill_id, amount, method, paid_at, notes,
 sync_status, updated_at, created_at)
VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        id,
        customerId,
        billId,
        amount,
        method,
        _ms(paidAt ?? now),
        notes,
        SyncStatus.pending.value,
        _ms(now),
        _ms(now),
      ],
    );
    if (billId != null) {
      db.execute(
        '''
UPDATE bills SET
  paid_amount = paid_amount + ?,
  status = CASE
    WHEN paid_amount + ? >= total THEN 'paid'
    WHEN paid_amount + ? > 0 THEN 'partial'
    ELSE status
  END,
  sync_status = ?,
  updated_at = ?
WHERE id = ?
''',
        [
          amount,
          amount,
          amount,
          SyncStatus.pending.value,
          _ms(now),
          billId,
        ],
      );
    }
    return id;
  }

  Future<List<Map<String, Object?>>> listPayments({String? customerId}) async {
    final rows = customerId == null
        ? _rows(db.select('SELECT * FROM payments ORDER BY paid_at DESC'))
        : _rows(db.select(
            'SELECT * FROM payments WHERE customer_id = ? ORDER BY paid_at DESC',
            [customerId],
          ));
    return rows
        .map(
          (r) => {
            'id': r['id'],
            'remote_id': r['remote_id'],
            'customer_id': r['customer_id'],
            'bill_id': r['bill_id'],
            'amount': r['amount'],
            'method': r['method'],
            'paid_at': _dt(r['paid_at']),
            'notes': r['notes'],
            'sync_status': r['sync_status'],
            'updated_at': _dt(r['updated_at']),
            'created_at': _dt(r['created_at']),
          },
        )
        .toList();
  }

  // ── Sync queue ───────────────────────────────────────────────

  Future<void> enqueueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
  }) async {
    final now = DateTime.now();
    db.execute(
      '''
INSERT INTO sync_queue
(id, entity_type, entity_id, operation, payload_json, attempts,
 last_error, next_attempt_at, created_at)
VALUES (?, ?, ?, ?, ?, 0, NULL, ?, ?)
''',
      [
        _uuid.v4(),
        entityType,
        entityId,
        operation,
        payloadJson,
        _ms(now),
        _ms(now),
      ],
    );
  }

  Future<List<Map<String, Object?>>> pendingSyncItems({int limit = 50}) async {
    final now = DateTime.now();
    final rows = _rows(db.select(
      '''
SELECT * FROM sync_queue
WHERE next_attempt_at <= ?
ORDER BY created_at
LIMIT ?
''',
      [_ms(now), limit],
    ));
    return rows
        .map(
          (r) => {
            'id': r['id'],
            'entity_type': r['entity_type'],
            'entity_id': r['entity_id'],
            'operation': r['operation'],
            'payload_json': r['payload_json'],
            'attempts': r['attempts'],
            'last_error': r['last_error'],
            'next_attempt_at': _dt(r['next_attempt_at']),
            'created_at': _dt(r['created_at']),
          },
        )
        .toList();
  }

  Future<void> removeSyncItem(String id) async {
    db.execute('DELETE FROM sync_queue WHERE id = ?', [id]);
  }

  Future<void> markSyncFailure(
    String id,
    String error,
    DateTime nextAttempt,
  ) async {
    db.execute(
      '''
UPDATE sync_queue SET
  attempts = attempts + 1,
  last_error = ?,
  next_attempt_at = ?
WHERE id = ?
''',
      [error, _ms(nextAttempt), id],
    );
  }

  Future<int> syncQueueCount() async {
    final rows = _rows(db.select('SELECT COUNT(*) AS c FROM sync_queue'));
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<List<Map<String, Object?>>> conflictRows() async {
    final out = <Map<String, Object?>>[];
    for (final table in [
      'customers',
      'subscriptions',
      'deliveries',
      'bills',
      'payments',
    ]) {
      final rows = _rows(db.select(
        'SELECT id, sync_status FROM $table WHERE sync_status = ?',
        [SyncStatus.conflict.value],
      ));
      for (final r in rows) {
        out.add({
          'entity_type': table,
          'entity_id': r['id'],
          'sync_status': r['sync_status'],
        });
      }
    }
    return out;
  }

  Future<void> resolveConflict({
    required String entityType,
    required String entityId,
    required bool keepLocal,
  }) async {
    final status =
        keepLocal ? SyncStatus.pending.value : SyncStatus.synced.value;
    db.execute(
      'UPDATE $entityType SET sync_status = ?, updated_at = ? WHERE id = ?',
      [status, _ms(DateTime.now()), entityId],
    );
  }

  Future<void> setMetadata(String key, String value) async {
    db.execute(
      '''
INSERT OR REPLACE INTO sync_metadata (key, value, updated_at)
VALUES (?, ?, ?)
''',
      [key, value, _ms(DateTime.now())],
    );
  }

  Future<String?> getMetadata(String key) async {
    final rows = _rows(db.select(
      'SELECT value FROM sync_metadata WHERE key = ?',
      [key],
    ));
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<Map<String, num>> dashboardStats({required DateTime day}) async {
    final deliveries = await deliveriesForDate(day);
    var litres = 0.0;
    var delivered = 0;
    var pending = 0;
    for (final d in deliveries) {
      litres += (d['quantity_litres'] as num).toDouble();
      if (d['status'] == 'delivered') {
        delivered++;
      } else if (d['status'] == 'pending') {
        pending++;
      }
    }
    final outstanding = await outstandingBills();
    var due = 0.0;
    for (final b in outstanding) {
      due += (b['due'] as num).toDouble();
    }
    final customers = await watchCustomersSnapshot();
    return {
      'customers': customers.length,
      'today_deliveries': deliveries.length,
      'today_litres': litres,
      'delivered': delivered,
      'pending': pending,
      'outstanding_due': due,
      'sync_queue': await syncQueueCount(),
    };
  }
}
