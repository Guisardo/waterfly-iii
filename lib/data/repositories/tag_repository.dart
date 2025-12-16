import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/config/cache_ttl_config.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/base_repository.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/models/cache/cache_result.dart';
import 'package:waterflyiii/services/uuid/uuid_service.dart';

/// Repository for managing tag data with cache-first architecture.
///
/// Handles CRUD operations for tags with full offline support and intelligent caching.
///
/// Features:
/// - **Cache-First Strategy**: Serves data from cache when fresh, fetches from database when stale
/// - **Stale-While-Revalidate**: Returns stale data immediately while refreshing in background
/// - **Search Capabilities**: Name-based tag search for autocomplete
/// - **Medium TTL**: Tags change occasionally, uses 1-hour cache TTL
/// - **Instant Autocomplete**: Provides fast local search for transaction forms
///
/// Cache Configuration:
/// - Single Tag TTL: 1 hour (CacheTtlConfig.tags)
/// - Tag List TTL: 1 hour (CacheTtlConfig.tagsList)
/// - Cache metadata stored in `cache_metadata` table
///
/// Example:
/// ```dart
/// final repository = TagRepository(
///   database: database,
///   cacheService: cacheService,
/// );
///
/// // Get all tags
/// final tags = await repository.getAll();
///
/// // Search tags for autocomplete
/// final results = await repository.search('vacation');
///
/// // Create new tag
/// final tag = await repository.create(TagEntity(...));
/// ```
///
/// Performance:
/// - Typical cache hit: <1ms response time
/// - Tags change moderately, expect >80% cache hit rate
class TagRepository extends BaseRepository<TagEntity, String> {
  /// Creates a tag repository with cache integration.
  TagRepository({
    required super.database,
    super.cacheService,
    UuidService? uuidService,
  }) : _uuidService = uuidService ?? UuidService();

  final UuidService _uuidService;

  @override
  final Logger logger = Logger('TagRepository');

  // ========================================================================
  // CACHE CONFIGURATION (Required by BaseRepository)
  // ========================================================================

  @override
  String get entityType => 'tag';

  @override
  Duration get cacheTtl => CacheTtlConfig.tags;

  @override
  Duration get collectionCacheTtl => CacheTtlConfig.tagsList;

  // ========================================================================
  // READ OPERATIONS
  // ========================================================================

