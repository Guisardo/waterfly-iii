/// Cache TTL (Time-To-Live) Configuration
///
/// Defines how long cached data remains fresh before becoming stale.
/// These values are carefully chosen based on:
/// - Data volatility (how often data changes)
/// - User expectations (how fresh data needs to be)
/// - API cost (expensive queries get longer TTL)
///
/// TTL Strategy:
/// - Highly volatile data (transactions): Short TTL (5 min)
/// - Moderately volatile (accounts, budgets): Medium TTL (15 min)
/// - Low volatility (categories, currencies): Long TTL (1 hour+)
/// - Rarely changes (user profile): Very long TTL (12 hours)
///
/// Stale-While-Revalidate Pattern:
/// When TTL expires, cached data becomes "stale":
/// 1. Return stale data immediately (instant UI)
/// 2. Fetch fresh data in background
/// 3. Update cache and UI when fetch completes
///
/// This provides:
/// - Instant UI response (no loading spinners)
/// - Eventually consistent data (auto-updates)
/// - Reduced API load (70-80% fewer calls)
/// - Better offline experience (stale data better than no data)
///
/// Tuning Guidelines:
/// - Too short TTL: Unnecessary API calls, poor performance
/// - Too long TTL: Stale data shown too long, user confusion
/// - Balance: Fresh enough for user needs, cached enough for performance
///
/// Usage Example:
/// ```dart
/// final ttl = CacheTtlConfig.getTtl('transaction');
/// await cacheService.set(
///   entityType: 'transaction',
///   entityId: '123',
///   data: transaction,
///   ttl: ttl, // 5 minutes for transactions
/// );
/// ```
class CacheTtlConfig {
  // Private constructor to prevent instantiation
  // This is a pure static configuration class
  CacheTtlConfig._();

  // ========== Highly Volatile Data (Short TTL) ==========

  /// TTL for individual transactions: 5 minutes
  ///
  /// Rationale:
  /// - Transactions change frequently (user creates/edits often)
  /// - Users expect recent transactions to be up-to-date
  /// - Transaction details affect many other entities (accounts, budgets)
  /// - Short TTL ensures mutations are reflected quickly
  ///
  /// Use case:
  /// - Transaction detail page
  /// - Transaction edit form (pre-fill)
  static const Duration transactions = Duration(minutes: 5);

  /// TTL for transaction lists: 3 minutes
  ///
  /// Rationale:
  /// - Lists are even more volatile than single transactions
  /// - New transactions appear at top of lists
  /// - Lists are viewed more frequently (main screen)
  /// - Shorter than single transaction to ensure lists refresh often
  ///
  /// Use case:
  /// - Transaction list page
  /// - Filtered transaction queries
  /// - Account transaction history
  /// - Budget transaction breakdown
  static const Duration transactionsList = Duration(minutes: 3);

  /// TTL for dashboard summary data: 5 minutes
  ///
  /// Rationale:
  /// - Dashboard aggregates multiple data sources (highly volatile)
  /// - Users check dashboard frequently (main screen)
  /// - Summary numbers (balance, spending) change with every transaction
  /// - Same TTL as transactions (dashboard derives from transactions)
  ///
  /// Use case:
  /// - Dashboard summary cards (total balance, spending)
  /// - Quick stats widgets
  /// - Net worth calculation
  static const Duration dashboard = Duration(minutes: 5);

  // ========== Moderately Volatile Data (Medium TTL) ==========

  /// TTL for individual accounts: 15 minutes
  ///
  /// Rationale:
  /// - Account balances change with transactions (moderately volatile)
  /// - Account metadata (name, type) rarely changes
  /// - Users don't expect instant balance updates across all accounts
  /// - 15 min balances performance with reasonable freshness
  ///
  /// Use case:
  /// - Account detail page
  /// - Account balance display
  /// - Account selection dropdowns
  static const Duration accounts = Duration(minutes: 15);

