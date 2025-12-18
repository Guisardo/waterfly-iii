import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart'
    show
        Chain,
        HttpMethod,
        Interceptor,
        Request,
        Response,
        StripStringExtension,
        applyHeaders;
import 'package:cronet_http/cronet_http.dart';
import 'package:drift/drift.dart' show Batch, InsertMode, Value;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:version/version.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/providers/sync_provider.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';
import 'package:waterflyiii/services/sync/metadata_service.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';
import 'package:waterflyiii/services/app_mode/app_mode_manager.dart';
import 'package:waterflyiii/services/app_mode/app_mode.dart';
import 'package:waterflyiii/stock.dart';
import 'package:waterflyiii/timezonehandler.dart';

final Logger log = Logger("Auth");
final Version minApiVersion = Version(6, 3, 2);

class APITZReply {
  APITZReply(this.data);
  APITZReplyData data;

  factory APITZReply.fromJson(dynamic json) {
    return APITZReply(APITZReplyData.fromJson(json['data']));
  }
}

class APITZReplyData {
  APITZReplyData(this.title, this.value, this.editable);
  String title;
  String value;
  bool editable;

  factory APITZReplyData.fromJson(dynamic json) {
    return APITZReplyData(
      json['title'] as String,
      json['value'] as String,
      json['editable'] as bool,
    );
  }
}

/// Authentication error with localization support.
///
/// The [cause] field contains a localization key that should be translated
/// using the app's localization system (e.g., AppLocalizations).
///
/// Example usage:
/// ```dart
/// throw AuthError('auth.error.invalid_credentials');
/// // In UI: Text(AppLocalizations.of(context)!.translate(error.cause))
/// ```
class AuthError implements Exception {
  const AuthError(this.cause);

  /// Localization key for the error message.
  /// Should be translated using the app's localization system.
  final String cause;

  @override
  String toString() => 'AuthError: $cause';
}

class AuthErrorHost extends AuthError {
  const AuthErrorHost(this.host) : super("Invalid host");

  final String host;
}

class AuthErrorApiKey extends AuthError {
  const AuthErrorApiKey() : super("Invalid API key");
}

class AuthErrorVersionInvalid extends AuthError {
  const AuthErrorVersionInvalid() : super("Invalid Firefly API version");
}

class AuthErrorVersionTooLow extends AuthError {
  const AuthErrorVersionTooLow(this.requiredVersion)
    : super("Firefly API version too low");

  final Version requiredVersion;
}

class AuthErrorStatusCode extends AuthError {
  const AuthErrorStatusCode(this.code) : super("Unexpected HTTP status code");

  final int code;
}

class AuthErrorNoInstance extends AuthError {
  const AuthErrorNoInstance(this.host)
    : super("Not a valid Firefly III instance");

  final String host;
}

http.Client get httpClient =>
    CronetClient.fromCronetEngine(CronetEngine.build(), closeEngine: false);

class APIRequestInterceptor implements Interceptor {
  APIRequestInterceptor(this.headerFunc);

  final Function() headerFunc;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) {
    log.finest(() => "API query ${chain.request.method} ${chain.request.url}");
    if (chain.request.body != null) {
      log.finest(() => "Query Body: ${chain.request.body}");
    }
    final Request request = applyHeaders(
      chain.request,
      headerFunc(),
      override: true,
    );
    request.followRedirects = true;
    request.maxRedirects = 5;
    return chain.proceed(request);
  }
}

class AuthUser {
  late Uri _host;
  late String _apiKey;
  late FireflyIii _api;

  //late FireflyIiiV2 _apiV2;

  Uri get host => _host;
  FireflyIii get api => _api;

  //FireflyIiiV2 get apiV2 => _apiV2;

  final Logger log = Logger("Auth.AuthUser");

  AuthUser._create(Uri host, String apiKey) {
    log.config("AuthUser->_create($host)");
    _apiKey = apiKey;

    _host = host.replace(pathSegments: <String>[...host.pathSegments, "api"]);

    _api = FireflyIii.create(
      baseUrl: _host,
      httpClient: httpClient,
      interceptors: <Interceptor>[APIRequestInterceptor(headers)],
    );

    /*_apiV2 = FireflyIiiV2.create(
      baseUrl: _host,
      httpClient: httpClient,
      interceptors: <Interceptor>[APIRequestInterceptor(headers)],
    );*/
  }

