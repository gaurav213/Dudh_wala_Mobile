import 'token_storage_backend.dart';

/// Tokens only — never store PII or business data here.
class TokenStorage {
  TokenStorage({TokenStorageBackend? backend})
      : _backend = backend ?? createTokenStorageBackend();

  final TokenStorageBackend _backend;

  static const _accessKey = 'dk_access_token';
  static const _refreshKey = 'dk_refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _backend.write(_accessKey, accessToken);
    await _backend.write(_refreshKey, refreshToken);
  }

  Future<String?> readAccessToken() => _backend.read(_accessKey);

  Future<String?> readRefreshToken() => _backend.read(_refreshKey);

  Future<void> clear() async {
    await _backend.delete(_accessKey);
    await _backend.delete(_refreshKey);
  }

  /// Session persistence is driven by the refresh token (Instagram-style).
  /// Access tokens may expire while the refresh token remains valid.
  Future<bool> hasSession() async {
    final refresh = await readRefreshToken();
    if (refresh != null && refresh.isNotEmpty) return true;
    final access = await readAccessToken();
    return access != null && access.isNotEmpty;
  }
}
