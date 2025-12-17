import 'dart:convert';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/account_repository.dart';
import 'package:waterflyiii/data/repositories/attachment_repository.dart';
import 'package:waterflyiii/data/repositories/bill_repository.dart';
import 'package:waterflyiii/data/repositories/budget_repository.dart';
import 'package:waterflyiii/data/repositories/category_repository.dart';
import 'package:waterflyiii/data/repositories/currency_repository.dart';
import 'package:waterflyiii/data/repositories/piggy_bank_repository.dart';
import 'package:waterflyiii/data/repositories/tag_repository.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/notificationlistener.dart';
import 'package:waterflyiii/pages/login.dart';
import 'package:waterflyiii/pages/navigation.dart';
import 'package:waterflyiii/pages/splash.dart';
import 'package:waterflyiii/pages/transaction.dart';
import 'package:waterflyiii/providers/app_mode_provider.dart';
import 'package:waterflyiii/providers/connectivity_provider.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';
import 'package:waterflyiii/providers/sync_provider.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';
import 'package:waterflyiii/services/cache/cache_warming_service.dart';
import 'package:waterflyiii/services/data/chart_data_service.dart';
import 'package:waterflyiii/services/data/insights_service.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';
import 'package:waterflyiii/settings.dart';
import 'package:waterflyiii/widgets/logo.dart';

final Logger log = Logger("App");

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(
  debugLabel: "Main Navigator",
);

class WaterflyApp extends StatefulWidget {
  const WaterflyApp({super.key});

  @override
  State<WaterflyApp> createState() => _WaterflyAppState();
}

class _WaterflyAppState extends State<WaterflyApp> {
  bool _startup = true;
  bool _authed = false;
  String? _quickAction;
  NotificationTransaction? _notificationPayload;
  // Not needed right now, as sharing while the app is open does not work
  //late StreamSubscription<List<SharedFile>> _intentDataStreamSubscription;
  List<SharedFile>? _filesSharedToApp;
  bool _requiresAuth = false;
  DateTime? _lcLastOpen;

