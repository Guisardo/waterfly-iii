import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:waterflyiii/data/local/database/accounts_table.dart';
import 'package:waterflyiii/data/local/database/bills_table.dart';
import 'package:waterflyiii/data/local/database/budgets_table.dart';
import 'package:waterflyiii/data/local/database/cache_metadata_table.dart';
import 'package:waterflyiii/data/local/database/categories_table.dart';
import 'package:waterflyiii/data/local/database/conflicts_table.dart';
import 'package:waterflyiii/data/local/database/currencies_table.dart';
import 'package:waterflyiii/data/local/database/error_log_table.dart';
import 'package:waterflyiii/data/local/database/id_mapping_table.dart';
import 'package:waterflyiii/data/local/database/piggy_banks_table.dart';
import 'package:waterflyiii/data/local/database/sync_metadata_table.dart';
import 'package:waterflyiii/data/local/database/sync_queue_table.dart';
import 'package:waterflyiii/data/local/database/sync_statistics_table.dart';
import 'package:waterflyiii/data/local/database/tags_table.dart';
import 'package:waterflyiii/data/local/database/transactions_table.dart';

part 'app_database.g.dart';

/// Main database class for Waterfly III offline mode.
///
/// This database stores all Firefly III entities locally and manages
/// synchronization state for offline operations.
///
/// Database version: 6
/// Schema includes:
/// - Transactions, Accounts, Categories, Budgets, Bills, Piggy Banks
/// - Sync queue for pending operations
/// - Sync metadata for tracking sync state
/// - ID mapping for local-to-server ID resolution
/// - Conflicts for storing sync conflicts
/// - Error log for tracking sync errors
/// - Cache metadata for cache-first architecture
/// - Sync statistics for incremental sync tracking
@DriftDatabase(tables: <Type>[
  Transactions,
  Accounts,
  Categories,
  Budgets,
  Bills,
  PiggyBanks,
  Currencies,
  Tags,
  SyncQueue,
  SyncMetadata,
  IdMapping,
  Conflicts,
  ErrorLog,
  SyncStatistics,
  CacheMetadataTable,
])
class AppDatabase extends _$AppDatabase {
  /// Creates a new instance of the database.
  ///
  /// The database file is stored in the application's documents directory
  /// with the name 'waterfly_offline.db'.
  AppDatabase() : super(_openConnection());

  /// Test constructor for creating database with custom executor.
  ///
  /// Used for testing with in-memory databases.
  ///
  /// Example:
  /// ```dart
  /// final database = AppDatabase.forTesting(NativeDatabase.memory());
  /// ```
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  /// Database schema version.
  ///
  /// Increment this when making schema changes and implement migration logic.
  /// Version 2: Added foreign key constraints for referential integrity
  /// Version 3: Added conflicts and error_log tables
  /// Version 4: Added sync_statistics table
  /// Version 5: Added cache_metadata table for cache-first architecture
  /// Version 6: Incremental sync support - added server_updated_at columns
  ///            and enhanced sync_statistics table schema
  /// Version 7: Added currencies and tags tables for cache-first architecture
  @override
  int get schemaVersion => 7;

  /// Database migration logic.
  ///
  /// Called when the database schema version changes. Implement migration
  /// steps here to preserve user data across updates.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Create all tables
        await m.createAll();
        
        // Create performance indexes (includes server_updated_at indexes)
        await _createIndexes();
        await _createServerUpdatedAtIndexes();
        
        // Initialize sync metadata with default values
        await into(syncMetadata).insert(
          SyncMetadataEntityCompanion.insert(
            key: 'last_full_sync',
            value: '',
            updatedAt: DateTime.now(),
          ),
        );
        await into(syncMetadata).insert(
          SyncMetadataEntityCompanion.insert(
            key: 'last_partial_sync',
            value: '',
            updatedAt: DateTime.now(),
          ),
        );
        await into(syncMetadata).insert(
          SyncMetadataEntityCompanion.insert(
            key: 'sync_version',
            value: '1',
            updatedAt: DateTime.now(),
          ),
        );
        
        // Initialize sync statistics for each entity type
        await _initializeSyncStatistics();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Implement migration logic here when schema version changes
        if (from < 2) {
          // Version 2: Foreign key constraints are added via customConstraints
          // No data migration needed, constraints will be enforced on new operations
          // Existing data integrity will be checked on startup by ReferentialIntegrityService
          await customStatement('PRAGMA foreign_keys = OFF');
          
          // Recreate tables with foreign key constraints
          // This is handled automatically by Drift when customConstraints are defined
          
          await customStatement('PRAGMA foreign_keys = ON');
        }
        
