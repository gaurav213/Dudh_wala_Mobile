import 'token_storage_backend.dart';

/// In-memory tokens for Flutter web (session-scoped).
class _MemoryTokenStorageBackend implements TokenStorageBackend {
  final Map<String, String> _values = {};

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}

TokenStorageBackend createTokenStorageBackend() => _MemoryTokenStorageBackend();
