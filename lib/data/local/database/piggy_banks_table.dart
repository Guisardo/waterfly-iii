import 'package:drift/drift.dart';

/// Piggy banks table for storing Firefly III piggy banks locally.
@DataClassName('PiggyBankEntity')
class PiggyBanks extends Table {
  /// Unique identifier (UUID) for the piggy bank.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API, nullable for offline-created piggy banks.
  TextColumn get serverId => text().nullable()();

  /// Piggy bank name.
  TextColumn get name => text()();

  /// Associated account ID (local or server ID).
  TextColumn get accountId => text()();

  /// Target amount to save, nullable.
  RealColumn get targetAmount => real().nullable()();

  /// Current amount saved.
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();

  /// Start date for saving, nullable.
  DateTimeColumn get startDate => dateTime().nullable()();

  /// Target date to reach the goal, nullable.
  DateTimeColumn get targetDate => dateTime().nullable()();

  /// Additional notes for the piggy bank, nullable.
  TextColumn get notes => text().nullable()();

  /// Timestamp when the piggy bank was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the piggy bank was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Whether the piggy bank has been synced with the server.
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
