import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waterflyiii/services/backup/cloud_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late Directory tempDir;
  late CloudBackupService backupService;
  late LocalFileBackupProvider provider;
  late Map<String, Object> prefsData;

  setUp(() async {
    // Create temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('waterfly_backup_test_');
    
    // Reset shared preferences data for each test
    prefsData = <String, Object>{};
    
    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
    
    // Mock shared_preferences
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return Map<String, Object>.from(prefsData);
        }
        if (methodCall.method == 'setInt') {
          final String key = methodCall.arguments['key'] as String;
          final int value = methodCall.arguments['value'] as int;
          prefsData[key] = value;
          return true;
        }
        if (methodCall.method == 'setString') {
          final String key = methodCall.arguments['key'] as String;
          final String value = methodCall.arguments['value'] as String;
          prefsData[key] = value;
          return true;
        }
        return null;
      },
    );
    
    provider = LocalFileBackupProvider(backupDirectory: tempDir.path);
    backupService = CloudBackupService(
      provider: provider,
      maxBackups: 3,
      encryptionEnabled: false, // Disable for testing
    );
  });

  tearDown(() async {
    // Clean up temporary directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CloudBackupService', () {
    test('should create backup successfully', () async {
      // Arrange - Create a test database file in the mocked app documents directory
      final File testDb = File(p.join(tempDir.path, 'waterfly_offline.db'));
      await testDb.create(recursive: true);
      await testDb.writeAsString('SQLite format 30test data');

      // Act
      final CloudBackupMetadata metadata = await backupService.createBackup(
        description: 'Test backup',
      );

      // Assert
      expect(metadata.description, 'Test backup');
      expect(metadata.compressed, true);
      expect(metadata.encrypted, false);
    });

    test('should list backups', () async {
      // Arrange - Create test database
      final File testDb = File(p.join(tempDir.path, 'waterfly_offline.db'));
      await testDb.create(recursive: true);
      await testDb.writeAsString('SQLite format 30test data');

      await backupService.createBackup(description: 'Backup 1');
      await Future<void>.delayed(const Duration(seconds: 1));
      await backupService.createBackup(description: 'Backup 2');

      // Act
      final List<CloudBackupMetadata> backups = await backupService.listBackups();

      // Assert
      expect(backups.length, 2);
    });

    test('should rotate old backups', () async {
      // Arrange - Create test database
      final File testDb = File(p.join(tempDir.path, 'waterfly_offline.db'));
      await testDb.create(recursive: true);
      await testDb.writeAsString('SQLite format 30test data');

      // Create more backups than maxBackups
      await backupService.createBackup(description: 'Backup 1');
      await Future<void>.delayed(const Duration(seconds: 1));
      await backupService.createBackup(description: 'Backup 2');
      await Future<void>.delayed(const Duration(seconds: 1));
      await backupService.createBackup(description: 'Backup 3');
      await Future<void>.delayed(const Duration(seconds: 1));
      await backupService.createBackup(description: 'Backup 4');

      // Act
      final List<CloudBackupMetadata> backups = await backupService.listBackups();

      // Assert - Should only keep maxBackups (3)
      expect(backups.length, 3);
    });

    test('should restore backup', () async {
      // Arrange - Create test database
      final File testDb = File(p.join(tempDir.path, 'waterfly_offline.db'));
      await testDb.create(recursive: true);
      const String originalContent = 'SQLite format 30original data';
      await testDb.writeAsString(originalContent);

      // Create backup
      final CloudBackupMetadata metadata = await backupService.createBackup();

      // Modify database
      await testDb.writeAsString('SQLite format 30modified data');

      // Act - Restore from backup
      await backupService.restoreBackup(metadata.id);

      // Assert - Database should be restored
      final String restoredContent = await testDb.readAsString();
      expect(restoredContent, originalContent);
    });

    test('should delete backup', () async {
      // Arrange
      final File testDb = File(p.join(tempDir.path, 'waterfly_offline.db'));
      await testDb.create(recursive: true);
      await testDb.writeAsString('SQLite format 30test data');

      final CloudBackupMetadata metadata = await backupService.createBackup();

      // Act
      await backupService.deleteBackup(metadata.id);

      // Assert
      final List<CloudBackupMetadata> backups = await backupService.listBackups();
      expect(backups.length, 0);
    });

    test('should track last backup time', () async {
      // Arrange
      final File testDb = File(p.join(tempDir.path, 'waterfly_offline.db'));
      await testDb.create(recursive: true);
      await testDb.writeAsString('SQLite format 30test data');

      // Act
      final DateTime beforeBackup = DateTime.now();
      await backupService.createBackup();
      final DateTime? lastBackupTime = await backupService.getLastBackupTime();

      // Assert
      expect(lastBackupTime, isNotNull);
      expect(lastBackupTime!.isAfter(beforeBackup.subtract(const Duration(seconds: 1))), true);
    });

    test('should determine if backup is needed', () async {
      // Arrange
      final File testDb = File(p.join(tempDir.path, 'waterfly_offline.db'));
      await testDb.create(recursive: true);
      await testDb.writeAsString('SQLite format 30test data');

      // Create backup
      await backupService.createBackup();

      // Act - Just backed up
      bool isNeeded = await backupService.isBackupNeeded(interval: const Duration(hours: 1));
      expect(isNeeded, false);

      // Act - Check with short interval
      isNeeded = await backupService.isBackupNeeded(interval: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      isNeeded = await backupService.isBackupNeeded(interval: const Duration(milliseconds: 1));
      expect(isNeeded, true);
    });
  });

  group('LocalFileBackupProvider', () {
    test('should upload backup', () async {
      // Arrange
      final List<int> testData = <int>[1, 2, 3, 4, 5];
      final CloudBackupMetadata metadata = CloudBackupMetadata(
        id: 'test_backup',
        timestamp: DateTime.now(),
        description: 'Test',
        size: testData.length,
        compressed: false,
        encrypted: false,
      );

      // Act
      await provider.uploadBackup('test_backup', testData, metadata);

      // Assert
      final File backupFile = File(p.join(tempDir.path, 'test_backup.db'));
      expect(await backupFile.exists(), true);
    });

    test('should download backup', () async {
      // Arrange
      final List<int> testData = <int>[1, 2, 3, 4, 5];
      final CloudBackupMetadata metadata = CloudBackupMetadata(
        id: 'test_backup',
        timestamp: DateTime.now(),
        description: 'Test',
        size: testData.length,
        compressed: false,
        encrypted: false,
      );

      await provider.uploadBackup('test_backup', testData, metadata);

      // Act
      final CloudBackupData downloadedData = await provider.downloadBackup('test_backup');

      // Assert
      expect(downloadedData.data, testData);
      expect(downloadedData.metadata.id, 'test_backup');
    });

    test('should list backups', () async {
      // Arrange
      final CloudBackupMetadata metadata1 = CloudBackupMetadata(
        id: 'backup_1',
        timestamp: DateTime.now(),
        description: 'Backup 1',
        size: 100,
        compressed: false,
        encrypted: false,
      );

      final CloudBackupMetadata metadata2 = CloudBackupMetadata(
        id: 'backup_2',
        timestamp: DateTime.now(),
        description: 'Backup 2',
        size: 200,
        compressed: false,
        encrypted: false,
      );

      await provider.uploadBackup('backup_1', <int>[1, 2, 3], metadata1);
      await provider.uploadBackup('backup_2', <int>[4, 5, 6], metadata2);

      // Act
      final List<CloudBackupMetadata> backups = await provider.listBackups();

      // Assert
      expect(backups.length, 2);
    });

    test('should delete backup', () async {
      // Arrange
      final CloudBackupMetadata metadata = CloudBackupMetadata(
        id: 'test_backup',
        timestamp: DateTime.now(),
        description: 'Test',
        size: 100,
        compressed: false,
        encrypted: false,
      );

      await provider.uploadBackup('test_backup', <int>[1, 2, 3], metadata);

      // Act
      await provider.deleteBackup('test_backup');

      // Assert
      final File backupFile = File(p.join(tempDir.path, 'test_backup.db'));
      expect(await backupFile.exists(), false);
    });
  });
}
