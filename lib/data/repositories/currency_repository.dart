import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/config/cache_ttl_config.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/base_repository.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/models/cache/cache_result.dart';

/// Repository for managing currency data with cache-first architecture.
///
/// Handles read operations for currencies with intelligent caching.
/// Currencies are read-only in the app (managed via Firefly III web interface).
///
/// Features:
/// - **Cache-First Strategy**: Serves data from cache when fresh, fetches from database when stale
/// - **Stale-While-Revalidate**: Returns stale data immediately while refreshing in background
/// - **Long TTL**: Currencies rarely change, uses 24-hour cache TTL
/// - **Instant Autocomplete**: Provides fast local search for transaction forms
/// - **Default Currency**: Quick access to the default currency
///
/// Cache Configuration:
/// - Single Currency TTL: 24 hours (CacheTtlConfig.currencies)
/// - Currency List TTL: 24 hours (CacheTtlConfig.currenciesList)
/// - Cache metadata stored in `cache_metadata` table
///
/// Example:
/// ```dart
/// final repository = CurrencyRepository(
///   database: database,
///   cacheService: cacheService,
/// );
///
/// // Get all enabled currencies for dropdowns
/// final currencies = await repository.getAllEnabled();
///
/// // Get default currency
/// final defaultCurrency = await repository.getDefault();
///
/// // Search currencies by code or name
/// final results = await repository.search('USD');
/// ```
///
/// Performance:
/// - Typical cache hit: <1ms response time
/// - Currencies change extremely rarely, expect >95% cache hit rate
class CurrencyRepository extends BaseRepository<CurrencyEntity, String> {
  /// Creates a currency repository with cache integration.
  CurrencyRepository({
    required super.database,
    super.cacheService,
  });

  @override
  final Logger logger = Logger('CurrencyRepository');

  // ========================================================================
  // CACHE CONFIGURATION (Required by BaseRepository)
  // ========================================================================

  @override
  String get entityType => 'currency';

  @override
  Duration get cacheTtl => CacheTtlConfig.currencies;

  @override
  Duration get collectionCacheTtl => CacheTtlConfig.currenciesList;

  // ========================================================================
  // READ OPERATIONS
  // ========================================================================

