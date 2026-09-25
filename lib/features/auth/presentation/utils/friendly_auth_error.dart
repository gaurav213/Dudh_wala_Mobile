import '../../../../core/errors/app_exception.dart';
import '../../../../l10n/app_localizations.dart';

/// User-facing copy for auth / API failures (never raw exception dumps).
String friendlyAuthError(Object error, AppLocalizations l10n) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid credentials') || msg.contains('unauthorized')) {
      return l10n.incorrectCredentials;
    }
    if (msg.contains('blocked')) {
      return l10n.accountBlocked;
    }
    if (msg.contains('not active')) {
      return l10n.accountNotActive;
    }
    if (msg.contains('unreachable') || msg.contains('no local session')) {
      return l10n.unableToReachServer;
    }
    return _clean(error.message);
  }
  if (error is NetworkException) {
    return _clean(error.message);
  }
  if (error is AppException) {
    return _clean(error.message);
  }
  final raw = error.toString();
  if (raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('Connection refused')) {
    return l10n.unableToReachServer;
  }
  return l10n.signInFailed;
}

String _clean(String message) {
  return message
      .replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .trim();
}
