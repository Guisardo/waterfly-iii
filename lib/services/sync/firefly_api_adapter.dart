import 'package:logging/logging.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/models/paginated_result.dart';

/// Exception thrown when an API operation fails.
///
/// Contains the error message and optionally the HTTP status code.
class ApiException implements Exception {
  /// Error message describing what went wrong.
  final String message;

  /// HTTP status code if available.
  final int? statusCode;

  /// Response headers if available (for rate limiting).
  final Map<String, String>? headers;

  /// Creates a new API exception.
  ApiException(this.message, {this.statusCode, this.headers});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Adapter for Firefly III API client to work with sync manager.
///
/// This adapter provides a clean interface for interacting with the Firefly III
/// API, handling pagination, error handling, and data transformation. It is
/// designed to work with both full sync and incremental sync strategies.
///
/// Key features:
/// - Paginated API methods that return [PaginatedResult] with metadata
/// - Date-range filtering for incremental sync support
/// - Comprehensive error handling with [ApiException]
/// - Logging for debugging and monitoring
class FireflyApiAdapter {
  final Logger _logger = Logger('FireflyApiAdapter');
  final FireflyIii apiClient;

  FireflyApiAdapter(this.apiClient);

  /// Create a transaction
  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Creating transaction via API');
    
    final TransactionStore store = TransactionStore(
      transactions: <TransactionSplitStore>[
        TransactionSplitStore(
          type: TransactionTypeProperty.withdrawal,
          amount: data['amount']?.toString() ?? '0',
          description: data['description'] as String? ?? '',
          date: DateTime.parse(data['date'] as String? ?? DateTime.now().toIso8601String()),
          sourceId: data['source_id'] as String?,
          destinationId: data['destination_id'] as String?,
          categoryId: data['category_id'] as String?,
        ),
      ],
    );

    final response = await apiClient.v1TransactionsPost(body: store);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to create transaction: ${response.error}');
    }