  @override
  Future<List<TagEntity>> getAll() async {
    try {
      logger.fine('Fetching all tags');
      final List<TagEntity> tags = await (database.select(database.tags)
            ..orderBy(<OrderClauseGenerator<$TagsTable>>[
              ($TagsTable t) => OrderingTerm.asc(t.tag)
            ]))
          .get();
      logger.info('Retrieved ${tags.length} tags');
      return tags;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch tags', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM tags',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<List<TagEntity>> watchAll() {
    logger.fine('Watching all tags');
    return (database.select(database.tags)
          ..orderBy(<OrderClauseGenerator<$TagsTable>>[
            ($TagsTable t) => OrderingTerm.asc(t.tag)
          ]))
        .watch();
  }

  /// Retrieves a tag by ID with cache-first strategy.
  @override
  Future<TagEntity?> getById(
    String id, {
    bool forceRefresh = false,
    bool backgroundRefresh = true,
  }) async {
    logger.fine('Fetching tag by ID: $id (forceRefresh: $forceRefresh)');

    try {
      if (cacheService != null) {
        logger.finest('Using cache-first strategy for tag $id');

        final CacheResult<TagEntity?> cacheResult =
            await cacheService!.get<TagEntity?>(
          entityType: entityType,
          entityId: id,
          fetcher: () => _fetchTagFromDb(id),
          ttl: cacheTtl,
          forceRefresh: forceRefresh,
          backgroundRefresh: backgroundRefresh,
        );

        logger.info(
          'Tag fetched: $id from ${cacheResult.source} '
          '(fresh: ${cacheResult.isFresh})',
        );

        return cacheResult.data;
      }

      logger.fine('CacheService not available, using direct database query');
      return await _fetchTagFromDb(id);
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch tag $id', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM tags WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  /// Get tag by name.
  ///
  /// Tag names are unique, so this returns at most one result.
  Future<TagEntity?> getByName(String name) async {
    try {
      logger.fine('Fetching tag by name: $name');
      final TagEntity? tag = await (database.select(database.tags)
            ..where(($TagsTable t) => t.tag.equals(name)))
          .getSingleOrNull();

      if (tag != null) {
        logger.fine('Found tag: $name');
      } else {
        logger.fine('Tag not found: $name');
      }

      return tag;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch tag by name: $name', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM tags WHERE tag = $name',
        error,
        stackTrace,
      );
    }
  }

  /// Search tags by name.
  ///
  /// Used for autocomplete in transaction forms.
  /// Performs case-insensitive partial match.
  Future<List<TagEntity>> search(String query) async {
    try {
      logger.fine('Searching tags: $query');
      final String searchPattern = '%$query%';

      final List<TagEntity> tags = await (database.select(database.tags)
            ..where(($TagsTable t) => t.tag.like(searchPattern))
            ..orderBy(<OrderClauseGenerator<$TagsTable>>[
              ($TagsTable t) => OrderingTerm.asc(t.tag)
            ])
            ..limit(10))
          .get();

      logger.info('Found ${tags.length} tags matching: $query');
      return tags;
    } catch (error, stackTrace) {
      logger.severe('Failed to search tags: $query', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM tags WHERE tag LIKE %$query%',
        error,
        stackTrace,
      );
    }
  }

  Future<TagEntity?> _fetchTagFromDb(String id) async {
    try {
      logger.finest('Fetching tag from database: $id');

      final SimpleSelectStatement<$TagsTable, TagEntity> query =
          database.select(database.tags)
            ..where(($TagsTable t) => t.id.equals(id));

      final TagEntity? tag = await query.getSingleOrNull();

      if (tag != null) {
        logger.finest('Found tag in database: $id');
      } else {
        logger.fine('Tag not found in database: $id');
      }

      return tag;
    } catch (error, stackTrace) {
      logger.severe(
        'Database query failed for tag $id',
        error,
        stackTrace,
      );
      throw DatabaseException.queryFailed(
        'SELECT * FROM tags WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<TagEntity?> watchById(String id) {
    logger.fine('Watching tag: $id');
    final SimpleSelectStatement<$TagsTable, TagEntity> query =
        database.select(database.tags)
          ..where(($TagsTable t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  // ========================================================================
  // WRITE OPERATIONS
  // ========================================================================

  @override
  Future<TagEntity> create(TagEntity entity) async {
    try {
      logger.info('Creating tag: ${entity.tag}');

      final String id =
          entity.id.isEmpty ? _uuidService.generateTagId() : entity.id;
      final DateTime now = DateTime.now();
      logger.fine('Tag ID: $id');

      final TagEntityCompanion companion = TagEntityCompanion.insert(
        id: id,
        serverId: Value(entity.serverId),
        tag: entity.tag,
        description: Value(entity.description),
        date: Value(entity.date),
        latitude: Value(entity.latitude),
        longitude: Value(entity.longitude),
        zoomLevel: Value(entity.zoomLevel),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await database.into(database.tags).insert(companion);
      logger.info('Tag inserted into database: $id');

      final TagEntity? created = await _fetchTagFromDb(id);
      if (created == null) {
        final String errorMsg = 'Failed to retrieve created tag: $id';
        logger.severe(errorMsg);
        throw DatabaseException(errorMsg);
      }

      logger.info('Tag created successfully: $id');

      // Store in cache
      if (cacheService != null) {
        await cacheService!.set<TagEntity>(
          entityType: entityType,
          entityId: id,
          data: created,
          ttl: cacheTtl,
        );
        logger.fine('Tag stored in cache: $id');
      }

      return created;
    } catch (error, stackTrace) {
      logger.severe('Failed to create tag', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to create tag: $error');
    }
  }

  /// Upsert a tag from API response.
  ///
  /// Used during sync to populate local database with tags from Firefly III.
  Future<TagEntity> upsertFromApi({
    required String id,
    required String tag,
    String? serverId,
    String? description,
    DateTime? date,
    double? latitude,
    double? longitude,
    int? zoomLevel,
    DateTime? serverUpdatedAt,
  }) async {
    try {
      logger.info('Upserting tag from API: $tag');
      final DateTime now = DateTime.now();

      final TagEntityCompanion companion = TagEntityCompanion.insert(
        id: id,
        serverId: Value(serverId ?? id),
        tag: tag,
        description: Value(description),
        date: Value(date),
        latitude: Value(latitude),
        longitude: Value(longitude),
        zoomLevel: Value(zoomLevel),
        createdAt: now,
        updatedAt: now,
        serverUpdatedAt: Value(serverUpdatedAt),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      );

      await database.into(database.tags).insertOnConflictUpdate(companion);
      logger.info('Tag upserted: $tag');

      final TagEntity? result = await _fetchTagFromDb(id);
      if (result == null) {
        throw DatabaseException('Failed to retrieve upserted tag: $tag');
      }

      // Update cache
      if (cacheService != null) {
        await cacheService!.set<TagEntity>(
          entityType: entityType,
          entityId: id,
          data: result,
          ttl: cacheTtl,
        );
        logger.fine('Tag stored in cache: $tag');
      }

      return result;
    } catch (error, stackTrace) {
      logger.severe('Failed to upsert tag: $tag', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to upsert tag: $error');
    }
  }

  @override
  Future<TagEntity> update(String id, TagEntity entity) async {
    try {
      logger.info('Updating tag: $id');

      final TagEntity? existing = await _fetchTagFromDb(id);
      if (existing == null) {
        final String errorMsg = 'Tag not found: $id';
        logger.severe(errorMsg);
        throw DatabaseException(errorMsg);
      }

      final TagEntityCompanion companion = TagEntityCompanion(
        id: Value(id),
        serverId: Value(entity.serverId),
        tag: Value(entity.tag),
        description: Value(entity.description),
        date: Value(entity.date),
        latitude: Value(entity.latitude),
        longitude: Value(entity.longitude),
        zoomLevel: Value(entity.zoomLevel),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await database.update(database.tags).replace(companion);
      logger.info('Tag updated in database: $id');

      final TagEntity? updated = await _fetchTagFromDb(id);
      if (updated == null) {
        final String errorMsg = 'Failed to retrieve updated tag: $id';
        logger.severe(errorMsg);
        throw DatabaseException(errorMsg);
      }

      logger.info('Tag updated successfully: $id');

      // Update cache
      if (cacheService != null) {
        await cacheService!.set<TagEntity>(
          entityType: entityType,
          entityId: id,
          data: updated,
          ttl: cacheTtl,
        );
        logger.fine('Tag cache updated: $id');
      }

      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to update tag $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to update tag: $error');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting tag: $id');

      final TagEntity? existing = await _fetchTagFromDb(id);
      if (existing == null) {
        final String errorMsg = 'Tag not found: $id';
        logger.severe(errorMsg);
        throw DatabaseException(errorMsg);
      }

      await (database.delete(database.tags)
            ..where(($TagsTable t) => t.id.equals(id)))
          .go();
      logger.info('Tag deleted from database: $id');

      // Invalidate cache
      if (cacheService != null) {
        await cacheService!.invalidate(entityType, id);
        logger.fine('Tag cache invalidated: $id');
      }

      logger.info('Tag deleted successfully: $id');
    } catch (error, stackTrace) {
      logger.severe('Failed to delete tag $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to delete tag: $error');
    }
  }

  @override
  Future<List<TagEntity>> getUnsynced() async {
    try {
      logger.fine('Fetching unsynced tags');
      final SimpleSelectStatement<$TagsTable, TagEntity> query =
          database.select(database.tags)
            ..where(($TagsTable t) => t.isSynced.equals(false));
      final List<TagEntity> tags = await query.get();
      logger.info('Found ${tags.length} unsynced tags');
      return tags;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch unsynced tags', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM tags WHERE is_synced = false',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> markAsSynced(String localId, String serverId) async {
    try {
      logger.info('Marking tag as synced: $localId -> $serverId');

      await (database.update(database.tags)
            ..where(($TagsTable t) => t.id.equals(localId)))
          .write(
        TagEntityCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      logger.info('Tag marked as synced: $localId');
    } catch (error, stackTrace) {
      logger.severe(
          'Failed to mark tag as synced: $localId', error, stackTrace);
      throw DatabaseException('Failed to mark tag as synced: $error');
    }
  }

  @override
  Future<String> getSyncStatus(String id) async {
    try {
      final TagEntity? tag = await getById(id);
      if (tag == null) {
        throw DatabaseException('Tag not found: $id');
      }
      return tag.syncStatus;
    } catch (error, stackTrace) {
      logger.severe('Failed to get sync status for tag $id', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.warning('Clearing all tags from local database');
      await database.delete(database.tags).go();
      logger.info('Tag database cleared');
    } catch (error, stackTrace) {
      logger.severe('Failed to clear tag database', error, stackTrace);
      throw DatabaseException('Failed to clear tag database: $error');
    }
  }

  @override
  Future<int> count() async {
    try {
      logger.fine('Counting tags');
      final int count = await database
          .select(database.tags)
          .get()
          .then((List<TagEntity> list) => list.length);
      logger.fine('Tag count: $count');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count tags', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT COUNT(*) FROM tags',
        error,
        stackTrace,
      );
    }
  }
}

