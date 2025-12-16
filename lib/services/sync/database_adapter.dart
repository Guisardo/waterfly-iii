import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/validators/transaction_validator.dart';
import 'package:waterflyiii/validators/account_validator.dart';
import 'package:waterflyiii/validators/category_validator.dart';
import 'package:waterflyiii/validators/budget_validator.dart';
import 'package:waterflyiii/validators/bill_validator.dart';
import 'package:waterflyiii/validators/piggy_bank_validator.dart';

/// Comprehensive adapter for database operations during synchronization.
///
/// Consolidates database_adapter.dart and entity_persistence_service.dart
/// to provide unified database access with validation.
///
/// Features:
/// - CRUD operations for all entity types
/// - Data validation before persistence
/// - API format to database format conversion
/// - Batch operations for performance
/// - Transaction-based operations
/// - Comprehensive error handling
/// - Detailed logging
///
/// Example:
/// ```dart
/// final adapter = DatabaseAdapter(database: database);
///
/// // Upsert with validation
/// await adapter.upsertTransaction(apiData);
///
/// // Batch upsert
/// await adapter.upsertTransactionsBatch(apiDataList);
///
/// // Get entity
/// final transaction = await adapter.getTransaction(id);
/// ```
class DatabaseAdapter {
  final Logger _logger = Logger('DatabaseAdapter');
  final AppDatabase database;
  
  // Validators
  final TransactionValidator _transactionValidator;
  final AccountValidator _accountValidator;
  final CategoryValidator _categoryValidator;
  final BudgetValidator _budgetValidator;
  final BillValidator _billValidator;
  final PiggyBankValidator _piggyBankValidator;

  DatabaseAdapter({
    required this.database,
    TransactionValidator? transactionValidator,
    AccountValidator? accountValidator,
    CategoryValidator? categoryValidator,
    BudgetValidator? budgetValidator,
    BillValidator? billValidator,
    PiggyBankValidator? piggyBankValidator,
  })  : _transactionValidator = transactionValidator ?? TransactionValidator(),
        _accountValidator = accountValidator ?? AccountValidator(),
        _categoryValidator = categoryValidator ?? CategoryValidator(),
        _budgetValidator = budgetValidator ?? BudgetValidator(),
        _billValidator = billValidator ?? BillValidator(),
        _piggyBankValidator = piggyBankValidator ?? PiggyBankValidator();

  // ==================== TRANSACTION OPERATIONS ====================

  /// Insert or update a transaction with validation.
  Future<void> upsertTransaction(Map<String, dynamic> data) async {
    try {
      // Validate data
      final ValidationResult validation = _transactionValidator.validate(data);
      if (!validation.isValid) {
        throw ValidationException(
          'Transaction validation failed: ${validation.errors.join(', ')}',
          <String, dynamic>{'errors': validation.errors},
        );
      }

      final String id = data['id'] as String;
      
      final TransactionEntityCompanion entity = TransactionEntityCompanion(
        id: Value(id),
        serverId: Value(data['server_id'] as String?),
        type: Value(data['type'] as String? ?? 'withdrawal'),
        date: Value(_parseDateTime(data['date']) ?? DateTime.now()),
        amount: Value(_parseDouble(data['amount'])),
        description: Value(data['description'] as String? ?? ''),
        sourceAccountId: Value(data['source_account_id'] as String? ?? ''),
        destinationAccountId: Value(data['destination_account_id'] as String? ?? ''),
        categoryId: Value(data['category_id'] as String?),
        budgetId: Value(data['budget_id'] as String?),
        currencyCode: Value(data['currency_code'] as String? ?? 'USD'),
        foreignAmount: Value(_parseDoubleNullable(data['foreign_amount'])),
        foreignCurrencyCode: Value(data['foreign_currency_code'] as String?),
        notes: Value(data['notes'] as String?),
        tags: Value(data['tags'] as String? ?? '[]'),
        createdAt: Value(_parseDateTime(data['created_at']) ?? DateTime.now()),
        updatedAt: Value(_parseDateTime(data['updated_at']) ?? DateTime.now()),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      );

      await database.into(database.transactions).insertOnConflictUpdate(entity);
      _logger.fine('Upserted transaction: $id');
    } catch (e, stackTrace) {
      _logger.severe('Failed to upsert transaction', e, stackTrace);
      rethrow;
    }
  }

