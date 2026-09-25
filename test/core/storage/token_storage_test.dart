import 'package:doodh_khata_mobile/core/storage/token_storage.dart';
import 'package:doodh_khata_mobile/core/storage/token_storage_backend.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryBackend implements TokenStorageBackend {
  final map = <String, String>{};

  @override
  Future<void> delete(String key) async => map.remove(key);

  @override
  Future<String?> read(String key) async => map[key];

  @override
  Future<void> write(String key, String value) async => map[key] = value;
}

void main() {
  test('hasSession is true when only refresh token is present', () async {
    final storage = TokenStorage(backend: _MemoryBackend());
    await storage.saveTokens(accessToken: '', refreshToken: 'refresh-abc');
    // Empty access is written; simulate access cleared but refresh kept.
    final backend = _MemoryBackend()..map['dk_refresh_token'] = 'refresh-abc';
    final tokens = TokenStorage(backend: backend);
    expect(await tokens.hasSession(), isTrue);
  });

  test('hasSession is false when both tokens missing', () async {
    final tokens = TokenStorage(backend: _MemoryBackend());
    expect(await tokens.hasSession(), isFalse);
  });
}
