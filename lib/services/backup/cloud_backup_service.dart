import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';

/// Service for backing up database to cloud storage.
///
/// Supports multiple cloud providers:
/// - Local file system (for testing)
/// - Custom cloud provider integration (extensible)
///
/// Features:
/// - Automatic scheduled backups
/// - Manual backup on demand
/// - Backup encryption
/// - Backup rotation (keep last N backups)
/// - Restore from cloud backup
/// - Backup verification
class CloudBackupService {
  CloudBackupService({
    required this.provider,
    this.maxBackups = 5,
    this.encryptionEnabled = true,
  });

  final CloudBackupProvider provider;
  final int maxBackups;
  final bool encryptionEnabled;
  final Logger _logger = Logger('CloudBackupService');

  static const String _lastBackupKey = 'last_cloud_backup';
  static const String _backupCountKey = 'cloud_backup_count';

  /// Create a backup and upload to cloud storage.
  Future<CloudBackupMetadata> createBackup({
    String? description,
    bool compress = true,
  }) async {
    try {
      _logger.info('Creating cloud backup');

      // Get database file
      final Directory dbFolder = await getApplicationDocumentsDirectory();
      final File dbFile = File(p.join(dbFolder.path, 'waterfly_offline.db'));

      if (!await dbFile.exists()) {
        throw DatabaseException('Database file not found');
      }

      // Create backup metadata
      final CloudBackupMetadata metadata = CloudBackupMetadata(
        id: _generateBackupId(),
        timestamp: DateTime.now(),
        description: description ?? 'Automatic backup',
        size: await dbFile.length(),
        compressed: compress,
        encrypted: encryptionEnabled,
      );

      // Read database file
      List<int> data = await dbFile.readAsBytes();

      // Compress if requested
      if (compress) {
        data = await _compressData(data);
        _logger.fine('Compressed backup from ${metadata.size} to ${data.length} bytes');
      }

      // Encrypt if enabled
      if (encryptionEnabled) {
        data = await _encryptData(data);
        _logger.fine('Encrypted backup data');
      }

      // Upload to cloud provider
      await provider.uploadBackup(metadata.id, data, metadata);

      // Update backup tracking
      await _updateBackupTracking(metadata);

      // Rotate old backups
      await _rotateBackups();

      _logger.info('Cloud backup created successfully: ${metadata.id}');
      return metadata;
    } catch (error, stackTrace) {
      _logger.severe('Failed to create cloud backup', error, stackTrace);
      throw DatabaseException('Failed to create cloud backup: $error');
    }
  }

  /// List all available cloud backups.
  Future<List<CloudBackupMetadata>> listBackups() async {
    try {
      return await provider.listBackups();
    } catch (error, stackTrace) {
      _logger.severe('Failed to list cloud backups', error, stackTrace);
      throw DatabaseException('Failed to list cloud backups: $error');
    }
  }

  /// Restore database from a cloud backup.
  Future<void> restoreBackup(String backupId) async {
    try {
      _logger.warning('Restoring from cloud backup: $backupId');

      // Download backup from cloud
      final CloudBackupData backupData = await provider.downloadBackup(backupId);

      // Decrypt if needed
      List<int> data = backupData.data;
      if (backupData.metadata.encrypted) {
        data = await _decryptData(data);
        _logger.fine('Decrypted backup data');
      }

      // Decompress if needed
      if (backupData.metadata.compressed) {
        data = await _decompressData(data);
        _logger.fine('Decompressed backup data');
      }

      // Verify data integrity
      if (!await _verifyBackupData(data)) {
        throw DatabaseException('Backup data verification failed');
      }

      // Get database file path
      final Directory dbFolder = await getApplicationDocumentsDirectory();
      final File dbFile = File(p.join(dbFolder.path, 'waterfly_offline.db'));

      // Create backup of current database before restoring
      final File currentBackup = File(p.join(dbFolder.path, 'waterfly_offline_pre_restore.db'));
      if (await dbFile.exists()) {
        await dbFile.copy(currentBackup.path);
        _logger.info('Created backup of current database before restore');
      }

      // Write restored data
      await dbFile.writeAsBytes(data);

      _logger.info('Successfully restored from cloud backup: $backupId');
    } catch (error, stackTrace) {
      _logger.severe('Failed to restore from cloud backup', error, stackTrace);
      throw DatabaseException('Failed to restore from cloud backup: $error');
    }
  }

  /// Delete a cloud backup.
  Future<void> deleteBackup(String backupId) async {
    try {
      await provider.deleteBackup(backupId);
      _logger.info('Deleted cloud backup: $backupId');
    } catch (error, stackTrace) {
      _logger.severe('Failed to delete cloud backup', error, stackTrace);
      throw DatabaseException('Failed to delete cloud backup: $error');
    }
  }

  /// Get the last backup timestamp.
  Future<DateTime?> getLastBackupTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_lastBackupKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Check if a backup is needed based on schedule.
  Future<bool> isBackupNeeded({Duration interval = const Duration(days: 1)}) async {
    final DateTime? lastBackup = await getLastBackupTime();
    if (lastBackup == null) return true;

    final Duration timeSinceBackup = DateTime.now().difference(lastBackup);
    return timeSinceBackup >= interval;
  }

  String _generateBackupId() {
    final DateTime now = DateTime.now();
    return 'backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> _updateBackupTracking(CloudBackupMetadata metadata) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupKey, metadata.timestamp.millisecondsSinceEpoch);

    final int count = prefs.getInt(_backupCountKey) ?? 0;
    await prefs.setInt(_backupCountKey, count + 1);
  }