  /// Batch upsert transactions.
  Future<void> upsertTransactionsBatch(List<Map<String, dynamic>> dataList) async {
    try {
      await database.transaction(() async {
        for (final Map<String, dynamic> data in dataList) {
          await upsertTransaction(data);
        }
      });
      _logger.info('Batch upserted ${dataList.length} transactions');
    } catch (e, stackTrace) {
      _logger.severe('Failed to batch upsert transactions', e, stackTrace);
      throw DatabaseException('Failed to batch upsert transactions: ${e.toString()}');
    }
  }

  /// Get a transaction by ID.
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    try {
      final TransactionEntity? result = await (database.select(database.transactions)
            ..where(($TransactionsTable t) => t.id.equals(id)))
          .getSingleOrNull();
      
      if (result == null) return null;

      return _transactionToMap(result);
    } catch (e, stackTrace) {
      _logger.severe('Failed to get transaction $id', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a transaction.
  Future<void> deleteTransaction(String id) async {
    try {
      await (database.delete(database.transactions)
            ..where(($TransactionsTable t) => t.id.equals(id)))
          .go();
      _logger.fine('Deleted transaction: $id');
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete transaction $id', e, stackTrace);
      rethrow;
    }
  }

  /// Get all transactions.
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final List<TransactionEntity> results = await database.select(database.transactions).get();
      return results.map(_transactionToMap).toList();
    } catch (e, stackTrace) {
      _logger.severe('Failed to get all transactions', e, stackTrace);
      rethrow;
    }
  }

  // ==================== ACCOUNT OPERATIONS ====================

  /// Insert or update an account with validation.
  Future<void> upsertAccount(Map<String, dynamic> data) async {
    try {
      final ValidationResult validation = await _accountValidator.validate(data);
      if (!validation.isValid) {
        throw ValidationException(
          'Account validation failed: ${validation.errors.join(', ')}',
          <String, dynamic>{'errors': validation.errors},
        );
      }

      final String id = data['id'] as String;
      
      final AccountEntityCompanion entity = AccountEntityCompanion(
        id: Value(id),
        serverId: Value(data['server_id'] as String?),
        name: Value(data['name'] as String),
        type: Value(data['type'] as String? ?? 'asset'),
        accountRole: Value(data['account_role'] as String?),
        currencyCode: Value(data['currency_code'] as String? ?? 'USD'),
        currentBalance: Value(_parseDouble(data['current_balance'])),
        iban: Value(data['iban'] as String?),
        bic: Value(data['bic'] as String?),
        accountNumber: Value(data['account_number'] as String?),
        notes: Value(data['notes'] as String?),
        active: Value(data['active'] as bool? ?? true),
        createdAt: Value(_parseDateTime(data['created_at']) ?? DateTime.now()),
        updatedAt: Value(_parseDateTime(data['updated_at']) ?? DateTime.now()),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      );

      await database.into(database.accounts).insertOnConflictUpdate(entity);
      _logger.fine('Upserted account: $id');
    } catch (e, stackTrace) {
      _logger.severe('Failed to upsert account', e, stackTrace);
      rethrow;
    }
  }

  /// Batch upsert accounts.
  Future<void> upsertAccountsBatch(List<Map<String, dynamic>> dataList) async {
    try {
      await database.transaction(() async {
        for (final Map<String, dynamic> data in dataList) {
          await upsertAccount(data);
        }
      });
      _logger.info('Batch upserted ${dataList.length} accounts');
    } catch (e, stackTrace) {
      _logger.severe('Failed to batch upsert accounts', e, stackTrace);
      throw DatabaseException('Failed to batch upsert accounts: ${e.toString()}');
    }
  }