  Map<String, String> headers() {
    return <String, String>{
      HttpHeaders.authorizationHeader: "Bearer $_apiKey",
      HttpHeaders.acceptHeader: "application/json",
    };
  }

  static Future<AuthUser> create(String host, String apiKey) async {
    final Logger log = Logger("Auth.AuthUser");
    log.config("AuthUser->create($host)");

    // Check app mode before making API calls
    // Wait for AppModeManager to initialize if it hasn't yet
    final AppModeManager appModeManager = AppModeManager();
    if (!appModeManager.isInitialized) {
      // Wait a short time for initialization (max 2 seconds)
      int attempts = 0;
      while (!appModeManager.isInitialized && attempts < 20) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    }

    if (appModeManager.isInitialized && appModeManager.currentMode == AppMode.offline) {
      log.info('Skipping authentication API call - app is in offline mode (mobile data may be disabled)');
      throw const AuthError("App is in offline mode");
    }

    // This call is on purpose not using the Swagger API
    final http.Client client = httpClient;
    late Uri uri;

    try {
      uri = Uri.parse(host);
    } on FormatException {
      throw AuthErrorHost(host);
    }

    final Uri aboutUri = uri.replace(
      pathSegments: <String>[...uri.pathSegments, "api", "v1", "about"],
    );

    try {
      final http.Request request = http.Request(HttpMethod.Get, aboutUri);
      request.headers[HttpHeaders.authorizationHeader] = "Bearer $apiKey";
      // See #497, redirect is a bad way to check for (un)successful login.
      request.followRedirects = true;
      request.maxRedirects = 5;
      final http.StreamedResponse response = await client.send(request);

      // If we get an html page, it's most likely the login page, and auth failed
      if (response.headers[HttpHeaders.contentTypeHeader]?.startsWith(
            "text/html",
          ) ??
          true) {
        throw const AuthErrorApiKey();
      }
      if (response.statusCode != 200) {
        throw AuthErrorStatusCode(response.statusCode);
      }

      final String stringData = await response.stream.bytesToString();

      try {
        SystemInfo.fromJson(json.decode(stringData));
      } on FormatException {
        throw AuthErrorNoInstance(host);
      }
    } finally {
      client.close();
    }

    return AuthUser._create(uri, apiKey);
  }
}

class FireflyService with ChangeNotifier {
  AuthUser? _currentUser;
  AuthUser? get user => _currentUser;
  bool _signedIn = false;
  bool get signedIn => _signedIn;
  String? _lastTriedHost;
  String? get lastTriedHost => _lastTriedHost;
  Object? _storageSignInException;
  Object? get storageSignInException => _storageSignInException;
  Version? _apiVersion;
  Version? get apiVersion => _apiVersion;

  TransStock? _transStock;
  TransStock? get transStock => _transStock;

  bool get hasApi => (_currentUser?.api != null) ? true : false;
  FireflyIii get api {
    if (_currentUser?.api == null) {
      signOut();
      throw Exception("FireflyService.api: API unavailable");
    }
    return _currentUser!.api;
  }

  /*FireflyIiiV2 get apiV2 {
    if (_currentUser?.apiV2 == null) {
      signOut();
      throw Exception("FireflyService.apiV2: API unavailable");
    }
    return _currentUser!.apiV2;
  }*/

  late CurrencyRead defaultCurrency;
  late TimeZoneHandler tzHandler;

  final FlutterSecureStorage storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  final Logger log = Logger("Auth.FireflyService");

  FireflyService() {
    log.finest(() => "new FireflyService");
  }

  Future<bool> signInFromStorage() async {
    _storageSignInException = null;
    final String? apiHost = await storage.read(key: 'api_host');
    final String? apiKey = await storage.read(key: 'api_key');

    log.config(
      "storage: $apiHost, apiKey ${apiKey?.isEmpty ?? true ? "unset" : "set"}",
    );

    if (apiHost == null || apiKey == null) {
      return false;
    }

    // Check app mode before attempting sign-in
    // Wait for AppModeManager to initialize if it hasn't yet
    final AppModeManager appModeManager = AppModeManager();
    if (!appModeManager.isInitialized) {
      // Wait a short time for initialization (max 2 seconds)
      int attempts = 0;
      while (!appModeManager.isInitialized && attempts < 20) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    }

    if (appModeManager.isInitialized && appModeManager.currentMode == AppMode.offline) {
      log.info('App is in offline mode (mobile data may be disabled), attempting offline sign-in');
      return _signInOffline(apiHost, apiKey);
    }

    try {
      await signIn(apiHost, apiKey);
      return true;
    } catch (e) {
      // Try offline mode if network error or app mode is offline
      if (e is SocketException ||
          e is TimeoutException ||
          e is http.ClientException ||
          (e is AuthError && e.cause == "App is in offline mode")) {
        log.info("Network error or offline mode during sign in, attempting offline mode");
        return _signInOffline(apiHost, apiKey);
      }
      _storageSignInException = e;
      log.finest(() => "notify FireflyService->signInFromStorage");
      notifyListeners();
      return false;
    }
  }

