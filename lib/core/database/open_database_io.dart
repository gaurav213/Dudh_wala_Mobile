import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'sqlite_api.dart';

Future<CommonDatabase> openPersistentDatabase() async {
  // Loads bundled SQLite on Android/iOS when the system lib is unavailable.
  await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'doodh_khata.sqlite');
  return sqlite3.open(path);
}

Future<CommonDatabase> openMemoryDatabase() async {
  await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  return sqlite3.openInMemory();
}
