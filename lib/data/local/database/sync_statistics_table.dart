import 'package:drift/drift.dart';

/// Tracks per-entity-type sync statistics for incremental sync monitoring and optimization.
///
/// This table stores statistics for each entity type (transaction, account, budget,
/// category, bill, piggy_bank) to track sync performance and enable informed decisions
/// about when to use incremental vs full sync.
///
/// The statistics help measure:
/// - Sync efficiency (items skipped vs updated)
/// - Bandwidth savings from incremental sync
/// - API call reduction
/// - Sync window management
///
/// Example usage:
/// ```dart
/// // Query total bandwidth saved across all entities
/// SELECT SUM(bandwidth_saved_bytes) FROM sync_statistics;
///
/// // Query sync efficiency for transactions
/// SELECT
///   items_fetched_total,
///   items_updated_total,
///   items_skipped_total,
///   (items_skipped_total * 100.0 / items_fetched_total) AS skip_rate_percent
/// FROM sync_statistics
/// WHERE entity_type = 'transaction';
/// ```
@DataClassName('SyncStatisticsEntity')
class SyncStatistics extends Table {
  @override
  String get tableName => 'sync_statistics';

  /// Entity type identifier.
  ///
  /// Valid values: 'transaction', 'account', 'budget', 'category', 'bill', 'piggy_bank'
  TextColumn get entityType => text()();

  /// Timestamp of the last successful incremental sync for this entity type.
  ///
  /// Used to determine the start point for the next incremental sync.
  /// Always updated after a successful incremental sync completes.
  DateTimeColumn get lastIncrementalSync => dateTime()();

  /// Timestamp of the last successful full sync for this entity type.
  ///
  /// Nullable because a full sync may not have occurred yet (e.g., new install
  /// that only does incremental syncs). Used to determine if a full sync fallback
  /// is needed (when >7 days since last full sync).
  DateTimeColumn get lastFullSync => dateTime().nullable()();

  /// Total number of items fetched from the server across all incremental syncs.
  ///
  /// Cumulative counter used to calculate sync efficiency metrics.
  /// Reset when statistics are cleared.
  IntColumn get itemsFetchedTotal => integer().withDefault(const Constant(0))();

  /// Total number of items that had changes and were updated locally.
  ///
  /// Items are updated when server timestamp is newer than local timestamp.
  /// Used to calculate the update rate (itemsUpdated / itemsFetched).
  IntColumn get itemsUpdatedTotal => integer().withDefault(const Constant(0))();

  /// Total number of items that were skipped because they were unchanged.
  ///
  /// Items are skipped when local timestamp equals server timestamp.
  /// High skip rate indicates good incremental sync efficiency.
  IntColumn get itemsSkippedTotal => integer().withDefault(const Constant(0))();

  /// Estimated total bandwidth saved in bytes from incremental syncs.
  ///
  /// Calculated as: (itemsSkipped * averageEntitySize).
  /// Provides user-visible metric showing value of incremental sync.
  IntColumn get bandwidthSavedBytes =>
      integer().withDefault(const Constant(0))();

  /// Total number of API calls saved from incremental syncs.
  ///
  /// Calculated based on reduced pagination needs and cache hits.
  /// Demonstrates reduced server load from incremental sync.
  IntColumn get apiCallsSavedCount =>
      integer().withDefault(const Constant(0))();

  /// Start timestamp of the current sync window.
  ///
  /// Defines the beginning of the date range for incremental sync queries.
  /// Updated at the start of each sync based on last sync timestamp.
  DateTimeColumn get syncWindowStart => dateTime().nullable()();

  /// End timestamp of the current sync window.
  ///
  /// Defines the end of the date range for incremental sync queries.
  /// Typically set to current time when sync starts.
  DateTimeColumn get syncWindowEnd => dateTime().nullable()();

  /// Sync window duration in days.
  ///
  /// Configurable by user: 7, 14, 30, 60, or 90 days.
  /// Default: 30 days provides good balance of coverage vs performance.
  ///
  /// Shorter windows = faster syncs, less data.
  /// Longer windows = more comprehensive, catches more edge cases.
  IntColumn get syncWindowDays => integer().withDefault(const Constant(30))();

  /// Primary key is the entity type - one row per entity type.
  @override
  Set<Column> get primaryKey => <Column<Object>>{entityType};
}
