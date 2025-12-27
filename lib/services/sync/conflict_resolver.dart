import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/sync_conflicts.dart';

enum ConflictType {
  download,
  upload,
  concurrent,
}

enum ConflictResolution {
  serverWins,
  localCancelled,
}

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
    final List<SyncConflicts> conflicts = entityType != null
        ? await isar.syncConflicts
            .filter()
            .entityTypeEqualTo(entityType)
            .findAll()
        : await isar.syncConflicts.where().findAll();
    
    conflicts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && limit < conflicts.length) {
      return conflicts.sublist(0, limit);
    }

    return conflicts;
  }
}
