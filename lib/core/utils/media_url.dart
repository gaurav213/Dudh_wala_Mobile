import '../api/api_base_url_store.dart';

/// Resolves a backend-relative media path (e.g. `/uploads/...`) against the
/// API host. Runtime base URL includes `/api/v1`, which must be stripped for
/// static upload URLs.
String? mediaUrl(String? path) {
  if (path == null) return null;
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = ApiBaseUrlStore.current.replaceFirst(
    RegExp(r'/api/v1/?$'),
    '',
  );
  final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$base$normalized';
}