        if (from < 3) {
          // Version 3: Add conflicts and error_log tables
          await m.createTable(conflicts);
          await m.createTable(errorLog);
          
          // Create indexes for performance
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_conflicts_status ON conflicts(status)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_conflicts_entity ON conflicts(entity_type, entity_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_error_log_type ON error_log(error_type)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_error_log_entity ON error_log(entity_type, entity_id)',
          );
        }
        
        if (from < 4) {
          // Version 4: Add sync_statistics table (old schema - will be migrated in v6)
          // Note: This table was created with old schema in v4 and will be recreated in v6
          await customStatement(
            'CREATE TABLE IF NOT EXISTS sync_statistics ('
            'key TEXT PRIMARY KEY, '
            'value TEXT NOT NULL, '
            'updated_at INTEGER NOT NULL'
            ')',
          );
        }

        if (from < 5) {
          // Version 5: Add cache_metadata table for cache-first architecture
          await m.createTable(cacheMetadataTable);

          // Create performance indexes for cache operations
          // These indexes dramatically improve cache performance:
          // - Type invalidation: O(log n) instead of O(n) table scan
          // - Staleness checks: Index-covered query for freshness
          // - LRU eviction: Ordered access without full table sort
          await customStatement(
            'CREATE INDEX IF NOT EXISTS cache_by_type ON cache_metadata_table(entity_type)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS cache_by_invalidation ON cache_metadata_table(is_invalidated, cached_at)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS cache_by_staleness ON cache_metadata_table(cached_at, ttl_seconds)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS cache_by_lru ON cache_metadata_table(last_accessed_at)',
          );
        }

        if (from < 6) {
          // Version 6: Incremental sync support
          await _migrateToVersion6(m);
        }

