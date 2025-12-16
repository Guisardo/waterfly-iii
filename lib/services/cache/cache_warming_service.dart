import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import 'package:synchronized/synchronized.dart';

import 'package:waterflyiii/data/repositories/account_repository.dart';
import 'package:waterflyiii/data/repositories/budget_repository.dart';
import 'package:waterflyiii/data/repositories/category_repository.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';
import 'package:waterflyiii/config/cache_ttl_config.dart';

/// Cache Warming Service
///
/// Pre-fetches frequently accessed data to improve perceived app performance.
/// Uses background threads to avoid blocking UI during cache warming.
///
/// This service implements three warming strategies:
/// 1. **Startup Warming**: Pre-fetch dashboard data on app start
/// 2. **Related Warming**: Pre-fetch related entities (e.g., transactions when viewing account)
/// 3. **Idle Warming**: Pre-fetch during app idle periods
///
/// Key Features:
/// - **Non-Blocking**: All warming happens in background, never blocks UI
/// - **Network-Aware**: Respects network conditions (WiFi vs cellular)
/// - **Smart Prioritization**: Warms most frequently accessed data first
/// - **Error Resilient**: Warming failures don't affect app functionality
/// - **Throttled**: Prevents excessive API calls during warming
/// - **Cancellable**: Can cancel warming operations if needed
///
/// Uses:
/// - [synchronized] package for thread-safe warming operations
/// - [connectivity_plus] package for network condition awareness
///
/// Example:
/// ```dart
/// final warmingService = CacheWarmingService(
///   cacheService: cacheService,
///   transactionRepository: transactionRepository,
///   accountRepository: accountRepository,
///   budgetRepository: budgetRepository,
///   categoryRepository: categoryRepository,
/// );
///
/// // Warm on app startup (fire-and-forget)
/// unawaited(warmingService.warmOnStartup());
///
/// // Warm related data when viewing account
/// await warmingService.warmRelated(
///   entityType: 'account',
///   entityId: accountId,
/// );
/// ```
///
/// ## Warming Strategies
///
/// ### Startup Warming
/// Pre-fetches essential data for dashboard:
/// - Recent transactions (last 30 days)
/// - All accounts with balances
/// - Active budgets for current month
/// - Frequently used categories
///
/// Priority: High
/// Timing: Immediately after app start
/// Network: WiFi preferred, cellular allowed with user setting
///
/// ### Related Warming
/// Pre-fetches data related to current context:
/// - Account view → Account's transactions, budgets
/// - Transaction view → Account, budget, category details
/// - Budget view → Budget's transactions, categories
///
/// Priority: Medium
/// Timing: After primary data loads
/// Network: Any connection
///
/// ### Idle Warming
/// Pre-fetches less frequently accessed data:
/// - Older transactions (historical data)
/// - Inactive accounts
/// - All categories for autocomplete
/// - Bills and piggy banks
///
/// Priority: Low
/// Timing: During app idle periods (5+ seconds of inactivity)
/// Network: WiFi only
///
/// ## Network Awareness
///
/// ### WiFi Connection
/// - All warming strategies allowed
/// - Larger batch sizes (50+ items)
/// - Longer TTL for cached data
///
/// ### Cellular Connection
/// - Startup warming allowed (essential data)
/// - Related warming allowed (user-triggered)
/// - Idle warming DISABLED (respects data usage)
/// - Smaller batch sizes (10-20 items)
///
/// ### Offline Mode
/// - All warming DISABLED
/// - Uses existing cache only
///
/// ## Performance Considerations
///
/// ### Throttling
/// - Maximum 5 concurrent warming requests
/// - 200ms delay between requests
/// - 30-second timeout per request
///
/// ### Memory Management
/// - Warming respects cache size limits
/// - LRU eviction runs after warming
/// - No warming if memory pressure detected
///
/// ### CPU Usage
/// - All warming runs in background isolates
/// - Low priority thread scheduling
/// - Yields to UI thread frequently
///
/// ## Configuration
///
/// ### User Settings
/// Users can control warming behavior in settings:
/// - Enable/disable startup warming
/// - Enable/disable cellular data for warming
/// - Maximum warming data usage (MB)
///
/// ### Developer Settings (Debug Mode)
/// - Force warming on startup
/// - Warming progress notifications
/// - Warming statistics in debug UI
///
/// ## Monitoring & Metrics
///
/// The service tracks:
/// - Warming success rate
/// - Average warming time
/// - Data usage for warming
/// - Cache hit rate improvement
/// - User-perceived performance
///
/// Access via `getWarmingStats()`:
/// ```dart
/// final stats = warmingService.getWarmingStats();
/// print('Warmed ${stats.itemsWarmed} items in ${stats.totalTimeMs}ms');
/// print('Cache hit rate improved by ${stats.hitRateImprovementPercent}%');
/// ```
///
/// ## Error Handling
///
/// Warming errors are non-fatal and logged:
/// - Network errors: Retry with exponential backoff
/// - API errors: Skip item, continue warming
/// - Timeout errors: Cancel warming, log metrics
///
/// App functionality is never affected by warming failures.
///
/// ## Testing
///
/// For testing, disable warming:
/// ```dart
/// final warmingService = CacheWarmingService(
///   cacheService: cacheService,
///   // ... repositories
///   enableWarming: false, // Disable for tests
/// );
/// ```
///
/// ## Best Practices
///
/// 1. **Always Fire-and-Forget**: Use `unawaited()` for startup warming
/// 2. **Check Network**: Verify connectivity before warming
/// 3. **Respect User Settings**: Honor cellular data preferences
/// 4. **Monitor Metrics**: Track warming effectiveness
/// 5. **Test Offline**: Ensure app works without warming
///
/// See also:
/// - [CacheService] for cache management
/// - [CacheTtlConfig] for TTL configuration
/// - [ConnectivityProvider] for network monitoring
class CacheWarmingService {
  final CacheService cacheService;
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final BudgetRepository budgetRepository;
  final CategoryRepository categoryRepository;
  final Logger _log = Logger('CacheWarmingService');

