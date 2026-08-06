import 'package:drift/drift.dart';

/// Drift table definitions for codegen (`dart run build_runner build`).
/// Runtime CRUD currently uses [AppDatabase] raw SQL so the app compiles
/// before codegen; keep these tables as the source of truth for schema.

class AppUsers extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get role => text()(); // supplier | customer
  TextColumn get syncStatus => text().withDefault(const Constant('SYNCED'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get supplierId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get address => text().nullable()();
  RealColumn get defaultRatePerLitre => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get customerId => text()();
  TextColumn get productType => text().withDefault(const Constant('milk'))();
  RealColumn get quantityLitres => real()();
  RealColumn get ratePerLitre => real()();
  TextColumn get frequency => text()(); // daily | alternate | custom
  TextColumn get deliverySlot => text().withDefault(const Constant('morning'))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Deliveries extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get customerId => text()();
  TextColumn get subscriptionId => text().nullable()();
  DateTimeColumn get deliveryDate => dateTime()();
  TextColumn get slot => text().withDefault(const Constant('morning'))();
  RealColumn get quantityLitres => real()();
  RealColumn get ratePerLitre => real()();
  RealColumn get amount => real()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending|delivered|skipped|partial
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get customerId => text()();
  TextColumn get billNumber => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get adjustments => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))(); // draft|issued|partial|paid
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class BillItems extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text()();
  TextColumn get deliveryId => text().nullable()();
  DateTimeColumn get itemDate => dateTime()();
  TextColumn get description => text()();
  RealColumn get quantityLitres => real()();
  RealColumn get ratePerLitre => real()();
  RealColumn get amount => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get customerId => text()();
  TextColumn get billId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  DateTimeColumn get paidAt => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // create|update|delete
  TextColumn get payloadJson => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
