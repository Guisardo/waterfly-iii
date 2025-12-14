import 'package:drift/drift.dart';

/// Sync statistics table for persisting sync metrics.
@DataClassName('SyncStatisticsEntity')
class SyncStatisticsTable extends Table {
  @override
  String get tableName => 'sync_statistics';

  /// Statistic key (e.g., 'total_syncs', 'successful_syncs')
  TextColumn get key => text()();

  /// Statistic value as string (can store numbers, dates, etc.)
  TextColumn get value => text()();

  /// Last updated timestamp
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{key};
}
