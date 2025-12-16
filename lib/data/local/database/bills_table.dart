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

  /// Minimum amount for the bill (stored as 'amount_min' in API).
  RealColumn get minAmount => real()();

  /// Maximum amount for the bill (stored as 'amount_max' in API).
  RealColumn get maxAmount => real()();

  /// Currency code for the bill.
  TextColumn get currencyCode => text()();

  /// Currency symbol (e.g., '$', '€'), nullable.
  TextColumn get currencySymbol => text().nullable()();

  /// Currency decimal places.
  IntColumn get currencyDecimalPlaces => integer().nullable()();

  /// Currency ID from Firefly III.
  TextColumn get currencyId => text().nullable()();

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

  /// Next expected match date from API.
  DateTimeColumn get nextExpectedMatch => dateTime().nullable()();

  /// Order for sorting.
  IntColumn get order => integer().nullable()();

  /// Object group order for grouping.
  IntColumn get objectGroupOrder => integer().nullable()();

  /// Object group title for grouping (e.g., 'Utilities').
  TextColumn get objectGroupTitle => text().nullable()();

  /// Timestamp when the bill was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the bill was last updated locally.
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
  /// - Offline-created bills that haven't been synced yet
  /// - Legacy bills created before incremental sync was implemented
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  /// Whether the bill has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error'.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{serverId}
      ];
}
