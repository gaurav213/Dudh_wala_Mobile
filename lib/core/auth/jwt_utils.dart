import 'dart:convert';

/// Lightweight JWT helpers (payload decode only — no signature verification).
class JwtUtils {
  JwtUtils._();

  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final json = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(json);
      return map is Map<String, dynamic> ? map : null;
    } catch (_) {
      return null;
    }
  }

  /// True when token is missing, malformed, or expires within [skew].
  static bool isExpiredOrExpiring(
    String? token, {
    Duration skew = const Duration(seconds: 60),
  }) {
    if (token == null || token.isEmpty) return true;
    if (token == 'local-access') return false;
    final payload = decodePayload(token);
    final exp = payload?['exp'];
    if (exp is! num) return true;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (exp * 1000).round(),
      isUtc: true,
    );
    return DateTime.now().toUtc().isAfter(expiresAt.subtract(skew));
  }
}