  Future<void> _rotateBackups() async {
    try {
      final List<CloudBackupMetadata> backups = await listBackups();

      if (backups.length <= maxBackups) return;

      // Sort by timestamp (oldest first)
      backups.sort((CloudBackupMetadata a, CloudBackupMetadata b) => a.timestamp.compareTo(b.timestamp));

      // Delete oldest backups
      final int toDelete = backups.length - maxBackups;
      for (int i = 0; i < toDelete; i++) {
        await deleteBackup(backups[i].id);
        _logger.info('Rotated old backup: ${backups[i].id}');
      }
    } catch (error, stackTrace) {
      _logger.warning('Failed to rotate backups', error, stackTrace);
      // Don't throw - rotation failure shouldn't fail the backup
    }
  }

  Future<List<int>> _compressData(List<int> data) async {
    // Use gzip compression
    return gzip.encode(data);
  }

  Future<List<int>> _decompressData(List<int> data) async {
    // Use gzip decompression
    return gzip.decode(data);
  }

  Future<List<int>> _encryptData(List<int> data) async {
    // TODO: Implement encryption using encrypt package
    // For now, return data as-is
    // In production, use AES-256 encryption with user's encryption key
    _logger.warning('Encryption not yet implemented - storing unencrypted');
    return data;
  }

  Future<List<int>> _decryptData(List<int> data) async {
    // TODO: Implement decryption using encrypt package
    // For now, return data as-is
    _logger.warning('Decryption not yet implemented - reading unencrypted');
    return data;
  }

  Future<bool> _verifyBackupData(List<int> data) async {
    // Basic verification - check if data looks like a SQLite database
    if (data.length < 16) return false;

    // SQLite database files start with "SQLite format 3\0"
    final String header = String.fromCharCodes(data.take(15));
    return header == 'SQLite format 3';
  }
}

/// Abstract interface for cloud backup providers.
abstract class CloudBackupProvider {
  Future<void> uploadBackup(String backupId, List<int> data, CloudBackupMetadata metadata);
  Future<CloudBackupData> downloadBackup(String backupId);
  Future<List<CloudBackupMetadata>> listBackups();
  Future<void> deleteBackup(String backupId);
}

/// Local file system backup provider (for testing and local backups).
class LocalFileBackupProvider implements CloudBackupProvider {
  LocalFileBackupProvider({this.backupDirectory});

  final String? backupDirectory;
  final Logger _logger = Logger('LocalFileBackupProvider');

  Future<Directory> _getBackupDirectory() async {
    if (backupDirectory != null) {
      return Directory(backupDirectory!);
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory backupDir = Directory(p.join(appDir.path, 'cloud_backups'));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  @override
  Future<void> uploadBackup(String backupId, List<int> data, CloudBackupMetadata metadata) async {
    final Directory backupDir = await _getBackupDirectory();
    final File backupFile = File(p.join(backupDir.path, '$backupId.db'));
    final File metadataFile = File(p.join(backupDir.path, '$backupId.json'));

    await backupFile.writeAsBytes(data);
    await metadataFile.writeAsString(metadata.toJson());

    _logger.info('Uploaded backup to local storage: $backupId');
  }

  @override
  Future<CloudBackupData> downloadBackup(String backupId) async {
    final Directory backupDir = await _getBackupDirectory();
    final File backupFile = File(p.join(backupDir.path, '$backupId.db'));
    final File metadataFile = File(p.join(backupDir.path, '$backupId.json'));

    if (!await backupFile.exists()) {
      throw DatabaseException('Backup not found: $backupId');
    }

    final List<int> data = await backupFile.readAsBytes();
    final String metadataJson = await metadataFile.readAsString();
    final CloudBackupMetadata metadata = CloudBackupMetadata.fromJson(metadataJson);

    return CloudBackupData(data: data, metadata: metadata);
  }

  @override
  Future<List<CloudBackupMetadata>> listBackups() async {
    final Directory backupDir = await _getBackupDirectory();
    final List<FileSystemEntity> files = await backupDir.list().toList();

    final List<CloudBackupMetadata> backups = <CloudBackupMetadata>[];

    for (final FileSystemEntity file in files) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final String json = await file.readAsString();
          backups.add(CloudBackupMetadata.fromJson(json));
        } catch (error) {
          _logger.warning('Failed to read backup metadata: ${file.path}', error);
        }
      }
    }

    return backups;
  }

  @override
  Future<void> deleteBackup(String backupId) async {
    final Directory backupDir = await _getBackupDirectory();
    final File backupFile = File(p.join(backupDir.path, '$backupId.db'));
    final File metadataFile = File(p.join(backupDir.path, '$backupId.json'));

    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    if (await metadataFile.exists()) {
      await metadataFile.delete();
    }

    _logger.info('Deleted backup from local storage: $backupId');
  }
}

/// Metadata for a cloud backup.
class CloudBackupMetadata {
  CloudBackupMetadata({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.size,
    required this.compressed,
    required this.encrypted,
  });

  factory CloudBackupMetadata.fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json) as Map<String, dynamic>;
    return CloudBackupMetadata(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      description: map['description'] as String,
      size: map['size'] as int,
      compressed: map['compressed'] as bool,
      encrypted: map['encrypted'] as bool,
    );
  }

  final String id;
  final DateTime timestamp;
  final String description;
  final int size;
  final bool compressed;
  final bool encrypted;

  String toJson() {
    return jsonEncode({
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'size': size,
      'compressed': compressed,
      'encrypted': encrypted,
    });
  }
}

/// Data from a cloud backup.
class CloudBackupData {
  CloudBackupData({
    required this.data,
    required this.metadata,
  });

  final List<int> data;
  final CloudBackupMetadata metadata;
}
