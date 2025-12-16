import 'package:drift/drift.dart';

/// Budgets table for storing Firefly III budgets locally.
@DataClassName('BudgetEntity')
class Budgets extends Table {
  /// Unique identifier (UUID) for the budget.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API, nullable for offline-created budgets.
  TextColumn get serverId => text().nullable()();

  /// Budget name.
  TextColumn get name => text()();

  /// Whether the budget is active.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Auto-budget type (e.g., 'reset', 'rollover'), nullable.
  TextColumn get autoBudgetType => text().nullable()();

  /// Auto-budget amount, nullable.
  RealColumn get autoBudgetAmount => real().nullable()();

  /// Auto-budget period (e.g., 'monthly', 'weekly'), nullable.
  TextColumn get autoBudgetPeriod => text().nullable()();

  /// Timestamp when the budget was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the budget was last updated locally.
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
  /// - Offline-created budgets that haven't been synced yet
  /// - Legacy budgets created before incremental sync was implemented
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  /// Whether the budget has been synced with the server.
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
