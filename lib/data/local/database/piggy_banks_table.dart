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

  /// Currency ID for the piggy bank.
  TextColumn get currencyId => text().nullable()();

  /// Currency code (e.g., 'USD', 'EUR').
  TextColumn get currencyCode => text().nullable()();

  /// Currency symbol (e.g., '$', '€').
  TextColumn get currencySymbol => text().nullable()();

  /// Currency decimal places.
  IntColumn get currencyDecimalPlaces => integer().nullable()();

  /// Percentage of target amount saved.
  RealColumn get percentage => real().nullable()();

  /// Amount left to save to reach target.
  RealColumn get leftToSave => real().nullable()();

  /// Whether the piggy bank is active.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Object group ID for grouping.
  TextColumn get objectGroupId => text().nullable()();

  /// Object group order for sorting.
  IntColumn get objectGroupOrder => integer().nullable()();

  /// Object group title for display.
  TextColumn get objectGroupTitle => text().nullable()();

  /// Order for sorting piggy banks.
  IntColumn get order => integer().nullable()();

  /// Timestamp when the piggy bank was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the piggy bank was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Server's last updated timestamp for incremental sync change detection.
  ///
  /// This field stores the `updated_at` timestamp from the Firefly III API
  /// response. It is used during incremental sync to determine if the local
  /// entity needs to be updated by comparing with the server's timestamp.
  ///
  /// If server timestamp is newer, the entity is updated. If equal or older,
  /// the entity is skipped (no database write), improving sync performance.
  ///
  /// Nullable for:
  /// - Offline-created piggy banks that haven't been synced yet
  /// - Legacy piggy banks created before incremental sync was implemented
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  /// Whether the piggy bank has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error'.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{serverId},
  ];

  @override
  List<String> get customConstraints => <String>[
    'FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE',
  ];
}
