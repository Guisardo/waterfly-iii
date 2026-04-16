import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/sync_conflicts.dart';

/// Type of sync conflict that occurred.
enum ConflictType {
  /// Conflict during download (server data conflicts with local).
  download,

  /// Conflict during upload (local changes conflict with server).
  upload,

  /// Concurrent modification conflict.
  concurrent,
}

/// Resolution strategy for conflicts.
enum ConflictResolution {
  /// Server version is kept, local changes are discarded.
  serverWins,

  /// Local changes were cancelled.
  localCancelled,
}

/// Resolves conflicts between local and server data.
///
/// Currently implements "server wins" strategy: server data always takes
/// precedence. Conflicts are logged for review in sync settings.
class ConflictResolver {
  final Isar isar;

  ConflictResolver(this.isar);

  Future<void> logConflict({
    required String entityType,
    required String entityId,
    required ConflictType conflictType,
    DateTime? localUpdatedAt,
    DateTime? serverUpdatedAt,
    required ConflictResolution resolution,
  }) async {
    final SyncConflicts conflict = SyncConflicts()
      ..entityType = entityType
      ..entityId = entityId
      ..conflictType = conflictType.name
      ..localUpdatedAt = localUpdatedAt
      ..serverUpdatedAt = serverUpdatedAt
      ..resolution = resolution.name
      ..timestamp = DateTime.now().toUtc();

    await isar.writeTxn(() async {
      await isar.syncConflicts.put(conflict);
    });
  }

  ConflictResolution resolveConflict({
    required DateTime? localUpdatedAt,
    required DateTime? serverUpdatedAt,
  }) {
    // Server wins if it's newer or equal (last modified wins)
    if (serverUpdatedAt == null) {
      return ConflictResolution.serverWins;
    }
    if (localUpdatedAt == null) {
      return ConflictResolution.serverWins;
    }

    if (serverUpdatedAt.isAfter(localUpdatedAt) ||
        serverUpdatedAt.isAtSameMomentAs(localUpdatedAt)) {
      return ConflictResolution.serverWins;
    }

    // Local is newer - but we still let server win for consistency
    // In a future enhancement, we could queue local changes for upload
    return ConflictResolution.serverWins;
  }

  Future<List<SyncConflicts>> getConflicts({
    String? entityType,
    int? limit,
  }) async {
    List<SyncConflicts> conflicts = entityType != null
        ? await isar.syncConflicts
              .filter()
              .entityTypeEqualTo(entityType)
              .findAll()
        : await isar.syncConflicts.where().findAll();

    // Fallback: filter in memory if MockIsar filter didn't work
    // This handles cases where MockIsar's filter has limitations
    if (entityType != null) {
      conflicts = conflicts
          .where((SyncConflicts conflict) => conflict.entityType == entityType)
          .toList();
    }

    conflicts.sort(
      (SyncConflicts a, SyncConflicts b) => b.timestamp.compareTo(a.timestamp),
    );

    if (limit != null && limit < conflicts.length) {
      return conflicts.sublist(0, limit);
    }

    return conflicts;
  }
}