  /// TTL for account lists: 10 minutes
  ///
  /// Rationale:
  /// - Lists viewed more often than individual accounts
  /// - New accounts created infrequently
  /// - Balance changes reflected through background refresh
  /// - Shorter than single account for better list freshness
  ///
  /// Use case:
  /// - Accounts list page
  /// - Account selection pickers
  /// - Asset/liability/revenue account lists
  static const Duration accountsList = Duration(minutes: 10);

  /// TTL for individual budgets: 15 minutes
  ///
  /// Rationale:
  /// - Budget spent amounts change with transactions
  /// - Budget limits rarely change
  /// - Users check budgets periodically (not constantly)
  /// - Same TTL as accounts (similar volatility)
  ///
  /// Use case:
  /// - Budget detail page
  /// - Budget spent/remaining display
  /// - Budget progress bars
  static const Duration budgets = Duration(minutes: 15);

  /// TTL for budget lists: 10 minutes
  ///
  /// Rationale:
  /// - Budget lists show overview (viewed more often)
  /// - New budgets created infrequently
  /// - Spent amounts need reasonable freshness
  /// - Shorter than single budget for list consistency
  ///
  /// Use case:
  /// - Budgets list page
  /// - Budget selection dropdowns
  /// - Available budgets screen
  static const Duration budgetsList = Duration(minutes: 10);

  /// TTL for chart/graph data: 10 minutes
  ///
  /// Rationale:
  /// - Charts aggregate transaction data (moderately volatile)
  /// - Chart rendering is expensive (prefer cached)
  /// - Users don't expect real-time chart updates
  /// - Balance between freshness and performance
  ///
  /// Use case:
  /// - Spending over time charts
  /// - Category breakdown pie charts
  /// - Budget progress graphs
  /// - Account balance history
  static const Duration charts = Duration(minutes: 10);

  // ========== Low Volatility Data (Long TTL) ==========

  /// TTL for individual categories: 1 hour
  ///
  /// Rationale:
  /// - Categories rarely change (metadata stable)
  /// - Users create/edit categories infrequently
  /// - Category name/color used for display (doesn't need instant update)
  /// - Long TTL reduces API calls significantly
  ///
  /// Use case:
  /// - Category detail page
  /// - Category selection dropdowns
  /// - Transaction category display
  static const Duration categories = Duration(hours: 1);

  /// TTL for category lists: 1 hour
  ///
  /// Rationale:
  /// - Category lists very stable (rarely change)
  /// - New categories created infrequently
  /// - Long cache lifetime appropriate
  /// - Same TTL as single category (equal volatility)
  ///
  /// Use case:
  /// - Categories list page
  /// - Category selection pickers
  /// - Category management screen
  static const Duration categoriesList = Duration(hours: 1);

  /// TTL for individual bills: 1 hour
  ///
  /// Rationale:
  /// - Bills are recurring (stable schedule)
  /// - Bill details rarely change once set up
  /// - Payment status updates less critical (not real-time)
  /// - Long TTL for good performance
  ///
  /// Use case:
  /// - Bill detail page
  /// - Bill payment status
  /// - Upcoming bills widget
  static const Duration bills = Duration(hours: 1);

  /// TTL for bill lists: 1 hour
  ///
  /// Rationale:
  /// - Bill lists very stable
  /// - New bills created infrequently
  /// - Payment status updates acceptable with delay
  /// - Same TTL as single bill
  ///
  /// Use case:
  /// - Bills list page
  /// - Upcoming bills screen
  /// - Bill management
  static const Duration billsList = Duration(hours: 1);

  /// TTL for individual piggy banks: 2 hours
  ///
  /// Rationale:
  /// - Piggy banks change infrequently (savings goals)
  /// - Users update piggy banks occasionally
  /// - Balance updates not critical (goal-oriented)
  /// - Very long TTL for excellent performance
  ///
  /// Use case:
  /// - Piggy bank detail page
  /// - Savings goal progress
  /// - Piggy bank contributions
  static const Duration piggyBanks = Duration(hours: 2);