    final transaction = response.body!.data;
    return {
      'id': transaction.id,
      'type': transaction.type,
      'attributes': transaction.attributes.toJson(),
    };
  }

  /// Update a transaction
  Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Updating transaction $id via API');
    
    final update = TransactionUpdate(
      transactions: [
        TransactionSplitUpdate(
          amount: data['amount']?.toString(),
          description: data['description'] as String?,
          date: data['date'] != null ? DateTime.parse(data['date'] as String) : null,
          sourceId: data['source_id'] as String?,
          destinationId: data['destination_id'] as String?,
          categoryId: data['category_id'] as String?,
        ),
      ],
    );

    final response = await apiClient.v1TransactionsIdPut(id: id, body: update);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to update transaction: ${response.error}');
    }

    final transaction = response.body!.data;
    return {
      'id': transaction.id,
      'type': transaction.type,
      'attributes': transaction.attributes.toJson(),
    };
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    _logger.fine('Deleting transaction $id via API');
    
    final response = await apiClient.v1TransactionsIdDelete(id: id);
    
    if (!response.isSuccessful) {
      throw Exception('Failed to delete transaction: ${response.error}');
    }
  }

  /// Get a transaction
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    _logger.fine('Getting transaction $id via API');
    
    final response = await apiClient.v1TransactionsIdGet(id: id);
    
    if (!response.isSuccessful || response.body == null) {
      return null;
    }

    final transaction = response.body!.data;
    return {
      'id': transaction.id,
      'type': transaction.type,
      'attributes': transaction.attributes.toJson(),
    };
  }

  // ==================== Account Methods ====================

  /// Create an account
  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async {
    _logger.fine('Creating account via API');
    
    final store = AccountStore(
      name: data['name'] as String,
      type: ShortAccountTypeProperty.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ShortAccountTypeProperty.asset,
      ),
      accountNumber: data['account_number'] as String?,
      iban: data['iban'] as String?,
      currencyId: data['currency_id'] as String?,
      openingBalance: data['opening_balance']?.toString(),
      openingBalanceDate: data['opening_balance_date'] != null
          ? DateTime.parse(data['opening_balance_date'] as String)
          : null,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1AccountsPost(body: store);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to create account: ${response.error}');
    }

    final account = response.body!.data;
    return {
      'id': account.id,
      'type': account.type,
      'attributes': account.attributes.toJson(),
    };
  }

  /// Update an account
  Future<Map<String, dynamic>> updateAccount(
    String id,
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Updating account $id via API');
    
    final String name = data['name'] as String? ?? '';
    
    final AccountUpdate update = AccountUpdate(
      name: name,
      accountNumber: data['account_number'] as String?,
      iban: data['iban'] as String?,
      currencyId: data['currency_id'] as String?,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1AccountsIdPut(id: id, body: update);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to update account: ${response.error}');
    }

    final AccountRead account = response.body!.data;
    return <String, dynamic>{
      'id': account.id,
      'type': account.type,
      'attributes': account.attributes.toJson(),
    };
  }

  /// Delete an account
  Future<void> deleteAccount(String id) async {
    _logger.fine('Deleting account $id via API');
    
    final response = await apiClient.v1AccountsIdDelete(id: id);
    
    if (!response.isSuccessful) {
      throw Exception('Failed to delete account: ${response.error}');
    }
  }

  // ==================== Category Methods ====================

  /// Create a category
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    _logger.fine('Creating category via API');
    
    final store = CategoryStore(
      name: data['name'] as String,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1CategoriesPost(body: store);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to create category: ${response.error}');
    }

    final category = response.body!.data;
    return {
      'id': category.id,
      'type': category.type,
      'attributes': category.attributes.toJson(),
    };
  }

  /// Update a category
  Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Updating category $id via API');
    
    final String name = data['name'] as String? ?? '';
    
    final CategoryUpdate update = CategoryUpdate(
      name: name,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1CategoriesIdPut(id: id, body: update);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to update category: ${response.error}');
    }

    final CategoryRead category = response.body!.data;
    return <String, dynamic>{
      'id': category.id,
      'type': category.type,
      'attributes': category.attributes.toJson(),
    };
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    _logger.fine('Deleting category $id via API');
    
    final response = await apiClient.v1CategoriesIdDelete(id: id);
    
    if (!response.isSuccessful) {
      throw Exception('Failed to delete category: ${response.error}');
    }
  }

  // ==================== Budget Methods ====================

  /// Create a budget
  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> data) async {
    _logger.fine('Creating budget via API');
    
    final store = BudgetStore(
      name: data['name'] as String,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1BudgetsPost(body: store);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to create budget: ${response.error}');
    }

    final budget = response.body!.data;
    return {
      'id': budget.id,
      'type': budget.type,
      'attributes': budget.attributes.toJson(),
    };
  }

  /// Update a budget
  Future<Map<String, dynamic>> updateBudget(
    String id,
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Updating budget $id via API');
    
    final String name = data['name'] as String? ?? '';
    
    final BudgetUpdate update = BudgetUpdate(
      name: name,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1BudgetsIdPut(id: id, body: update);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to update budget: ${response.error}');
    }

    final BudgetRead budget = response.body!.data;
    return <String, dynamic>{
      'id': budget.id,
      'type': budget.type,
      'attributes': budget.attributes.toJson(),
    };
  }

  /// Delete a budget
  Future<void> deleteBudget(String id) async {
    _logger.fine('Deleting budget $id via API');
    
    final response = await apiClient.v1BudgetsIdDelete(id: id);
    
    if (!response.isSuccessful) {
      throw Exception('Failed to delete budget: ${response.error}');
    }
  }

  // ==================== Bill Methods ====================

  /// Create a bill
  Future<Map<String, dynamic>> createBill(Map<String, dynamic> data) async {
    _logger.fine('Creating bill via API');
    
    final store = BillStore(
      name: data['name'] as String,
      amountMin: data['amount_min']?.toString() ?? '0',
      amountMax: data['amount_max']?.toString() ?? '0',
      date: DateTime.parse(data['date'] as String? ?? DateTime.now().toIso8601String()),
      repeatFreq: BillRepeatFrequency.values.firstWhere(
        (f) => f.name == data['repeat_freq'],
        orElse: () => BillRepeatFrequency.monthly,
      ),
      currencyId: data['currency_id'] as String?,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1BillsPost(body: store);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to create bill: ${response.error}');
    }

    final bill = response.body!.data;
    return {
      'id': bill.id,
      'type': bill.type,
      'attributes': bill.attributes.toJson(),
    };
  }

  /// Update a bill
  Future<Map<String, dynamic>> updateBill(
    String id,
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Updating bill $id via API');
    
    final String name = data['name'] as String? ?? '';
    
    final BillUpdate update = BillUpdate(
      name: name,
      amountMin: data['amount_min']?.toString(),
      amountMax: data['amount_max']?.toString(),
      date: data['date'] != null ? DateTime.parse(data['date'] as String) : null,
      repeatFreq: data['repeat_freq'] != null
          ? BillRepeatFrequency.values.firstWhere(
              (BillRepeatFrequency f) => f.name == data['repeat_freq'],
              orElse: () => BillRepeatFrequency.monthly,
            )
          : null,
      currencyId: data['currency_id'] as String?,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1BillsIdPut(id: id, body: update);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to update bill: ${response.error}');
    }

    final BillRead bill = response.body!.data;
    return <String, dynamic>{
      'id': bill.id,
      'type': bill.type,
      'attributes': bill.attributes.toJson(),
    };
  }

  /// Delete a bill
  Future<void> deleteBill(String id) async {
    _logger.fine('Deleting bill $id via API');
    
    final response = await apiClient.v1BillsIdDelete(id: id);
    
    if (!response.isSuccessful) {
      throw Exception('Failed to delete bill: ${response.error}');
    }
  }

  // ==================== Piggy Bank Methods ====================

  /// Create a piggy bank
  Future<Map<String, dynamic>> createPiggyBank(Map<String, dynamic> data) async {
    _logger.fine('Creating piggy bank via API');
    
    final PiggyBankStore store = PiggyBankStore(
      name: data['name'] as String,
      accounts: data['account_id'] != null 
          ? <PiggyBankAccountStore>[
              PiggyBankAccountStore(id: data['account_id'] as String)
            ]
          : null,
      targetAmount: data['target_amount']?.toString(),
      currentAmount: data['current_amount']?.toString(),
      startDate: data['start_date'] != null
          ? DateTime.parse(data['start_date'] as String)
          : DateTime.now(),
      targetDate: data['target_date'] != null
          ? DateTime.parse(data['target_date'] as String)
          : null,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1PiggyBanksPost(body: store);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to create piggy bank: ${response.error}');
    }

    final PiggyBankRead piggyBank = response.body!.data;
    return <String, dynamic>{
      'id': piggyBank.id,
      'type': piggyBank.type,
      'attributes': piggyBank.attributes.toJson(),
    };
  }

  /// Update a piggy bank
  Future<Map<String, dynamic>> updatePiggyBank(
    String id,
    Map<String, dynamic> data,
  ) async {
    _logger.fine('Updating piggy bank $id via API');
    
    final PiggyBankUpdate update = PiggyBankUpdate(
      name: data['name'] as String?,
      accounts: data['account_id'] != null 
          ? <PiggyBankAccountUpdate>[
              PiggyBankAccountUpdate(accountId: data['account_id'] as String)
            ]
          : null,
      targetAmount: data['target_amount']?.toString(),
      startDate: data['start_date'] != null
          ? DateTime.parse(data['start_date'] as String)
          : null,
      targetDate: data['target_date'] != null
          ? DateTime.parse(data['target_date'] as String)
          : null,
      notes: data['notes'] as String?,
    );

    final response = await apiClient.v1PiggyBanksIdPut(id: id, body: update);
    
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to update piggy bank: ${response.error}');
    }

    final PiggyBankRead piggyBank = response.body!.data;
    return <String, dynamic>{
      'id': piggyBank.id,
      'type': piggyBank.type,
      'attributes': piggyBank.attributes.toJson(),
    };
  }

  /// Delete a piggy bank
  Future<void> deletePiggyBank(String id) async {
    _logger.fine('Deleting piggy bank $id via API');
    
    final response = await apiClient.v1PiggyBanksIdDelete(id: id);
    
    if (!response.isSuccessful) {
      throw Exception('Failed to delete piggy bank: ${response.error}');
    }
  }

  // ==================== Full Sync Methods ====================

  /// Get all accounts from server
  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    _logger.fine('Fetching all accounts from API');
    
    final List<Map<String, dynamic>> allAccounts = <Map<String, dynamic>>[];
    int page = 1;
    
    while (true) {
      final response = await apiClient.v1AccountsGet(page: page);
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch accounts: ${response.error}');
      }
      
      final accounts = response.body!.data;
      if (accounts.isEmpty) break;
      
      for (final account in accounts) {
        allAccounts.add({
          'id': account.id,
          'type': account.type,
          'attributes': account.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${allAccounts.length} accounts');
    return allAccounts;
  }

  /// Get all categories from server
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    _logger.fine('Fetching all categories from API');
    
    final List<Map<String, dynamic>> allCategories = <Map<String, dynamic>>[];
    int page = 1;
    
    while (true) {
      final response = await apiClient.v1CategoriesGet(page: page);
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch categories: ${response.error}');
      }
      
      final categories = response.body!.data;
      if (categories.isEmpty) break;
      
      for (final category in categories) {
        allCategories.add({
          'id': category.id,
          'type': category.type,
          'attributes': category.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${allCategories.length} categories');
    return allCategories;
  }

  /// Get all budgets from server
  Future<List<Map<String, dynamic>>> getAllBudgets() async {
    _logger.fine('Fetching all budgets from API');
    
    final List<Map<String, dynamic>> allBudgets = <Map<String, dynamic>>[];
    int page = 1;
    
    while (true) {
      final response = await apiClient.v1BudgetsGet(page: page);
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch budgets: ${response.error}');
      }
      
      final budgets = response.body!.data;
      if (budgets.isEmpty) break;
      
      for (final budget in budgets) {
        allBudgets.add({
          'id': budget.id,
          'type': budget.type,
          'attributes': budget.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${allBudgets.length} budgets');
    return allBudgets;
  }

  /// Get all bills from server
  Future<List<Map<String, dynamic>>> getAllBills() async {
    _logger.fine('Fetching all bills from API');
    
    final List<Map<String, dynamic>> allBills = <Map<String, dynamic>>[];
    int page = 1;
    
    while (true) {
      final response = await apiClient.v1BillsGet(page: page);
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch bills: ${response.error}');
      }
      
      final bills = response.body!.data;
      if (bills.isEmpty) break;
      
      for (final bill in bills) {
        allBills.add({
          'id': bill.id,
          'type': bill.type,
          'attributes': bill.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${allBills.length} bills');
    return allBills;
  }

  /// Get all piggy banks from server
  Future<List<Map<String, dynamic>>> getAllPiggyBanks() async {
    _logger.fine('Fetching all piggy banks from API');
    
    final List<Map<String, dynamic>> allPiggyBanks = <Map<String, dynamic>>[];
    int page = 1;
    
    while (true) {
      final response = await apiClient.v1PiggyBanksGet(page: page);
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch piggy banks: ${response.error}');
      }
      
      final piggyBanks = response.body!.data;
      if (piggyBanks.isEmpty) break;
      
      for (final piggyBank in piggyBanks) {
        allPiggyBanks.add({
          'id': piggyBank.id,
          'type': piggyBank.type,
          'attributes': piggyBank.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${allPiggyBanks.length} piggy banks');
    return allPiggyBanks;
  }

  /// Get all transactions from server with pagination
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    _logger.fine('Fetching all transactions from API');
    
    final List<Map<String, dynamic>> allTransactions = <Map<String, dynamic>>[];
    int page = 1;
    
    while (true) {
      final response = await apiClient.v1TransactionsGet(page: page);
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch transactions: ${response.error}');
      }
      
      final transactions = response.body!.data;
      if (transactions.isEmpty) break;
      
      for (final transaction in transactions) {
        allTransactions.add({
          'id': transaction.id,
          'type': transaction.type,
          'attributes': transaction.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${allTransactions.length} transactions');
    return allTransactions;
  }

  // ==================== Incremental Sync Methods ====================

  /// Get accounts updated since timestamp
  Future<List<Map<String, dynamic>>> getAccountsSince(DateTime since) async {
    _logger.fine('Fetching accounts updated since $since');
    
    final List<Map<String, dynamic>> accounts = <Map<String, dynamic>>[];
    int page = 1;
    final startDate = since.toIso8601String().split('T')[0];
    
    while (true) {
      final response = await apiClient.v1AccountsGet(
        page: page,
        start: startDate,
      );
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch accounts: ${response.error}');
      }
      
      final data = response.body!.data;
      if (data.isEmpty) break;
      
      for (final account in data) {
        accounts.add({
          'id': account.id,
          'type': account.type,
          'attributes': account.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${accounts.length} accounts since $since');
    return accounts;
  }

  /// Get categories updated since timestamp
  Future<List<Map<String, dynamic>>> getCategoriesSince(DateTime since) async {
    _logger.fine('Fetching categories updated since $since');
    
    final List<Map<String, dynamic>> categories = <Map<String, dynamic>>[];
    int page = 1;
    
    // Note: Categories API doesn't support date filtering, fetch all and filter locally
    while (true) {
      final response = await apiClient.v1CategoriesGet(
        page: page,
      );
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch categories: ${response.error}');
      }
      
      final data = response.body!.data;
      if (data.isEmpty) break;
      
      for (final category in data) {
        categories.add({
          'id': category.id,
          'type': category.type,
          'attributes': category.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${categories.length} categories since $since');
    return categories;
  }

  /// Get budgets updated since timestamp
  Future<List<Map<String, dynamic>>> getBudgetsSince(DateTime since) async {
    _logger.fine('Fetching budgets updated since $since');
    
    final List<Map<String, dynamic>> budgets = <Map<String, dynamic>>[];
    int page = 1;
    final startDate = since.toIso8601String().split('T')[0];
    
    while (true) {
      final response = await apiClient.v1BudgetsGet(
        page: page,
        start: startDate,
      );
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch budgets: ${response.error}');
      }
      
      final data = response.body!.data;
      if (data.isEmpty) break;
      
      for (final budget in data) {
        budgets.add({
          'id': budget.id,
          'type': budget.type,
          'attributes': budget.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${budgets.length} budgets since $since');
    return budgets;
  }

  /// Get bills updated since timestamp
  Future<List<Map<String, dynamic>>> getBillsSince(DateTime since) async {
    _logger.fine('Fetching bills updated since $since');
    
    final List<Map<String, dynamic>> bills = <Map<String, dynamic>>[];
    int page = 1;
    
    // Note: Bills API doesn't support date filtering, fetch all and filter locally
    while (true) {
      final response = await apiClient.v1BillsGet(
        page: page,
      );
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch bills: ${response.error}');
      }
      
      final data = response.body!.data;
      if (data.isEmpty) break;
      
      for (final bill in data) {
        bills.add({
          'id': bill.id,
          'type': bill.type,
          'attributes': bill.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${bills.length} bills since $since');
    return bills;
  }

  /// Get piggy banks updated since timestamp
  Future<List<Map<String, dynamic>>> getPiggyBanksSince(DateTime since) async {
    _logger.fine('Fetching piggy banks updated since $since');
    
    final List<Map<String, dynamic>> piggyBanks = <Map<String, dynamic>>[];
    int page = 1;
    
    // Note: Piggy banks API doesn't support date filtering, fetch all and filter locally
    while (true) {
      final response = await apiClient.v1PiggyBanksGet(
        page: page,
      );
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch piggy banks: ${response.error}');
      }
      
      final data = response.body!.data;
      if (data.isEmpty) break;
      
      for (final piggyBank in data) {
        piggyBanks.add({
          'id': piggyBank.id,
          'type': piggyBank.type,
          'attributes': piggyBank.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${piggyBanks.length} piggy banks since $since');
    return piggyBanks;
  }

  /// Get transactions updated since timestamp
  Future<List<Map<String, dynamic>>> getTransactionsSince(DateTime since) async {
    _logger.fine('Fetching transactions updated since $since');
    
    final List<Map<String, dynamic>> transactions = <Map<String, dynamic>>[];
    int page = 1;
    final startDate = since.toIso8601String().split('T')[0];
    
    while (true) {
      final response = await apiClient.v1TransactionsGet(
        page: page,
        start: startDate,
      );
      
      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch transactions: ${response.error}');
      }
      
      final data = response.body!.data;
      if (data.isEmpty) break;
      
      for (final transaction in data) {
        transactions.add({
          'id': transaction.id,
          'type': transaction.type,
          'attributes': transaction.attributes.toJson(),
        });
      }
      
      page++;
    }
    
    _logger.info('Fetched ${transactions.length} transactions since $since');
    return transactions;
  }

  // ==================== Paginated API Methods (Incremental Sync) ====================

  /// Fetch transactions with pagination and optional date filtering.
  ///
  /// This method returns pagination metadata along with the data, enabling
  /// efficient iteration through large datasets for incremental sync.
  ///
  /// Parameters:
  /// - [page]: Page number (1-indexed)
  /// - [start]: Optional start date filter (YYYY-MM-DD format)
  /// - [end]: Optional end date filter (YYYY-MM-DD format)
  /// - [limit]: Items per page (default: 50)
  ///
  /// Returns a [PaginatedResult] containing:
  /// - Transaction data for the requested page
  /// - Total count of all transactions matching the filter
  /// - Current page number
  /// - Total number of pages
  /// - Items per page
  ///
  /// Example:
  /// ```dart
  /// final result = await adapter.getTransactionsPaginated(
  ///   page: 1,
  ///   start: DateTime(2024, 12, 1),
  ///   end: DateTime(2024, 12, 31),
  /// );
  ///
  /// while (result.hasMore) {
  ///   result = await adapter.getTransactionsPaginated(
  ///     page: result.currentPage + 1,
  ///     start: DateTime(2024, 12, 1),
  ///   );
  /// }
  /// ```
  Future<PaginatedResult<Map<String, dynamic>>> getTransactionsPaginated({
    required int page,
    DateTime? start,
    DateTime? end,
    int limit = 50,
  }) async {
    _logger.fine('Fetching transactions page $page (start: $start, end: $end, limit: $limit)');

    final response = await apiClient.v1TransactionsGet(
      page: page,
      limit: limit,
      start: start?.toIso8601String().split('T')[0],
      end: end?.toIso8601String().split('T')[0],
    );

    if (!response.isSuccessful || response.body == null) {
      final String error = 'Failed to fetch transactions: ${response.error}';
      _logger.severe(error);
      throw ApiException(error, statusCode: response.statusCode);
    }

    final TransactionArray body = response.body!;
    final Meta? meta = body.meta;

    // Extract pagination metadata, using safe defaults if not available
    final int total = meta?.pagination?.total ?? body.data.length;
    final int currentPage = meta?.pagination?.currentPage ?? page;
    final int totalPages = meta?.pagination?.totalPages ?? 1;
    final int perPage = meta?.pagination?.perPage ?? limit;

    final PaginatedResult<Map<String, dynamic>> result =
        PaginatedResult<Map<String, dynamic>>(
      data: body.data.map((TransactionRead t) => <String, dynamic>{
        'id': t.id,
        'type': t.type,
        'attributes': t.attributes.toJson(),
      }).toList(),
      total: total,
      currentPage: currentPage,
      totalPages: totalPages,
      perPage: perPage,
    );

    _logger.fine('Fetched transactions page $page: ${result.data.length} items '
        '(${result.currentPage}/${result.totalPages}, total: ${result.total})');

    return result;
  }

  /// Fetch accounts with pagination and optional date filtering.
  ///
  /// Similar to [getTransactionsPaginated] but for accounts.
  /// The date filter affects balance calculations, not account filtering.
  ///
  /// Parameters:
  /// - [page]: Page number (1-indexed)
  /// - [start]: Optional start date for balance calculation
  /// - [limit]: Items per page (default: 50)
  Future<PaginatedResult<Map<String, dynamic>>> getAccountsPaginated({
    required int page,
    DateTime? start,
    int limit = 50,
  }) async {
    _logger.fine('Fetching accounts page $page (start: $start, limit: $limit)');

    final response = await apiClient.v1AccountsGet(
      page: page,
      limit: limit,
      date: start?.toIso8601String().split('T')[0],
    );

    if (!response.isSuccessful || response.body == null) {
      final String error = 'Failed to fetch accounts: ${response.error}';
      _logger.severe(error);
      throw ApiException(error, statusCode: response.statusCode);
    }

    final AccountArray body = response.body!;
    final Meta? meta = body.meta;

    final int total = meta?.pagination?.total ?? body.data.length;
    final int currentPage = meta?.pagination?.currentPage ?? page;
    final int totalPages = meta?.pagination?.totalPages ?? 1;
    final int perPage = meta?.pagination?.perPage ?? limit;

    final PaginatedResult<Map<String, dynamic>> result =
        PaginatedResult<Map<String, dynamic>>(
      data: body.data.map((AccountRead a) => <String, dynamic>{
        'id': a.id,
        'type': a.type,
        'attributes': a.attributes.toJson(),
      }).toList(),
      total: total,
      currentPage: currentPage,
      totalPages: totalPages,
      perPage: perPage,
    );

    _logger.fine('Fetched accounts page $page: ${result.data.length} items '
        '(${result.currentPage}/${result.totalPages}, total: ${result.total})');

    return result;
  }

  /// Fetch budgets with pagination and optional date filtering.
  ///
  /// Similar to [getTransactionsPaginated] but for budgets.
  /// The date filter affects budget limit calculations.
  ///
  /// Parameters:
  /// - [page]: Page number (1-indexed)
  /// - [start]: Optional start date for budget period
  /// - [end]: Optional end date for budget period
  /// - [limit]: Items per page (default: 50)
  Future<PaginatedResult<Map<String, dynamic>>> getBudgetsPaginated({
    required int page,
    DateTime? start,
    DateTime? end,
    int limit = 50,
  }) async {
    _logger.fine('Fetching budgets page $page (start: $start, end: $end, limit: $limit)');

    final response = await apiClient.v1BudgetsGet(
      page: page,
      limit: limit,
      start: start?.toIso8601String().split('T')[0],
      end: end?.toIso8601String().split('T')[0],
    );

    if (!response.isSuccessful || response.body == null) {
      final String error = 'Failed to fetch budgets: ${response.error}';
      _logger.severe(error);
      throw ApiException(error, statusCode: response.statusCode);
    }

    final BudgetArray body = response.body!;
    final Meta? meta = body.meta;

    final int total = meta?.pagination?.total ?? body.data.length;
    final int currentPage = meta?.pagination?.currentPage ?? page;
    final int totalPages = meta?.pagination?.totalPages ?? 1;
    final int perPage = meta?.pagination?.perPage ?? limit;

    final PaginatedResult<Map<String, dynamic>> result =
        PaginatedResult<Map<String, dynamic>>(
      data: body.data.map((BudgetRead b) => <String, dynamic>{
        'id': b.id,
        'type': b.type,
        'attributes': b.attributes.toJson(),
      }).toList(),
      total: total,
      currentPage: currentPage,
      totalPages: totalPages,
      perPage: perPage,
    );

    _logger.fine('Fetched budgets page $page: ${result.data.length} items '
        '(${result.currentPage}/${result.totalPages}, total: ${result.total})');

    return result;
  }

  /// Fetch categories with pagination.
  ///
  /// Note: Firefly III API does not support date filtering for categories.
  /// Categories are cached entities with extended TTL (24 hours).
  ///
  /// Parameters:
  /// - [page]: Page number (1-indexed)
  /// - [limit]: Items per page (default: 50)
  Future<PaginatedResult<Map<String, dynamic>>> getCategoriesPaginated({
    required int page,
    int limit = 50,
  }) async {
    _logger.fine('Fetching categories page $page (limit: $limit)');

    final response = await apiClient.v1CategoriesGet(
      page: page,
      limit: limit,
    );

    if (!response.isSuccessful || response.body == null) {
      final String error = 'Failed to fetch categories: ${response.error}';
      _logger.severe(error);
      throw ApiException(error, statusCode: response.statusCode);
    }

    final CategoryArray body = response.body!;
    final Meta? meta = body.meta;

    final int total = meta?.pagination?.total ?? body.data.length;
    final int currentPage = meta?.pagination?.currentPage ?? page;
    final int totalPages = meta?.pagination?.totalPages ?? 1;
    final int perPage = meta?.pagination?.perPage ?? limit;

    final PaginatedResult<Map<String, dynamic>> result =
        PaginatedResult<Map<String, dynamic>>(
      data: body.data.map((CategoryRead c) => <String, dynamic>{
        'id': c.id,
        'type': c.type,
        'attributes': c.attributes.toJson(),
      }).toList(),
      total: total,
      currentPage: currentPage,
      totalPages: totalPages,
      perPage: perPage,
    );

    _logger.fine('Fetched categories page $page: ${result.data.length} items '
        '(${result.currentPage}/${result.totalPages}, total: ${result.total})');

    return result;
  }

  /// Fetch bills with pagination.
  ///
  /// Note: Firefly III API does not support date filtering for bills.
  /// Bills are cached entities with extended TTL (24 hours).
  ///
  /// Parameters:
  /// - [page]: Page number (1-indexed)
  /// - [limit]: Items per page (default: 50)
  Future<PaginatedResult<Map<String, dynamic>>> getBillsPaginated({
    required int page,
    int limit = 50,
  }) async {
    _logger.fine('Fetching bills page $page (limit: $limit)');

    final response = await apiClient.v1BillsGet(
      page: page,
      limit: limit,
    );

    if (!response.isSuccessful || response.body == null) {
      final String error = 'Failed to fetch bills: ${response.error}';
      _logger.severe(error);
      throw ApiException(error, statusCode: response.statusCode);
    }

    final BillArray body = response.body!;
    final Meta? meta = body.meta;

    final int total = meta?.pagination?.total ?? body.data.length;
    final int currentPage = meta?.pagination?.currentPage ?? page;
    final int totalPages = meta?.pagination?.totalPages ?? 1;
    final int perPage = meta?.pagination?.perPage ?? limit;

    final PaginatedResult<Map<String, dynamic>> result =
        PaginatedResult<Map<String, dynamic>>(
      data: body.data.map((BillRead b) => <String, dynamic>{
        'id': b.id,
        'type': b.type,
        'attributes': b.attributes.toJson(),
      }).toList(),
      total: total,
      currentPage: currentPage,
      totalPages: totalPages,
      perPage: perPage,
    );

    _logger.fine('Fetched bills page $page: ${result.data.length} items '
        '(${result.currentPage}/${result.totalPages}, total: ${result.total})');

    return result;
  }

  /// Fetch piggy banks with pagination.
  ///
  /// Note: Firefly III API does not support date filtering for piggy banks.
  /// Piggy banks are cached entities with extended TTL (24 hours).
  ///
  /// Parameters:
  /// - [page]: Page number (1-indexed)
  /// - [limit]: Items per page (default: 50)
  Future<PaginatedResult<Map<String, dynamic>>> getPiggyBanksPaginated({
    required int page,
    int limit = 50,
  }) async {
    _logger.fine('Fetching piggy banks page $page (limit: $limit)');

    final response = await apiClient.v1PiggyBanksGet(
      page: page,
      limit: limit,
    );

    if (!response.isSuccessful || response.body == null) {
      final String error = 'Failed to fetch piggy banks: ${response.error}';
      _logger.severe(error);
      throw ApiException(error, statusCode: response.statusCode);
    }

    final PiggyBankArray body = response.body!;
    final Meta? meta = body.meta;

    final int total = meta?.pagination?.total ?? body.data.length;
    final int currentPage = meta?.pagination?.currentPage ?? page;
    final int totalPages = meta?.pagination?.totalPages ?? 1;
    final int perPage = meta?.pagination?.perPage ?? limit;

    final PaginatedResult<Map<String, dynamic>> result =
        PaginatedResult<Map<String, dynamic>>(
      data: body.data.map((PiggyBankRead p) => <String, dynamic>{
        'id': p.id,
        'type': p.type,
        'attributes': p.attributes.toJson(),
      }).toList(),
      total: total,
      currentPage: currentPage,
      totalPages: totalPages,
      perPage: perPage,
    );

    _logger.fine('Fetched piggy banks page $page: ${result.data.length} items '
        '(${result.currentPage}/${result.totalPages}, total: ${result.total})');

    return result;
  }
}
