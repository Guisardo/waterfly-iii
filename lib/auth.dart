import 'dart:async' show FutureOr, unawaited;
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
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/data/repositories/currency_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';
import 'package:waterflyiii/services/sync/upload_service.dart';
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

class AuthError implements Exception {
  const AuthError(this.cause);

  final String cause;
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

  /// Creates AuthUser without API validation (for restoring from storage)
  static AuthUser createWithoutValidation(String host, String apiKey) {
    final Logger log = Logger("Auth.AuthUser");
    log.config("AuthUser->createWithoutValidation($host)");

    late Uri uri;
    try {
      uri = Uri.parse(host);
    } on FormatException {
      throw AuthErrorHost(host);
    }

    return AuthUser._create(uri, apiKey);
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
      final http.StreamedResponse response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));

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

      final String stringData = await response.stream.bytesToString().timeout(
        const Duration(seconds: 30),
      );

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
  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;
  String? _lastTriedHost;
  String? get lastTriedHost => _lastTriedHost;
  Object? _storageSignInException;
  Object? get storageSignInException => _storageSignInException;
  Version? _apiVersion;
  Version? get apiVersion => _apiVersion;

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

  /// Restores credentials from storage without making API calls.
  /// API validation should happen during sync, not on every app start.
  Future<bool> restoreFromStorage() async {
    _storageSignInException = null;
    _isAuthenticating = true;
    notifyListeners();

    try {
      // Use timeouts on FlutterSecureStorage reads to prevent indefinite
      // hangs caused by Android Keystore becoming temporarily unavailable.
      final String? apiHost = await storage
          .read(key: 'api_host')
          .timeout(const Duration(seconds: 15));
      final String? apiKey = await storage
          .read(key: 'api_key')
          .timeout(const Duration(seconds: 15));

      log.config(
        "restoreFromStorage: $apiHost, apiKey ${apiKey?.isEmpty ?? true ? "unset" : "set"}",
      );

      if (apiHost == null || apiKey == null) {
        _isAuthenticating = false;
        notifyListeners();
        return false;
      }

      try {
        // Create API client without making API calls
        // Credentials will be validated during sync
        final String host = apiHost.strip().rightStrip('/');
        final String key = apiKey.strip();

        _lastTriedHost = host;

        // Create AuthUser without API validation
        // This just sets up the API client structure
        _currentUser = AuthUser.createWithoutValidation(host, key);

        if (_currentUser == null || !hasApi) {
          _isAuthenticating = false;
          notifyListeners();
          return false;
        }

        // Try to restore timezone from storage if available
        try {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? timezone = prefs.getString('server_timezone');

          if (timezone != null) {
            tzHandler = TimeZoneHandler(timezone);
          } else {
            // Default timezone if not stored - will be fetched during sync
            tzHandler = TimeZoneHandler('UTC');
          }
        } catch (e) {
          log.finer(() => "Could not restore timezone from storage: $e");
          // Use default - will be fetched during sync
          tzHandler = TimeZoneHandler('UTC');
        }

        // Try to restore default currency from local database
        // If not available, it will be fetched during sync
        try {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final String? defaultCurrencyId = prefs.getString(
            'default_currency_id',
          );

          if (defaultCurrencyId != null) {
            final Isar isar = await AppDatabase.instance;
            final CurrencyRepository currencyRepo = CurrencyRepository(isar);
            final CurrencyRead? currency = await currencyRepo.getById(
              defaultCurrencyId,
            );

            if (currency != null) {
              defaultCurrency = currency;
              log.finer(
                () =>
                    "Restored default currency from database: ${currency.attributes.code}",
              );
            } else {
              // Currency not in database yet - will be fetched during sync
              // Create a temporary default currency to avoid LateInitializationError
              defaultCurrency = CurrencyRead(
                type: "currencies",
                id: defaultCurrencyId,
                attributes: const CurrencyProperties(
                  code: "USD",
                  name: "US Dollar",
                  symbol: "\$",
                  decimalPlaces: 2,
                ),
              );
              log.finer(
                () =>
                    "Created temporary default currency, will be updated during sync",
              );
            }
          } else {
            // No stored currency ID - create a temporary default
            defaultCurrency = const CurrencyRead(
              type: "currencies",
              id: "0",
              attributes: CurrencyProperties(
                code: "USD",
                name: "US Dollar",
                symbol: "\$",
                decimalPlaces: 2,
              ),
            );
            log.finer(
              () =>
                  "No default currency stored, using temporary default, will be updated during sync",
            );
          }
        } catch (e) {
          log.finer(() => "Could not restore default currency: $e");
          // Create a temporary default currency to avoid LateInitializationError
          defaultCurrency = const CurrencyRead(
            type: "currencies",
            id: "0",
            attributes: CurrencyProperties(
              code: "USD",
              name: "US Dollar",
              symbol: "\$",
              decimalPlaces: 2,
            ),
          );
        }

        _signedIn = true;
        _isAuthenticating = false;
        log.finest(() => "notify FireflyService->restoreFromStorage");
        notifyListeners();
        return true;
      } catch (e) {
        _storageSignInException = e;
        _isAuthenticating = false;
        log.finest(() => "notify FireflyService->restoreFromStorage");
        notifyListeners();
        return false;
      }
    } catch (e) {
      _storageSignInException = e;
      _isAuthenticating = false;
      log.finest(() => "notify FireflyService->restoreFromStorage");
      notifyListeners();
      return false;
    }
  }

  /// Deprecated: Use restoreFromStorage() instead for app startup.
  /// This method makes API calls and should only be used for actual login.
  @Deprecated(
    'Use restoreFromStorage() for app startup. Use signIn() for new logins.',
  )
  Future<bool> signInFromStorage() {
    return restoreFromStorage();
  }

  Future<void> signOut() async {
    log.config("FireflyService->signOut()");
    _currentUser = null;
    _signedIn = false;
    _isAuthenticating = false;
    _storageSignInException = null;
    await storage.deleteAll();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    log.finest(() => "notify FireflyService->signOut");
    notifyListeners();
  }

  Future<void> _triggerInitialSync() async {
    // Run sync in background without blocking
    unawaited(
      Future<void>.microtask(() async {
        try {
          final Isar isar = await AppDatabase.instance;

          // Clear stale credentialsInvalid flag so sync is not blocked
          // after user enters new credentials. At this point signIn() has
          // already verified the credentials are working.
          final SyncMetadata? staleAuthMeta = await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('auth')
              .findFirst();
          if (staleAuthMeta != null) {
            staleAuthMeta
              ..credentialsInvalid = false
              ..credentialsValidated = false;
            await isar.writeTxn(() async {
              await isar.syncMetadatas.put(staleAuthMeta);
            });
            log.config("Reset credentials metadata after new login");
          }

          // Check if this is first-time login (no sync metadata exists)
          final SyncMetadata? downloadMetadata = await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('download')
              .findFirst();

          final bool isFirstTime = downloadMetadata == null;

          // Initialize sync services
          // Note: These need to be accessed via a different mechanism since
          // we're not in a widget context. For now, we'll create them directly.
          // In a production app, you might want to use a service locator or
          // pass them as dependencies.
          final ConnectivityService connectivityService = ConnectivityService();
          final SyncNotifications notifications = SyncNotifications();
          await notifications.initialize();

          final SyncService syncService = SyncService(
            isar: isar,
            fireflyService: this,
            connectivityService: connectivityService,
            notifications: notifications,
            settingsProvider: null, // Will be set when available
          );

          final UploadService uploadService = UploadService(
            isar: isar,
            fireflyService: this,
            connectivityService: connectivityService,
            notifications: notifications,
            settingsProvider: null, // Will be set when available
          );

          if (isFirstTime) {
            log.config("First-time login: Triggering full sync");
            await syncService.sync(forceFullSync: true);
          } else {
            log.config("Returning user: Triggering incremental sync");
            await syncService.sync(forceFullSync: false);
          }

          // Also trigger upload sync for any pending changes
          await uploadService.uploadPendingChanges();
        } catch (e, stackTrace) {
          log.warning("Failed to trigger initial sync", e, stackTrace);
          // Don't throw - sync failure shouldn't prevent login
        }
      }),
    );
  }

  Future<bool> signIn(
    String host,
    String apiKey, {
    String? customHeadersRaw,
  }) async {
    log.config("FireflyService->signIn($host)");
    _isAuthenticating = true;
    notifyListeners();

    try {
      host = host.strip().rightStrip('/');
      apiKey = apiKey.strip();

      _lastTriedHost = host;
      final Map<String, String> customHeaders = _parseCustomHeaders(
        customHeadersRaw ?? "",
      );

      final AuthUser nextUser = await AuthUser.create(host, apiKey);
      final Response<CurrencySingle> currencyInfo = await nextUser.api
          .v1CurrenciesPrimaryGet()
          .timeout(const Duration(seconds: 30));
      final CurrencyRead nextDefaultCurrency = currencyInfo.body!.data;

      // Store default currency ID for future restoreFromStorage() calls
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('default_currency_id', nextDefaultCurrency.id);
      } catch (e) {
        log.finer(() => "Could not store default currency ID: $e");
      }

      final Response<SystemInfo> about = await nextUser.api
          .v1AboutGet()
          .timeout(const Duration(seconds: 30));
      late Version nextApiVersion;
      try {
        String apiVersionStr = about.body?.data?.apiVersion ?? "";
        if (apiVersionStr.startsWith("develop/")) {
          apiVersionStr = "9.9.9";
        }
        nextApiVersion = Version.parse(apiVersionStr);
      } on FormatException {
        _isAuthenticating = false;
        notifyListeners();
        throw const AuthErrorVersionInvalid();
      }
      log.info(() => "Firefly API version $nextApiVersion");
      if (nextApiVersion < minApiVersion) {
        _isAuthenticating = false;
        notifyListeners();
        throw AuthErrorVersionTooLow(minApiVersion);
      }

      // Manual API query as the Swagger type doesn't resolve in Flutter :(
      final http.Client client = httpClient;
      final Uri tzUri = nextUser.host.replace(
        pathSegments: <String>[
          ...nextUser.host.pathSegments,
          "v1",
          "configuration",
          ConfigValueFilter.appTimezone.value!,
        ],
      );
      late TimeZoneHandler nextTzHandler;
      try {
        final http.Response response = await client
            .get(tzUri, headers: nextUser.headers())
            .timeout(const Duration(seconds: 30));
        final APITZReply reply = APITZReply.fromJson(
          json.decode(response.body),
        );
        nextTzHandler = TimeZoneHandler(reply.data.value);
      } finally {
        client.close();
      }

      _currentUser = nextUser;
      defaultCurrency = nextDefaultCurrency;
      _apiVersion = nextApiVersion;
      tzHandler = nextTzHandler;
      _signedIn = true;
      _isAuthenticating = false;
      log.finest(() => "notify FireflyService->signIn");
      notifyListeners();

      // Write credentials in background — do NOT block signIn() return on
      // FlutterSecureStorage, which can hang indefinitely on Android Keystore.
      // notifyListeners() already fired above so the UI can proceed.
      unawaited(
        Future<void>(() async {
          try {
            await storage
                .write(key: 'api_host', value: host)
                .timeout(const Duration(seconds: 15));
            await storage
                .write(key: 'api_key', value: apiKey)
                .timeout(const Duration(seconds: 15));
            if (customHeaders.isNotEmpty) {
              await storage
                  .write(
                    key: 'api_headers',
                    value: _encodeCustomHeaders(customHeaders),
                  )
                  .timeout(const Duration(seconds: 15));
            }
            log.info('Credentials saved to storage successfully');
          } catch (e) {
            log.warning('Failed to save credentials to storage: $e', e);
          }

          // Store timezone for future restoreFromStorage() calls
          try {
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            await prefs.setString('server_timezone', tzHandler.serverTimezone);
          } catch (e) {
            log.finer(() => "Could not store timezone: $e");
          }
        }),
      );

      // Trigger initial sync in background
      unawaited(_triggerInitialSync());

      return true;
    } catch (e) {
      _isAuthenticating = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Parses a raw custom-headers string (one "Key: Value" per line) into a map.
  static Map<String, String> _parseCustomHeaders(String raw) {
    final Map<String, String> headers = <String, String>{};
    if (raw.trim().isEmpty) {
      return headers;
    }
    for (final String line in raw.split('\n')) {
      final int colonIndex = line.indexOf(':');
      if (colonIndex < 1) {
        continue;
      }
      final String key = line.substring(0, colonIndex).trim();
      final String value = line.substring(colonIndex + 1).trim();
      if (key.isNotEmpty) {
        headers[key] = value;
      }
    }
    return headers;
  }

  /// Encodes a header map back to the raw "Key: Value\n" string format.
  static String _encodeCustomHeaders(Map<String, String> headers) {
    return headers.entries
        .map((MapEntry<String, String> e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  /// Reads stored credentials from secure storage for display/editing.
  Future<AuthCredentials> readStoredCredentials() async {
    try {
      final String? host = await storage
          .read(key: 'api_host')
          .timeout(const Duration(seconds: 15));
      final String? apiKey = await storage
          .read(key: 'api_key')
          .timeout(const Duration(seconds: 15));
      final String? headersRaw = await storage
          .read(key: 'api_headers')
          .timeout(const Duration(seconds: 15));
      return AuthCredentials(
        host: host,
        apiKey: apiKey,
        customHeadersRaw: headersRaw,
      );
    } catch (e) {
      log.warning('Failed to read stored credentials: $e', e);
      return const AuthCredentials();
    }
  }
}

/// Holds API connection credentials read from secure storage.
class AuthCredentials {
  const AuthCredentials({this.host, this.apiKey, this.customHeadersRaw});

  final String? host;
  final String? apiKey;
  final String? customHeadersRaw;
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