  /// Get an account by ID.
  Future<Map<String, dynamic>?> getAccount(String id) async {
    try {
      final AccountEntity? result = await (database.select(database.accounts)
            ..where(($AccountsTable a) => a.id.equals(id)))
          .getSingleOrNull();
      
      if (result == null) return null;

      return _accountToMap(result);
    } catch (e, stackTrace) {
      _logger.severe('Failed to get account $id', e, stackTrace);
      rethrow;
    }
  }

  // ==================== CATEGORY OPERATIONS ====================

  /// Insert or update a category with validation.
  Future<void> upsertCategory(Map<String, dynamic> data) async {
    try {
      final ValidationResult validation = await _categoryValidator.validate(data);
      if (!validation.isValid) {
        throw ValidationException(
          'Category validation failed: ${validation.errors.join(', ')}',
          <String, dynamic>{'errors': validation.errors},
        );
      }

      final String id = data['id'] as String;
      
      final CategoryEntityCompanion entity = CategoryEntityCompanion(
        id: Value(id),
        serverId: Value(data['server_id'] as String?),
        name: Value(data['name'] as String),
        notes: Value(data['notes'] as String?),
        createdAt: Value(_parseDateTime(data['created_at']) ?? DateTime.now()),
        updatedAt: Value(_parseDateTime(data['updated_at']) ?? DateTime.now()),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      );

      await database.into(database.categories).insertOnConflictUpdate(entity);
      _logger.fine('Upserted category: $id');
    } catch (e, stackTrace) {
      _logger.severe('Failed to upsert category', e, stackTrace);
      rethrow;
    }
  }

  /// Batch upsert categories.
  Future<void> upsertCategoriesBatch(List<Map<String, dynamic>> dataList) async {
    try {
      await database.transaction(() async {
        for (final Map<String, dynamic> data in dataList) {
          await upsertCategory(data);
        }
      });
      _logger.info('Batch upserted ${dataList.length} categories');
    } catch (e, stackTrace) {
      _logger.severe('Failed to batch upsert categories', e, stackTrace);
      throw DatabaseException('Failed to batch upsert categories: ${e.toString()}');
    }
  }

  // ==================== BUDGET OPERATIONS ====================

  /// Insert or update a budget with validation.
  Future<void> upsertBudget(Map<String, dynamic> data) async {
    try {
      final ValidationResult validation = await _budgetValidator.validate(data);
      if (!validation.isValid) {
        throw ValidationException(
          'Budget validation failed: ${validation.errors.join(', ')}',
          <String, dynamic>{'errors': validation.errors},
        );
      }

      final String id = data['id'] as String;
      
      final BudgetEntityCompanion entity = BudgetEntityCompanion(
        id: Value(id),
        serverId: Value(data['server_id'] as String?),
        name: Value(data['name'] as String),
        active: Value(data['active'] as bool? ?? true),
        createdAt: Value(_parseDateTime(data['created_at']) ?? DateTime.now()),
        updatedAt: Value(_parseDateTime(data['updated_at']) ?? DateTime.now()),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      );

      await database.into(database.budgets).insertOnConflictUpdate(entity);
      _logger.fine('Upserted budget: $id');
    } catch (e, stackTrace) {
      _logger.severe('Failed to upsert budget', e, stackTrace);
      rethrow;
    }
  }

  // ==================== BILL OPERATIONS ====================

  /// Insert or update a bill with validation.
  Future<void> upsertBill(Map<String, dynamic> data) async {
    try {
      final ValidationResult validation = await _billValidator.validate(data);
      if (!validation.isValid) {
        throw ValidationException(
          'Bill validation failed: ${validation.errors.join(', ')}',
          <String, dynamic>{'errors': validation.errors},
        );
      }

      final String id = data['id'] as String;
      
      final BillEntityCompanion entity = BillEntityCompanion(
        id: Value(id),
        serverId: Value(data['server_id'] as String?),
        name: Value(data['name'] as String),
        amountMin: Value(_parseDouble(data['amount_min'])),
        amountMax: Value(_parseDouble(data['amount_max'])),
        currencyCode: Value(data['currency_code'] as String? ?? 'USD'),
        date: Value(_parseDateTime(data['date']) ?? DateTime.now()),
        repeatFreq: Value(data['repeat_freq'] as String? ?? 'monthly'),
        skip: Value(data['skip'] as int? ?? 0),
        active: Value(data['active'] as bool? ?? true),
        notes: Value(data['notes'] as String?),
        createdAt: Value(_parseDateTime(data['created_at']) ?? DateTime.now()),
        updatedAt: Value(_parseDateTime(data['updated_at']) ?? DateTime.now()),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      );

      await database.into(database.bills).insertOnConflictUpdate(entity);
      _logger.fine('Upserted bill: $id');
    } catch (e, stackTrace) {
      _logger.severe('Failed to upsert bill', e, stackTrace);
      rethrow;
    }
  }

