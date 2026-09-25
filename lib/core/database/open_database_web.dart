import 'package:sqlite3/wasm.dart';

import 'sqlite_api.dart';

Future<CommonDatabase> openPersistentDatabase() async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final fileSystem = await IndexedDbFileSystem.open(dbName: 'doodh_khata');
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  return sqlite.open('/doodh_khata.sqlite');
}

Future<CommonDatabase> openMemoryDatabase() async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final fileSystem = InMemoryFileSystem();
  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);
  return sqlite.openInMemory();
}
