import 'package:drift/drift.dart';

/// Transactions table for storing Firefly III transactions locally.
///
/// This table mirrors the Firefly III transaction structure and includes
/// additional fields for offline mode synchronization tracking.
@DataClassName('TransactionEntity')
class Transactions extends Table {
  /// Unique identifier (UUID) for the transaction.
  /// For offline-created transactions, this is a local UUID.
  /// For synced transactions, this maps to the server ID.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API.
  /// Null for transactions created offline that haven't been synced yet.
  TextColumn get serverId => text().nullable()();

  /// Transaction type: 'withdrawal', 'deposit', or 'transfer'.
  TextColumn get type => text()();

  /// Transaction date and time.
  DateTimeColumn get date => dateTime()();

  /// Transaction amount (always positive).
  RealColumn get amount => real()();

  /// Transaction description/title.
  TextColumn get description => text()();

  /// Source account ID (local or server ID).
  TextColumn get sourceAccountId => text()();

  /// Destination account ID (local or server ID).
  TextColumn get destinationAccountId => text()();

  /// Category ID (local or server ID), nullable.
  TextColumn get categoryId => text().nullable()();

  /// Budget ID (local or server ID), nullable.
  TextColumn get budgetId => text().nullable()();

  /// Currency code (e.g., 'USD', 'EUR').
  TextColumn get currencyCode => text()();

  /// Foreign amount for multi-currency transactions, nullable.
  RealColumn get foreignAmount => real().nullable()();

  /// Foreign currency code, nullable.
  TextColumn get foreignCurrencyCode => text().nullable()();

  /// Additional notes for the transaction, nullable.
  TextColumn get notes => text().nullable()();

  /// Tags as JSON array string (e.g., '["tag1","tag2"]').
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// Timestamp when the transaction was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the transaction was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Whether the transaction has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error'.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Timestamp of the last sync attempt, nullable.
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();

  /// Error message from last sync attempt, nullable.
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {serverId}
      ];
}
