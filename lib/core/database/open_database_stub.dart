import 'sqlite_api.dart';

Future<CommonDatabase> openPersistentDatabase() {
  throw UnsupportedError('No SQLite backend for this platform');
}

Future<CommonDatabase> openMemoryDatabase() {
  throw UnsupportedError('No SQLite backend for this platform');
}
