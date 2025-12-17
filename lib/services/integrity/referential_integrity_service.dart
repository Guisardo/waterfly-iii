import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';

/// Service for maintaining referential integrity in the offline database.
///
/// Ensures that:
/// - Foreign key relationships are valid
/// - Cascade deletes are handled properly
/// - Orphaned records are detected and cleaned
/// - Data consistency is maintained
class ReferentialIntegrityService {
  ReferentialIntegrityService({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;
  final Logger _logger = Logger('ReferentialIntegrityService');

  /// Check if an account can be deleted (no dependent transactions).
  Future<bool> canDeleteAccount(String accountId) async {
    try {
      _logger.fine('Checking if account can be deleted: $accountId');

      final int transactionCount = await (_database.select(
        _database.transactions,
      )..where(
        ($TransactionsTable t) =>
            t.sourceAccountId.equals(accountId) |
            t.destinationAccountId.equals(accountId),
      )).get().then((List<TransactionEntity> list) => list.length);

      final bool canDelete = transactionCount == 0;
      _logger.info(
        'Account $accountId can delete: $canDelete (transactions: $transactionCount)',
      );
      return canDelete;
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to check account deletion: $accountId',
        error,
        stackTrace,
      );
      throw DatabaseException('Failed to check account deletion: $error');
    }
  }

  /// Check if a category can be deleted (no dependent transactions).
  Future<bool> canDeleteCategory(String categoryId) async {
    try {
      _logger.fine('Checking if category can be deleted: $categoryId');

      final int transactionCount = await (_database.select(
        _database.transactions,
      )..where(
        ($TransactionsTable t) => t.categoryId.equals(categoryId),
      )).get().then((List<TransactionEntity> list) => list.length);

      final bool canDelete = transactionCount == 0;
      _logger.info(
        'Category $categoryId can delete: $canDelete (transactions: $transactionCount)',
      );
      return canDelete;
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to check category deletion: $categoryId',
        error,
        stackTrace,
      );
      throw DatabaseException('Failed to check category deletion: $error');
    }
  }

