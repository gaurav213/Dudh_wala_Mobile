import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../database/sync_status.dart';
import '../errors/app_exception.dart';
import '../storage/storage_providers.dart';
import '../storage/token_storage.dart';

enum SyncPhase { idle, pushing, pulling, error }

class SyncState {
  const SyncState({
    this.phase = SyncPhase.idle,
    this.queueCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  final SyncPhase phase;
  final int queueCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  SyncState copyWith({
    SyncPhase? phase,
    int? queueCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      queueCount: queueCount ?? this.queueCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
    );
  }
}

/// Local-first sync aligned with backend `POST /sync/push` + `GET /sync/pull?cursor=`.
class SyncService {
  SyncService({
    required AppDatabase db,
    required ApiClient api,
    required TokenStorage tokens,
    Connectivity? connectivity,
  })  : _db = db,
        _api = api,
        _tokens = tokens,
        _connectivity = connectivity ?? Connectivity();

  final AppDatabase _db;
  final ApiClient _api;
  final TokenStorage _tokens;
  final Connectivity _connectivity;
  final _uuid = const Uuid();

  bool _running = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  final _controller = StreamController<SyncState>.broadcast();
  SyncState _state = const SyncState();

  Stream<SyncState> get stream => _controller.stream;
  SyncState get state => _state;

  void startConnectivityListener() {
    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        unawaited(syncNow());
      }
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db.enqueueSync(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payloadJson: jsonEncode(payload),
    );
    _emit(queueCount: await _db.syncQueueCount());
    unawaited(syncNow());
  }

  /// Single-flight lock — concurrent calls coalesce.
  Future<void> syncNow() async {
    if (_running) return;
    final hasSession = await _tokens.hasSession().timeout(
          const Duration(seconds: 2),
          onTimeout: () => false,
        );
    if (!hasSession) return;
    _running = true;
    try {
      _emit(phase: SyncPhase.pushing);
      await _pushQueue();
      _emit(phase: SyncPhase.pulling);
      await _pullRemote();
      await _db.setMetadata('last_synced_at', DateTime.now().toIso8601String());
      _emit(
        phase: SyncPhase.idle,
        queueCount: await _db.syncQueueCount(),
        lastSyncedAt: DateTime.now(),
        lastError: null,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Sync failed: $e\n$st');
      }
      _emit(
        phase: SyncPhase.error,
        lastError: e.toString(),
        queueCount: await _db.syncQueueCount(),
      );
    } finally {
      _running = false;
    }
  }

  String _mapEntityType(String local) {
    switch (local.toLowerCase()) {
      case 'customers':
      case 'customer':
        return 'CUSTOMER';
      case 'subscriptions':
      case 'subscription':
        return 'SUBSCRIPTION';
      case 'deliveries':
      case 'delivery':
      case 'milk_deliveries':
        return 'DELIVERY';
      case 'payments':
      case 'payment':
        return 'PAYMENT';
      default:
        return local.toUpperCase();
    }
  }

  String _mapOperation(String local) {
    switch (local.toLowerCase()) {
      case 'create':
        return 'CREATE';
      case 'delete':
        return 'DELETE';
      default:
        return 'UPDATE';
    }
  }

  Future<void> _pushQueue() async {
    final items = await _db.pendingSyncItems();
    if (items.isEmpty) return;

    final deviceId = await _db.getMetadata('device_id') ?? _uuid.v4();
    await _db.setMetadata('device_id', deviceId);

    // Batch into the backend contract. Items that have exhausted their
    // retries are dead-lettered on the spot (not thrown) so one bad item
    // can't abort the whole batch and block everything queued after it.
    final operations = <Map<String, dynamic>>[];
    final pushable = <Map<String, Object?>>[];
    for (final item in items) {
      final id = item['id'] as String;
      final attempts = (item['attempts'] as int?) ?? 0;
      if (attempts >= 8) {
        // Kept in `sync_queue` with a long next-attempt so the UI can surface
        // a "sync failed" state for it, without it clogging future batches.
        await _db.markSyncFailure(
          id,
          'Exhausted retries after $attempts attempts',
          DateTime.now().add(const Duration(days: 3650)),
        );
        continue;
      }
      final entityType = _mapEntityType(item['entity_type'] as String);
      final operation = _mapOperation(item['operation'] as String);
      final entityId = item['entity_id'] as String;
      final payload =
          jsonDecode(item['payload_json'] as String) as Map<String, dynamic>;
      operations.add({
        'operationId': id,
        'deviceId': deviceId,
        'entityType': entityType,
        'entityId': entityId,
        'operationType': operation,
        'baseVersion': payload['version'] is int
            ? payload['version']
            : int.tryParse('${payload['version']}') ?? 0,
        'clientUpdatedAt': payload['updated_at']?.toString() ??
            DateTime.now().toIso8601String(),
        'payload': payload,
      });
      pushable.add(item);
    }
    if (pushable.isEmpty) return;

    try {
      await _api.post('/sync/push', data: {'operations': operations});
      for (final item in pushable) {
        await _db.removeSyncItem(item['id'] as String);
      }
    } on NetworkException {
      for (final item in pushable) {
        final id = item['id'] as String;
        final attempts = (item['attempts'] as int?) ?? 0;
        final delay = Duration(seconds: _backoffSeconds(attempts));
        await _db.markSyncFailure(id, 'offline', DateTime.now().add(delay));
      }
      rethrow;
    } catch (e) {
      for (final item in pushable) {
        final id = item['id'] as String;
        final attempts = (item['attempts'] as int?) ?? 0;
        final delay = Duration(seconds: _backoffSeconds(attempts));
        await _db.markSyncFailure(id, e.toString(), DateTime.now().add(delay));
      }
      rethrow;
    }
  }

  Future<void> _pullRemote() async {
    final cursorRaw = await _db.getMetadata('sync_cursor');
    final cursor = int.tryParse(cursorRaw ?? '0') ?? 0;
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/sync/pull',
        query: {'cursor': cursor},
      );
      final body = res.data ?? const <String, dynamic>{};
      // Support both raw and interceptor-unwrapped shapes.
      final payload = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      final nextCursor = '${payload['cursor'] ?? cursor}';
      await _db.setMetadata('sync_cursor', nextCursor);

      final changes = payload['changes'];
      if (changes is List) {
        for (final change in changes) {
          if (change is! Map) continue;
          final entityType = '${change['entityType'] ?? ''}';
          final entity = change['entity'];
          if (entity is! Map<String, dynamic>) continue;
          try {
            await _applyPulledEntity(entityType, entity);
          } catch (e, st) {
            // One malformed/unexpected change must not sink the rest of the
            // batch — the cursor has already moved past every change in it.
            if (kDebugMode) {
              debugPrint('Sync pull: failed to apply $entityType: $e\n$st');
            }
          }
        }
      }
    } on AuthException catch (e) {
      // Farm-owner-only endpoint — customers/staff skip without failing the app.
      if (e.code == '403') {
        if (kDebugMode) {
          debugPrint('Sync pull skipped: role not permitted for /sync/pull');
        }
        return;
      }
      rethrow;
    } on NetworkException {
      // Pull is best-effort when offline.
    }
  }

  /// Writes one pulled change into the local DB, reusing the same
  /// insert/update methods (and `AppDatabase.resolveConflict` to mark the
  /// row SYNCED) that the push side and direct-API flows already use —
  /// see `CustomerRepository`, `DeliveryRepository`, `SubscriptionRepository`
  /// and `AuthRepositoryImpl._persistSession` for the equivalent local
  /// writes on the way in.
  ///
  /// Field names are read defensively in both the camelCase shape push
  /// payloads use and the snake_case shape local DB columns use, since nothing
  /// in this repo currently pins down the exact `/sync/pull` entity shape.
  Future<void> _applyPulledEntity(
    String entityType,
    Map<String, dynamic> entity,
  ) async {
    final id = '${entity['id'] ?? entity['entityId'] ?? ''}';
    if (id.isEmpty) return;

    switch (entityType.toUpperCase()) {
      case 'CUSTOMER':
        await _applyCustomer(id, entity);
        break;
      case 'SUBSCRIPTION':
        await _applySubscription(id, entity);
        break;
      case 'DELIVERY':
        await _applyDelivery(id, entity);
        break;
      case 'PAYMENT':
        await _applyPayment(id, entity);
        break;
      case 'USER':
        // Same upsert AuthRepositoryImpl uses for every remote-authoritative
        // user write (login/refresh/restoreSession).
        await _db.upsertAppUser({
          'id': id,
          'remote_id': entity['remoteId'] ?? entity['remote_id'] ?? id,
          'name': entity['name'],
          'phone': entity['phone'] ?? entity['mobileNumber'],
          'email': entity['email'],
          'role': entity['role'],
          'sync_status': SyncStatus.synced.value,
        });
        break;
      default:
        // TODO(sync-pull): BILL / BILL_ITEM changes aren't applied locally
        // yet. Bills are nested (a bill + its bill_items) and this app has
        // no existing "write a full bill from a remote payload" path to
        // reuse (BillingRepository.generateFromPreview only builds bills
        // from local deliveries) — wire this up once the backend's BILL
        // pull payload shape (and whether it inlines items) is confirmed.
        // Any other unrecognized entityType lands here too; log it so gaps
        // are visible instead of silently dropped.
        if (kDebugMode) {
          debugPrint('Sync pull: unhandled entity type "$entityType" id=$id');
        }
    }
  }

  Object? _field(Map<String, dynamic> e, String camel, String snake) =>
      e[camel] ?? e[snake];

  DateTime? _parseDate(Object? v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  double? _parseNum(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// `is_active` must be *omitted* (not passed as null) when unknown — the
  /// DB layer uses `Map.containsKey('is_active')` to decide whether to touch
  /// the column at all (see `AppDatabase.updateCustomer`/`updateSubscription`).
  bool? _parseBool(Object? v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return null;
  }

  Future<void> _applyCustomer(String id, Map<String, dynamic> e) async {
    final existing = await _db.getCustomer(id);
    if (existing != null) {
      final fields = <String, Object?>{
        'name': _field(e, 'name', 'name'),
        'phone': _field(e, 'phone', 'phone'),
        'address': _field(e, 'address', 'address'),
        'default_rate_per_litre':
            _parseNum(_field(e, 'defaultRatePerLitre', 'default_rate_per_litre')),
        'notes': _field(e, 'notes', 'notes'),
      };
      final isActive = _parseBool(_field(e, 'isActive', 'is_active'));
      if (isActive != null) fields['is_active'] = isActive;
      await _db.updateCustomer(id, fields);
    } else {
      final supplierId = '${_field(e, 'supplierId', 'supplier_id') ?? ''}';
      final name = '${_field(e, 'name', 'name') ?? ''}';
      final phone = '${_field(e, 'phone', 'phone') ?? ''}';
      if (supplierId.isEmpty || name.isEmpty || phone.isEmpty) return;
      await _db.insertCustomer(
        id: id,
        supplierId: supplierId,
        name: name,
        phone: phone,
        address: _field(e, 'address', 'address') as String?,
        defaultRatePerLitre:
            _parseNum(_field(e, 'defaultRatePerLitre', 'default_rate_per_litre')) ??
                0,
        notes: _field(e, 'notes', 'notes') as String?,
      );
    }
    await _db.resolveConflict(
      entityType: 'customers',
      entityId: id,
      keepLocal: false,
    );
  }

  Future<void> _applySubscription(String id, Map<String, dynamic> e) async {
    final exists = await _db.rowExists('subscriptions', id);
    if (exists) {
      final fields = <String, Object?>{
        'quantity_litres': _parseNum(_field(e, 'quantityLitres', 'quantity_litres')),
        'rate_per_litre': _parseNum(_field(e, 'ratePerLitre', 'rate_per_litre')),
        'frequency': _field(e, 'frequency', 'frequency'),
        'delivery_slot': _field(e, 'deliverySlot', 'delivery_slot'),
        'end_date': _parseDate(_field(e, 'endDate', 'end_date')),
      };
      final isActive = _parseBool(_field(e, 'isActive', 'is_active'));
      if (isActive != null) fields['is_active'] = isActive;
      await _db.updateSubscription(id, fields);
    } else {
      final customerId = '${_field(e, 'customerId', 'customer_id') ?? ''}';
      final startDate = _parseDate(_field(e, 'startDate', 'start_date'));
      final quantity = _parseNum(_field(e, 'quantityLitres', 'quantity_litres'));
      final rate = _parseNum(_field(e, 'ratePerLitre', 'rate_per_litre'));
      final frequency = _field(e, 'frequency', 'frequency');
      if (customerId.isEmpty ||
          startDate == null ||
          quantity == null ||
          rate == null ||
          frequency == null) {
        return;
      }
      await _db.insertSubscription({
        'id': id,
        'customer_id': customerId,
        'product_type': _field(e, 'productType', 'product_type'),
        'quantity_litres': quantity,
        'rate_per_litre': rate,
        'frequency': frequency,
        'delivery_slot': _field(e, 'deliverySlot', 'delivery_slot'),
        'start_date': startDate,
        'end_date': _parseDate(_field(e, 'endDate', 'end_date')),
      });
    }
    await _db.resolveConflict(
      entityType: 'subscriptions',
      entityId: id,
      keepLocal: false,
    );
  }

  Future<void> _applyDelivery(String id, Map<String, dynamic> e) async {
    final existing = await _db.getDelivery(id);
    if (existing != null) {
      await _db.updateDeliveryStatus(
        id,
        status: '${_field(e, 'status', 'status') ?? existing['status']}',
        quantityLitres: _parseNum(_field(e, 'quantityLitres', 'quantity_litres')),
        notes: _field(e, 'notes', 'notes') as String?,
      );
    } else {
      final customerId = '${_field(e, 'customerId', 'customer_id') ?? ''}';
      final date = _parseDate(_field(e, 'deliveryDate', 'delivery_date'));
      final quantity = _parseNum(_field(e, 'quantityLitres', 'quantity_litres'));
      final rate = _parseNum(_field(e, 'ratePerLitre', 'rate_per_litre'));
      if (customerId.isEmpty || date == null || quantity == null || rate == null) {
        return;
      }
      await _db.insertDelivery(
        id: id,
        customerId: customerId,
        subscriptionId:
            _field(e, 'subscriptionId', 'subscription_id') as String?,
        deliveryDate: date,
        quantityLitres: quantity,
        ratePerLitre: rate,
        slot: '${_field(e, 'slot', 'slot') ?? 'morning'}',
        status: '${_field(e, 'status', 'status') ?? 'pending'}',
        notes: _field(e, 'notes', 'notes') as String?,
      );
    }
    await _db.resolveConflict(
      entityType: 'deliveries',
      entityId: id,
      keepLocal: false,
    );
  }

  Future<void> _applyPayment(String id, Map<String, dynamic> e) async {
    // Payments are append-only in this app (no updatePayment path exists) —
    // once a payment id is known locally there's nothing to reconcile.
    if (await _db.rowExists('payments', id)) return;
    final customerId = '${_field(e, 'customerId', 'customer_id') ?? ''}';
    final amount = _parseNum(_field(e, 'amount', 'amount'));
    if (customerId.isEmpty || amount == null) return;
    await _db.insertPayment(
      id: id,
      customerId: customerId,
      billId: _field(e, 'billId', 'bill_id') as String?,
      amount: amount,
      method: '${_field(e, 'method', 'method') ?? 'cash'}',
      paidAt: _parseDate(_field(e, 'paidAt', 'paid_at')),
      notes: _field(e, 'notes', 'notes') as String?,
    );
    await _db.resolveConflict(
      entityType: 'payments',
      entityId: id,
      keepLocal: false,
    );
  }

  int _backoffSeconds(int attempts) {
    const caps = [5, 15, 30, 60, 120, 300, 600, 900];
    if (attempts < 0) return caps.first;
    if (attempts >= caps.length) return caps.last;
    return caps[attempts];
  }

  void _emit({
    SyncPhase? phase,
    int? queueCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    _state = _state.copyWith(
      phase: phase,
      queueCount: queueCount,
      lastSyncedAt: lastSyncedAt,
      lastError: lastError,
    );
    if (!_controller.isClosed) {
      _controller.add(_state);
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStorageProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final syncStateProvider = StreamProvider<SyncState>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.stream;
});
