import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';

/// Manages retry logic with exponential backoff for sync operations.
///
/// Implements exponential backoff strategy: 2^retryCount * 60 seconds,
/// capped at 1 hour. Tracks pause state and next retry time for each
/// entity type independently.
class RetryManager {
  final Isar isar;

  RetryManager(this.isar);

  /// Maximum backoff time in seconds (1 hour).
  static const int maxBackoffSeconds = 3600; // 1 hour

  /// Calculates backoff time in seconds based on retry count.
  ///
  /// Formula: 2^retryCount * 60 seconds, capped at [maxBackoffSeconds].
  /// Examples:
  /// - retryCount 0: 60 seconds (1 minute)
  /// - retryCount 1: 120 seconds (2 minutes)
  /// - retryCount 2: 240 seconds (4 minutes)
  /// - retryCount 5: 1920 seconds (32 minutes)
  /// - retryCount 6+: 3600 seconds (1 hour, max)
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

  Future<void> pauseWithBackoff(String entityType, String error) async {
    final SyncMetadata? existing = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();

    final int retryCount = (existing?.retryCount ?? 0) + 1;
    final int backoffSeconds = calculateBackoffSeconds(retryCount);
    final DateTime nextRetryAt = DateTime.now().toUtc().add(
      Duration(seconds: backoffSeconds),
    );

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

  Future<SyncMetadata?> getMetadata(String entityType) {
    return isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();
  }
}