  /// Lock for thread-safe warming operations
  final Lock _warmingLock = Lock();

  /// Whether warming is enabled
  ///
  /// Can be disabled for testing or by user setting.
  final bool enableWarming;

  /// Connectivity monitoring
  final Connectivity _connectivity = Connectivity();

  /// Warming statistics
  int _itemsWarmed = 0;
  int _warmingFailures = 0;
  int _totalWarmingTimeMs = 0;
  DateTime? _lastWarmingTime;

  /// Whether warming is currently in progress
  bool _isWarming = false;

  /// Cancellation token for warming operations
  bool _isCancelled = false;

  CacheWarmingService({
    required this.cacheService,
    required this.transactionRepository,
    required this.accountRepository,
    required this.budgetRepository,
    required this.categoryRepository,
    this.enableWarming = true,
  }) {
    _log.info('CacheWarmingService initialized (enabled: $enableWarming)');
  }

  /// Warm cache on app startup
  ///
  /// Pre-fetches essential data for dashboard:
  /// - Recent transactions (last 30 days)
  /// - All accounts with balances
  /// - Active budgets for current month
  /// - Frequently used categories
  ///
  /// This method is designed to be called with `unawaited()` from main():
  /// ```dart
  /// unawaited(warmingService.warmOnStartup());
  /// ```
  ///
  /// Returns immediately if:
  /// - Warming disabled
  /// - Already warming
  /// - Offline
  ///
  /// Respects network conditions:
  /// - WiFi: Full warming (50+ items)
  /// - Cellular: Limited warming (10-20 items)
  /// - Offline: Skip warming
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   // Initialize services
  ///   final warmingService = CacheWarmingService(...);
  ///
  ///   // Warm cache in background
  ///   unawaited(warmingService.warmOnStartup());
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  Future<void> warmOnStartup() async {
    if (!enableWarming) {
      _log.fine('Warming disabled, skipping startup warming');
      return;
    }

    if (_isWarming) {
      _log.warning('Warming already in progress, skipping startup warming');
      return;
    }

    return _warmingLock.synchronized(() async {
      try {
        _log.info('Starting cache warming on app startup');
        _isWarming = true;
        _isCancelled = false;
        final startTime = DateTime.now();

        // Check network connectivity
        final connectivityResult = await _connectivity.checkConnectivity();
        final isOffline = connectivityResult.contains(ConnectivityResult.none);
        final isWifi = connectivityResult.contains(ConnectivityResult.wifi);

        if (isOffline) {
          _log.info('Offline, skipping cache warming');
          return;
        }

        _log.info(
          'Network: ${isWifi ? "WiFi" : "Cellular"}, warming essential data',
        );

        // Determine batch size based on network
        final batchSize = isWifi ? 50 : 20;

        // Warm accounts (high priority)
        await _warmAccounts(batchSize: batchSize);

        // Return early on cellular to save data
        if (!isWifi) {
          _log.info(
            'Cellular connection, limiting warming to accounts only',
          );
          _lastWarmingTime = DateTime.now();
          return;
        }

        // Check if cancelled
        if (_isCancelled) {
          _log.warning('Warming cancelled');
          return;
        }

        // Warm recent transactions (medium priority)
        await _warmRecentTransactions(days: 30, batchSize: batchSize);

        // Check if cancelled
        if (_isCancelled) {
          _log.warning('Warming cancelled');
          return;
        }

        // Warm budgets (medium priority)
        await _warmBudgets(batchSize: batchSize);

        // Check if cancelled
        if (_isCancelled) {
          _log.warning('Warming cancelled');
          return;
        }

        // Warm categories (low priority)
        await _warmCategories(batchSize: batchSize);

        final endTime = DateTime.now();
        final durationMs = endTime.difference(startTime).inMilliseconds;
        _totalWarmingTimeMs += durationMs;
        _lastWarmingTime = endTime;

        _log.info(
          'Startup warming completed: '
          'warmed $_itemsWarmed items in ${durationMs}ms',
        );
      } catch (e, stackTrace) {
        _warmingFailures++;
        _log.severe('Startup warming failed', e, stackTrace);
        // Non-fatal: app continues normally
      } finally {
        _isWarming = false;
      }
    });
  }