        if (from < 7) {
          // Version 7: Add currencies and tags tables for cache-first architecture
          await _migrateToVersion7(m);
        }
      },
      beforeOpen: (OpeningDetails details) async {
        // Enable foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON');
        
        // Optimize database performance
        await customStatement('PRAGMA journal_mode = WAL');
        await customStatement('PRAGMA synchronous = NORMAL');
        await customStatement('PRAGMA temp_store = MEMORY');
        await customStatement('PRAGMA cache_size = -64000'); // 64MB cache
      },
    );
  }

  /// Closes the database connection.
  ///
  /// Should be called when the database is no longer needed to free resources.
  @override
  Future<void> close() async {
    await super.close();
  }

  /// Creates performance indexes on frequently queried columns.
  ///
  /// Indexes significantly improve query performance for:
  /// - Date range queries on transactions
  /// - Account and category filtering
  /// - Sync status queries
  /// - Queue priority ordering
  Future<void> _createIndexes() async {
    // Transactions indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_source_account ON transactions(source_account_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_dest_account ON transactions(destination_account_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_budget ON transactions(budget_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_sync_status ON transactions(is_synced, sync_status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_type_date ON transactions(type, date DESC)',
    );

    // Accounts indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounts_active ON accounts(active)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounts_sync_status ON accounts(is_synced, sync_status)',
    );

    // Categories indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_sync_status ON categories(is_synced, sync_status)',
    );

    // Budgets indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_budgets_active ON budgets(active)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_budgets_sync_status ON budgets(is_synced, sync_status)',
    );

    // Bills indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bills_active ON bills(active)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bills_date ON bills(date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bills_sync_status ON bills(is_synced, sync_status)',
    );

    // Piggy Banks indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_piggy_banks_account ON piggy_banks(account_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_piggy_banks_sync_status ON piggy_banks(is_synced, sync_status)',
    );

    // Sync Queue indexes (critical for performance)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_status_priority ON sync_queue(status, priority, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_entity ON sync_queue(entity_type, entity_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at DESC)',
    );

    // ID Mapping indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_id_mapping_server_id ON id_mapping(server_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_id_mapping_entity_type ON id_mapping(entity_type)',
    );

    // Sync Metadata indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_metadata_key ON sync_metadata(key)',
    );
  }

  /// Creates indexes on server_updated_at columns for incremental sync performance.
  ///
  /// These indexes are critical for efficiently querying entities that have
  /// been updated since the last sync.
  Future<void> _createServerUpdatedAtIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_server_updated_at '
      'ON transactions(server_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_accounts_server_updated_at '
      'ON accounts(server_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_budgets_server_updated_at '
      'ON budgets(server_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_server_updated_at '
      'ON categories(server_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bills_server_updated_at '
      'ON bills(server_updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_piggy_banks_server_updated_at '
      'ON piggy_banks(server_updated_at)',
    );
  }

  /// Migrate database from version 5 to version 6.
  ///
  /// Changes in v6:
  /// - Add `server_updated_at` column to all entity tables for incremental sync
  /// - Recreate `sync_statistics` table with enhanced schema for tracking sync performance
  /// - Add indexes on `server_updated_at` columns for performance
  /// - Backfill `server_updated_at` from existing `updated_at` fields
  /// - Initialize sync statistics for each entity type
  Future<void> _migrateToVersion6(Migrator m) async {
    final Logger log = Logger('AppDatabase.Migration');
    log.info('Starting migration to version 6 (incremental sync support)');

    try {
      // Step 1: Add server_updated_at columns to entity tables
      log.fine('Adding server_updated_at columns to entity tables');

      await customStatement(
        'ALTER TABLE transactions ADD COLUMN server_updated_at INTEGER',
      );
      await customStatement(
        'ALTER TABLE accounts ADD COLUMN server_updated_at INTEGER',
      );
      await customStatement(
        'ALTER TABLE budgets ADD COLUMN server_updated_at INTEGER',
      );
      await customStatement(
        'ALTER TABLE categories ADD COLUMN server_updated_at INTEGER',
      );
      await customStatement(
        'ALTER TABLE bills ADD COLUMN server_updated_at INTEGER',
      );
      await customStatement(
        'ALTER TABLE piggy_banks ADD COLUMN server_updated_at INTEGER',
      );

      // Step 2: Recreate sync_statistics table with new schema
      // The old table had a simple key-value structure, we need a more comprehensive one
      log.fine('Recreating sync_statistics table with enhanced schema');

      await customStatement('DROP TABLE IF EXISTS sync_statistics');
      await m.createTable(syncStatistics);

      // Step 3: Create indexes for performance on server_updated_at columns
      log.fine('Creating indexes on server_updated_at columns');
      await _createServerUpdatedAtIndexes();

      // Step 4: Backfill server_updated_at from existing updated_at field
      log.fine('Backfilling server_updated_at fields from updated_at');
      await _backfillServerUpdatedAtFields();

      // Step 5: Initialize sync statistics for each entity type
      log.fine('Initializing sync statistics');
      await _initializeSyncStatistics();

      // Step 6: Validate migration
      log.fine('Validating migration');
      await _validateMigrationToV6();

      log.info('Migration to version 6 completed successfully');
    } catch (e, stackTrace) {
      log.severe('Migration to version 6 failed', e, stackTrace);
      rethrow;
    }
  }

  /// Backfill server_updated_at fields from existing updated_at values.
  ///
  /// This ensures existing entities have a baseline timestamp for
  /// incremental sync change detection. The updated_at field contains
  /// the local timestamp which is a reasonable approximation.
  Future<void> _backfillServerUpdatedAtFields() async {
    await customStatement(
      'UPDATE transactions SET server_updated_at = updated_at '
      'WHERE server_updated_at IS NULL AND updated_at IS NOT NULL',
    );
    await customStatement(
      'UPDATE accounts SET server_updated_at = updated_at '
      'WHERE server_updated_at IS NULL AND updated_at IS NOT NULL',
    );
    await customStatement(
      'UPDATE budgets SET server_updated_at = updated_at '
      'WHERE server_updated_at IS NULL AND updated_at IS NOT NULL',
    );
    await customStatement(
      'UPDATE categories SET server_updated_at = updated_at '
      'WHERE server_updated_at IS NULL AND updated_at IS NOT NULL',
    );
    await customStatement(
      'UPDATE bills SET server_updated_at = updated_at '
      'WHERE server_updated_at IS NULL AND updated_at IS NOT NULL',
    );
    await customStatement(
      'UPDATE piggy_banks SET server_updated_at = updated_at '
      'WHERE server_updated_at IS NULL AND updated_at IS NOT NULL',
    );
  }

  /// Initialize sync statistics entries for each entity type.
  ///
  /// Creates a row for each entity type with default values.
  /// This provides a baseline for tracking incremental sync performance.
  Future<void> _initializeSyncStatistics() async {
    final List<String> entityTypes = <String>[
      'transaction',
      'account',
      'budget',
      'category',
      'bill',
      'piggy_bank',
    ];

    final DateTime now = DateTime.now();

    for (final String entityType in entityTypes) {
      await into(syncStatistics).insert(
        SyncStatisticsEntityCompanion.insert(
          entityType: entityType,
          lastIncrementalSync: now,
          lastFullSync: Value<DateTime?>(now),
          syncWindowDays: const Value<int>(30),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Validate migration to v6 by checking table existence and row counts.
  ///
  /// Throws [MigrationException] if validation fails.
  Future<void> _validateMigrationToV6() async {
    final Logger log = Logger('AppDatabase.Migration');

    // Check that sync_statistics table exists with new schema
    final QueryRow? tableExists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_statistics'",
    ).getSingleOrNull();

    if (tableExists == null) {
      throw MigrationException('sync_statistics table not created');
    }

    // Check that sync_statistics has entries for all entity types
    final List<SyncStatisticsEntity> statsCount =
        await (select(syncStatistics)..limit(10)).get();

    if (statsCount.length < 6) {
      throw MigrationException(
        'Expected 6 sync_statistics entries, found ${statsCount.length}',
      );
    }

    // Verify indexes exist
    final List<QueryRow> indexes = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='index' "
      "AND name LIKE 'idx_%_server_updated_at'",
    ).get();

    if (indexes.length < 6) {
      throw MigrationException(
        'Expected 6 server_updated_at indexes, found ${indexes.length}',
      );
    }

    // Verify server_updated_at columns exist by checking column info
    final List<String> tables = <String>[
      'transactions',
      'accounts',
      'budgets',
      'categories',
      'bills',
      'piggy_banks',
    ];

    for (final String table in tables) {
      final List<QueryRow> columns = await customSelect(
        "PRAGMA table_info($table)",
      ).get();

      final bool hasServerUpdatedAt = columns.any(
        (QueryRow col) => col.read<String>('name') == 'server_updated_at',
      );

      if (!hasServerUpdatedAt) {
        throw MigrationException(
          'Table $table missing server_updated_at column',
        );
      }
    }

    log.info('Migration validation passed: all checks successful');
  }

  /// Migrate database from version 6 to version 7.
  ///
  /// Changes in v7:
  /// - Add currencies table for local currency caching
  /// - Add tags table for local tag caching
  /// - Create indexes for performance
  Future<void> _migrateToVersion7(Migrator m) async {
    final Logger log = Logger('AppDatabase.Migration');
    log.info('Starting migration to version 7 (currencies and tags tables)');

    try {
      // Step 1: Create currencies table
      log.fine('Creating currencies table');
      await m.createTable(currencies);

      // Step 2: Create tags table
      log.fine('Creating tags table');
      await m.createTable(tags);

      // Step 3: Create indexes for performance
      log.fine('Creating indexes for currencies and tags');
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_currencies_code ON currencies(code)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_currencies_enabled ON currencies(enabled)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_currencies_default ON currencies(is_default)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_currencies_sync_status ON currencies(is_synced, sync_status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(tag)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tags_sync_status ON tags(is_synced, sync_status)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_currencies_server_updated_at '
        'ON currencies(server_updated_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_tags_server_updated_at '
        'ON tags(server_updated_at)',
      );

      // Step 4: Add sync statistics entries for new entity types
      log.fine('Adding sync statistics for currencies and tags');
      final DateTime now = DateTime.now();
      await into(syncStatistics).insert(
        SyncStatisticsEntityCompanion.insert(
          entityType: 'currency',
          lastIncrementalSync: now,
          lastFullSync: Value<DateTime?>(now),
          syncWindowDays: const Value<int>(30),
        ),
        mode: InsertMode.insertOrIgnore,
      );
      await into(syncStatistics).insert(
        SyncStatisticsEntityCompanion.insert(
          entityType: 'tag',
          lastIncrementalSync: now,
          lastFullSync: Value<DateTime?>(now),
          syncWindowDays: const Value<int>(30),
        ),
        mode: InsertMode.insertOrIgnore,
      );

      log.info('Migration to version 7 completed successfully');
    } catch (e, stackTrace) {
      log.severe('Migration to version 7 failed', e, stackTrace);
      rethrow;
    }
  }
}

/// Custom exception for database migration failures.
///
/// Thrown when migration validation fails or an unrecoverable
/// error occurs during schema migration.
class MigrationException implements Exception {
  /// Description of the migration failure.
  final String message;

  /// Creates a new migration exception with the given [message].
  MigrationException(this.message);

  @override
  String toString() => 'MigrationException: $message';
}

/// Opens a connection to the database.
///
/// The database file is stored in the application's documents directory.
/// Returns a [LazyDatabase] that opens the connection on first access.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dbFolder = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dbFolder.path, 'waterfly_offline.db'));
    
    return NativeDatabase.createInBackground(
      file,
      logStatements: true, // Enable SQL logging in debug mode
    );
  });
}
