import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:drift/src/runtime/query_builder/query_builder.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';

/// Comprehensive error recovery and database repair service.
///
/// Features:
/// - Error classification and recovery strategies
/// - Database integrity checks and repairs
/// - Corrupted data detection and removal
/// - Backup creation and restoration
/// - Database reset to clean state
/// - Recovery statistics tracking
class ErrorRecoveryService {
  final Logger _logger = Logger('ErrorRecoveryService');
  final AppDatabase _database;

  static const int _maxBackups = 5;
  static const String _backupPrefix = 'waterfly_backup_';

  ErrorRecoveryService(this._database);

  /// Attempt to recover from an error using appropriate strategy.
  Future<bool> recoverFromError(Exception error) async {
    _logger.warning('Attempting error recovery: $error');

    try {
      final ErrorType errorType = _classifyError(error);
      _logger.info('Error classified as: $errorType');

      switch (errorType) {
        case ErrorType.network:
          return await _recoverFromNetworkError();
        case ErrorType.database:
          return await _recoverFromDatabaseError();
        case ErrorType.validation:
          return await _recoverFromValidationError();
        case ErrorType.sync:
          return await _recoverFromSyncError();
        case ErrorType.unknown:
          _logger.warning('Unknown error type, no recovery strategy available');
          return false;
      }
    } catch (e, stackTrace) {
      _logger.severe('Error recovery failed', e, stackTrace);
      return false;
    }
  }

  /// Repair database integrity issues.
  Future<void> repairDatabase() async {
    _logger.info('Starting database repair');

    try {
      // Run integrity check
      _logger.info('Running PRAGMA integrity_check');
      final List<QueryRow> integrityResult =
          await _database.customSelect('PRAGMA integrity_check').get();
      _logger.info('Integrity check result: $integrityResult');

      if (integrityResult.isNotEmpty &&
          integrityResult.first.data['integrity_check'] != 'ok') {
        _logger.warning('Database integrity issues detected');
      }

      // Rebuild indexes
      _logger.info('Rebuilding indexes');
      await _database.customStatement('REINDEX');

      // Vacuum database
      _logger.info('Vacuuming database');
      await _database.customStatement('VACUUM');

      // Optimize database
      _logger.info('Optimizing database');
      await _database.customStatement('PRAGMA optimize');

      _logger.info('Database repair completed successfully');
    } catch (e, stackTrace) {
      _logger.severe('Database repair failed', e, stackTrace);
      rethrow;
    }
  }

  /// Clear corrupted data from database.
  Future<void> clearCorruptedData() async {
    _logger.info('Clearing corrupted data');

    try {
      // Find and remove records with NULL required fields using Drift's customStatement
      _logger.info('Removing records with NULL required fields');

      await _database.customStatement(
        'DELETE FROM transactions WHERE description IS NULL OR amount IS NULL',
      );
      await _database.customStatement(
        'DELETE FROM accounts WHERE name IS NULL',
      );
      await _database.customStatement(
        'DELETE FROM categories WHERE name IS NULL',
      );

      _logger.info('Corrupted data cleared successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear corrupted data', e, stackTrace);
      rethrow;
    }
  }

  /// Create a backup of the current database.
  Future<String> createBackup() async {
    _logger.info('Creating database backup');

    try {
      final String dbPath = await _getDatabasePath();
      final Directory backupDir = await _getBackupDirectory();
      final String timestamp = DateTime.now().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final String backupName = '$_backupPrefix$timestamp.db.gz';
      final String backupPath = path.join(backupDir.path, backupName);

      // Copy and compress database file
      final File dbFile = File(dbPath);
      final Uint8List bytes = await dbFile.readAsBytes();
      final List<int> compressed = const GZipEncoder().encode(bytes);

      final File backupFile = File(backupPath);
      await backupFile.writeAsBytes(compressed);

      _logger.info('Backup created: $backupPath');

      // Rotate old backups
      await _rotateBackups(backupDir);

      return backupPath;
    } catch (e, stackTrace) {
      _logger.severe('Failed to create backup', e, stackTrace);
      rethrow;
    }
  }

