import 'dart:io';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../data/local/database/app_database.dart';
import '../../exceptions/offline_exceptions.dart';

/// Service for recovering from database and synchronization errors.
///
/// Provides capabilities for:
/// - Database integrity checking and repair
/// - Backup and restore operations
/// - Sync error recovery
/// - Graceful degradation
///
/// Example:
/// ```dart
/// final recoveryService = ErrorRecoveryService(database);
///
/// try {
///   // Attempt operation
/// } catch (e) {
///   await recoveryService.recoverFromDatabaseError();
/// }
/// ```
class ErrorRecoveryService {
  final AppDatabase _database;
  final Logger _logger = Logger('ErrorRecoveryService');

  /// Maximum number of backups to keep
  static const int maxBackups = 3;

  /// Backup file prefix
  static const String backupPrefix = 'waterfly_backup_';

  ErrorRecoveryService(this._database);

  /// Attempts to recover from a database error
  ///
  /// Recovery steps:
  /// 1. Check database integrity
  /// 2. Attempt to repair corrupted data
  /// 3. Restore from backup if repair fails
  /// 4. Reinitialize database if all else fails
  ///
  /// Returns true if recovery successful, false otherwise
  Future<bool> recoverFromDatabaseError() async {
    _logger.warning('Attempting database error recovery');

    try {
      // Step 1: Check integrity
      _logger.info('Checking database integrity');
      final integrityOk = await _checkDatabaseIntegrity();

      if (integrityOk) {
        _logger.info('Database integrity check passed');
        return true;
      }

      // Step 2: Attempt repair
      _logger.warning('Database integrity check failed, attempting repair');
      final repairSuccess = await _repairDatabase();

      if (repairSuccess) {
        _logger.info('Database repair successful');
        return true;
      }

      // Step 3: Restore from backup
      _logger.warning('Database repair failed, attempting restore from backup');
      final restoreSuccess = await _restoreFromLatestBackup();

      if (restoreSuccess) {
        _logger.info('Database restored from backup');
        return true;
      }

      // Step 4: Reinitialize database
      _logger.error('All recovery attempts failed, reinitializing database');
      await _reinitializeDatabase();

      _logger.warning('Database reinitialized - all local data lost');
      return false;
    } catch (e, stackTrace) {
      _logger.severe('Database recovery failed', e, stackTrace);
      return false;
    }
  }

  /// Attempts to recover from synchronization errors
  ///
  /// Recovery steps:
  /// 1. Identify problematic operations
  /// 2. Skip operations that consistently fail
  /// 3. Reset retry counters for transient errors
  /// 4. Notify user of unrecoverable issues
  ///
  /// Returns list of operation IDs that were skipped
  Future<List<String>> recoverFromSyncError() async {
    _logger.warning('Attempting sync error recovery');

    final skippedOperations = <String>[];

    try {
      // Find operations that have failed multiple times
      final query = _database.select(_database.syncQueueTable)
        ..where((tbl) =>
            tbl.status.equals('failed') & tbl.attempts.isBiggerOrEqualValue(5));

      final failedOperations = await query.get();

      _logger.info('Found ${failedOperations.length} permanently failed operations');

      for (final operation in failedOperations) {
        _logger.warning('Skipping permanently failed operation: ${operation.id}');

        // Mark as skipped
        final update = _database.update(_database.syncQueueTable)
          ..where((tbl) => tbl.id.equals(operation.id));

        await update.write(
          SyncQueueTableCompanion(
            status: Value('skipped'),
          ),
        );

        skippedOperations.add(operation.id);
      }

      // Reset operations with transient errors (< 3 attempts)
      final resetQuery = _database.update(_database.syncQueueTable)
        ..where((tbl) =>
            tbl.status.equals('failed') & tbl.attempts.isSmallerThanValue(3));

      final resetCount = await resetQuery.write(
        SyncQueueTableCompanion(
          status: Value('pending'),
          attempts: Value(0),
          errorMessage: Value(null),
        ),
      );

      _logger.info('Reset $resetCount operations with transient errors');

      return skippedOperations;
    } catch (e, stackTrace) {
      _logger.severe('Sync error recovery failed', e, stackTrace);
      throw SyncException(
        'Failed to recover from sync error',
        originalException: e,
      );
    }
  }

  /// Creates a backup of the current database
  ///
  /// Backups are stored in the app's documents directory with timestamps.
  /// Old backups are automatically cleaned up to maintain [maxBackups] limit.
  ///
  /// Returns the path to the backup file
  Future<String> createBackup() async {
    _logger.info('Creating database backup');

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(docsDir.path, 'backups'));

      // Create backup directory if it doesn't exist
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Generate backup filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = '$backupPrefix$timestamp.db';
      final backupPath = path.join(backupDir.path, backupFileName);