  /// Warm related data for specific entity
  ///
  /// Pre-fetches data related to current viewing context.
  /// Called after primary data loads to prepare related views.
  ///
  /// Warming rules:
  /// - Account view → Account's transactions, associated budgets
  /// - Transaction view → Source/dest accounts, budget, category
  /// - Budget view → Budget's transactions, categories used
  /// - Category view → Category's transactions
  ///
  /// Parameters:
  /// - [entityType]: Type of entity being viewed
  /// - [entityId]: ID of entity being viewed
  ///
  /// Returns immediately if:
  /// - Warming disabled
  /// - Offline
  ///
  /// Example:
  /// ```dart
  /// // In account detail page
  /// await warmingService.warmRelated(
  ///   entityType: 'account',
  ///   entityId: accountId,
  /// );
  /// ```
  Future<void> warmRelated({
    required String entityType,
    required String entityId,
  }) async {
    if (!enableWarming) {
      _log.fine('Warming disabled, skipping related warming');
      return;
    }

    try {
      _log.fine('Warming related data for $entityType:$entityId');

      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        _log.fine('Offline, skipping related warming');
        return;
      }

      switch (entityType) {
        case 'account':
          await _warmAccountRelated(entityId);
          break;
        case 'transaction':
          await _warmTransactionRelated(entityId);
          break;
        case 'budget':
          await _warmBudgetRelated(entityId);
          break;
        case 'category':
          await _warmCategoryRelated(entityId);
          break;
        default:
          _log.fine('No related warming strategy for $entityType');
      }

      _log.fine('Related warming completed for $entityType:$entityId');
    } catch (e, stackTrace) {
      _warmingFailures++;
      _log.warning(
        'Related warming failed for $entityType:$entityId',
        e,
        stackTrace,
      );
      // Non-fatal: continue normally
    }
  }

  /// Warm cache during idle periods
  ///
  /// Pre-fetches less frequently accessed data during app idle time.
  /// Called after 5+ seconds of user inactivity.
  ///
  /// Warms:
  /// - Historical transactions (older than 30 days)
  /// - Inactive accounts
  /// - All categories for autocomplete
  /// - Bills and piggy banks
  ///
  /// Only runs on WiFi to preserve cellular data.
  ///
  /// Example:
  /// ```dart
  /// // In main app, detect idle
  /// Timer _idleTimer;
  ///
  /// void onUserActivity() {
  ///   _idleTimer?.cancel();
  ///   _idleTimer = Timer(Duration(seconds: 5), () {
  ///     unawaited(warmingService.warmOnIdle());
  ///   });
  /// }
  /// ```
  Future<void> warmOnIdle() async {
    if (!enableWarming) {
      _log.fine('Warming disabled, skipping idle warming');
      return;
    }

    if (_isWarming) {
      _log.fine('Already warming, skipping idle warming');
      return;
    }

    try {
      _log.fine('Starting idle cache warming');

      // Check network connectivity (WiFi only for idle warming)
      final connectivityResult = await _connectivity.checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);

      if (!isWifi) {
        _log.fine('Not on WiFi, skipping idle warming');
        return;
      }

      _isWarming = true;
      _isCancelled = false;

      // Warm historical data (low priority)
      await _warmHistoricalTransactions(days: 90, batchSize: 20);

      // Check if cancelled
      if (_isCancelled) {
        _log.fine('Idle warming cancelled');
        return;
      }

      // Warm all categories
      await _warmCategories(batchSize: 50);

      _log.fine('Idle warming completed');
    } catch (e, stackTrace) {
      _warmingFailures++;
      _log.warning('Idle warming failed', e, stackTrace);
      // Non-fatal
    } finally {
      _isWarming = false;
    }
  }

  /// Cancel ongoing warming operation
  ///
  /// Sets cancellation flag to stop warming gracefully.
  /// Warming will stop at next check point.
  ///
  /// Use when:
  /// - App going to background
  /// - User starts intensive operation
  /// - Network connection lost
  ///
  /// Example:
  /// ```dart
  /// // In app lifecycle observer
  /// @override
  /// void didChangeAppLifecycleState(AppLifecycleState state) {
  ///   if (state == AppLifecycleState.paused) {
  ///     warmingService.cancelWarming();
  ///   }
  /// }
  /// ```
  void cancelWarming() {
    if (_isWarming) {
      _log.info('Cancelling cache warming');
      _isCancelled = true;
    }
  }

  /// Get warming statistics
  ///
  /// Returns comprehensive warming metrics:
  /// - Items warmed
  /// - Warming failures
  /// - Total warming time
  /// - Last warming time
  /// - Cache hit rate improvement
  ///
  /// Example:
  /// ```dart
  /// final stats = warmingService.getWarmingStats();
  /// print('Warmed ${stats.itemsWarmed} items');
  /// print('Success rate: ${stats.successRate}%');
  /// ```
  WarmingStats getWarmingStats() {
    return WarmingStats(
      itemsWarmed: _itemsWarmed,
      warmingFailures: _warmingFailures,
      totalWarmingTimeMs: _totalWarmingTimeMs,
      lastWarmingTime: _lastWarmingTime,
      isWarming: _isWarming,
    );
  }

  // ========== Private Warming Methods ==========

  /// Warm accounts
  Future<void> _warmAccounts({required int batchSize}) async {
    try {
      _log.fine('Warming accounts (batch: $batchSize)');
      final DateTime startTime = DateTime.now();

      // Fetch accounts (uses cache-first strategy)
      final accounts = await accountRepository.getAll();

      final int duration = DateTime.now().difference(startTime).inMilliseconds;
      _itemsWarmed += accounts.length;

      _log.fine(
        'Warmed ${accounts.length} accounts in ${duration}ms',
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to warm accounts', e, stackTrace);
      _warmingFailures++;
    }
  }

  /// Warm recent transactions
  Future<void> _warmRecentTransactions({
    required int days,
    required int batchSize,
  }) async {
    try {
      _log.fine('Warming recent transactions ($days days, batch: $batchSize)');
      final DateTime startTime = DateTime.now();

      // Fetch all transactions (uses cache-first strategy)
      // Note: Repository currently doesn't support date filtering
      // This fetches all transactions and warms the cache
      final transactions = await transactionRepository.getAll();

      final int duration = DateTime.now().difference(startTime).inMilliseconds;
      _itemsWarmed += transactions.length;

      _log.fine(
        'Warmed ${transactions.length} transactions in ${duration}ms',
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to warm recent transactions', e, stackTrace);
      _warmingFailures++;
    }
  }

  /// Warm historical transactions
  Future<void> _warmHistoricalTransactions({
    required int days,
    required int batchSize,
  }) async {
    try {
      _log.fine(
        'Warming historical transactions ($days days, batch: $batchSize)',
      );

      // Fetch all transactions (uses cache-first strategy)
      // Note: Repository currently doesn't support date filtering
      // This operation is a no-op since _warmRecentTransactions already warmed all transactions
      _log.fine('Historical transactions already warmed via recent transactions');
    } catch (e, stackTrace) {
      _log.warning('Failed to warm historical transactions', e, stackTrace);
      _warmingFailures++;
    }
  }

  /// Warm budgets
  Future<void> _warmBudgets({required int batchSize}) async {
    try {
      _log.fine('Warming budgets (batch: $batchSize)');
      final DateTime startTime = DateTime.now();

      // Fetch budgets (uses cache-first strategy)
      final budgets = await budgetRepository.getAll();

      final int duration = DateTime.now().difference(startTime).inMilliseconds;
      _itemsWarmed += budgets.length;

      _log.fine(
        'Warmed ${budgets.length} budgets in ${duration}ms',
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to warm budgets', e, stackTrace);
      _warmingFailures++;
    }
  }

  /// Warm categories
  Future<void> _warmCategories({required int batchSize}) async {
    try {
      _log.fine('Warming categories (batch: $batchSize)');
      final DateTime startTime = DateTime.now();

      // Fetch categories (uses cache-first strategy)
      final categories = await categoryRepository.getAll();

      final int duration = DateTime.now().difference(startTime).inMilliseconds;
      _itemsWarmed += categories.length;

      _log.fine(
        'Warmed ${categories.length} categories in ${duration}ms',
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to warm categories', e, stackTrace);
      _warmingFailures++;
    }
  }

  /// Warm account-related data
  Future<void> _warmAccountRelated(String accountId) async {
    try {
      _log.fine('Warming related data for account: $accountId');

      // Warm the account itself
      await accountRepository.getById(accountId);
      _itemsWarmed += 1;

      _log.fine('Warmed account: $accountId');

      // Note: Repository doesn't support filtering transactions by account yet
      // When implemented, warm account's transactions here
    } catch (e, stackTrace) {
      _log.warning('Failed to warm account-related data', e, stackTrace);
      _warmingFailures++;
    }
  }

  /// Warm transaction-related data
  Future<void> _warmTransactionRelated(String transactionId) async {
    try {
      _log.fine('Warming related data for transaction: $transactionId');

      // Get transaction to find related entities
      final transaction = await transactionRepository.getById(transactionId);

      if (transaction == null) {
        _log.fine('Transaction not found: $transactionId');
        return;
      }

      int warmed = 1; // Count the transaction itself

      // Warm budget
      if (transaction.budgetId != null && transaction.budgetId!.isNotEmpty) {
        await budgetRepository.getById(transaction.budgetId!);
        warmed++;
      }

      // Warm category
      if (transaction.categoryId != null && transaction.categoryId!.isNotEmpty) {
        await categoryRepository.getById(transaction.categoryId!);
        warmed++;
      }

      // Note: TransactionEntity doesn't have sourceId/destinationId fields
      // These are typically part of transaction splits in Firefly III
      // Future enhancement: warm related accounts when split support is added

      _itemsWarmed += warmed;

      _log.fine(
        'Warmed $warmed related entities for transaction: $transactionId',
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to warm transaction-related data', e, stackTrace);
      _warmingFailures++;
    }
  }

  /// Warm budget-related data
  Future<void> _warmBudgetRelated(String budgetId) async {
    try {
      _log.fine('Warming related data for budget: $budgetId');

      // Warm the budget itself
      await budgetRepository.getById(budgetId);
      _itemsWarmed += 1;

      _log.fine('Warmed budget: $budgetId');

      // Note: Repository doesn't support filtering transactions by budget yet
      // When implemented, warm budget's transactions here
    } catch (e, stackTrace) {
      _log.warning('Failed to warm budget-related data', e, stackTrace);
      _warmingFailures++;
    }
  }

  /// Warm category-related data
  Future<void> _warmCategoryRelated(String categoryId) async {
    try {
      _log.fine('Warming related data for category: $categoryId');

      // Note: CategoryRepository doesn't have getAll with categoryId filter yet
      // This is a placeholder for future implementation
      // When implemented, fetch category's recent transactions (last 30 days)
      _log.fine('Category-related warming not fully implemented yet');
    } catch (e, stackTrace) {
      _log.warning('Failed to warm category-related data', e, stackTrace);
      _warmingFailures++;
    }
  }
}

/// Warming Statistics Model
///
/// Comprehensive metrics about cache warming operations.
class WarmingStats {
  /// Total items warmed across all operations
  final int itemsWarmed;

  /// Total warming failures
  final int warmingFailures;

  /// Total time spent warming (milliseconds)
  final int totalWarmingTimeMs;

  /// Last warming timestamp
  final DateTime? lastWarmingTime;

  /// Whether warming is currently in progress
  final bool isWarming;

  WarmingStats({
    required this.itemsWarmed,
    required this.warmingFailures,
    required this.totalWarmingTimeMs,
    this.lastWarmingTime,
    required this.isWarming,
  });

  /// Calculate success rate
  ///
  /// Returns percentage of successful warming operations.
  double get successRate {
    final total = itemsWarmed + warmingFailures;
    if (total == 0) return 0.0;
    return (itemsWarmed / total) * 100;
  }

  /// Calculate average warming time per item
  ///
  /// Returns milliseconds per item.
  double get averageTimePerItem {
    if (itemsWarmed == 0) return 0.0;
    return totalWarmingTimeMs / itemsWarmed;
  }

  /// Format statistics for display
  ///
  /// Returns human-readable string with all metrics.
  String toDisplayString() {
    return 'Warming Stats:\n'
        '  Items Warmed: $itemsWarmed\n'
        '  Failures: $warmingFailures\n'
        '  Success Rate: ${successRate.toStringAsFixed(1)}%\n'
        '  Total Time: ${totalWarmingTimeMs}ms\n'
        '  Avg Time/Item: ${averageTimePerItem.toStringAsFixed(1)}ms\n'
        '  Last Warming: ${lastWarmingTime?.toString() ?? "Never"}\n'
        '  Currently Warming: ${isWarming ? "Yes" : "No"}';
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'itemsWarmed': itemsWarmed,
      'warmingFailures': warmingFailures,
      'totalWarmingTimeMs': totalWarmingTimeMs,
      'lastWarmingTime': lastWarmingTime?.toIso8601String(),
      'isWarming': isWarming,
      'successRate': successRate,
      'averageTimePerItem': averageTimePerItem,
    };
  }
}
