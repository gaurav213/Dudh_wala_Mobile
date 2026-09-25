import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'token_storage_backend.dart';

bool get _useFileBackend {
  // Sandboxed macOS desktop builds hit Keychain errSecMissingEntitlement (-34018)
  // without a signed keychain-access-groups entitlement. Prefer a local file.
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

class _FileTokenStorageBackend implements TokenStorageBackend {
  Future<File> _fileFor(String key) async {
    final dir = await getApplicationSupportDirectory();
    final safe = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File(p.join(dir.path, 'tokens', '$safe.tok'));
  }

  @override
  Future<void> write(String key, String value) async {
    final file = await _fileFor(key);
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  @override
  Future<String?> read(String key) async {
    final file = await _fileFor(key);
    if (!await file.exists()) return null;
    final value = await file.readAsString();
    return value.isEmpty ? null : value;
  }

  @override
  Future<void> delete(String key) async {
    final file = await _fileFor(key);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class _SecureTokenStorageBackend implements TokenStorageBackend {
  _SecureTokenStorageBackend()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

TokenStorageBackend createTokenStorageBackend() {
  if (_useFileBackend) return _FileTokenStorageBackend();
  return _SecureTokenStorageBackend();
}
