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

  /// Whether the budget has been synced with the server.
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