  Future<bool> _signInOffline(String host, String apiKey) async {
    log.config("FireflyService->_signInOffline($host)");

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if we have cached data
    final String? cachedCurrency = prefs.getString('cached_default_currency');
    final String? cachedApiVersion = prefs.getString('cached_api_version');
    final String? cachedTimezone = prefs.getString('cached_timezone');

    if (cachedCurrency == null ||
        cachedApiVersion == null ||
        cachedTimezone == null) {
      log.warning("Missing cached data for offline mode");
      return false;
    }

    try {
      host = host.strip().rightStrip('/');
      apiKey = apiKey.strip();

      final Uri uri = Uri.parse(host);
      _currentUser = AuthUser._create(uri, apiKey);

      // Restore cached data
      defaultCurrency = CurrencyRead.fromJson(json.decode(cachedCurrency));
      _apiVersion = Version.parse(cachedApiVersion);
      tzHandler = TimeZoneHandler(cachedTimezone);

      _signedIn = true;
      _transStock = TransStock(api);

      log.info("Signed in offline mode with cached data");
      log.finest(() => "notify FireflyService->_signInOffline");
      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      log.warning("Failed to sign in offline", e, stackTrace);
      return false;
    }
  }

  Future<void> signOut() async {
    log.config("FireflyService->signOut()");
    _currentUser = null;
    _signedIn = false;
    _storageSignInException = null;
    await storage.deleteAll();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    log.finest(() => "notify FireflyService->signOut");
    notifyListeners();
  }

  Future<bool> signIn(String host, String apiKey) async {
    log.config("FireflyService->signIn($host)");
    host = host.strip().rightStrip('/');
    apiKey = apiKey.strip();

    // Check app mode before making API calls
    // Wait for AppModeManager to initialize if it hasn't yet
    final AppModeManager appModeManager = AppModeManager();
    if (!appModeManager.isInitialized) {
      // Wait a short time for initialization (max 2 seconds)
      int attempts = 0;
      while (!appModeManager.isInitialized && attempts < 20) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    }

    if (appModeManager.isInitialized && appModeManager.currentMode == AppMode.offline) {
      log.info('Skipping sign-in API calls - app is in offline mode (mobile data may be disabled)');
      // Try offline sign-in instead
      return _signInOffline(host, apiKey);
    }

    _lastTriedHost = host;
    _currentUser = await AuthUser.create(host, apiKey);
    if (_currentUser == null || !hasApi) return false;

    final Response<CurrencySingle> currencyInfo =
        await api.v1CurrenciesPrimaryGet();
    defaultCurrency = currencyInfo.body!.data;

    final Response<SystemInfo> about = await api.v1AboutGet();
    try {
      String apiVersionStr = about.body?.data?.apiVersion ?? "";
      if (apiVersionStr.startsWith("develop/")) {
        apiVersionStr = "9.9.9";
      }
      _apiVersion = Version.parse(apiVersionStr);
    } on FormatException {
      throw const AuthErrorVersionInvalid();
    }
    log.info(() => "Firefly API version $_apiVersion");
    if (apiVersion == null || apiVersion! < minApiVersion) {
      throw AuthErrorVersionTooLow(minApiVersion);
    }

    // Manual API query as the Swagger type doesn't resolve in Flutter :(
    final http.Client client = httpClient;
    final Uri tzUri = user!.host.replace(
      pathSegments: <String>[
        ...user!.host.pathSegments,
        "v1",
        "configuration",
        ConfigValueFilter.appTimezone.value!,
      ],
    );
    try {
      final http.Response response = await client.get(
        tzUri,
        headers: user!.headers(),
      );
      final APITZReply reply = APITZReply.fromJson(json.decode(response.body));
      tzHandler = TimeZoneHandler(reply.data.value);
    } finally {
      client.close();
    }

    _signedIn = true;
    _transStock = TransStock(api);
    log.finest(() => "notify FireflyService->signIn");
    notifyListeners();

    await storage.write(key: 'api_host', value: host);
    await storage.write(key: 'api_key', value: apiKey);

    // Cache data for offline mode
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cached_default_currency',
      json.encode(defaultCurrency.toJson()),
    );
    await prefs.setString('cached_api_version', _apiVersion.toString());
    await prefs.setString('cached_timezone', tzHandler.sLocation.name);

