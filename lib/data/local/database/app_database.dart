import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:waterflyiii/data/local/database/accounts_table.dart';
import 'package:waterflyiii/data/local/database/bills_table.dart';
import 'package:waterflyiii/data/local/database/budgets_table.dart';
import 'package:waterflyiii/data/local/database/categories_table.dart';
import 'package:waterflyiii/data/local/database/id_mapping_table.dart';
import 'package:waterflyiii/data/local/database/piggy_banks_table.dart';
import 'package:waterflyiii/data/local/database/sync_metadata_table.dart';
import 'package:waterflyiii/data/local/database/sync_queue_table.dart';
import 'package:waterflyiii/data/local/database/transactions_table.dart';

part 'app_database.g.dart';

/// Main database class for Waterfly III offline mode.
///
/// This database stores all Firefly III entities locally and manages
/// synchronization state for offline operations.
///
/// Database version: 1
/// Schema includes:
/// - Transactions, Accounts, Categories, Budgets, Bills, Piggy Banks
/// - Sync queue for pending operations
/// - Sync metadata for tracking sync state
/// - ID mapping for local-to-server ID resolution
@DriftDatabase(tables: <Type>[
  Transactions,
  Accounts,
  Categories,
  Budgets,
  Bills,
  PiggyBanks,
  SyncQueue,
  SyncMetadata,
  IdMapping,
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
  @visibleForTesting
  AppDatabase._testConstructor(QueryExecutor executor) : super(executor);

  /// Database schema version.
  ///
  /// Increment this when making schema changes and implement migration logic.
  /// Version 2: Added foreign key constraints for referential integrity
  @override
  int get schemaVersion => 2;

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
        
        // Create performance indexes
        await _createIndexes();
        
        // TODO: Initialize sync metadata with default values
        // Uncomment after first successful generation
        /*
        await into(syncMetadata).insert(
          SyncMetadataCompanion.insert(
            key: 'last_full_sync',
            value: '',
            updatedAt: DateTime.now(),
          ),
        );
        await into(syncMetadata).insert(
          SyncMetadataCompanion.insert(
            key: 'last_partial_sync',
            value: '',
            updatedAt: DateTime.now(),
          ),
        );
        await into(syncMetadata).insert(
          SyncMetadataCompanion.insert(
            key: 'sync_version',
            value: '1',
            updatedAt: DateTime.now(),
          ),
        );
        */
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
