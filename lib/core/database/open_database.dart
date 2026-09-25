import 'sqlite_api.dart';

import 'open_database_stub.dart'
    if (dart.library.io) 'open_database_io.dart'
    if (dart.library.html) 'open_database_web.dart' as impl;

/// Opens the persistent app database for the current platform.
Future<CommonDatabase> openPersistentDatabase() =>
    impl.openPersistentDatabase();

/// Opens an in-memory database (tests / ephemeral sessions).
Future<CommonDatabase> openMemoryDatabase() => impl.openMemoryDatabase();
