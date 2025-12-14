import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';

/// Service for mapping between local offline IDs and server IDs.
///
/// Manages the bidirectional mapping between locally generated UUIDs
/// and server-assigned IDs after synchronization.
class IdMappingService {
  IdMappingService({required AppDatabase database}) : _database = database;

  final AppDatabase _database;
  final Logger _logger = Logger('IdMappingService');
  final Map<String, String> _localToServerCache = <String, String>{};
  final Map<String, String> _serverToLocalCache = <String, String>{};

  /// Map a local ID to a server ID.
  Future<void> mapIds(String localId, String serverId, String entityType) async {
    try {
      _logger.info('Mapping IDs: $localId -> $serverId ($entityType)');

      final DateTime now = DateTime.now();
      final IdMappingEntityCompanion companion = IdMappingEntityCompanion.insert(
        localId: localId,
        serverId: serverId,
        entityType: entityType,
        createdAt: now,
        syncedAt: now,
      );

      await _database.into(_database.idMapping).insert(
            companion,
            mode: InsertMode.insertOrReplace,
          );

      // Update caches
      _localToServerCache[localId] = serverId;
      _serverToLocalCache[serverId] = localId;

      _logger.fine('ID mapping created successfully');
    } catch (error, stackTrace) {
      _logger.severe('Failed to map IDs: $localId -> $serverId', error, stackTrace);
      throw DatabaseException('Failed to create ID mapping: $error');
    }
  }

  /// Get server ID for a local ID.
  Future<String?> getServerId(String localId) async {
    try {
      // Check cache first
      if (_localToServerCache.containsKey(localId)) {
        return _localToServerCache[localId];
      }

      _logger.fine('Looking up server ID for: $localId');
      final IdMappingEntity? mapping = await (_database.select(_database.idMapping)
            ..where(($IdMappingTable m) => m.localId.equals(localId)))
          .getSingleOrNull();

      if (mapping != null) {
        _localToServerCache[localId] = mapping.serverId;
        return mapping.serverId;
      }

      return null;
    } catch (error, stackTrace) {
      _logger.severe('Failed to get server ID for: $localId', error, stackTrace);
      throw DatabaseException.queryFailed('SELECT server_id FROM id_mapping WHERE local_id = $localId', error, stackTrace);
    }
  }

  /// Get local ID for a server ID.
  Future<String?> getLocalId(String serverId) async {
    try {
      // Check cache first
      if (_serverToLocalCache.containsKey(serverId)) {
        return _serverToLocalCache[serverId];
      }

      _logger.fine('Looking up local ID for: $serverId');
      final IdMappingEntity? mapping = await (_database.select(_database.idMapping)
            ..where(($IdMappingTable m) => m.serverId.equals(serverId)))
          .getSingleOrNull();

      if (mapping != null) {
        _serverToLocalCache[serverId] = mapping.localId;
        return mapping.localId;
      }

      return null;
    } catch (error, stackTrace) {
      _logger.severe('Failed to get local ID for: $serverId', error, stackTrace);
      throw DatabaseException.queryFailed('SELECT local_id FROM id_mapping WHERE server_id = $serverId', error, stackTrace);
    }
  }

  /// Get all mappings for an entity type.
  Future<List<IdMappingEntity>> getMappingsByType(String entityType) async {
    try {
      _logger.fine('Fetching mappings for entity type: $entityType');
      return await (_database.select(_database.idMapping)..where(($IdMappingTable m) => m.entityType.equals(entityType))).get();
    } catch (error, stackTrace) {
      _logger.severe('Failed to get mappings for type: $entityType', error, stackTrace);
      throw DatabaseException.queryFailed('SELECT * FROM id_mapping WHERE entity_type = $entityType', error, stackTrace);
    }
  }

  /// Clear all ID mappings.
  Future<void> clearAll() async {
    try {
      _logger.warning('Clearing all ID mappings');
      await _database.delete(_database.idMapping).go();
      _localToServerCache.clear();
      _serverToLocalCache.clear();
      _logger.info('All ID mappings cleared');
    } catch (error, stackTrace) {
      _logger.severe('Failed to clear ID mappings', error, stackTrace);
      throw DatabaseException('Failed to clear ID mappings: $error');
    }
  }

  /// Clear cache (keeps database intact).
  void clearCache() {
    _logger.fine('Clearing ID mapping cache');
    _localToServerCache.clear();
    _serverToLocalCache.clear();
  }
}