      // Get database file path
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw DatabaseException('Database file not found: $dbPath');
      }

      // Copy database file to backup location
      await dbFile.copy(backupPath);

      _logger.info('Backup created: $backupPath');

      // Clean up old backups
      await _cleanupOldBackups(backupDir);

      return backupPath;
    } catch (e, stackTrace) {
      _logger.severe('Failed to create backup', e, stackTrace);
      throw DatabaseException(
        'Failed to create database backup',
        originalException: e,
      );
    }
  }

  /// Restores database from a backup file
  ///
  /// Closes current database connection, replaces database file,
  /// and reopens connection.
  ///
  /// Returns true if restore successful
  Future<bool> restoreFromBackup(String backupPath) async {
    _logger.info('Restoring database from backup: $backupPath');

    try {
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        _logger.error('Backup file not found: $backupPath');
        return false;
      }

      // Close database connection
      await _database.close();

      // Get database file path
      final dbPath = await _getDatabasePath();

      // Replace database file with backup
      await backupFile.copy(dbPath);

      _logger.info('Database restored from backup');

      // Note: Database will be reopened on next access
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to restore from backup', e, stackTrace);
      return false;
    }
  }

  /// Lists all available backup files
  ///
  /// Returns list of backup file paths, sorted by date (newest first)
  Future<List<String>> listBackups() async {
    _logger.fine('Listing available backups');

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(docsDir.path, 'backups'));

      if (!await backupDir.exists()) {
        return [];
      }

      final backups = await backupDir
          .list()
          .where((entity) =>
              entity is File && path.basename(entity.path).startsWith(backupPrefix))
          .map((entity) => entity.path)
          .toList();

      // Sort by modification time (newest first)
      backups.sort((a, b) {
        final aFile = File(a);
        final bFile = File(b);
        return bFile.lastModifiedSync().compareTo(aFile.lastModifiedSync());
      });

      _logger.fine('Found ${backups.length} backups');
      return backups;
    } catch (e, stackTrace) {
      _logger.severe('Failed to list backups', e, stackTrace);
      return [];
    }
  }

  // Private helper methods

  Future<bool> _checkDatabaseIntegrity() async {
    try {
      // Perform basic integrity checks
      // Try to query each table
      await _database.select(_database.transactionsTable).get();
      await _database.select(_database.accountsTable).get();
      await _database.select(_database.categoriesTable).get();
      await _database.select(_database.budgetsTable).get();
      await _database.select(_database.billsTable).get();
      await _database.select(_database.piggyBanksTable).get();
      await _database.select(_database.syncQueueTable).get();
      await _database.select(_database.syncMetadataTable).get();
      await _database.select(_database.idMappingTable).get();

      return true;
    } catch (e) {
      _logger.warning('Database integrity check failed: $e');
      return false;
    }
  }

  Future<bool> _repairDatabase() async {
    try {
      // Attempt to clear corrupted data
      // This is a simplified repair - real implementation would be more sophisticated

      // Clear sync queue of corrupted entries
      await _database.delete(_database.syncQueueTable).go();

      // Verify tables are accessible
      return await _checkDatabaseIntegrity();
    } catch (e) {
      _logger.warning('Database repair failed: $e');
      return false;
    }
  }

  Future<bool> _restoreFromLatestBackup() async {
    final backups = await listBackups();

    if (backups.isEmpty) {
      _logger.warning('No backups available for restore');
      return false;
    }

    // Try each backup until one works
    for (final backupPath in backups) {
      _logger.info('Attempting restore from: $backupPath');

      if (await restoreFromBackup(backupPath)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _reinitializeDatabase() async {
    try {
      // Close database
      await _database.close();

      // Delete database file
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      _logger.info('Database file deleted, will be recreated on next access');
    } catch (e, stackTrace) {
      _logger.severe('Failed to reinitialize database', e, stackTrace);
      throw DatabaseException(
        'Failed to reinitialize database',
        originalException: e,
      );
    }
  }

  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final backups = await backupDir
          .list()
          .where((entity) =>
              entity is File && path.basename(entity.path).startsWith(backupPrefix))
          .map((entity) => File(entity.path))
          .toList();

      if (backups.length <= maxBackups) {
        return;
      }

      // Sort by modification time (oldest first)
      backups.sort((a, b) =>
          a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Delete oldest backups
      final toDelete = backups.length - maxBackups;
      for (int i = 0; i < toDelete; i++) {
        await backups[i].delete();
        _logger.fine('Deleted old backup: ${backups[i].path}');
      }

      _logger.info('Cleaned up $toDelete old backups');
    } catch (e, stackTrace) {
      _logger.warning('Failed to cleanup old backups', e, stackTrace);
      // Don't throw - this is not critical
    }
  }

  Future<String> _getDatabasePath() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return path.join(docsDir.path, 'waterfly.db');
  }
}
