import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/services/app_mode/app_mode_manager.dart';
import 'package:waterflyiii/services/uuid/uuid_service.dart';

import 'base_repository.dart';

/// Repository for managing category data.
///
/// Handles CRUD operations for categories, automatically routing to
/// local storage or remote API based on the current app mode.
class CategoryRepository implements BaseRepository<CategoryEntity, String> {
  /// Creates a category repository.
  CategoryRepository({
    required AppDatabase database,
    AppModeManager? appModeManager,
    UuidService? uuidService,
  })  : _database = database,
        _appModeManager = appModeManager ?? AppModeManager(),
        _uuidService = uuidService ?? UuidService();

  final AppDatabase _database;
  final AppModeManager _appModeManager;
  final UuidService _uuidService;

  @override
  final Logger logger = Logger('CategoryRepository');

  @override
  Future<List<CategoryEntity>> getAll() async {
    try {
      logger.fine('Fetching all categories');
      final categories = await (_database.select(_database.categories)
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();
      logger.info('Retrieved ${categories.length} categories');
      return categories;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch categories', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM categories',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<List<CategoryEntity>> watchAll() {
    logger.fine('Watching all categories');
    return (_database.select(_database.categories)..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    try {
      logger.fine('Fetching category by ID: $id');
      final query = _database.select(_database.categories)..where((c) => c.id.equals(id));
      final category = await query.getSingleOrNull();

      if (category != null) {
        logger.fine('Found category: $id');
      } else {
        logger.fine('Category not found: $id');
      }

      return category;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch category $id', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM categories WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<CategoryEntity?> watchById(String id) {
    logger.fine('Watching category: $id');
    final query = _database.select(_database.categories)..where((c) => c.id.equals(id));
    return query.watchSingleOrNull();
  }

  @override
  Future<CategoryEntity> create(CategoryEntity entity) async {
    try {
      logger.info('Creating category');

      final id = entity.id.isEmpty ? _uuidService.generateCategoryId() : entity.id;
      final now = DateTime.now();

      final companion = CategoryEntityCompanion.insert(
        id: id,
        serverId: Value(entity.serverId),
        name: entity.name,
        notes: Value(entity.notes),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.into(_database.categories).insert(companion);

      final created = await getById(id);
      if (created == null) {
        throw DatabaseException('Failed to retrieve created category');
      }

      logger.info('Category created successfully: $id');
      return created;
    } catch (error, stackTrace) {
      logger.severe('Failed to create category', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to create category: $error');
    }
  }

  @override
  Future<CategoryEntity> update(String id, CategoryEntity entity) async {
    try {
      logger.info('Updating category: $id');

      final existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Category not found: $id');
      }

      final companion = CategoryEntityCompanion(
        id: Value(id),
        serverId: Value(entity.serverId),
        name: Value(entity.name),
        notes: Value(entity.notes),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.update(_database.categories).replace(companion);

      final updated = await getById(id);
      if (updated == null) {
        throw DatabaseException('Failed to retrieve updated category');
      }

      logger.info('Category updated successfully: $id');
      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to update category $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to update category: $error');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting category: $id');

      final existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Category not found: $id');
      }

      await (_database.delete(_database.categories)..where((c) => c.id.equals(id))).go();

      logger.info('Category deleted successfully: $id');
    } catch (error, stackTrace) {
      logger.severe('Failed to delete category $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to delete category: $error');
    }
  }

  @override
  Future<List<CategoryEntity>> getUnsynced() async {
    try {
      logger.fine('Fetching unsynced categories');
      final query = _database.select(_database.categories)
        ..where((c) => c.isSynced.equals(false));
      final categories = await query.get();
      logger.info('Found ${categories.length} unsynced categories');
      return categories;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch unsynced categories', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM categories WHERE is_synced = false',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> markAsSynced(String localId, String serverId) async {
    try {
      logger.info('Marking category as synced: $localId -> $serverId');

      await (_database.update(_database.categories)..where((c) => c.id.equals(localId))).write(
        CategoryEntityCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      logger.info('Category marked as synced: $localId');
    } catch (error, stackTrace) {
      logger.severe('Failed to mark category as synced: $localId', error, stackTrace);
      throw DatabaseException('Failed to mark category as synced: $error');
    }
  }

  @override
  Future<String> getSyncStatus(String id) async {
    try {
      final category = await getById(id);
      if (category == null) {
        throw DatabaseException('Category not found: $id');
      }
      return category.syncStatus;
    } catch (error, stackTrace) {
      logger.severe('Failed to get sync status for category $id', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.warning('Clearing all categories from cache');
      await _database.delete(_database.categories).go();
      logger.info('Category cache cleared');
    } catch (error, stackTrace) {
      logger.severe('Failed to clear category cache', error, stackTrace);
      throw DatabaseException('Failed to clear category cache: $error');
    }
  }

  @override
  Future<int> count() async {
    try {
      logger.fine('Counting categories');
      final count = await _database.select(_database.categories).get().then((list) => list.length);
      logger.fine('Category count: $count');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count categories', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT COUNT(*) FROM categories',
        error,
        stackTrace,
      );
    }
  }

  /// Search categories by name.
  Future<List<CategoryEntity>> searchByName(String query) async {
    try {
      logger.fine('Searching categories by name: $query');
      final searchQuery = _database.select(_database.categories)
        ..where((c) => c.name.like('%$query%'))
        ..orderBy([(c) => OrderingTerm.asc(c.name)]);
      final categories = await searchQuery.get();
      logger.info('Found ${categories.length} categories matching: $query');
      return categories;
    } catch (error, stackTrace) {
      logger.severe('Failed to search categories: $query', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM categories WHERE name LIKE %$query%',
        error,
        stackTrace,
      );
    }
  }

  /// Get transaction count for a category.
  Future<int> getTransactionCount(String categoryId) async {
    try {
      logger.fine('Counting transactions for category: $categoryId');
      final transactions = await (_database.select(_database.transactions)
            ..where((t) => t.categoryId.equals(categoryId)))
          .get();
      final count = transactions.length;
      logger.fine('Category $categoryId has $count transactions');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count transactions for category: $categoryId', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT COUNT(*) FROM transactions WHERE category_id = $categoryId',
        error,
        stackTrace,
      );
    }
  }
}