  /// Restore database from backup.
  Future<void> restoreFromBackup(String backupPath) async {
    _logger.info('Restoring database from backup: $backupPath');

    try {
      final String dbPath = await _getDatabasePath();

      // Close database connection
      await _database.close();

      // Read and decompress backup
      final File backupFile = File(backupPath);
      final Uint8List compressed = await backupFile.readAsBytes();
      final Uint8List decompressed = const GZipDecoder().decodeBytes(
        compressed,
      );

      // Restore database file
      final File dbFile = File(dbPath);
      await dbFile.writeAsBytes(decompressed);

      _logger.info('Database restored successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to restore backup', e, stackTrace);
      rethrow;
    }
  }

  /// List available backups.
  Future<List<File>> listBackups() async {
    try {
      final Directory backupDir = await _getBackupDirectory();
      final List<FileSystemEntity> files = await backupDir.list().toList();

      final List<File> backups =
          files
              .whereType<File>()
              .where(
                (File f) => path.basename(f.path).startsWith(_backupPrefix),
              )
              .toList();

      backups.sort(
        (File a, File b) => b.path.compareTo(a.path),
      ); // Newest first

      return backups;
    } catch (e, stackTrace) {
      _logger.warning('Failed to list backups', e, stackTrace);
      return <File>[];
    }
  }

  /// Delete a specific backup.
  Future<void> deleteBackup(String backupPath) async {
    try {
      final File file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        _logger.info('Backup deleted: $backupPath');
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to delete backup: $backupPath', e, stackTrace);
    }
  }

  /// Reset database to clean state (delete all data).
  Future<void> resetToClean() async {
    _logger.warning('Resetting database to clean state');

    try {
      // Delete all data from tables using Drift's delete methods
      await _database.delete(_database.transactions).go();
      await _database.delete(_database.accounts).go();
      await _database.delete(_database.categories).go();
      await _database.delete(_database.budgets).go();
      await _database.delete(_database.bills).go();
      await _database.delete(_database.piggyBanks).go();
      await _database.delete(_database.syncQueue).go();
      await _database.delete(_database.syncMetadata).go();

      _logger.info('Database reset to clean state');
    } catch (e, stackTrace) {
      _logger.severe('Failed to reset database', e, stackTrace);
      rethrow;
    }
  }

  // Private helper methods

  ErrorType _classifyError(Exception error) {
    final String errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return ErrorType.network;
    } else if (errorString.contains('database') ||
        errorString.contains('sql') ||
        errorString.contains('sqlite')) {
      return ErrorType.database;
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid')) {
      return ErrorType.validation;
    } else if (errorString.contains('sync') ||
        errorString.contains('conflict')) {
      return ErrorType.sync;
    }

    return ErrorType.unknown;
  }

  Future<bool> _recoverFromNetworkError() async {
    _logger.info('Recovering from network error: retry with backoff');
    // Network errors are typically transient, caller should retry
    return true;
  }

  Future<bool> _recoverFromDatabaseError() async {
    _logger.info('Recovering from database error: repair and retry');
    await repairDatabase();
    return true;
  }

  Future<bool> _recoverFromValidationError() async {
    _logger.info('Recovering from validation error: skip and log');
    // Validation errors should be logged but not block operation
    return false;
  }

  Future<bool> _recoverFromSyncError() async {
    _logger.info('Recovering from sync error: reset sync state');
    // Sync errors may require resetting sync metadata
    return true;
  }

  Future<Directory> _getBackupDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory backupDir = Directory(path.join(appDir.path, 'backups'));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  /// Get the database file path.
  Future<String> _getDatabasePath() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'waterfly_offline.db');
  }

  Future<void> _rotateBackups(Directory backupDir) async {
    try {
      final List<File> backups = await listBackups();

      if (backups.length > _maxBackups) {
        _logger.info('Rotating old backups (keeping last $_maxBackups)');

        for (int i = _maxBackups; i < backups.length; i++) {
          await backups[i].delete();
          _logger.info('Deleted old backup: ${backups[i].path}');
        }
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to rotate backups', e, stackTrace);
    }
  }
}

/// Error type classification for recovery strategies.
enum ErrorType { network, database, validation, sync, unknown }