  @override
  Future<List<CurrencyEntity>> getAll() async {
    try {
      logger.fine('Fetching all currencies');
      final List<CurrencyEntity> currencies = await (database
              .select(database.currencies)
            ..orderBy(<OrderClauseGenerator<$CurrenciesTable>>[
              ($CurrenciesTable c) => OrderingTerm.asc(c.code)
            ]))
          .get();
      logger.info('Retrieved ${currencies.length} currencies');
      return currencies;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch currencies', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM currencies',
        error,
        stackTrace,
      );
    }
  }

  /// Get all enabled currencies for dropdowns.
  ///
  /// Returns only currencies that are enabled in Firefly III.
  /// Cached with 24-hour TTL.
  Future<List<CurrencyEntity>> getAllEnabled() async {
    try {
      logger.fine('Fetching enabled currencies');
      final List<CurrencyEntity> currencies = await (database
              .select(database.currencies)
            ..where(($CurrenciesTable c) => c.enabled.equals(true))
            ..orderBy(<OrderClauseGenerator<$CurrenciesTable>>[
              ($CurrenciesTable c) => OrderingTerm.asc(c.code)
            ]))
          .get();
      logger.info('Retrieved ${currencies.length} enabled currencies');
      return currencies;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch enabled currencies', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM currencies WHERE enabled = true',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<List<CurrencyEntity>> watchAll() {
    logger.fine('Watching all currencies');
    return (database.select(database.currencies)
          ..orderBy(<OrderClauseGenerator<$CurrenciesTable>>[
            ($CurrenciesTable c) => OrderingTerm.asc(c.code)
          ]))
        .watch();
  }

  /// Retrieves a currency by ID with cache-first strategy.
  @override
  Future<CurrencyEntity?> getById(
    String id, {
    bool forceRefresh = false,
    bool backgroundRefresh = true,
  }) async {
    logger.fine('Fetching currency by ID: $id (forceRefresh: $forceRefresh)');

    try {
      if (cacheService != null) {
        logger.finest('Using cache-first strategy for currency $id');

        final CacheResult<CurrencyEntity?> cacheResult =
            await cacheService!.get<CurrencyEntity?>(
          entityType: entityType,
          entityId: id,
          fetcher: () => _fetchCurrencyFromDb(id),
          ttl: cacheTtl,
          forceRefresh: forceRefresh,
          backgroundRefresh: backgroundRefresh,
        );

        logger.info(
          'Currency fetched: $id from ${cacheResult.source} '
          '(fresh: ${cacheResult.isFresh})',
        );

        return cacheResult.data;
      }

      logger.fine('CacheService not available, using direct database query');
      return await _fetchCurrencyFromDb(id);
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch currency $id', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM currencies WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  /// Get currency by ISO code (e.g., 'USD', 'EUR').
  ///
  /// This is the primary lookup method since currency codes are
  /// more commonly used than internal IDs.
  Future<CurrencyEntity?> getByCode(String code) async {
    try {
      logger.fine('Fetching currency by code: $code');
      final CurrencyEntity? currency = await (database
              .select(database.currencies)
            ..where(($CurrenciesTable c) => c.code.equals(code.toUpperCase())))
          .getSingleOrNull();

      if (currency != null) {
        logger.fine('Found currency: $code');
      } else {
        logger.fine('Currency not found: $code');
      }

      return currency;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch currency by code: $code', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM currencies WHERE code = $code',
        error,
        stackTrace,
      );
    }
  }

  /// Get the default currency for the Firefly III instance.
  ///
  /// Returns the currency marked as default, or null if none set.
  Future<CurrencyEntity?> getDefault() async {
    try {
      logger.fine('Fetching default currency');
      final CurrencyEntity? currency = await (database
              .select(database.currencies)
            ..where(($CurrenciesTable c) => c.isDefault.equals(true)))
          .getSingleOrNull();

      if (currency != null) {
        logger.fine('Found default currency: ${currency.code}');
      } else {
        logger.fine('No default currency set');
      }

      return currency;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch default currency', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM currencies WHERE is_default = true',
        error,
        stackTrace,
      );
    }
  }

  /// Search currencies by code or name.
  ///
  /// Used for autocomplete in transaction forms.
  /// Searches both code and name fields.
  Future<List<CurrencyEntity>> search(String query) async {
    try {
      logger.fine('Searching currencies: $query');
      final String searchPattern = '%${query.toUpperCase()}%';

      final List<CurrencyEntity> currencies = await (database
              .select(database.currencies)
            ..where(($CurrenciesTable c) =>
                c.code.like(searchPattern) |
                c.name.upper().like(searchPattern))
            ..where(($CurrenciesTable c) => c.enabled.equals(true))
            ..orderBy(<OrderClauseGenerator<$CurrenciesTable>>[
              ($CurrenciesTable c) => OrderingTerm.asc(c.code)
            ])
            ..limit(10))
          .get();

      logger.info('Found ${currencies.length} currencies matching: $query');
      return currencies;
    } catch (error, stackTrace) {
      logger.severe('Failed to search currencies: $query', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM currencies WHERE code LIKE %$query%',
        error,
        stackTrace,
      );
    }
  }

  Future<CurrencyEntity?> _fetchCurrencyFromDb(String id) async {
    try {
      logger.finest('Fetching currency from database: $id');

      final SimpleSelectStatement<$CurrenciesTable, CurrencyEntity> query =
          database.select(database.currencies)
            ..where(($CurrenciesTable c) => c.id.equals(id));

      final CurrencyEntity? currency = await query.getSingleOrNull();

      if (currency != null) {
        logger.finest('Found currency in database: $id');
      } else {
        logger.fine('Currency not found in database: $id');
      }

      return currency;
    } catch (error, stackTrace) {
      logger.severe(
        'Database query failed for currency $id',
        error,
        stackTrace,
      );
      throw DatabaseException.queryFailed(
        'SELECT * FROM currencies WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<CurrencyEntity?> watchById(String id) {
    logger.fine('Watching currency: $id');
    final SimpleSelectStatement<$CurrenciesTable, CurrencyEntity> query =
        database.select(database.currencies)
          ..where(($CurrenciesTable c) => c.id.equals(id));
    return query.watchSingleOrNull();
  }

  // ========================================================================
  // WRITE OPERATIONS (Currencies are typically read-only in the app)
  // ========================================================================

  /// Upsert a currency from API response.
  ///
  /// Used during sync to populate local database with currencies from Firefly III.
  /// This is the primary write operation - currencies are managed in the web UI.
  Future<CurrencyEntity> upsertFromApi({
    required String id,
    required String code,
    required String name,
    required String symbol,
    required int decimalPlaces,
    required bool enabled,
    required bool isDefault,
    String? serverId,
    DateTime? serverUpdatedAt,
  }) async {
    try {
      logger.info('Upserting currency from API: $code');
      final DateTime now = DateTime.now();

      final CurrencyEntityCompanion companion = CurrencyEntityCompanion.insert(
        id: id,
        serverId: Value(serverId ?? id),
        code: code,
        name: name,
        symbol: symbol,
        decimalPlaces: Value(decimalPlaces),
        enabled: Value(enabled),
        isDefault: Value(isDefault),
        createdAt: now,
        updatedAt: now,
        serverUpdatedAt: Value(serverUpdatedAt),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      );

      await database
          .into(database.currencies)
          .insertOnConflictUpdate(companion);
      logger.info('Currency upserted: $code');

      final CurrencyEntity? result = await _fetchCurrencyFromDb(id);
      if (result == null) {
        throw DatabaseException('Failed to retrieve upserted currency: $code');
      }

      // Update cache
      if (cacheService != null) {
        await cacheService!.set<CurrencyEntity>(
          entityType: entityType,
          entityId: id,
          data: result,
          ttl: cacheTtl,
        );
        logger.fine('Currency stored in cache: $code');
      }

      return result;
    } catch (error, stackTrace) {
      logger.severe('Failed to upsert currency: $code', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to upsert currency: $error');
    }
  }

  @override
  Future<CurrencyEntity> create(CurrencyEntity entity) async {
    // Currencies should be created via upsertFromApi during sync
    throw UnimplementedError(
      'Currencies cannot be created locally. Use upsertFromApi() during sync.',
    );
  }

  @override
  Future<CurrencyEntity> update(String id, CurrencyEntity entity) async {
    // Currencies should be updated via upsertFromApi during sync
    throw UnimplementedError(
      'Currencies cannot be updated locally. Use upsertFromApi() during sync.',
    );
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting currency: $id');

      await (database.delete(database.currencies)
            ..where(($CurrenciesTable c) => c.id.equals(id)))
          .go();

      if (cacheService != null) {
        await cacheService!.invalidate(entityType, id);
        logger.fine('Currency cache invalidated: $id');
      }

      logger.info('Currency deleted: $id');
    } catch (error, stackTrace) {
      logger.severe('Failed to delete currency: $id', error, stackTrace);
      throw DatabaseException('Failed to delete currency: $error');
    }
  }

  @override
  Future<List<CurrencyEntity>> getUnsynced() async {
    // Currencies are read-only, always synced from server
    return <CurrencyEntity>[];
  }

  @override
  Future<void> markAsSynced(String localId, String serverId) async {
    // Currencies are always synced from server
    logger.fine('Currency $localId is already synced (read-only entity)');
  }

  @override
  Future<String> getSyncStatus(String id) async {
    final CurrencyEntity? currency = await getById(id);
    if (currency == null) {
      throw DatabaseException('Currency not found: $id');
    }
    return currency.syncStatus;
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.warning('Clearing all currencies from local database');
      await database.delete(database.currencies).go();
      logger.info('Currency database cleared');
    } catch (error, stackTrace) {
      logger.severe('Failed to clear currency database', error, stackTrace);
      throw DatabaseException('Failed to clear currency database: $error');
    }
  }

  @override
  Future<int> count() async {
    try {
      logger.fine('Counting currencies');
      final int count = await database
          .select(database.currencies)
          .get()
          .then((List<CurrencyEntity> list) => list.length);
      logger.fine('Currency count: $count');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count currencies', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT COUNT(*) FROM currencies',
        error,
        stackTrace,
      );
    }
  }
}