  /// TTL for piggy bank lists: 2 hours
  ///
  /// Rationale:
  /// - Piggy bank lists very stable
  /// - New piggy banks created rarely
  /// - Same TTL as single piggy bank
  ///
  /// Use case:
  /// - Piggy banks list page
  /// - Savings goals overview
  static const Duration piggyBanksList = Duration(hours: 2);

  // ========== Rarely Changing Data (Very Long TTL) ==========

  /// TTL for individual currencies: 24 hours
  ///
  /// Rationale:
  /// - Currencies almost never change
  /// - Currency list is static for most users
  /// - Currency codes/symbols stable
  /// - Very long TTL maximizes performance
  /// - Exchange rates handled separately (if needed)
  ///
  /// Use case:
  /// - Currency detail page
  /// - Currency selection dropdowns
  /// - Multi-currency displays
  static const Duration currencies = Duration(hours: 24);

  /// TTL for currency lists: 24 hours
  ///
  /// Rationale:
  /// - Currency lists essentially static
  /// - New currencies added extremely rarely
  /// - Same long TTL as single currency
  ///
  /// Use case:
  /// - Currency list page
  /// - Currency selection pickers
  /// - Available currencies screen
  static const Duration currenciesList = Duration(hours: 24);

  /// TTL for user profile data: 12 hours
  ///
  /// Rationale:
  /// - User profile changes very rarely
  /// - Profile data not critical for freshness
  /// - Long TTL reduces API load
  /// - Will be invalidated on explicit profile update
  ///
  /// Use case:
  /// - User profile page
  /// - Profile settings display
  /// - User preferences
  static const Duration userProfile = Duration(hours: 12);

  /// TTL for tags: 1 hour
  ///
  /// Rationale:
  /// - Tags relatively stable
  /// - New tags created occasionally
  /// - Tag metadata (name, color) doesn't need instant update
  ///
  /// Use case:
  /// - Tag selection dropdowns
  /// - Tag lists
  /// - Transaction tag display
  static const Duration tags = Duration(hours: 1);

  /// TTL for tag lists: 1 hour
  ///
  /// Rationale:
  /// - Tag lists change infrequently
  /// - Same TTL as single tag
  ///
  /// Use case:
  /// - Tags list page
  /// - Tag management screen
  static const Duration tagsList = Duration(hours: 1);

  // ========== Collection Queries (Special Cases) ==========

  /// TTL for search results: 5 minutes
  ///
  /// Rationale:
  /// - Search results volatile (underlying data changes)
  /// - User expects relatively fresh search results
  /// - Short TTL appropriate for dynamic queries
  ///
  /// Use case:
  /// - Transaction search
  /// - Account search
  /// - Global search results
  static const Duration searchResults = Duration(minutes: 5);

  /// TTL for filtered queries: 5 minutes
  ///
  /// Rationale:
  /// - Filtered queries as volatile as underlying data
  /// - Common filters (date range, category) need freshness
  /// - Short TTL ensures filters show current data
  ///
  /// Use case:
  /// - Date range filtered transactions
  /// - Category filtered lists
  /// - Account filtered budgets
  static const Duration filteredQueries = Duration(minutes: 5);

  // ========== Configuration Methods ==========

