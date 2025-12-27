import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';

class RetryManager {
  final Isar isar;

  RetryManager(this.isar);

  static const int maxBackoffSeconds = 3600; // 1 hour

  int calculateBackoffSeconds(int retryCount) {
    final int backoff = (1 << retryCount) * 60; // 2^retryCount * 60 seconds
    return backoff > maxBackoffSeconds ? maxBackoffSeconds : backoff;
  }

  Future<bool> isPaused(String entityType) async {
    final SyncMetadata? metadata = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();

    if (metadata == null || !metadata.syncPaused) {
      return false;
    }

    if (metadata.nextRetryAt == null) {
      return true;
    }

    // Check if retry time has passed
    final DateTime now = DateTime.now().toUtc();
    if (now.isAfter(metadata.nextRetryAt!)) {
      // Time to retry - reset pause state
      metadata
        ..syncPaused = false
        ..nextRetryAt = null;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });
      return false;
    }

    return true;
  }

  Future<void> pauseWithBackoff(
    String entityType,
    String error,
  ) async {
    final SyncMetadata? existing = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();

    final int retryCount = (existing?.retryCount ?? 0) + 1;
    final int backoffSeconds = calculateBackoffSeconds(retryCount);
    final DateTime nextRetryAt =
        DateTime.now().toUtc().add(Duration(seconds: backoffSeconds));

    if (existing == null) {
      final SyncMetadata metadata = SyncMetadata()
        ..entityType = entityType
        ..syncPaused = true
        ..retryCount = retryCount
        ..nextRetryAt = nextRetryAt
        ..lastError = error;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });
    } else {
      existing
        ..syncPaused = true
        ..retryCount = retryCount
        ..nextRetryAt = nextRetryAt
        ..lastError = error;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(existing);
      });
    }
  }

  Future<void> resetRetry(String entityType) async {
    final SyncMetadata? existing = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();

    if (existing != null) {
      existing
        ..syncPaused = false
        ..retryCount = 0
        ..nextRetryAt = null
        ..lastError = null;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(existing);
      });
    }
  }

  Future<SyncMetadata?> getMetadata(String entityType) async {
    return await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();
  }
}
