import 'package:logging/logging.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';

/// Cache Invalidation Rules
///
/// Defines comprehensive cache invalidation rules for maintaining cache consistency
/// in Waterfly III's cache-first architecture.
///
/// Core Principle: **Conservative Invalidation**
/// When in doubt, invalidate. Better to miss cache than show incorrect data.
///
/// Invalidation Strategy:
/// - Cascade invalidation: Invalidate all related entities
/// - Granular control: Invalidate specific entries when possible
/// - Type-level invalidation: Invalidate collections when appropriate
/// - Logged invalidation: All invalidations logged for debugging
///
/// Entity Dependency Graph:
/// ```
/// Transaction → Source Account, Destination Account, Budget, Category, Bill, Tags
/// Account → Transactions, Budgets, Piggy Banks
/// Budget → Transactions
/// Category → Transactions
/// Bill → Transactions
/// Piggy Bank → Account
/// Currency → ALL entities (nuclear option)
/// Tags → Transactions
/// ```
///
/// Usage Example:
/// ```dart
/// // After creating a transaction
/// await CacheInvalidationRules.onTransactionMutation(
///   cacheService,
///   transaction,
///   MutationType.create,
/// );
/// // Cascades to: accounts, budgets, categories, transaction lists, dashboard
///
/// // After syncing
/// await CacheInvalidationRules.onSyncComplete(
///   cacheService,
///   syncOperations,
/// );
/// // Intelligently invalidates based on operation types
/// ```
///
/// Design Principles:
/// 1. **Comprehensive**: Invalidate all potentially affected caches
/// 2. **Efficient**: Use batch operations where possible
/// 3. **Logged**: Detailed logging for debugging
/// 4. **Safe**: Conservative invalidation over stale data
///
/// Integration:
/// Called by repositories after mutations:
/// - create() → onEntityMutation(..., MutationType.create)
/// - update() → onEntityMutation(..., MutationType.update)
/// - delete() → onEntityMutation(..., MutationType.delete)
class CacheInvalidationRules {
  // Private constructor - this is a pure static utility class
  CacheInvalidationRules._();

  static final Logger _log = Logger('CacheInvalidationRules');

  // ========== Transaction Invalidation ==========

