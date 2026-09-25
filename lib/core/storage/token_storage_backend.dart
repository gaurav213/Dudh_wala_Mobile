import 'token_storage_backend_stub.dart'
    if (dart.library.io) 'token_storage_backend_io.dart'
    if (dart.library.html) 'token_storage_backend_web.dart' as impl;

/// Platform token persistence (Keychain / file / memory).
abstract class TokenStorageBackend {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

TokenStorageBackend createTokenStorageBackend() =>
    impl.createTokenStorageBackend();
