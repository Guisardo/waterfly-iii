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
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/id_mapping/id_mapping_service.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/sync_manager.dart';
import 'package:waterflyiii/services/sync/sync_progress_tracker.dart';
import 'package:waterflyiii/services/sync/sync_queue_manager.dart';
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

    try {
      await signIn(apiHost, apiKey);
      return true;
    } catch (e) {
      // Try offline mode if network error
      if (e is SocketException || e is TimeoutException || e is http.ClientException) {
        log.info("Network error during sign in, attempting offline mode");
        return await _signInOffline(apiHost, apiKey);
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
    
    if (cachedCurrency == null || cachedApiVersion == null || cachedTimezone == null) {
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
    await prefs.setString('cached_default_currency', json.encode(defaultCurrency.toJson()));
    await prefs.setString('cached_api_version', _apiVersion.toString());
    await prefs.setString('cached_timezone', tzHandler.sLocation.name);
    
    // Trigger initial sync to populate local database for offline use
    _triggerInitialSync();

    return true;
  }
  
  /// Triggers initial full sync in background to populate local database
  void _triggerInitialSync() {
    // Delay sync to not interfere with initial app loading
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        log.info('Triggering initial sync to populate local database...');
        
        final prefs = await SharedPreferences.getInstance();
        final lastSyncTime = prefs.getInt('last_full_sync_time') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Only sync if last sync was more than 1 hour ago
        if (now - lastSyncTime > 3600000) {
          // Import sync dependencies
          final database = AppDatabase();
          final connectivity = ConnectivityService();
          final queueManager = SyncQueueManager(database);
          final idMapping = IdMappingService(database: database);
          final progressTracker = SyncProgressTracker();
          final apiAdapter = FireflyApiAdapter(api);
          
          final syncManager = SyncManager(
            queueManager: queueManager,
            apiClient: apiAdapter,
            database: database,
            connectivity: connectivity,
            idMapping: idMapping,
            progressTracker: progressTracker,
          );
          
          // Notify sync started
          notifyGlobalSyncState(true);
          
          await syncManager.performFullSync();
          await prefs.setInt('last_full_sync_time', now);
          
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