  // ==================== PIGGY BANK OPERATIONS ====================

  /// Insert or update a piggy bank with validation.
  Future<void> upsertPiggyBank(Map<String, dynamic> data) async {
    try {
      final ValidationResult validation = await _piggyBankValidator.validate(data);
      if (!validation.isValid) {
        throw ValidationException(
          'Piggy bank validation failed: ${validation.errors.join(', ')}',
          <String, dynamic>{'errors': validation.errors},
        );
      }

      final String id = data['id'] as String;
      
      final PiggyBankEntityCompanion entity = PiggyBankEntityCompanion(
        id: Value(id),
        serverId: Value(data['server_id'] as String?),
        name: Value(data['name'] as String),
        accountId: Value(data['account_id'] as String),
        targetAmount: Value(_parseDouble(data['target_amount'])),
        currentAmount: Value(_parseDouble(data['current_amount'])),
        startDate: Value(_parseDateTime(data['start_date'])),
        targetDate: Value(_parseDateTime(data['target_date'])),
        notes: Value(data['notes'] as String?),
        createdAt: Value(_parseDateTime(data['created_at']) ?? DateTime.now()),
        updatedAt: Value(_parseDateTime(data['updated_at']) ?? DateTime.now()),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
      );

      await database.into(database.piggyBanks).insertOnConflictUpdate(entity);
      _logger.fine('Upserted piggy bank: $id');
    } catch (e, stackTrace) {
      _logger.severe('Failed to upsert piggy bank', e, stackTrace);
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Parse DateTime from various formats.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        _logger.warning('Failed to parse datetime: $value');
        return null;
      }
    }
    return null;
  }

  /// Parse double from various formats.
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        _logger.warning('Failed to parse double: $value');
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Parse nullable double from various formats.
  double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        _logger.warning('Failed to parse double: $value');
        return null;
      }
    }
    return null;
  }

  /// Convert transaction entity to map.
  Map<String, dynamic> _transactionToMap(TransactionEntity t) {
    return <String, dynamic>{
      'id': t.id,
      'server_id': t.serverId,
      'type': t.type,
      'date': t.date.toIso8601String(),
      'amount': t.amount,
      'description': t.description,
      'source_account_id': t.sourceAccountId,
      'destination_account_id': t.destinationAccountId,
      'category_id': t.categoryId,
      'budget_id': t.budgetId,
      'currency_code': t.currencyCode,
      'foreign_amount': t.foreignAmount,
      'foreign_currency_code': t.foreignCurrencyCode,
      'notes': t.notes,
      'tags': t.tags,
      'is_synced': t.isSynced,
      'sync_status': t.syncStatus,
      'created_at': t.createdAt.toIso8601String(),
      'updated_at': t.updatedAt.toIso8601String(),
    };
  }

  /// Convert account entity to map.
  Map<String, dynamic> _accountToMap(AccountEntity a) {
    return <String, dynamic>{
      'id': a.id,
      'server_id': a.serverId,
      'name': a.name,
      'type': a.type,
      'account_role': a.accountRole,
      'currency_code': a.currencyCode,
      'current_balance': a.currentBalance,
      'iban': a.iban,
      'bic': a.bic,
      'account_number': a.accountNumber,
      'notes': a.notes,
      'active': a.active,
      'is_synced': a.isSynced,
      'sync_status': a.syncStatus,
      'created_at': a.createdAt.toIso8601String(),
      'updated_at': a.updatedAt.toIso8601String(),
    };
  }
}
