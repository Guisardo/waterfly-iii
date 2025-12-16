import 'package:drift/drift.dart';

/// Accounts table for storing Firefly III accounts locally.
///
/// Stores all account types: asset, expense, revenue, and liability accounts.
@DataClassName('AccountEntity')
class Accounts extends Table {
  /// Unique identifier (UUID) for the account.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API, nullable for offline-created accounts.
  TextColumn get serverId => text().nullable()();

  /// Account name.
  TextColumn get name => text()();

  /// Account type: 'asset', 'expense', 'revenue', 'liability'.
  TextColumn get type => text()();

  /// Account role (e.g., 'defaultAsset', 'savingsAsset'), nullable.
  TextColumn get accountRole => text().nullable()();

  /// Currency code for the account.
  TextColumn get currencyCode => text()();

  /// Current account balance.
  RealColumn get currentBalance => real()();

  /// IBAN number, nullable.
  TextColumn get iban => text().nullable()();

  /// BIC/SWIFT code, nullable.
  TextColumn get bic => text().nullable()();

  /// Account number, nullable.
  TextColumn get accountNumber => text().nullable()();

  /// Opening balance amount, nullable.
  RealColumn get openingBalance => real().nullable()();

  /// Opening balance date, nullable.
  DateTimeColumn get openingBalanceDate => dateTime().nullable()();

  /// Additional notes for the account, nullable.
  TextColumn get notes => text().nullable()();

  /// Whether the account is active.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Timestamp when the account was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the account was last updated locally.
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
  /// - Offline-created accounts that haven't been synced yet
  /// - Legacy accounts created before incremental sync was implemented
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  /// Whether the account has been synced with the server.
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
