import 'package:drift/drift.dart';

/// Bills table for storing Firefly III bills locally.
@DataClassName('BillEntity')
class Bills extends Table {
  /// Unique identifier (UUID) for the bill.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API, nullable for offline-created bills.
  TextColumn get serverId => text().nullable()();

  /// Bill name.
  TextColumn get name => text()();

  /// Minimum amount for the bill.
  RealColumn get amountMin => real()();

  /// Maximum amount for the bill.
  RealColumn get amountMax => real()();

  /// Currency code for the bill.
  TextColumn get currencyCode => text()();

  /// Bill date.
  DateTimeColumn get date => dateTime()();

  /// Repeat frequency (e.g., 'monthly', 'weekly').
  TextColumn get repeatFreq => text()();

  /// Number of periods to skip.
  IntColumn get skip => integer().withDefault(const Constant(0))();

  /// Whether the bill is active.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Additional notes for the bill, nullable.
  TextColumn get notes => text().nullable()();

  /// Timestamp when the bill was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the bill was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Whether the bill has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error'.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {serverId}
      ];
}
