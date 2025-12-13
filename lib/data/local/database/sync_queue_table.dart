import 'package:drift/drift.dart';

/// Sync queue table for tracking operations that need to be synchronized.
///
/// This table stores all create, update, and delete operations performed
/// while offline, ensuring they are synced when connectivity is restored.
@DataClassName('SyncQueueEntity')
class SyncQueue extends Table {
  /// Unique identifier (UUID) for the sync operation.
  TextColumn get id => text()();

  /// Entity type: 'transaction', 'account', 'category', 'budget', 'bill', 'piggy_bank'.
  TextColumn get entityType => text()();

  /// ID of the entity being synced (local ID).
  TextColumn get entityId => text()();

  /// Operation type: 'create', 'update', 'delete'.
  TextColumn get operation => text()();

  /// JSON payload containing the entity data.
  TextColumn get payload => text()();

  /// Timestamp when the operation was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Number of sync attempts made.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Timestamp of the last sync attempt, nullable.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// Status: 'pending', 'processing', 'completed', 'failed'.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Error message from last failed attempt, nullable.
  TextColumn get errorMessage => text().nullable()();

  /// Priority for sync order (0 = highest, 10 = lowest).
  IntColumn get priority => integer().withDefault(const Constant(5))();

  @override
  Set<Column> get primaryKey => {id};
}