  @override
  void initState() {
    super.initState();

    // Notifications
    FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
      ),
      onDidReceiveNotificationResponse: nlNotificationTap,
    );

    FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails().then((
      NotificationAppLaunchDetails? details,
    ) {
      log.config("checking NotificationAppLaunchDetails");
      if ((details?.didNotificationLaunchApp ?? false) &&
          (details?.notificationResponse?.payload?.isNotEmpty ?? false)) {
        log.info("Was launched from notification!");
        _notificationPayload = NotificationTransaction.fromJson(
          jsonDecode(details!.notificationResponse!.payload!),
        );
      }
    });

    // Quick Actions
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      log.info("Was launched from QuickAction $shortcutType");
      _quickAction = shortcutType;
      if (!_startup && navigatorKey.currentState != null) {
        log.finest(() => "App already started, pushing route");
        navigatorKey.currentState!.push(
          MaterialPageRoute<Widget>(
            builder: (BuildContext context) => const TransactionPage(),
          ),
        );
      }
    });
    quickActions.clearShortcutItems();

    // App Lifecycle State
    AppLifecycleListener(
      onResume: () {
        if (_requiresAuth &&
            (_lcLastOpen?.isBefore(
                  DateTime.now().subtract(const Duration(minutes: 10)),
                ) ??
                false)) {
          log.finest(() => "App resuming, last opened: $_lcLastOpen");
          _lcLastOpen = null;
          _authed = false;

          final bool canPush = navigatorKey.currentState != null;
          if (canPush) {
            navigatorKey.currentState?.push(
              MaterialPageRoute<Widget>(
                builder: (BuildContext context) => const AppLogo(),
              ),
            );
          }

          auth().then((bool authed) {
            log.finest(() => "done authing, $authed");
            if (authed) {
              log.finest(() => "authentication succeeded");
              _authed = true;
              if (canPush) {
                navigatorKey.currentState?.pop();
              }
            } else {
              log.shout(() => "authentication failed");
              _lcLastOpen = DateTime.now().subtract(
                const Duration(minutes: 10),
              );
              // close app
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              if (canPush) {
                navigatorKey.currentState?.pop();
              }
            }
          });
        }
      },
      onPause: () {
        if (_requiresAuth) {
          _lcLastOpen ??= DateTime.now();
          log.finest(() => "App pausing now");
        }
      },
    );

    // Share to Waterfly III
    // While the app is open...
    /* Sharing while app is open is currently not supported :(
       The fix from https://github.com/bhagat-techind/flutter_sharing_intent/issues/33
       does not seem to work, unfortunately.
       
    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedFile> value) {
      setState(() {
        list = value;
      });
      debugPrint(
          "Shared: getMediaStream ${value.map((SharedFile f) => f.value).join(",")}");
    }, onError: (Object err) {
      debugPrint("getIntentDataStream error: $err");
    });*/

    // For sharing images coming from outside the app while the app is closed
    FlutterSharingIntent.instance.getInitialSharing().then((
      List<SharedFile> value,
    ) {
      log.config("App was opened via file sharing");
      log.finest(
        () => "files: ${value.map((SharedFile f) => f.value).join(",")}",
      );
      _filesSharedToApp = value;
    });
  }

  /* Not needed right now, as sharing while the app is open does not work
  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();

    super.dispose();
  }*/

  Future<bool> auth() {
    final LocalAuthentication auth = LocalAuthentication();
    return auth.authenticate(
      localizedReason: "Waterfly III",
      persistAcrossBackgrounding: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    log.fine(() => "WaterflyApp() building");

    return DynamicColorBuilder(
      builder: (
        ColorScheme? cSchemeDynamicLight,
        ColorScheme? cSchemeDynamicDark,
      ) {
        final ColorScheme cSchemeLight = ColorScheme.fromSeed(
          seedColor: Colors.blue,
        );
        final ColorScheme cSchemeDark = ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ).copyWith(
          surfaceContainerHighest: Colors.blueGrey.shade900,
          onSurfaceVariant: Colors.white,
        );

        log.finest(
          () =>
              "has dynamic color? light: ${cSchemeDynamicLight != null}, dark: ${cSchemeDynamicDark != null}",
        );

        return MultiProvider(
          providers: <SingleChildWidget>[
            // Core Services
            ChangeNotifierProvider<FireflyService>(
              create: (_) => FireflyService(),
            ),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
            ChangeNotifierProvider<ConnectivityProvider>(
              create: (_) => ConnectivityProvider()..initialize(),
            ),
            ChangeNotifierProvider<SyncProvider>(create: (_) => SyncProvider()),
            ChangeNotifierProvider<AppModeProvider>(
              create: (_) => AppModeProvider(),
            ),
            ChangeNotifierProvider<OfflineSettingsProvider>(
              create: (_) => OfflineSettingsProvider.create(),
            ),

            // Database and Cache (Phase 2-3: Cache-First Architecture)
            Provider<AppDatabase>(
              create: (_) => AppDatabase(),
              dispose: (_, AppDatabase db) => db.close(),
            ),
            Provider<CacheService>(
              create:
                  (BuildContext context) =>
                      CacheService(database: context.read<AppDatabase>()),
              dispose: (_, CacheService cache) => cache.dispose(),
            ),

            // Repositories (Phase 2-3: Cache-First Architecture)
            // These repositories provide data access with cache-first strategy.
            // Pages should use these instead of direct API calls.
            Provider<TransactionRepository>(
              create:
                  (BuildContext context) => TransactionRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),
            Provider<AccountRepository>(
              create:
                  (BuildContext context) => AccountRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),
            Provider<CategoryRepository>(
              create:
                  (BuildContext context) => CategoryRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),
            Provider<BudgetRepository>(
              create:
                  (BuildContext context) => BudgetRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),
            Provider<BillRepository>(
              create:
                  (BuildContext context) => BillRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),
            Provider<PiggyBankRepository>(
              create:
                  (BuildContext context) => PiggyBankRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),
            Provider<CurrencyRepository>(
              create:
                  (BuildContext context) => CurrencyRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),
            Provider<TagRepository>(
              create:
                  (BuildContext context) => TagRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),
            Provider<AttachmentRepository>(
              create:
                  (BuildContext context) => AttachmentRepository(
                    database: context.read<AppDatabase>(),
                    cacheService: context.read<CacheService>(),
                  ),
            ),

            // Data Services (Phase 2: Cached API Access)
            // These services provide cached access to computed/aggregate data.
            ProxyProvider3<FireflyService, CacheService, TransactionRepository, InsightsService?>(
              update: (_, FireflyService firefly, CacheService cache, TransactionRepository transactionRepo, _) {
                // Only create service when signed in
                if (!firefly.signedIn) return null;
                return InsightsService(
                  fireflyService: firefly,
                  cacheService: cache,
                  transactionRepository: transactionRepo,
                );
              },
            ),
            ProxyProvider2<FireflyService, CacheService, ChartDataService?>(
              update: (_, FireflyService firefly, CacheService cache, _) {
                // Only create service when signed in
                if (!firefly.signedIn) return null;
                return ChartDataService(
                  fireflyService: firefly,
                  cacheService: cache,
                );
              },
            ),

            // Cache Warming Service (Phase 3: Background Refresh)
            Provider<CacheWarmingService>(
              create:
                  (BuildContext context) => CacheWarmingService(
                    cacheService: context.read<CacheService>(),
                    transactionRepository:
                        context.read<TransactionRepository>(),
                    accountRepository: context.read<AccountRepository>(),
                    budgetRepository: context.read<BudgetRepository>(),
                    categoryRepository: context.read<CategoryRepository>(),
                  ),
            ),

            // Incremental Sync Service (Entity-Specific Sync)
            // Provides force sync functionality for individual entity types.
            // Only created when user is signed in.
            ProxyProvider3<
              FireflyService,
              AppDatabase,
              CacheService,
              IncrementalSyncService?
            >(
              update: (
                _,
                FireflyService firefly,
                AppDatabase database,
                CacheService cache,
                _,
              ) {
                // Only create service when signed in
                if (!firefly.signedIn) return null;
                return IncrementalSyncService(
                  database: database,
                  apiAdapter: FireflyApiAdapter(firefly.api),
                  cacheService: cache,
                );
              },
              dispose:
                  (_, IncrementalSyncService? service) => service?.dispose(),
            ),
          ],
          builder: (BuildContext context, _) {
            // Force AppModeProvider to be created early
            context.read<AppModeProvider>();
            
            late bool signedIn;
            log.finest(() => "_startup = $_startup");
            _requiresAuth = context.watch<SettingsProvider>().lock;
            log.finest(() => "_requiresAuth = $_requiresAuth");
            if (_startup) {
              signedIn = false;

              if (!context.select((SettingsProvider s) => s.loaded)) {
                log.finer(() => "Load Step 1: Loading Settings");
                context.read<SettingsProvider>().loadSettings();
              } else {
                log.finer(() => "Load Step 2: Signin In");

                if (context.read<SettingsProvider>().lock && !_authed) {
                  // Authentication required
                  log.fine("awaiting authentication");
                  auth().then((bool authed) {
                    log.finest(() => "done authing, $authed");
                    if (authed) {
                      log.finest(() => "authentication succeeded");
                      setState(() {
                        _authed = true;
                      });
                    } else {
                      log.shout(() => "authentication failed");
                      // close app
                      SystemChannels.platform.invokeMethod(
                        'SystemNavigator.pop',
                      );
                    }
                  });
                } else {
                  log.finest(() => "signing in");
                  // Store context-dependent value before async gap
                  final CacheWarmingService? warmingService =
                      mounted ? context.read<CacheWarmingService>() : null;
                  context.read<FireflyService>().signInFromStorage().then((
                    bool signedInSuccess,
                  ) {
                    log.finest(() => "set _startup = false");
                    if (!mounted) return;

                    setState(() {
                      _authed = true;
                      _startup = false;
                    });

                    // Trigger cache warming after successful sign-in (Phase 3)
                    if (signedInSuccess && mounted && warmingService != null) {
                      log.fine('Triggering cache warming after sign-in');
                      try {
                        // Fire-and-forget: warm in background without blocking
                        Future<void>.microtask(() {
                          if (mounted) {
                            warmingService.warmOnStartup();
                          }
                        });
                      } catch (e) {
                        log.warning('Failed to start cache warming: $e');
                        // Non-fatal: app continues normally
                      }
                    }
                  });
                }
              }
            } else {
              signedIn = context.select((FireflyService f) => f.signedIn);
              if (signedIn) {
                context.read<FireflyService>().tzHandler.setUseServerTime(
                  context.read<SettingsProvider>().useServerTime,
                );
              }
              log.config("signedIn: $signedIn");
            }

            return MaterialApp(
              title: 'Waterfly III',
              theme: ThemeData(
                brightness: Brightness.light,
                colorScheme:
                    context.select((SettingsProvider s) => s.dynamicColors)
                        ? cSchemeDynamicLight?.harmonized() ?? cSchemeLight
                        : cSchemeLight,
                useMaterial3: true,
                // See https://github.com/flutter/flutter/issues/131042#issuecomment-1690737834
                appBarTheme: const AppBarTheme(shape: RoundedRectangleBorder()),
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android:
                        PredictiveBackPageTransitionsBuilder(),
                  },
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme:
                    context.select((SettingsProvider s) => s.dynamicColors)
                        ? cSchemeDynamicDark?.harmonized() ?? cSchemeDark
                        : cSchemeDark,
                useMaterial3: true,
              ),
              themeMode: context.select((SettingsProvider s) => s.theme),
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              locale: context.select((SettingsProvider s) => s.locale),
              navigatorKey: navigatorKey,
              home:
                  ((_startup || !_authed) ||
                          context.select(
                            (FireflyService f) =>
                                f.storageSignInException != null,
                          ))
                      ? const SplashPage()
                      : signedIn
                      ? (_notificationPayload != null ||
                              _quickAction == "action_transaction_add" ||
                              (_filesSharedToApp != null &&
                                  _filesSharedToApp!.isNotEmpty))
                          ? TransactionPage(
                            notification: _notificationPayload,
                            files: _filesSharedToApp,
                          )
                          : const NavPage()
                      : const LoginPage(),
            );
          },
        );
      },
    );
  }
}
