import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/services/app_mode/app_mode_manager.dart';
import 'package:waterflyiii/services/uuid/uuid_service.dart';

import 'base_repository.dart';

/// Repository for managing account data.
///
/// Handles CRUD operations for accounts, automatically routing to
/// local storage or remote API based on the current app mode.
class AccountRepository implements BaseRepository<AccountEntity, String> {
  /// Creates an account repository.
  AccountRepository({
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
  final Logger logger = Logger('AccountRepository');

  @override
  Future<List<AccountEntity>> getAll() async {
    try {
      logger.fine('Fetching all accounts');
      final accounts = await _database.select(_database.accounts).get();
      logger.info('Retrieved ${accounts.length} accounts');
      return accounts;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch accounts', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM accounts',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<List<AccountEntity>> watchAll() {
    logger.fine('Watching all accounts');
    return _database.select(_database.accounts).watch();
  }

  @override
  Future<AccountEntity?> getById(String id) async {
    try {
      logger.fine('Fetching account by ID: $id');
      final query = _database.select(_database.accounts)
        ..where((a) => a.id.equals(id));
      final account = await query.getSingleOrNull();

      if (account != null) {
        logger.fine('Found account: $id');
      } else {
        logger.fine('Account not found: $id');
      }

      return account;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch account $id', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM accounts WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<AccountEntity?> watchById(String id) {
    logger.fine('Watching account: $id');
    final query = _database.select(_database.accounts)
      ..where((a) => a.id.equals(id));
    return query.watchSingleOrNull();
  }

  @override
  Future<AccountEntity> create(AccountEntity entity) async {
    try {
      logger.info('Creating account');

      final id = entity.id.isEmpty ? _uuidService.generateAccountId() : entity.id;
      final now = DateTime.now();

      final companion = AccountEntityCompanion.insert(
        id: id,
        serverId: Value(entity.serverId),
        name: entity.name,
        type: entity.type,
        accountRole: Value(entity.accountRole),
        currencyCode: entity.currencyCode,
        currentBalance: entity.currentBalance,
        iban: Value(entity.iban),
        bic: Value(entity.bic),
        accountNumber: Value(entity.accountNumber),
        openingBalance: Value(entity.openingBalance),
        openingBalanceDate: Value(entity.openingBalanceDate),
        notes: Value(entity.notes),
        active: Value(entity.active),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.into(_database.accounts).insert(companion);

      final created = await getById(id);
      if (created == null) {
        throw DatabaseException('Failed to retrieve created account');
      }

      logger.info('Account created successfully: $id');
      return created;
    } catch (error, stackTrace) {
      logger.severe('Failed to create account', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to create account: $error');
    }
  }

  @override
  Future<AccountEntity> update(String id, AccountEntity entity) async {
    try {
      logger.info('Updating account: $id');

      final existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Account not found: $id');
      }

      final companion = AccountEntityCompanion(
        id: Value(id),
        serverId: Value(entity.serverId),
        name: Value(entity.name),
        type: Value(entity.type),
        accountRole: Value(entity.accountRole),
        currencyCode: Value(entity.currencyCode),
        currentBalance: Value(entity.currentBalance),
        iban: Value(entity.iban),
        bic: Value(entity.bic),
        accountNumber: Value(entity.accountNumber),
        openingBalance: Value(entity.openingBalance),
        openingBalanceDate: Value(entity.openingBalanceDate),
        notes: Value(entity.notes),
        active: Value(entity.active),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.update(_database.accounts).replace(companion);

      final updated = await getById(id);
      if (updated == null) {
        throw DatabaseException('Failed to retrieve updated account');
      }

      logger.info('Account updated successfully: $id');
      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to update account $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to update account: $error');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting account: $id');

      final existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Account not found: $id');
      }

      await (_database.delete(_database.accounts)..where((a) => a.id.equals(id))).go();

      logger.info('Account deleted successfully: $id');
    } catch (error, stackTrace) {
      logger.severe('Failed to delete account $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to delete account: $error');
    }
  }

  @override
  Future<List<AccountEntity>> getUnsynced() async {
    try {
      logger.fine('Fetching unsynced accounts');
      final query = _database.select(_database.accounts)
        ..where((a) => a.isSynced.equals(false));
      final accounts = await query.get();
      logger.info('Found ${accounts.length} unsynced accounts');
      return accounts;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch unsynced accounts', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM accounts WHERE is_synced = false',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> markAsSynced(String localId, String serverId) async {
    try {
      logger.info('Marking account as synced: $localId -> $serverId');

      await (_database.update(_database.accounts)..where((a) => a.id.equals(localId))).write(
        AccountEntityCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      logger.info('Account marked as synced: $localId');
    } catch (error, stackTrace) {
      logger.severe('Failed to mark account as synced: $localId', error, stackTrace);
      throw DatabaseException('Failed to mark account as synced: $error');
    }
  }

  @override
  Future<String> getSyncStatus(String id) async {
    try {
      final account = await getById(id);
      if (account == null) {
        throw DatabaseException('Account not found: $id');
      }
      return account.syncStatus;
    } catch (error, stackTrace) {
      logger.severe('Failed to get sync status for account $id', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.warning('Clearing all accounts from cache');
      await _database.delete(_database.accounts).go();
      logger.info('Account cache cleared');
    } catch (error, stackTrace) {
      logger.severe('Failed to clear account cache', error, stackTrace);
      throw DatabaseException('Failed to clear account cache: $error');
    }
  }

  @override
  Future<int> count() async {
    try {
      logger.fine('Counting accounts');
      final count = await _database.select(_database.accounts).get().then((list) => list.length);
      logger.fine('Account count: $count');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count accounts', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT COUNT(*) FROM accounts',
        error,
        stackTrace,
      );
    }
  }

  /// Get accounts by type (asset, expense, revenue, liability).
  Future<List<AccountEntity>> getByType(String type) async {
    try {
      logger.fine('Fetching accounts by type: $type');
      final query = _database.select(_database.accounts)
        ..where((a) => a.type.equals(type))
        ..orderBy([(a) => OrderingTerm.asc(a.name)]);
      final accounts = await query.get();
      logger.info('Found ${accounts.length} accounts of type: $type');
      return accounts;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch accounts by type: $type', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM accounts WHERE type = $type',
        error,
        stackTrace,
      );
    }
  }

  /// Get active accounts only.
  Future<List<AccountEntity>> getActive() async {
    try {
      logger.fine('Fetching active accounts');
      final query = _database.select(_database.accounts)
        ..where((a) => a.active.equals(true))
        ..orderBy([(a) => OrderingTerm.asc(a.name)]);
      final accounts = await query.get();
      logger.info('Found ${accounts.length} active accounts');
      return accounts;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch active accounts', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM accounts WHERE active = true',
        error,
        stackTrace,
      );
    }
  }

  /// Calculate total balance for asset accounts.
  Future<double> getTotalAssetBalance() async {
    try {
      logger.fine('Calculating total asset balance');
      final assetAccounts = await getByType('asset');
      final total = assetAccounts.fold<double>(0.0, (sum, account) => sum + account.currentBalance);
      logger.info('Total asset balance: $total');
      return total;
    } catch (error, stackTrace) {
      logger.severe('Failed to calculate total asset balance', error, stackTrace);
      throw DatabaseException('Failed to calculate total asset balance: $error');
    }
  }
}
