import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../errors/app_exception.dart';

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

/// Local-first sync: write SQLite → enqueue → push/pull with single-flight + backoff.
class SyncService {
  SyncService({
    required AppDatabase db,
    required ApiClient api,
    Connectivity? connectivity,
  })  : _db = db,
        _api = api,
        _connectivity = connectivity ?? Connectivity();

  final AppDatabase _db;
  final ApiClient _api;
  final Connectivity _connectivity;

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

  Future<void> _pushQueue() async {
    final items = await _db.pendingSyncItems();
    for (final item in items) {
      final id = item['id'] as String;
      final entityType = item['entity_type'] as String;
      final operation = item['operation'] as String;
      final payload =
          jsonDecode(item['payload_json'] as String) as Map<String, dynamic>;
      final attempts = (item['attempts'] as int?) ?? 0;
      try {
        final path = '/sync/$entityType';
        if (operation == 'delete') {
          await _api.delete('$path/${payload['id']}');
        } else if (operation == 'create') {
          await _api.post(path, data: payload);
        } else {
          await _api.put('$path/${payload['id']}', data: payload);
        }
        await _db.removeSyncItem(id);
      } on NetworkException {
        // Stay queued; backoff.
        final delay = Duration(seconds: _backoffSeconds(attempts));
        await _db.markSyncFailure(
          id,
          'offline',
          DateTime.now().add(delay),
        );
        rethrow;
      } catch (e) {
        final delay = Duration(seconds: _backoffSeconds(attempts));
        await _db.markSyncFailure(id, e.toString(), DateTime.now().add(delay));
        if (attempts >= 8) {
          throw SyncException('Sync item exhausted retries: $id', cause: e);
        }
      }
    }
  }

  Future<void> _pullRemote() async {
    final since = await _db.getMetadata('last_synced_at');
    try {
      await _api.get('/sync/pull', query: {
        if (since != null) 'since': since,
      });
      // Server payload mapping is applied when API contract is finalized.
    } on AuthException {
      rethrow;
    } on NetworkException {
      // Pull is best-effort when offline.
    }
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
  );
  ref.onDispose(service.dispose);
  return service;
});

final syncStateProvider = StreamProvider<SyncState>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.stream;
});
