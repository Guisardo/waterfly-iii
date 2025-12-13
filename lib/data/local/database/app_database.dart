import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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
@DriftDatabase(tables: [
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

  /// Database schema version.
  ///
  /// Increment this when making schema changes and implement migration logic.
  @override
  int get schemaVersion => 1;

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
        // Example:
        // if (from < 2) {
        //   await m.addColumn(transactions, transactions.newColumn);
        // }
      },
      beforeOpen: (details) async {
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
}

/// Opens a connection to the database.
///
/// The database file is stored in the application's documents directory.
/// Returns a [LazyDatabase] that opens the connection on first access.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'waterfly_offline.db'));
    
    return NativeDatabase.createInBackground(
      file,
      logStatements: true, // Enable SQL logging in debug mode
    );
  });
}
