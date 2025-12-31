import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/services/sync/retry_manager.dart';
import '../../helpers/test_database.dart';

void main() {
  group('RetryManager', () {
    late Isar isar;
    late RetryManager retryManager;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      retryManager = RetryManager(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('calculateBackoffSeconds returns exponential backoff', () {
      expect(retryManager.calculateBackoffSeconds(0), 60); // 2^0 * 60
      expect(retryManager.calculateBackoffSeconds(1), 120); // 2^1 * 60
      expect(retryManager.calculateBackoffSeconds(2), 240); // 2^2 * 60
      expect(retryManager.calculateBackoffSeconds(3), 480); // 2^3 * 60
      expect(retryManager.calculateBackoffSeconds(4), 960); // 2^4 * 60
    });

    test('calculateBackoffSeconds caps at maxBackoffSeconds', () {
      // After retry count 6, should cap at 3600 (1 hour)
      final int backoff = retryManager.calculateBackoffSeconds(10);
      expect(backoff, RetryManager.maxBackoffSeconds);
      expect(backoff, 3600);
    });

    test('isPaused returns false when not paused', () async {
      final bool isPaused = await retryManager.isPaused('test');
      expect(isPaused, false);
    });

    test(
      'isPaused returns true when paused and retry time not reached',
      () async {
        final DateTime now = DateTime.now().toUtc();
        final DateTime nextRetry = now.add(const Duration(hours: 1));

        final SyncMetadata metadata =
            SyncMetadata()
              ..entityType = 'test'
              ..syncPaused = true
              ..nextRetryAt = nextRetry;

        await isar.writeTxn(() async {
          await isar.syncMetadatas.put(metadata);
        });

        final bool isPaused = await retryManager.isPaused('test');
        expect(isPaused, true);
      },
    );

    test('isPaused returns false when retry time passed', () async {
      final DateTime now = DateTime.now().toUtc();
      final DateTime nextRetry = now.subtract(const Duration(hours: 1));

      final SyncMetadata metadata =
          SyncMetadata()
            ..entityType = 'test'
            ..syncPaused = true
            ..nextRetryAt = nextRetry;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });

      final bool isPaused = await retryManager.isPaused('test');
      expect(isPaused, false);

      // Verify metadata was updated
      final SyncMetadata? updated =
          await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('test')
              .findFirst();
      expect(updated, isNotNull);
      expect(updated!.syncPaused, false);
      expect(updated.nextRetryAt, isNull);
    });

    test('isPaused returns true when paused with null nextRetryAt', () async {
      final SyncMetadata metadata =
          SyncMetadata()
            ..entityType = 'test'
            ..syncPaused = true
            ..nextRetryAt = null;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });

      final bool isPaused = await retryManager.isPaused('test');
      expect(isPaused, true);
    });

    test('pauseWithBackoff creates new metadata', () async {
      await retryManager.pauseWithBackoff('test', 'Test error');

      final SyncMetadata? metadata =
          await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('test')
              .findFirst();
      expect(metadata, isNotNull);
      expect(metadata!.syncPaused, true);
      expect(metadata.retryCount, 1);
      expect(metadata.lastError, 'Test error');
      expect(metadata.nextRetryAt, isNotNull);
    });

    test('pauseWithBackoff updates existing metadata', () async {
      final SyncMetadata existing =
          SyncMetadata()
            ..entityType = 'test'
            ..syncPaused = false
            ..retryCount = 2;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(existing);
      });

      await retryManager.pauseWithBackoff('test', 'New error');

      final SyncMetadata? metadata =
          await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('test')
              .findFirst();
      expect(metadata, isNotNull);
      expect(metadata!.syncPaused, true);
      expect(metadata.retryCount, 3); // Incremented
      expect(metadata.lastError, 'New error');
    });

    test('resetRetry clears pause state', () async {
      final SyncMetadata metadata =
          SyncMetadata()
            ..entityType = 'test'
            ..syncPaused = true
            ..retryCount = 5
            ..nextRetryAt = DateTime.now().toUtc()
            ..lastError = 'Error';

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });

      await retryManager.resetRetry('test');

      final SyncMetadata? updated =
          await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('test')
              .findFirst();
      expect(updated, isNotNull);
      expect(updated!.syncPaused, false);
      expect(updated.retryCount, 0);
      expect(updated.nextRetryAt, isNull);
      expect(updated.lastError, isNull);
    });

    test('resetRetry does nothing when metadata does not exist', () async {
      await retryManager.resetRetry('nonexistent');
      // Should not throw
      expect(true, true);
    });

    test('getMetadata returns metadata when exists', () async {
      final SyncMetadata metadata =
          SyncMetadata()
            ..entityType = 'test'
            ..syncPaused = true
            ..retryCount = 3;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });

      final SyncMetadata? retrieved = await retryManager.getMetadata('test');
      expect(retrieved, isNotNull);
      expect(retrieved!.entityType, 'test');
      expect(retrieved.retryCount, 3);
    });

    test('getMetadata returns null when metadata does not exist', () async {
      final SyncMetadata? retrieved = await retryManager.getMetadata(
        'nonexistent',
      );
      expect(retrieved, isNull);
    });
  });
}