    // Trigger initial sync to populate local database for offline use
    _triggerInitialSync();

    return true;
  }

  /// Triggers initial full sync in background to populate local database
  void _triggerInitialSync() {
    // Delay sync to not interfere with initial app loading
    Future<void>.delayed(const Duration(seconds: 5), () async {
      try {
        log.info('Triggering initial sync to populate local database...');

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final int lastSyncTime = prefs.getInt('last_full_sync_time') ?? 0;
        final int now = DateTime.now().millisecondsSinceEpoch;

        log.fine(
          'Sync time check: lastSyncTime=$lastSyncTime, now=$now, diff=${now - lastSyncTime}, threshold=3600000',
        );

        // Only sync if last sync was more than 1 hour ago
        if (now - lastSyncTime > 3600000) {
          // Check app mode - don't sync if in offline mode (e.g., mobile data disabled)
          final AppModeManager appModeManager = AppModeManager();
          if (!appModeManager.isInitialized) {
            await appModeManager.initialize();
          }
          final AppMode currentMode = appModeManager.currentMode;
          if (currentMode == AppMode.offline) {
            log.info('Skipping initial sync - app is in offline mode (mobile data may be disabled)');
            return;
          }

          // Notify sync started with estimated operations
          // 6 entity types: accounts, categories, budgets, bills, piggy_banks, transactions
          notifyGlobalSyncState(true, totalOperations: 6);
          updateGlobalSyncProgress(currentOperation: 'Preparing...');

          // Use singleton database instance (same as Provider's)
          final AppDatabase database = AppDatabase();
          log.fine('Using database instance: ${database.hashCode}');
          final FireflyApiAdapter apiAdapter = FireflyApiAdapter(api);

          // Check if incremental sync is possible
          final CacheService cacheService = CacheService(database: database);
          final IncrementalSyncService incrementalSync = IncrementalSyncService(
            database: database,
            apiAdapter: apiAdapter,
            cacheService: cacheService,
          );

          // Try incremental sync first if possible
          final bool canUseIncremental = await incrementalSync.canUseIncrementalSync();
          if (canUseIncremental) {
            log.info('Using incremental sync (with sort/order optimization)');
            try {
              final IncrementalSyncResult result = await incrementalSync.performIncrementalSync();
              // Use incremental sync if it was actually incremental, even if some entities failed
              // (partial success is better than falling back to full sync)
              if (result.isIncremental) {
                if (result.success) {
                  log.info('Incremental sync completed successfully');
                } else {
                  log.warning('Incremental sync completed with some failures: ${result.error}');
                }
                // Store timestamp in both SharedPreferences (for backward compatibility) and database
                await prefs.setInt('last_full_sync_time', now);
                final MetadataService metadata = MetadataService(database);
                await metadata.set('last_full_sync', DateTime.now().toIso8601String());
                notifyGlobalSyncState(false);
                return;
              } else {
                log.info('Incremental sync not possible, falling back to full sync');
              }
            } catch (e, stackTrace) {
              log.warning('Incremental sync failed, falling back to full sync', e, stackTrace);
            }
          } else {
            log.info('Performing full sync (incremental sync not available)');
          }

          // Perform full sync with progress tracking
          await _performSyncWithProgress(database, apiAdapter);

          // Store timestamp in both SharedPreferences (for backward compatibility) and database
          await prefs.setInt('last_full_sync_time', now);
          final MetadataService metadata = MetadataService(database);
          await metadata.set('last_full_sync', DateTime.now().toIso8601String());

          // Notify sync completed
          notifyGlobalSyncState(false);

          log.info('Initial sync completed successfully');
        } else {
          log.info('Skipping initial sync - recent sync exists');
        }
      } catch (e, stackTrace) {
        notifyGlobalSyncState(false);
        log.warning('Initial sync failed (non-critical)', e, stackTrace);
      }
    });
  }

  /// Performs full sync with granular progress reporting
  Future<void> _performSyncWithProgress(
    AppDatabase database,
    FireflyApiAdapter apiAdapter,
  ) async {
    int completedSteps = 0;
    const int totalSteps = 6;

    void updateStep(String operation) {
      completedSteps++;
      updateGlobalSyncProgress(
        currentOperation: operation,
        completedOperations: completedSteps,
        totalOperations: totalSteps,
      );
      log.info('Sync progress: $completedSteps/$totalSteps - $operation');
    }

    // Sync order: accounts first, then categories, piggy banks, budgets, bills, transactions last
    // Each entity type is saved immediately after fetching for better UX

    // Step 1: Fetch and save accounts (most important - needed for other views)
    updateGlobalSyncProgress(currentOperation: 'Syncing accounts...');
    final List<Map<String, dynamic>> accounts =
        await apiAdapter.getAllAccounts();
    log.fine('Fetched ${accounts.length} accounts from API');
    await _saveAccounts(database, accounts);
    updateStep('Accounts: ${accounts.length}');

    // Step 2: Fetch and save categories
    updateGlobalSyncProgress(currentOperation: 'Syncing categories...');
    final List<Map<String, dynamic>> categories =
        await apiAdapter.getAllCategories();
    await _saveCategories(database, categories);
    updateStep('Categories: ${categories.length}');

    // Step 3: Fetch and save piggy banks (depends on accounts)
    updateGlobalSyncProgress(currentOperation: 'Syncing piggy banks...');
    final List<Map<String, dynamic>> piggyBanks =
        await apiAdapter.getAllPiggyBanks();
    await _savePiggyBanks(database, piggyBanks);
    updateStep('Piggy banks: ${piggyBanks.length}');

    // Step 4: Fetch and save budgets
    updateGlobalSyncProgress(currentOperation: 'Syncing budgets...');
    final List<Map<String, dynamic>> budgets = await apiAdapter.getAllBudgets();
    await _saveBudgets(database, budgets);
    updateStep('Budgets: ${budgets.length}');

    // Step 5: Fetch and save bills
    updateGlobalSyncProgress(currentOperation: 'Syncing bills...');
    final List<Map<String, dynamic>> bills = await apiAdapter.getAllBills();
    await _saveBills(database, bills);
    updateStep('Bills: ${bills.length}');

    // Step 6: Fetch and save transactions (slowest - done last)
    updateGlobalSyncProgress(currentOperation: 'Syncing transactions...');
    final List<Map<String, dynamic>> transactions =
        await _fetchTransactionsWithProgress(apiAdapter);
    await _saveTransactions(database, transactions);
    updateStep('Transactions: ${transactions.length}');

    updateGlobalSyncProgress(currentOperation: 'Sync complete!');
  }

  /// Fetch transactions with progress reporting for pagination
  Future<List<Map<String, dynamic>>> _fetchTransactionsWithProgress(
    FireflyApiAdapter apiAdapter,
  ) async {
    final List<Map<String, dynamic>> allTransactions = <Map<String, dynamic>>[];
    int page = 1;
    int? totalPages;

    while (true) {
      // Update progress with page info
      final String pageInfo =
          totalPages != null ? 'page $page/$totalPages' : 'page $page';
      updateGlobalSyncProgress(currentOperation: 'Transactions ($pageInfo)...');

      final Response<TransactionArray> response = await api.v1TransactionsGet(
        page: page,
      );

      if (!response.isSuccessful || response.body == null) {
        throw Exception('Failed to fetch transactions: ${response.error}');
      }

      // Try to get total pages from pagination meta
      if (totalPages == null) {
        final Meta meta = response.body!.meta;
        final Meta$Pagination? pagination = meta.pagination;
        if (pagination != null) {
          totalPages = pagination.totalPages;
        }
      }

      final List<TransactionRead> transactions = response.body!.data;
      if (transactions.isEmpty) break;

      for (final TransactionRead transaction in transactions) {
        allTransactions.add(<String, dynamic>{
          'id': transaction.id,
          'type': transaction.type,
          'attributes': transaction.attributes.toJson(),
        });
      }

      // Update progress based on pages if we know total
      if (totalPages != null && totalPages > 0) {
        // Keep base progress at step 5 (out of 6), add fractional progress for pages
        final double pageProgress = page / totalPages;
        final double overallProgress = (5 + pageProgress) / 6;
        updateGlobalSyncProgress(progress: overallProgress);
      }

      page++;
    }

    log.info(
      'Fetched ${allTransactions.length} transactions in ${page - 1} pages',
    );
    updateGlobalSyncProgress(
      currentOperation: 'Transactions: ${allTransactions.length}',
    );
    return allTransactions;
  }

  /// Save accounts to local database (uses insertOnConflictUpdate to preserve existing data)
  Future<void> _saveAccounts(
    AppDatabase database,
    List<Map<String, dynamic>> accounts,
  ) async {
    log.fine('Saving ${accounts.length} accounts to database');
    try {
      // Log first account for debugging
      if (accounts.isNotEmpty) {
        final Map<String, dynamic> first = accounts.first;
        log.fine(
          'First account sample: id=${first['id']}, attrs keys=${(first['attributes'] as Map<String, dynamic>?)?.keys.toList()}',
        );
      }

      await database.batch((Batch batch) {
        for (final Map<String, dynamic> account in accounts) {
          final Map<String, dynamic> attrs =
              account['attributes'] as Map<String, dynamic>;
          // Parse current_balance - API returns it as String, not num
          final dynamic rawBalance = attrs['current_balance'];
          final double balance =
              rawBalance is num
                  ? rawBalance.toDouble()
                  : double.tryParse(rawBalance?.toString() ?? '') ?? 0.0;

          batch.insert(
            database.accounts,
            AccountEntityCompanion.insert(
            id: account['id'] as String,
            serverId: Value<String?>(account['id'] as String),
            name: attrs['name'] as String,
            type: attrs['type'] as String,
            accountNumber: Value<String?>(attrs['account_number'] as String?),
            accountRole: Value<String?>(attrs['account_role'] as String?),
            iban: Value<String?>(attrs['iban'] as String?),
            currencyCode: attrs['currency_code'] as String? ?? 'USD',
            currentBalance: balance,
            notes: Value<String?>(attrs['notes'] as String?),
            createdAt:
                DateTime.tryParse(attrs['created_at'] as String? ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(attrs['updated_at'] as String? ?? '') ??
                DateTime.now(),
            isSynced: const Value<bool>(true),
            syncStatus: const Value<String>('synced'),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      log.info('Saved ${accounts.length} accounts to database');
    } catch (e, stackTrace) {
      log.severe('Failed to save accounts: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Save categories to local database
  Future<void> _saveCategories(
    AppDatabase database,
    List<Map<String, dynamic>> categories,
  ) async {
    log.fine('Saving ${categories.length} categories to database');
    await database.batch((Batch batch) {
      for (final Map<String, dynamic> category in categories) {
        final Map<String, dynamic> attrs =
            category['attributes'] as Map<String, dynamic>;
        batch.insert(
          database.categories,
          CategoryEntityCompanion.insert(
            id: category['id'] as String,
            serverId: Value<String?>(category['id'] as String),
            name: attrs['name'] as String,
            notes: Value<String?>(attrs['notes'] as String?),
            createdAt:
                DateTime.tryParse(attrs['created_at'] as String? ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(attrs['updated_at'] as String? ?? '') ??
                DateTime.now(),
            isSynced: const Value<bool>(true),
            syncStatus: const Value<String>('synced'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    log.info('Saved ${categories.length} categories to database');
  }

  /// Save piggy banks to local database
  Future<void> _savePiggyBanks(
    AppDatabase database,
    List<Map<String, dynamic>> piggyBanks,
  ) async {
    log.fine('Saving ${piggyBanks.length} piggy banks to database');
    await database.batch((Batch batch) {
      for (final Map<String, dynamic> piggyBank in piggyBanks) {
        final Map<String, dynamic> attrs =
            piggyBank['attributes'] as Map<String, dynamic>;

        // Parse amounts - API may return as String
        final dynamic rawTarget = attrs['target_amount'];
        final double? targetAmount =
            rawTarget is num
                ? rawTarget.toDouble()
                : double.tryParse(rawTarget?.toString() ?? '');
        final dynamic rawCurrent = attrs['current_amount'];
        final double currentAmount =
            rawCurrent is num
                ? rawCurrent.toDouble()
                : double.tryParse(rawCurrent?.toString() ?? '') ?? 0.0;

        batch.insert(
          database.piggyBanks,
          PiggyBankEntityCompanion.insert(
            id: piggyBank['id'] as String,
            serverId: Value<String?>(piggyBank['id'] as String),
            name: attrs['name'] as String,
            accountId: attrs['account_id']?.toString() ?? '',
            targetAmount: Value<double?>(targetAmount),
            currentAmount: Value<double?>(currentAmount),
            startDate: Value<DateTime?>(
              attrs['start_date'] != null
                  ? DateTime.tryParse(attrs['start_date'] as String)
                  : null,
            ),
            targetDate: Value<DateTime?>(
              attrs['target_date'] != null
                  ? DateTime.tryParse(attrs['target_date'] as String)
                  : null,
            ),
            createdAt:
                DateTime.tryParse(attrs['created_at'] as String? ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(attrs['updated_at'] as String? ?? '') ??
                DateTime.now(),
            isSynced: const Value<bool>(true),
            syncStatus: const Value<String>('synced'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    log.info('Saved ${piggyBanks.length} piggy banks to database');
  }

  /// Save budgets to local database
  Future<void> _saveBudgets(
    AppDatabase database,
    List<Map<String, dynamic>> budgets,
  ) async {
    log.fine('Saving ${budgets.length} budgets to database');
    await database.batch((Batch batch) {
      for (final Map<String, dynamic> budget in budgets) {
        final Map<String, dynamic> attrs =
            budget['attributes'] as Map<String, dynamic>;
        batch.insert(
          database.budgets,
          BudgetEntityCompanion.insert(
            id: budget['id'] as String,
            serverId: Value<String?>(budget['id'] as String),
            name: attrs['name'] as String,
            createdAt:
                DateTime.tryParse(attrs['created_at'] as String? ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(attrs['updated_at'] as String? ?? '') ??
                DateTime.now(),
            isSynced: const Value<bool>(true),
            syncStatus: const Value<String>('synced'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    log.info('Saved ${budgets.length} budgets to database');
  }

  /// Save bills to local database
  Future<void> _saveBills(
    AppDatabase database,
    List<Map<String, dynamic>> bills,
  ) async {
    log.fine('Saving ${bills.length} bills to database');
    await database.batch((Batch batch) {
      for (final Map<String, dynamic> bill in bills) {
        final Map<String, dynamic> attrs =
            bill['attributes'] as Map<String, dynamic>;

        // Parse amounts - API may return as String
        final dynamic rawMin = attrs['amount_min'];
        final double minAmount =
            rawMin is num
                ? rawMin.toDouble()
                : double.tryParse(rawMin?.toString() ?? '') ?? 0.0;
        final dynamic rawMax = attrs['amount_max'];
        final double maxAmount =
            rawMax is num
                ? rawMax.toDouble()
                : double.tryParse(rawMax?.toString() ?? '') ?? 0.0;

        // Parse int fields safely
        final dynamic rawDecimalPlaces = attrs['currency_decimal_places'];
        final int? decimalPlaces =
            rawDecimalPlaces is int
                ? rawDecimalPlaces
                : int.tryParse(rawDecimalPlaces?.toString() ?? '');
        final dynamic rawOrder = attrs['order'];
        final int? order =
            rawOrder is int
                ? rawOrder
                : int.tryParse(rawOrder?.toString() ?? '');
        final dynamic rawGroupOrder = attrs['object_group_order'];
        final int? groupOrder =
            rawGroupOrder is int
                ? rawGroupOrder
                : int.tryParse(rawGroupOrder?.toString() ?? '');

        batch.insert(
          database.bills,
          BillEntityCompanion.insert(
            id: bill['id'] as String,
            serverId: Value<String?>(bill['id'] as String),
            name: attrs['name'] as String,
            minAmount: minAmount,
            maxAmount: maxAmount,
            date:
                DateTime.tryParse(attrs['date'] as String? ?? '') ??
                DateTime.now(),
            repeatFreq: attrs['repeat_freq'] as String? ?? 'monthly',
            currencyCode: attrs['currency_code'] as String? ?? 'USD',
            currencySymbol: Value<String?>(attrs['currency_symbol'] as String?),
            currencyDecimalPlaces: Value<int?>(decimalPlaces),
            currencyId: Value<String?>(attrs['currency_id']?.toString()),
            nextExpectedMatch: Value<DateTime?>(
              attrs['next_expected_match'] != null
                  ? DateTime.tryParse(attrs['next_expected_match'] as String)
                  : null,
            ),
            order: Value<int?>(order),
            objectGroupOrder: Value<int?>(groupOrder),
            objectGroupTitle: Value<String?>(attrs['object_group_title'] as String?),
            notes: Value<String?>(attrs['notes'] as String?),
            createdAt:
                DateTime.tryParse(attrs['created_at'] as String? ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(attrs['updated_at'] as String? ?? '') ??
                DateTime.now(),
            isSynced: const Value<bool>(true),
            syncStatus: const Value<String>('synced'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    log.info('Saved ${bills.length} bills to database');
  }

  /// Save transactions to local database (in chunks for performance)
  Future<void> _saveTransactions(
    AppDatabase database,
    List<Map<String, dynamic>> transactions,
  ) async {
    log.fine('Saving ${transactions.length} transactions to database');
    const int batchSize = 500;
    int saved = 0;

    for (int i = 0; i < transactions.length; i += batchSize) {
      final int end =
          (i + batchSize < transactions.length)
              ? i + batchSize
              : transactions.length;
      final List<Map<String, dynamic>> chunk = transactions.sublist(i, end);

      await database.batch((Batch batch) {
        for (final Map<String, dynamic> transaction in chunk) {
          final Map<String, dynamic> attrs =
              transaction['attributes'] as Map<String, dynamic>;
          final List<dynamic> txList =
              attrs['transactions'] as List<dynamic>? ?? <dynamic>[];

          for (final dynamic tx in txList) {
            final Map<String, dynamic> txData = tx as Map<String, dynamic>;

            // Parse amounts - API may return as String
            final dynamic rawAmount = txData['amount'];
            final double amount =
                rawAmount is num
                    ? rawAmount.toDouble()
                    : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;
            final dynamic rawForeignAmount = txData['foreign_amount'];
            final double? foreignAmount =
                rawForeignAmount is num
                    ? rawForeignAmount.toDouble()
                    : double.tryParse(rawForeignAmount?.toString() ?? '');

            batch.insert(
              database.transactions,
              TransactionEntityCompanion.insert(
                id: transaction['id'] as String,
                serverId: Value<String?>(transaction['id'] as String),
                type: txData['type'] as String? ?? 'withdrawal',
                date:
                    DateTime.tryParse(txData['date'] as String? ?? '') ??
                    DateTime.now(),
                amount: amount,
                description: txData['description'] as String? ?? '',
                sourceAccountId: txData['source_id']?.toString() ?? '',
                destinationAccountId:
                    txData['destination_id']?.toString() ?? '',
                categoryId: Value<String?>(txData['category_id']?.toString()),
                budgetId: Value<String?>(txData['budget_id']?.toString()),
                currencyCode: txData['currency_code'] as String? ?? 'USD',
                foreignAmount: Value<double?>(foreignAmount),
                foreignCurrencyCode: Value<String?>(
                  txData['foreign_currency_code'] as String?,
                ),
                notes: Value<String?>(txData['notes'] as String?),
                tags: Value<String?>(txData['tags']?.toString() ?? '[]'),
                createdAt:
                    DateTime.tryParse(attrs['created_at'] as String? ?? '') ??
                    DateTime.now(),
                updatedAt:
                    DateTime.tryParse(attrs['updated_at'] as String? ?? '') ??
                    DateTime.now(),
                isSynced: const Value<bool>(true),
                syncStatus: const Value<String>('synced'),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        }
      });
      saved += chunk.length;
      log.finest('Saved transaction batch: $saved/${transactions.length}');
    }
    log.info('Saved ${transactions.length} transactions to database');
  }
}

void apiThrowErrorIfEmpty(Response<dynamic> response, BuildContext? context) {
  if (response.isSuccessful && response.body != null) {
    return;
  }
  log.severe("Invalid API response", response.error);
  if (context?.mounted ?? false) {
    throw Exception(
      S.of(context!).errorAPIInvalidResponse(response.error?.toString() ?? ""),
    );
  } else {
    throw Exception("[nocontext] Invalid API response: ${response.error}");
  }
}