  /// Check if a budget can be deleted (no dependent transactions).
  Future<bool> canDeleteBudget(String budgetId) async {
    try {
      _logger.fine('Checking if budget can be deleted: $budgetId');

      final int transactionCount = await (_database.select(
        _database.transactions,
      )..where(
        ($TransactionsTable t) => t.budgetId.equals(budgetId),
      )).get().then((List<TransactionEntity> list) => list.length);

      final bool canDelete = transactionCount == 0;
      _logger.info(
        'Budget $budgetId can delete: $canDelete (transactions: $transactionCount)',
      );
      return canDelete;
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to check budget deletion: $budgetId',
        error,
        stackTrace,
      );
      throw DatabaseException('Failed to check budget deletion: $error');
    }
  }

  /// Cascade delete account and all dependent transactions.
  Future<void> cascadeDeleteAccount(String accountId) async {
    try {
      _logger.warning('Cascade deleting account and transactions: $accountId');

      await _database.transaction(() async {
        // Delete all transactions referencing this account
        await (_database.delete(_database.transactions)..where(
          ($TransactionsTable t) =>
              t.sourceAccountId.equals(accountId) |
              t.destinationAccountId.equals(accountId),
        )).go();

        // Delete the account
        await (_database.delete(_database.accounts)
          ..where(($AccountsTable a) => a.id.equals(accountId))).go();
      });

      _logger.info('Cascade delete completed for account: $accountId');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to cascade delete account: $accountId',
        error,
        stackTrace,
      );
      throw DatabaseException('Failed to cascade delete account: $error');
    }
  }

  /// Cascade delete category and nullify dependent transactions.
  Future<void> cascadeDeleteCategory(String categoryId) async {
    try {
      _logger.warning('Cascade deleting category: $categoryId');

      await _database.transaction(() async {
        // Nullify category_id in transactions
        await (_database.update(_database.transactions)..where(
          ($TransactionsTable t) => t.categoryId.equals(categoryId),
        )).write(const TransactionEntityCompanion(categoryId: Value(null)));

        // Delete the category
        await (_database.delete(_database.categories)
          ..where(($CategoriesTable c) => c.id.equals(categoryId))).go();
      });

      _logger.info('Cascade delete completed for category: $categoryId');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to cascade delete category: $categoryId',
        error,
        stackTrace,
      );
      throw DatabaseException('Failed to cascade delete category: $error');
    }
  }

  /// Find orphaned transactions (referencing non-existent accounts/categories).
  Future<List<String>> findOrphanedTransactions() async {
    try {
      _logger.info('Searching for orphaned transactions');

      final List<TransactionEntity> allTransactions =
          await _database.select(_database.transactions).get();
      final List<AccountEntity> allAccounts =
          await _database.select(_database.accounts).get();
      final List<CategoryEntity> allCategories =
          await _database.select(_database.categories).get();

      final Set<String> accountIds =
          allAccounts.map((AccountEntity a) => a.id).toSet();
      final Set<String> categoryIds =
          allCategories.map((CategoryEntity c) => c.id).toSet();

      final List<String> orphanedIds = <String>[];

      for (final TransactionEntity txn in allTransactions) {
        if (!accountIds.contains(txn.sourceAccountId) ||
            !accountIds.contains(txn.destinationAccountId)) {
          orphanedIds.add(txn.id);
        } else if (txn.categoryId != null &&
            !categoryIds.contains(txn.categoryId)) {
          orphanedIds.add(txn.id);
        }
      }

      _logger.info('Found ${orphanedIds.length} orphaned transactions');
      return orphanedIds;
    } catch (error, stackTrace) {
      _logger.severe('Failed to find orphaned transactions', error, stackTrace);
      throw DatabaseException('Failed to find orphaned transactions: $error');
    }
  }

  /// Repair orphaned transactions by removing invalid references.
  Future<int> repairOrphanedTransactions() async {
    try {
      _logger.warning('Repairing orphaned transactions');

      final List<String> orphanedIds = await findOrphanedTransactions();

      if (orphanedIds.isEmpty) {
        _logger.info('No orphaned transactions to repair');
        return 0;
      }

      // Delete orphaned transactions
      for (final String id in orphanedIds) {
        await (_database.delete(_database.transactions)
          ..where(($TransactionsTable t) => t.id.equals(id))).go();
      }

      _logger.info('Repaired ${orphanedIds.length} orphaned transactions');
      return orphanedIds.length;
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to repair orphaned transactions',
        error,
        stackTrace,
      );
      throw DatabaseException('Failed to repair orphaned transactions: $error');
    }
  }

  /// Perform comprehensive integrity check on startup.
  Future<Map<String, int>> performIntegrityCheck() async {
    try {
      _logger.info('Performing comprehensive integrity check');

      final Map<String, int> results = <String, int>{
        'orphaned_transactions': 0,
        'invalid_accounts': 0,
        'invalid_categories': 0,
        'invalid_budgets': 0,
      };

      // Check for orphaned transactions
      final List<String> orphanedTransactions =
          await findOrphanedTransactions();
      results['orphaned_transactions'] = orphanedTransactions.length;

      // Check for accounts with invalid data
      final List<AccountEntity> accounts =
          await _database.select(_database.accounts).get();
      results['invalid_accounts'] =
          accounts.where((AccountEntity a) => a.name.isEmpty).length;

      // Check for categories with invalid data
      final List<CategoryEntity> categories =
          await _database.select(_database.categories).get();
      results['invalid_categories'] =
          categories.where((CategoryEntity c) => c.name.isEmpty).length;

      _logger.info('Integrity check complete: $results');
      return results;
    } catch (error, stackTrace) {
      _logger.severe('Failed to perform integrity check', error, stackTrace);
      throw DatabaseException('Failed to perform integrity check: $error');
    }
  }

  /// Repair all integrity issues found.
  Future<Map<String, int>> repairAllIssues() async {
    try {
      _logger.warning('Repairing all integrity issues');

      final Map<String, int> results = <String, int>{
        'orphaned_transactions_repaired': 0,
        'invalid_accounts_removed': 0,
        'invalid_categories_removed': 0,
      };

      // Repair orphaned transactions
      results['orphaned_transactions_repaired'] =
          await repairOrphanedTransactions();

      // Remove invalid accounts
      final List<AccountEntity> accounts =
          await _database.select(_database.accounts).get();
      for (final AccountEntity account in accounts.where(
        (AccountEntity a) => a.name.isEmpty,
      )) {
        await (_database.delete(_database.accounts)
          ..where(($AccountsTable a) => a.id.equals(account.id))).go();
        results['invalid_accounts_removed'] =
            results['invalid_accounts_removed']! + 1;
      }

      // Remove invalid categories
      final List<CategoryEntity> categories =
          await _database.select(_database.categories).get();
      for (final CategoryEntity category in categories.where(
        (CategoryEntity c) => c.name.isEmpty,
      )) {
        await (_database.delete(_database.categories)
          ..where(($CategoriesTable c) => c.id.equals(category.id))).go();
        results['invalid_categories_removed'] =
            results['invalid_categories_removed']! + 1;
      }

      _logger.info('Repair complete: $results');
      return results;
    } catch (error, stackTrace) {
      _logger.severe('Failed to repair integrity issues', error, stackTrace);
      throw DatabaseException('Failed to repair integrity issues: $error');
    }
  }
}