  /// Invalidate caches after transaction mutation
  ///
  /// This is the most complex invalidation due to transactions affecting many entities:
  /// - Source and destination accounts (balance changes)
  /// - Budget (spent amount changes)
  /// - Category (category totals change)
  /// - Bill (payment status changes if linked)
  /// - Tags (tag totals change)
  /// - Dashboard (summary data affected)
  /// - All charts (transaction data aggregations)
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [transaction]: Transaction entity (must have IDs populated)
  /// - [mutationType]: Type of mutation (create, update, delete)
  ///
  /// Complexity: O(1) per invalidation, but many invalidations per transaction
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onTransactionMutation(
  ///   cacheService,
  ///   Transaction(
  ///     id: '123',
  ///     sourceAccountId: 'acc1',
  ///     destinationAccountId: 'acc2',
  ///     budgetId: 'bud1',
  ///     categoryId: 'cat1',
  ///   ),
  ///   MutationType.create,
  /// );
  /// ```
  static Future<void> onTransactionMutation(
    CacheService cache,
    dynamic transaction,
    MutationType mutationType,
  ) async {
    _log.info(
      'Invalidating caches after transaction $mutationType: ${transaction.id}',
    );

    try {
      // Always invalidate the transaction itself
      await cache.invalidate('transaction', transaction.id);

      // Invalidate ALL transaction lists
      // Reason: Transaction could appear in many filtered/paginated lists
      await cache.invalidateType('transaction_list');
      _log.fine('Invalidated all transaction lists');

      // Invalidate source account
      if (transaction.sourceAccountId != null &&
          transaction.sourceAccountId.toString().isNotEmpty) {
        await cache.invalidate('account', transaction.sourceAccountId);
        _log.fine('Invalidated source account: ${transaction.sourceAccountId}');

        // Invalidate account's transaction list
        await cache.invalidate(
          'account_transactions',
          transaction.sourceAccountId,
        );
      }

      // Invalidate destination account
      if (transaction.destinationAccountId != null &&
          transaction.destinationAccountId.toString().isNotEmpty) {
        await cache.invalidate('account', transaction.destinationAccountId);
        _log.fine(
          'Invalidated destination account: ${transaction.destinationAccountId}',
        );

        // Invalidate account's transaction list
        await cache.invalidate(
          'account_transactions',
          transaction.destinationAccountId,
        );
      }

      // Invalidate ALL account lists (balances changed)
      await cache.invalidateType('account_list');
      _log.fine('Invalidated all account lists');

      // Invalidate budget if present
      if (transaction.budgetId != null &&
          transaction.budgetId.toString().isNotEmpty) {
        await cache.invalidate('budget', transaction.budgetId);
        _log.fine('Invalidated budget: ${transaction.budgetId}');

        // Invalidate budget's transaction list
        await cache.invalidate('budget_transactions', transaction.budgetId);

        // Invalidate all budget lists (spent amounts changed)
        await cache.invalidateType('budget_list');
      }

      // Invalidate category if present
      if (transaction.categoryId != null &&
          transaction.categoryId.toString().isNotEmpty) {
        await cache.invalidate('category', transaction.categoryId);
        _log.fine('Invalidated category: ${transaction.categoryId}');

        // Invalidate category's transaction list
        await cache.invalidate('category_transactions', transaction.categoryId);
      }

      // Invalidate bill if present
      final String? billId = _getTransactionBillId(transaction);
      if (billId != null && billId.isNotEmpty) {
        await cache.invalidate('bill', billId);
        _log.fine('Invalidated bill: $billId');

        // Invalidate bill's transaction list
        await cache.invalidate('bill_transactions', billId);

        // Invalidate bill list (payment status changed)
        await cache.invalidateType('bill_list');
      }

      // Invalidate tags if present
      final List<String>? tags = _getTransactionTags(transaction);
      if (tags != null && tags.isNotEmpty) {
        for (final String tag in tags) {
          await cache.invalidate('tag', tag);
          await cache.invalidate('tag_transactions', tag);
          _log.fine('Invalidated tag: $tag');
        }
        await cache.invalidateType('tag_list');
      }

      // Invalidate dashboard (summary data affected)
      await cache.invalidateType('dashboard');
      await cache.invalidateType('dashboard_summary');
      _log.fine('Invalidated dashboard caches');

      // Invalidate ALL charts/graphs (they aggregate transaction data)
      await cache.invalidateType('chart');
      await cache.invalidateType('chart_account');
      await cache.invalidateType('chart_budget');
      await cache.invalidateType('chart_category');
      _log.fine('Invalidated all chart caches');

      _log.info('Transaction cache invalidation complete');
    } catch (e, stackTrace) {
      _log.severe('Error during transaction cache invalidation', e, stackTrace);
      // Don't rethrow - invalidation errors shouldn't break transaction mutation
    }
  }

  // ========== Account Invalidation ==========

  /// Invalidate caches after account mutation
  ///
  /// Affects:
  /// - Account itself
  /// - Account lists
  /// - Account's transaction list
  /// - ALL transactions if account deleted (transaction display affected)
  /// - Piggy banks (linked to account)
  /// - Budgets (auto-budget calculations may use account)
  /// - Dashboard
  /// - Account-specific charts
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [account]: Account entity
  /// - [mutationType]: Type of mutation (create, update, delete)
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onAccountMutation(
  ///   cacheService,
  ///   account,
  ///   MutationType.update,
  /// );
  /// ```
  static Future<void> onAccountMutation(
    CacheService cache,
    dynamic account,
    MutationType mutationType,
  ) async {
    _log.info('Invalidating caches after account $mutationType: ${account.id}');

    try {
      // Invalidate the account itself
      await cache.invalidate('account', account.id);

      // Invalidate all account lists
      await cache.invalidateType('account_list');

      // Invalidate account's transaction list
      await cache.invalidate('account_transactions', account.id);

      // If account deleted, invalidate ALL transactions
      // Reason: Transactions with this account need to reflect deleted state
      if (mutationType == MutationType.delete) {
        _log.warning('Account deleted, invalidating all transactions');
        await cache.invalidateType('transaction');
        await cache.invalidateType('transaction_list');
      }

      // Invalidate piggy banks linked to this account
      await cache.invalidateType('piggy_bank_list');

      // Invalidate budgets (auto-budget calculations may use account)
      await cache.invalidateType('budget_list');

      // Invalidate dashboard
      await cache.invalidateType('dashboard');
      await cache.invalidateType('dashboard_summary');

      // Invalidate account-specific charts
      await cache.invalidate('chart_account', account.id);
      await cache.invalidateType('chart');

      _log.info('Account cache invalidation complete');
    } catch (e, stackTrace) {
      _log.severe('Error during account cache invalidation', e, stackTrace);
    }
  }

  // ========== Budget Invalidation ==========

  /// Invalidate caches after budget mutation
  ///
  /// Affects:
  /// - Budget itself
  /// - Budget lists
  /// - Budget's transaction list
  /// - Transaction lists (if budget deleted, need to show transactions without budget)
  /// - Dashboard (budget summary)
  /// - Budget-specific charts
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [budget]: Budget entity
  /// - [mutationType]: Type of mutation (create, update, delete)
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onBudgetMutation(
  ///   cacheService,
  ///   budget,
  ///   MutationType.create,
  /// );
  /// ```
  static Future<void> onBudgetMutation(
    CacheService cache,
    dynamic budget,
    MutationType mutationType,
  ) async {
    _log.info('Invalidating caches after budget $mutationType: ${budget.id}');

    try {
      // Invalidate the budget itself
      await cache.invalidate('budget', budget.id);

      // Invalidate all budget lists
      await cache.invalidateType('budget_list');

      // Invalidate budget's transaction list
      await cache.invalidate('budget_transactions', budget.id);

      // If budget deleted, invalidate transactions with this budget
      if (mutationType == MutationType.delete) {
        _log.warning('Budget deleted, invalidating related transactions');
        // Don't invalidate all transactions - they're still valid, just without budget
        // But invalidate lists that filter by budget
        await cache.invalidateType('transaction_list');
      }

      // Invalidate dashboard (budget summary affected)
      await cache.invalidateType('dashboard');
      await cache.invalidateType('dashboard_summary');

      // Invalidate budget-specific charts
      await cache.invalidate('chart_budget', budget.id);
      await cache.invalidateType('chart');

      _log.info('Budget cache invalidation complete');
    } catch (e, stackTrace) {
      _log.severe('Error during budget cache invalidation', e, stackTrace);
    }
  }

  // ========== Category Invalidation ==========

  /// Invalidate caches after category mutation
  ///
  /// Affects:
  /// - Category itself
  /// - Category lists
  /// - Category's transaction list
  /// - Transaction lists (category info shown in transaction display)
  /// - Transactions if deleted (category reference now invalid)
  /// - Category-specific charts
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [category]: Category entity
  /// - [mutationType]: Type of mutation (create, update, delete)
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onCategoryMutation(
  ///   cacheService,
  ///   category,
  ///   MutationType.update,
  /// );
  /// ```
  static Future<void> onCategoryMutation(
    CacheService cache,
    dynamic category,
    MutationType mutationType,
  ) async {
    _log.info(
      'Invalidating caches after category $mutationType: ${category.id}',
    );

    try {
      // Invalidate the category itself
      await cache.invalidate('category', category.id);

      // Invalidate all category lists
      await cache.invalidateType('category_list');

      // Invalidate category's transaction list
      await cache.invalidate('category_transactions', category.id);

      // Category changes affect transaction display (name, color, etc.)
      // Invalidate transaction lists (they show category info)
      await cache.invalidateType('transaction_list');

      // If category deleted, invalidate transactions with this category
      if (mutationType == MutationType.delete) {
        _log.warning('Category deleted, invalidating related transactions');
        // Transactions still exist, but category reference is now invalid
        await cache.invalidateType('transaction');
      }

      // Invalidate category-specific charts
      await cache.invalidate('chart_category', category.id);
      await cache.invalidateType('chart');

      _log.info('Category cache invalidation complete');
    } catch (e, stackTrace) {
      _log.severe('Error during category cache invalidation', e, stackTrace);
    }
  }

  // ========== Bill Invalidation ==========

  /// Invalidate caches after bill mutation
  ///
  /// Affects:
  /// - Bill itself
  /// - Bill lists
  /// - Bill's transaction list
  /// - Transaction lists (bill info shown)
  /// - Dashboard (upcoming bills widget)
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [bill]: Bill entity
  /// - [mutationType]: Type of mutation (create, update, delete)
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onBillMutation(
  ///   cacheService,
  ///   bill,
  ///   MutationType.delete,
  /// );
  /// ```
  static Future<void> onBillMutation(
    CacheService cache,
    dynamic bill,
    MutationType mutationType,
  ) async {
    _log.info('Invalidating caches after bill $mutationType: ${bill.id}');

    try {
      // Invalidate the bill itself
      await cache.invalidate('bill', bill.id);

      // Invalidate all bill lists
      await cache.invalidateType('bill_list');

      // Invalidate bill's transaction list
      await cache.invalidate('bill_transactions', bill.id);

      // Bill changes might affect transaction display
      await cache.invalidateType('transaction_list');

      // Invalidate dashboard (upcoming bills widget)
      await cache.invalidateType('dashboard');

      _log.info('Bill cache invalidation complete');
    } catch (e, stackTrace) {
      _log.severe('Error during bill cache invalidation', e, stackTrace);
    }
  }

  // ========== Piggy Bank Invalidation ==========

  /// Invalidate caches after piggy bank mutation
  ///
  /// Affects:
  /// - Piggy bank itself
  /// - Piggy bank lists
  /// - Linked account (piggy bank affects account display)
  /// - Dashboard (piggy banks widget)
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [piggyBank]: Piggy bank entity
  /// - [mutationType]: Type of mutation (create, update, delete)
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onPiggyBankMutation(
  ///   cacheService,
  ///   piggyBank,
  ///   MutationType.create,
  /// );
  /// ```
  static Future<void> onPiggyBankMutation(
    CacheService cache,
    dynamic piggyBank,
    MutationType mutationType,
  ) async {
    _log.info(
      'Invalidating caches after piggy bank $mutationType: ${piggyBank.id}',
    );

    try {
      // Invalidate the piggy bank itself
      await cache.invalidate('piggy_bank', piggyBank.id);

      // Invalidate all piggy bank lists
      await cache.invalidateType('piggy_bank_list');

      // Invalidate linked account (piggy bank affects account display)
      final String? accountId = _getPiggyBankAccountId(piggyBank);
      if (accountId != null && accountId.isNotEmpty) {
        await cache.invalidate('account', accountId);
        _log.fine('Invalidated linked account: $accountId');
      }

      // Invalidate dashboard (piggy banks widget)
      await cache.invalidateType('dashboard');

      _log.info('Piggy bank cache invalidation complete');
    } catch (e, stackTrace) {
      _log.severe('Error during piggy bank cache invalidation', e, stackTrace);
    }
  }

  // ========== Currency Invalidation ==========

  /// Invalidate caches after currency mutation
  ///
  /// Currency changes are RARE but affect EVERYTHING with amounts.
  /// This is a nuclear option that invalidates all monetary data.
  ///
  /// Affects:
  /// - Currency itself
  /// - Currency lists
  /// - ALL transactions (currency display)
  /// - ALL accounts (balance currency)
  /// - ALL budgets (amount currency)
  /// - ALL bills (amount currency)
  /// - ALL piggy banks (target amount currency)
  /// - Dashboard
  /// - All charts
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [currency]: Currency entity
  /// - [mutationType]: Type of mutation (create, update, delete)
  ///
  /// Warning: This is expensive. Only call when currency actually changes.
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onCurrencyMutation(
  ///   cacheService,
  ///   currency,
  ///   MutationType.update,
  /// );
  /// ```
  static Future<void> onCurrencyMutation(
    CacheService cache,
    dynamic currency,
    MutationType mutationType,
  ) async {
    _log.warning(
      'Invalidating caches after currency $mutationType: ${_getCurrencyCode(currency)}',
    );

    try {
      // Currency changes affect all monetary displays
      // Nuclear option: invalidate everything

      await cache.invalidate('currency', _getCurrencyCode(currency));
      await cache.invalidateType('currency_list');

      // Invalidate all entities with amounts
      await cache.invalidateType('transaction');
      await cache.invalidateType('transaction_list');
      await cache.invalidateType('account');
      await cache.invalidateType('account_list');
      await cache.invalidateType('budget');
      await cache.invalidateType('budget_list');
      await cache.invalidateType('bill');
      await cache.invalidateType('bill_list');
      await cache.invalidateType('piggy_bank');
      await cache.invalidateType('piggy_bank_list');

      // Invalidate dashboard and charts
      await cache.invalidateType('dashboard');
      await cache.invalidateType('chart');

      _log.warning('Currency cache invalidation complete - full cache cleared');
    } catch (e, stackTrace) {
      _log.severe('Error during currency cache invalidation', e, stackTrace);
    }
  }

  // ========== Tag Invalidation ==========

  /// Invalidate caches after tag mutation
  ///
  /// Affects:
  /// - Tag itself
  /// - Tag lists
  /// - Tag's transaction list
  /// - Transaction lists (tag info shown)
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [tagName]: Tag name (tags use names as IDs)
  /// - [mutationType]: Type of mutation (create, update, delete)
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onTagMutation(
  ///   cacheService,
  ///   'groceries',
  ///   MutationType.update,
  /// );
  /// ```
  static Future<void> onTagMutation(
    CacheService cache,
    String tagName,
    MutationType mutationType,
  ) async {
    _log.info('Invalidating caches after tag $mutationType: $tagName');

    try {
      // Invalidate the tag itself
      await cache.invalidate('tag', tagName);

      // Invalidate all tag lists
      await cache.invalidateType('tag_list');

      // Invalidate tag's transaction list
      await cache.invalidate('tag_transactions', tagName);

      // Tag changes affect transaction display
      await cache.invalidateType('transaction_list');

      _log.info('Tag cache invalidation complete');
    } catch (e, stackTrace) {
      _log.severe('Error during tag cache invalidation', e, stackTrace);
    }
  }

  // ========== Sync-Triggered Invalidation ==========

  /// Invalidate caches after sync operations complete
  ///
  /// When background sync completes, invalidate affected caches based on
  /// the operations that were synced.
  ///
  /// Strategy:
  /// 1. Group operations by entity type
  /// 2. Invalidate individual entities
  /// 3. Invalidate type-level collections
  /// 4. Cascade based on entity type
  ///
  /// Parameters:
  /// - [cache]: CacheService instance
  /// - [operations]: List of sync operations that completed
  ///
  /// Example:
  /// ```dart
  /// await CacheInvalidationRules.onSyncComplete(
  ///   cacheService,
  ///   [
  ///     SyncOperation(entityType: 'transaction', entityId: '123', ...),
  ///     SyncOperation(entityType: 'transaction', entityId: '456', ...),
  ///     SyncOperation(entityType: 'account', entityId: '789', ...),
  ///   ],
  /// );
  /// ```
  static Future<void> onSyncComplete(
    CacheService cache,
    List<dynamic> operations,
  ) async {
    _log.info(
      'Invalidating caches after sync: ${operations.length} operations',
    );

    try {
      // Group operations by entity type
      final Map<String, Set<String>> byType = <String, Set<String>>{};
      for (final op in operations) {
        final String entityType = _getOperationEntityType(op);
        final String entityId = _getOperationEntityId(op);
        byType.putIfAbsent(entityType, () => <String>{}).add(entityId);
      }

      // Invalidate per entity type
      for (final MapEntry<String, Set<String>> entry in byType.entries) {
        final String entityType = entry.key;
        final Set<String> entityIds = entry.value;

        _log.fine('Invalidating $entityType: ${entityIds.length} entities');

        // Invalidate individual entities
        for (final String id in entityIds) {
          await cache.invalidate(entityType, id);
        }

        // Invalidate collections
        await cache.invalidateType('${entityType}_list');

        // Cascade invalidation based on entity type
        switch (entityType) {
          case 'transaction':
            // Transactions affect accounts, budgets, categories
            await cache.invalidateType('account');
            await cache.invalidateType('account_list');
            await cache.invalidateType('budget_list');
            await cache.invalidateType('category_list');
            await cache.invalidateType('dashboard');
            await cache.invalidateType('chart');
            break;

          case 'account':
            // Accounts affect dashboard and charts
            await cache.invalidateType('dashboard');
            await cache.invalidateType('chart');
            break;

          case 'budget':
            // Budgets affect dashboard
            await cache.invalidateType('dashboard');
            await cache.invalidateType('chart');
            break;

          case 'category':
            // Categories affect transaction display
            await cache.invalidateType('transaction_list');
            break;

          case 'bill':
            // Bills affect dashboard
            await cache.invalidateType('dashboard');
            break;

          case 'piggy_bank':
            // Piggy banks affect accounts and dashboard
            await cache.invalidateType('account_list');
            await cache.invalidateType('dashboard');
            break;

          default:
            _log.fine('No cascade invalidation for type: $entityType');
        }
      }

      _log.info('Sync cache invalidation complete');
    } catch (e, stackTrace) {
      _log.severe('Error during sync cache invalidation', e, stackTrace);
    }
  }

  // ========== Helper Methods ==========

  /// Get bill ID from transaction
  ///
  /// Handles different transaction model structures.
  static String? _getTransactionBillId(dynamic transaction) {
    try {
      if (transaction is Map) {
        return transaction['billId']?.toString();
      }
      // Try reflection for object property access
      return transaction.billId?.toString();
    } catch (e) {
      return null;
    }
  }

  /// Get tags from transaction
  ///
  /// Handles different transaction model structures.
  static List<String>? _getTransactionTags(dynamic transaction) {
    try {
      if (transaction is Map) {
        final tags = transaction['tags'];
        if (tags is List) {
          return tags.map((t) => t.toString()).toList();
        }
      }
      // Try reflection for object property access
      final tags = transaction.tags;
      if (tags is List) {
        return tags.map((t) => t.toString()).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get account ID from piggy bank
  static String? _getPiggyBankAccountId(dynamic piggyBank) {
    try {
      if (piggyBank is Map) {
        return piggyBank['accountId']?.toString();
      }
      return piggyBank.accountId?.toString();
    } catch (e) {
      return null;
    }
  }

  /// Get currency code from currency entity
  static String _getCurrencyCode(dynamic currency) {
    try {
      if (currency is Map) {
        return currency['code']?.toString() ??
            currency['id']?.toString() ??
            'unknown';
      }
      return currency.code?.toString() ?? currency.id?.toString() ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get entity type from sync operation
  static String _getOperationEntityType(dynamic operation) {
    try {
      if (operation is Map) {
        return operation['entityType']?.toString() ?? 'unknown';
      }
      return operation.entityType?.toString() ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get entity ID from sync operation
  static String _getOperationEntityId(dynamic operation) {
    try {
      if (operation is Map) {
        return operation['entityId']?.toString() ?? 'unknown';
      }
      return operation.entityId?.toString() ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}

/// Mutation Type Enum
///
/// Defines the type of entity mutation that occurred.
///
/// Used to determine appropriate invalidation strategy:
/// - create: Invalidate collections, related entities
/// - update: Invalidate entity, related entities
/// - delete: Nuclear invalidation, affect many entities
enum MutationType {
  /// Entity was created
  create,

  /// Entity was updated
  update,

  /// Entity was deleted (most aggressive invalidation)
  delete,
}