  /// Get TTL for a specific entity type
  ///
  /// Central method to retrieve appropriate TTL based on entity type.
  /// Returns configured duration for known types, default for unknown.
  ///
  /// Parameters:
  /// - [entityType]: Entity type string (e.g., 'transaction', 'account')
  ///
  /// Returns:
  /// - Configured Duration for the entity type
  /// - Default Duration(minutes: 15) for unknown types
  ///
  /// Example:
  /// ```dart
  /// final ttl = CacheTtlConfig.getTtl('transaction'); // 5 minutes
  /// final ttl = CacheTtlConfig.getTtl('unknown_type'); // 15 minutes (default)
  /// ```
  ///
  /// Design Pattern:
  /// - Use switch statement for exhaustive type checking
  /// - Separate entity types from list types (different TTLs)
  /// - Provide sensible default for extensibility
  static Duration getTtl(String entityType) {
    switch (entityType) {
      // Highly volatile (short TTL)
      case 'transaction':
        return transactions;
      case 'transaction_list':
        return transactionsList;
      case 'dashboard':
        return dashboard;
      case 'dashboard_summary':
        return dashboard;

      // Moderately volatile (medium TTL)
      case 'account':
        return accounts;
      case 'account_list':
        return accountsList;
      case 'budget':
        return budgets;
      case 'budget_list':
        return budgetsList;
      case 'chart':
      case 'chart_account':
      case 'chart_budget':
      case 'chart_category':
        return charts;

      // Low volatility (long TTL)
      case 'category':
        return categories;
      case 'category_list':
        return categoriesList;
      case 'bill':
        return bills;
      case 'bill_list':
        return billsList;
      case 'piggy_bank':
        return piggyBanks;
      case 'piggy_bank_list':
        return piggyBanksList;

      // Rarely changing (very long TTL)
      case 'currency':
        return currencies;
      case 'currency_list':
        return currenciesList;
      case 'user':
      case 'user_profile':
        return userProfile;
      case 'tag':
        return tags;
      case 'tag_list':
        return tagsList;

      // Special cases
      case 'search':
      case 'search_results':
        return searchResults;
      case 'filtered':
      case 'filtered_query':
        return filteredQueries;

      // Default for unknown types
      // 15 minutes balances freshness and performance
      default:
        return const Duration(minutes: 15);
    }
  }

  /// Get all configured TTL values as a map
  ///
  /// Useful for:
  /// - Debugging cache configuration
  /// - Cache statistics and monitoring
  /// - Configuration validation
  /// - Documentation generation
  ///
  /// Returns:
  /// Map of entity type to TTL duration in seconds
  ///
  /// Example:
  /// ```dart
  /// final config = CacheTtlConfig.getAllTtls();
  /// print('Transaction TTL: ${config['transaction']}s'); // 300s
  /// ```
  static Map<String, int> getAllTtls() {
    return <String, int>{
      // Highly volatile
      'transaction': transactions.inSeconds,
      'transaction_list': transactionsList.inSeconds,
      'dashboard': dashboard.inSeconds,

      // Moderately volatile
      'account': accounts.inSeconds,
      'account_list': accountsList.inSeconds,
      'budget': budgets.inSeconds,
      'budget_list': budgetsList.inSeconds,
      'chart': charts.inSeconds,

      // Low volatility
      'category': categories.inSeconds,
      'category_list': categoriesList.inSeconds,
      'bill': bills.inSeconds,
      'bill_list': billsList.inSeconds,
      'piggy_bank': piggyBanks.inSeconds,
      'piggy_bank_list': piggyBanksList.inSeconds,

      // Rarely changing
      'currency': currencies.inSeconds,
      'currency_list': currenciesList.inSeconds,
      'user': userProfile.inSeconds,
      'tag': tags.inSeconds,
      'tag_list': tagsList.inSeconds,

      // Special cases
      'search': searchResults.inSeconds,
      'filtered': filteredQueries.inSeconds,
    };
  }

  /// Check if an entity type is configured
  ///
  /// Useful for validation and debugging.
  ///
  /// Parameters:
  /// - [entityType]: Entity type to check
  ///
  /// Returns:
  /// - true if entity type has explicit TTL configuration
  /// - false if entity type would use default TTL
  ///
  /// Example:
  /// ```dart
  /// CacheTtlConfig.isConfigured('transaction'); // true
  /// CacheTtlConfig.isConfigured('unknown'); // false
  /// ```
  static bool isConfigured(String entityType) {
    return getAllTtls().containsKey(entityType);
  }

  /// Get TTL in seconds for a specific entity type
  ///
  /// Convenience method for cache service integration.
  ///
  /// Parameters:
  /// - [entityType]: Entity type string
  ///
  /// Returns:
  /// - TTL in seconds (integer)
  ///
  /// Example:
  /// ```dart
  /// final ttlSeconds = CacheTtlConfig.getTtlSeconds('transaction'); // 300
  /// ```
  static int getTtlSeconds(String entityType) {
    return getTtl(entityType).inSeconds;
  }
}
