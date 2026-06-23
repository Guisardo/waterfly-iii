import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart'
    as enums;
import 'package:waterflyiii/generated/swagger_fireflyiii_api/client_mapping.dart';

/// Mock HTTP client that returns predefined responses
class MockHttpClient extends http.BaseClient {
  final Map<String, http.Response> _responses = <String, http.Response>{};
  final Map<String, http.Response Function(http.BaseRequest)> _handlers =
      <String, http.Response Function(http.BaseRequest)>{};

  void setResponse(String url, http.Response response) {
    _responses[url] = response;
  }

  void setJsonResponse(
    String url,
    Map<String, dynamic> json, {
    int statusCode = 200,
  }) {
    _responses[url] = http.Response(
      jsonEncode(json),
      statusCode,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }

  void setHandler(
    String pattern,
    http.Response Function(http.BaseRequest) handler,
  ) {
    _handlers[pattern] = handler;
  }

  String _normalizeUrl(String url) {
    // Remove query parameters for matching
    final Uri uri = Uri.parse(url);
    return uri.replace(queryParameters: <String, dynamic>{}).toString();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String url = request.url.toString();
    final String normalizedUrl = _normalizeUrl(url);
    final String path = request.url.path;

    // Debug: log URL for troubleshooting (only in test mode)
    if (kDebugMode) {
      debugPrint(
        'MockHttpClient: Request URL=$url, path=$path, normalized=$normalizedUrl',
      );
      debugPrint('MockHttpClient: Handlers=${_handlers.keys.toList()}');
    }

    // Check exact match first
    http.Response? response = _responses[url] ?? _responses[normalizedUrl];

    // Check pattern handlers - match on path or full URL
    if (response == null) {
      for (final MapEntry<String, http.Response Function(http.BaseRequest)>
          entry
          in _handlers.entries) {
        final bool matches =
            url.contains(entry.key) ||
            normalizedUrl.contains(entry.key) ||
            path.contains(entry.key);
        if (kDebugMode && matches) {
          debugPrint('MockHttpClient: Handler matched pattern=${entry.key}');
        }
        if (matches) {
          try {
            response = entry.value(request);
          } catch (e) {
            // If handler throws, convert to error response
            // Check if exception contains status code information
            final String errorStr = e.toString();
            int statusCode = 500;
            if (errorStr.contains('409')) {
              statusCode = 409;
            } else if (errorStr.contains('404')) {
              statusCode = 404;
            } else if (errorStr.contains('401') || errorStr.contains('403')) {
              statusCode = errorStr.contains('401') ? 401 : 403;
            }
            response = http.Response(
              jsonEncode(<String, String>{'error': errorStr}),
              statusCode,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }
          break;
        }
      }
    }

    if (response != null) {
      return http.StreamedResponse(
        Stream<List<int>>.value(response.bodyBytes),
        response.statusCode,
        headers: response.headers,
      );
    }

    // Default 404 response
    if (kDebugMode) {
      debugPrint('MockHttpClient: No handler matched, returning 404');
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{"error": "Not found"}')),
      404,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }

  void clear() {
    _responses.clear();
    _handlers.clear();
  }
}

/// Helper class to create a mock FireflyService with mocked API responses
class MockFireflyServiceHelper {
  final MockHttpClient mockHttpClient = MockHttpClient();
  late FireflyIii mockApi;
  late FireflyService fireflyService;
  late _MockFireflyService _mockFireflyService;

  MockFireflyServiceHelper() {
    // Pre-register all factory mappings to ensure Chopper can deserialize
    _registerFactories();

    mockApi = FireflyIii.create(
      baseUrl: Uri.parse('http://test.firefly.local/api'),
      httpClient: mockHttpClient,
    );
    // Don't create a real FireflyService - just provide the mock API
    // Tests will need to handle FireflyService separately
    _mockFireflyService = _MockFireflyService(mockApi, mockHttpClient);
    fireflyService = _mockFireflyService;
  }

  /// Pre-register all factory mappings needed for Chopper deserialization
  void _registerFactories() {
    // Register all array types that might be used in tests
    generatedMapping.putIfAbsent(
      AccountArray,
      () => AccountArray.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      AccountRead,
      () => AccountRead.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      AccountProperties,
      () => AccountProperties.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      CategoryArray,
      () => CategoryArray.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      CategoryRead,
      () => CategoryRead.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      CategoryProperties,
      () => CategoryProperties.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(TagArray, () => TagArray.fromJsonFactory);
    generatedMapping.putIfAbsent(TagRead, () => TagRead.fromJsonFactory);
    generatedMapping.putIfAbsent(TagModel, () => TagModel.fromJsonFactory);
    generatedMapping.putIfAbsent(BillArray, () => BillArray.fromJsonFactory);
    generatedMapping.putIfAbsent(BillRead, () => BillRead.fromJsonFactory);
    generatedMapping.putIfAbsent(
      BudgetArray,
      () => BudgetArray.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(BudgetRead, () => BudgetRead.fromJsonFactory);
    generatedMapping.putIfAbsent(
      BudgetLimitArray,
      () => BudgetLimitArray.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      BudgetLimitRead,
      () => BudgetLimitRead.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      TransactionSingle,
      () => TransactionSingle.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      CurrencyArray,
      () => CurrencyArray.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      CurrencyRead,
      () => CurrencyRead.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      CurrencyProperties,
      () => CurrencyProperties.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      PiggyBankArray,
      () => PiggyBankArray.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      PiggyBankRead,
      () => PiggyBankRead.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      PiggyBankProperties,
      () => PiggyBankProperties.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(BillArray, () => BillArray.fromJsonFactory);
    generatedMapping.putIfAbsent(BillRead, () => BillRead.fromJsonFactory);
    generatedMapping.putIfAbsent(
      BillProperties,
      () => BillProperties.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      BudgetArray,
      () => BudgetArray.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(BudgetRead, () => BudgetRead.fromJsonFactory);
    generatedMapping.putIfAbsent(
      BudgetProperties,
      () => BudgetProperties.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      TransactionArray,
      () => TransactionArray.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      TransactionRead,
      () => TransactionRead.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      Transaction,
      () => Transaction.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(
      TransactionSplit,
      () => TransactionSplit.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(SystemInfo, () => SystemInfo.fromJsonFactory);
    generatedMapping.putIfAbsent(
      SystemInfo$Data,
      () => SystemInfo$Data.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(Meta, () => Meta.fromJsonFactory);
    generatedMapping.putIfAbsent(
      Meta$Pagination,
      () => Meta$Pagination.fromJsonFactory,
    );
    generatedMapping.putIfAbsent(ObjectLink, () => ObjectLink.fromJsonFactory);
    generatedMapping.putIfAbsent(PageLink, () => PageLink.fromJsonFactory);
  }

  /// Get a FireflyService instance that can be used in tests
  /// Note: This doesn't create a real signed-in service, tests need to handle that
  FireflyService getFireflyService() {
    return fireflyService;
  }

  /// Set the signed in state of the mock service
  void setSignedIn(bool value) {
    _mockFireflyService.setSignedIn(value);
  }

  /// Set up a successful SystemInfo response for validateCredentials
  void setupSystemInfo({String? apiVersion}) {
    final Map<String, dynamic> response = MockApiResponses.systemInfo(
      apiVersion: apiVersion,
    );
    mockHttpClient.setJsonResponse(
      'http://test.firefly.local/api/v1/about',
      response,
    );
  }

  /// Set up transaction list response
  void setupTransactions({List<Map<String, dynamic>>? transactions}) {
    final Map<String, dynamic> response = MockApiResponses.transactionList(
      transactions: transactions,
    );
    // Handle pagination - set up handler for any page
    mockHttpClient.setHandler('/v1/transactions', (http.BaseRequest request) {
      return http.Response(
        jsonEncode(response),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
  }

  /// Set up account list response with pagination support
  void setupAccounts({
    List<Map<String, dynamic>>? accounts,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    // Use handler to support pagination
    mockHttpClient.setHandler('/v1/accounts', (http.BaseRequest request) {
      final Uri uri = request.url;
      final int page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final Map<String, dynamic> pageResponse = MockApiResponses.accountList(
        accounts: accounts,
        page: page,
        totalPages: totalPages ?? 1,
        updatedAt: updatedAt,
      );
      return http.Response(
        jsonEncode(pageResponse),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
  }

  /// Set up category list response with pagination support
  void setupCategories({
    List<Map<String, dynamic>>? categories,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    mockHttpClient.setHandler('/v1/categories', (http.BaseRequest request) {
      final Uri uri = request.url;
      final int page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final Map<String, dynamic> pageResponse = MockApiResponses.categoryList(
        categories: categories,
        page: page,
        totalPages: totalPages ?? 1,
        updatedAt: updatedAt,
      );
      return http.Response(
        jsonEncode(pageResponse),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
  }

  /// Set up tag list response with pagination support
  void setupTags({List<Map<String, dynamic>>? tags, int? totalPages}) {
    mockHttpClient.setHandler('/v1/tags', (http.BaseRequest request) {
      final Uri uri = request.url;
      final int page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final Map<String, dynamic> pageResponse = MockApiResponses.tagList(
        tags: tags,
        page: page,
        totalPages: totalPages ?? 1,
      );
      return http.Response(
        jsonEncode(pageResponse),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
  }

  /// Set up bill list response with pagination support
  void setupBills({List<Map<String, dynamic>>? bills, int? totalPages}) {
    mockHttpClient.setHandler('/v1/bills', (http.BaseRequest request) {
      final Uri uri = request.url;
      final int page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final Map<String, dynamic> pageResponse = MockApiResponses.billList(
        bills: bills,
        page: page,
        totalPages: totalPages ?? 1,
      );
      return http.Response(
        jsonEncode(pageResponse),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
  }

  /// Set up budget list response with pagination support
  void setupBudgets({List<Map<String, dynamic>>? budgets, int? totalPages}) {
    mockHttpClient.setHandler('/v1/budgets', (http.BaseRequest request) {
      final Uri uri = request.url;
      final int page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final Map<String, dynamic> pageResponse = MockApiResponses.budgetList(
        budgets: budgets,
        page: page,
        totalPages: totalPages ?? 1,
      );
      return http.Response(
        jsonEncode(pageResponse),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
  }

  /// Set up currency list response with pagination support
  void setupCurrencies({
    List<Map<String, dynamic>>? currencies,
    int? totalPages,
  }) {
    mockHttpClient.setHandler('/v1/currencies', (http.BaseRequest request) {
      final Uri uri = request.url;
      final int page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final Map<String, dynamic> pageResponse = MockApiResponses.currencyList(
        currencies: currencies,
        page: page,
        totalPages: totalPages ?? 1,
      );
      return http.Response(
        jsonEncode(pageResponse),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
  }

  /// Set up piggy bank list response with pagination support
  void setupPiggyBanks({
    List<Map<String, dynamic>>? piggyBanks,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    mockHttpClient.setHandler('/v1/piggy-banks', (http.BaseRequest request) {
      final Uri uri = request.url;
      final int page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
      final Map<String, dynamic> pageResponse = MockApiResponses.piggyBankList(
        piggyBanks: piggyBanks,
        page: page,
        totalPages: totalPages ?? 1,
        updatedAt: updatedAt,
      );
      return http.Response(
        jsonEncode(pageResponse),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
  }

  void clear() {
    mockHttpClient.clear();
  }
}

/// Internal mock FireflyService implementation
/// This is a minimal mock that provides the API interface
/// Note: It creates a real AuthUser but with mocked HTTP client
class _MockFireflyService extends FireflyService {
  final FireflyIii _mockApi;
  bool _mockSignedIn = false; // Start as not signed in to avoid issues
  AuthUser? _mockUser;

  _MockFireflyService(this._mockApi, MockHttpClient httpClient) {
    // Create a real AuthUser with test host, but it will use the mocked API
    // This allows sync_service to access user.host and user.headers()
    try {
      _mockUser = AuthUser.createWithoutValidation(
        'http://test.firefly.local',
        'test-api-key',
      );
      // Replace the API with our mocked one
      // Note: This is a workaround since AuthUser creates its own API
      // The sync service will use the mocked HTTP client for direct requests
    } catch (e) {
      // If creation fails, user will be null
    }
  }

  @override
  bool get signedIn => _mockSignedIn;

  @override
  AuthUser? get user {
    if (!_mockSignedIn) {
      return null;
    }
    return _mockUser;
  }

  @override
  FireflyIii get api {
    if (!_mockSignedIn) {
      throw Exception(
        "_MockFireflyService.api: API unavailable - not signed in",
      );
    }
    return _mockApi;
  }

  void setSignedIn(bool value) {
    _mockSignedIn = value;
    notifyListeners();
  }
}

/// Helper to create mock API responses
class MockApiResponses {
  static Map<String, dynamic> systemInfo({String? apiVersion}) {
    // Use actual model objects to ensure correct structure
    final SystemInfo$Data data = SystemInfo$Data(
      version: '1.0.0',
      apiVersion: apiVersion ?? '6.3.2',
      phpVersion: '8.1.0',
      os: 'Linux',
      driver: 'sqlite',
    );
    final SystemInfo info = SystemInfo(data: data);
    return info.toJson();
  }

  static Map<String, dynamic> transactionList({
    List<Map<String, dynamic>>? transactions,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    final DateTime now = updatedAt ?? DateTime.now().toUtc();

    // Create actual model objects to ensure correct structure
    final List<TransactionRead> transactionObjects;
    if (transactions != null) {
      transactionObjects = transactions
          .map((Map<String, dynamic> json) => TransactionRead.fromJson(json))
          .toList();
    } else {
      transactionObjects = <TransactionRead>[
        TransactionRead(
          type: 'transactions',
          id: 'tx-1',
          attributes: Transaction(
            createdAt: now,
            updatedAt: now,
            groupTitle: null,
            transactions: <TransactionSplit>[
              TransactionSplit(
                transactionJournalId: 'tx-1',
                type: enums.TransactionTypeProperty.withdrawal,
                date: now,
                order: 0,
                currencyId: '1',
                currencyCode: 'USD',
                currencySymbol: '\$',
                currencyDecimalPlaces: 2,
                amount: '10.00',
                description: 'Test transaction',
                sourceId: '1',
                sourceName: 'Source Account',
                sourceType: enums.AccountTypeProperty.assetAccount,
                destinationId: '2',
                destinationName: 'Destination Account',
                destinationType: enums.AccountTypeProperty.expenseAccount,
                reconciled: false,
                tags: const <String>[],
                hasAttachments: false,
              ),
            ],
          ),
          links: const ObjectLink(
            self: 'https://example.com/api/v1/transactions/tx-1',
          ),
        ),
      ];
    }

    // Create proper Meta, PageLink, and TransactionArray objects
    final Meta$Pagination pagination = Meta$Pagination(
      total: transactionObjects.length,
      count: transactionObjects.length,
      perPage: 50,
      currentPage: page ?? 1,
      totalPages: totalPages ?? 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final PageLink links = PageLink(
      self: 'http://test.firefly.local/api/v1/transactions?page=${page ?? 1}',
      first: 'http://test.firefly.local/api/v1/transactions?page=1',
      last:
          'http://test.firefly.local/api/v1/transactions?page=${totalPages ?? 1}',
    );
    final TransactionArray transactionArray = TransactionArray(
      data: transactionObjects,
      meta: meta,
      links: links,
    );

    return transactionArray.toJson();
  }

  static Map<String, dynamic> accountList({
    List<Map<String, dynamic>>? accounts,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    final DateTime now = updatedAt ?? DateTime.now().toUtc();

    // Create actual model objects to ensure correct structure
    final List<AccountRead> accountObjects;
    if (accounts != null) {
      accountObjects = accounts
          .map((Map<String, dynamic> json) => AccountRead.fromJson(json))
          .toList();
    } else {
      accountObjects = <AccountRead>[
        AccountRead(
          type: 'accounts',
          id: 'acc-1',
          attributes: AccountProperties(
            name: 'Test Account',
            type: enums.ShortAccountTypeProperty.asset,
            currencyId: '1',
            currencyCode: 'USD',
            currencySymbol: '\$',
            currencyDecimalPlaces: 2,
            createdAt: now,
            updatedAt: now,
            active: true,
            includeNetWorth: true,
          ),
        ),
      ];
    }

    // Create proper Meta and AccountArray objects
    final Meta$Pagination pagination = Meta$Pagination(
      total: accountObjects.length,
      count: accountObjects.length,
      perPage: 50,
      currentPage: page ?? 1,
      totalPages: totalPages ?? 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final AccountArray accountArray = AccountArray(
      data: accountObjects,
      meta: meta,
    );

    return accountArray.toJson();
  }

  static Map<String, dynamic> categoryList({
    List<Map<String, dynamic>>? categories,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    final DateTime now = updatedAt ?? DateTime.now().toUtc();

    // Create actual model objects
    final List<CategoryRead> categoryObjects;
    if (categories != null) {
      categoryObjects = categories
          .map((Map<String, dynamic> json) => CategoryRead.fromJson(json))
          .toList();
    } else {
      categoryObjects = <CategoryRead>[
        CategoryRead(
          type: 'categories',
          id: 'cat-1',
          attributes: CategoryProperties(
            name: 'Test Category',
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ];
    }

    final Meta$Pagination pagination = Meta$Pagination(
      total: categoryObjects.length,
      count: categoryObjects.length,
      perPage: 50,
      currentPage: page ?? 1,
      totalPages: totalPages ?? 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final CategoryArray categoryArray = CategoryArray(
      data: categoryObjects,
      meta: meta,
    );

    return categoryArray.toJson();
  }

  static Map<String, dynamic> tagList({
    List<Map<String, dynamic>>? tags,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    final DateTime now = updatedAt ?? DateTime.now().toUtc();

    // Create actual model objects
    final List<TagRead> tagObjects;
    if (tags != null) {
      tagObjects = tags
          .map((Map<String, dynamic> json) => TagRead.fromJson(json))
          .toList();
    } else {
      tagObjects = <TagRead>[
        TagRead(
          type: 'tags',
          id: 'tag-1',
          attributes: TagModel(tag: 'test-tag', createdAt: now, updatedAt: now),
          links: const ObjectLink(
            self: 'https://example.com/api/v1/tags/tag-1',
          ),
        ),
      ];
    }

    final Meta$Pagination pagination = Meta$Pagination(
      total: tagObjects.length,
      count: tagObjects.length,
      perPage: 50,
      currentPage: page ?? 1,
      totalPages: totalPages ?? 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final PageLink links = PageLink(
      self: 'http://test.firefly.local/api/v1/tags?page=${page ?? 1}',
      first: 'http://test.firefly.local/api/v1/tags?page=1',
      last: 'http://test.firefly.local/api/v1/tags?page=${totalPages ?? 1}',
    );
    final TagArray tagArray = TagArray(
      data: tagObjects,
      meta: meta,
      links: links,
    );

    return tagArray.toJson();
  }

  static Map<String, dynamic> billList({
    List<Map<String, dynamic>>? bills,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    final DateTime now = updatedAt ?? DateTime.now().toUtc();

    // Create actual model objects
    final List<BillRead> billObjects;
    if (bills != null) {
      billObjects = bills
          .map((Map<String, dynamic> json) => BillRead.fromJson(json))
          .toList();
    } else {
      billObjects = <BillRead>[
        BillRead(
          type: 'bills',
          id: 'bill-1',
          attributes: BillProperties(
            name: 'Test Bill',
            amountMin: '10.00',
            amountMax: '20.00',
            currencyId: '1',
            currencyCode: 'USD',
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ];
    }

    final Meta$Pagination pagination = Meta$Pagination(
      total: billObjects.length,
      count: billObjects.length,
      perPage: 50,
      currentPage: page ?? 1,
      totalPages: totalPages ?? 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final BillArray billArray = BillArray(data: billObjects, meta: meta);

    return billArray.toJson();
  }

  static Map<String, dynamic> budgetList({
    List<Map<String, dynamic>>? budgets,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    final DateTime now = updatedAt ?? DateTime.now().toUtc();

    // Create actual model objects
    final List<BudgetRead> budgetObjects;
    if (budgets != null) {
      budgetObjects = budgets
          .map((Map<String, dynamic> json) => BudgetRead.fromJson(json))
          .toList();
    } else {
      budgetObjects = <BudgetRead>[
        BudgetRead(
          type: 'budgets',
          id: 'budget-1',
          attributes: BudgetProperties(
            name: 'Test Budget',
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ];
    }

    final Meta$Pagination pagination = Meta$Pagination(
      total: budgetObjects.length,
      count: budgetObjects.length,
      perPage: 50,
      currentPage: page ?? 1,
      totalPages: totalPages ?? 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final BudgetArray budgetArray = BudgetArray(
      data: budgetObjects,
      meta: meta,
    );

    return budgetArray.toJson();
  }

  static Map<String, dynamic> currencyList({
    List<Map<String, dynamic>>? currencies,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    final DateTime now = updatedAt ?? DateTime.now().toUtc();

    // Create actual model objects
    final List<CurrencyRead> currencyObjects;
    if (currencies != null) {
      currencyObjects = currencies
          .map((Map<String, dynamic> json) => CurrencyRead.fromJson(json))
          .toList();
    } else {
      currencyObjects = <CurrencyRead>[
        CurrencyRead(
          type: 'currencies',
          id: '1',
          attributes: CurrencyProperties(
            name: 'US Dollar',
            code: 'USD',
            symbol: '\$',
            decimalPlaces: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ];
    }

    final Meta$Pagination pagination = Meta$Pagination(
      total: currencyObjects.length,
      count: currencyObjects.length,
      perPage: 50,
      currentPage: page ?? 1,
      totalPages: totalPages ?? 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final PageLink links = PageLink(
      self: 'http://test.firefly.local/api/v1/currencies?page=${page ?? 1}',
      first: 'http://test.firefly.local/api/v1/currencies?page=1',
      last:
          'http://test.firefly.local/api/v1/currencies?page=${totalPages ?? 1}',
    );
    final CurrencyArray currencyArray = CurrencyArray(
      data: currencyObjects,
      meta: meta,
      links: links,
    );

    return currencyArray.toJson();
  }

  static Map<String, dynamic> piggyBankList({
    List<Map<String, dynamic>>? piggyBanks,
    int? page,
    int? totalPages,
    DateTime? updatedAt,
  }) {
    final DateTime now = updatedAt ?? DateTime.now().toUtc();

    // Create actual model objects
    final List<PiggyBankRead> piggyBankObjects;
    if (piggyBanks != null) {
      piggyBankObjects = piggyBanks
          .map((Map<String, dynamic> json) => PiggyBankRead.fromJson(json))
          .toList();
    } else {
      piggyBankObjects = <PiggyBankRead>[
        PiggyBankRead(
          type: 'piggy_banks',
          id: 'piggy-1',
          attributes: PiggyBankProperties(
            name: 'Test Piggy Bank',
            targetAmount: '100.00',
            currentAmount: '50.00',
            currencyId: '1',
            currencyCode: 'USD',
            createdAt: now,
            updatedAt: now,
          ),
          links: const ObjectLink(
            self: 'https://example.com/api/v1/piggy-banks/piggy-1',
          ),
        ),
      ];
    }

    final Meta$Pagination pagination = Meta$Pagination(
      total: piggyBankObjects.length,
      count: piggyBankObjects.length,
      perPage: 50,
      currentPage: page ?? 1,
      totalPages: totalPages ?? 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final PageLink links = PageLink(
      self: 'http://test.firefly.local/api/v1/piggy-banks?page=${page ?? 1}',
      first: 'http://test.firefly.local/api/v1/piggy-banks?page=1',
      last:
          'http://test.firefly.local/api/v1/piggy-banks?page=${totalPages ?? 1}',
    );
    final PiggyBankArray piggyBankArray = PiggyBankArray(
      data: piggyBankObjects,
      meta: meta,
      links: links,
    );

    return piggyBankArray.toJson();
  }

  static Map<String, dynamic> transactionSingle({
    Map<String, dynamic>? transaction,
  }) {
    return <String, dynamic>{
      'data':
          transaction ??
          <String, dynamic>{
            'type': 'transactions',
            'id': 'tx-1',
            'attributes': <String, Object>{
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
              'transactions': <Map<String, String>>[
                <String, String>{
                  'type': 'withdrawal',
                  'date': DateTime.now().toUtc().toIso8601String(),
                  'amount': '10.00',
                  'description': 'Test transaction',
                  'currency_id': '1',
                  'currency_code': 'USD',
                },
              ],
            },
            'links': <String, String>{
              'self': 'https://example.com/api/v1/transactions/tx-1',
            },
          },
    };
  }

  static Map<String, dynamic> accountSingle({Map<String, dynamic>? account}) {
    return <String, dynamic>{
      'data':
          account ??
          <String, dynamic>{
            'type': 'accounts',
            'id': 'acc-1',
            'attributes': <String, String>{
              'name': 'Test Account',
              'type': 'asset',
              'currency_id': '1',
              'currency_code': 'USD',
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            'links': <String, String>{
              'self': 'https://example.com/api/v1/accounts/acc-1',
            },
          },
    };
  }

  static Map<String, dynamic> budgetLimitList({
    List<Map<String, dynamic>>? budgetLimits,
  }) {
    final DateTime now = DateTime.now().toUtc();

    // Create actual model objects
    final List<BudgetLimitRead> budgetLimitObjects;
    if (budgetLimits != null) {
      budgetLimitObjects = budgetLimits
          .map((Map<String, dynamic> json) => BudgetLimitRead.fromJson(json))
          .toList();
    } else {
      budgetLimitObjects = <BudgetLimitRead>[
        BudgetLimitRead(
          type: 'budget_limits',
          id: 'limit-1',
          attributes: BudgetLimitProperties(
            start: now,
            end: now.add(const Duration(days: 30)),
            amount: '100.00',
            budgetId: 'budget-1',
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ];
    }

    final Meta$Pagination pagination = Meta$Pagination(
      total: budgetLimitObjects.length,
      count: budgetLimitObjects.length,
      perPage: 50,
      currentPage: 1,
      totalPages: 1,
    );
    final Meta meta = Meta(pagination: pagination);
    final BudgetLimitArray budgetLimitArray = BudgetLimitArray(
      data: budgetLimitObjects,
      meta: meta,
    );

    return budgetLimitArray.toJson();
  }
}
