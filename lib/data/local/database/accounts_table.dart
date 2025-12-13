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

  /// Whether the account has been synced with the server.
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
