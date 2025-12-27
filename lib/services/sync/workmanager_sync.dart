import 'package:workmanager/workmanager.dart';
import 'package:logging/logging.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';
import 'package:waterflyiii/services/sync/upload_service.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart' show ConnectivityService;
import 'package:workmanager_platform_interface/src/pigeon/workmanager_api.g.dart' as workmanager;
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/auth.dart';

final Logger log = Logger("WorkManagerSync");

const String syncTaskName = "waterflySyncTask";
const String uploadTaskName = "waterflyUploadTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    log.config("Background task started: $task");

    try {
      // Initialize database
      final Isar isar = await AppDatabase.instance;

      // Read credentials from secure storage
      const FlutterSecureStorage storage = FlutterSecureStorage(
        aOptions: AndroidOptions(resetOnError: true),
      );
      final String? apiHost = await storage.read(key: 'api_host');
      final String? apiKey = await storage.read(key: 'api_key');

      if (apiHost == null || apiKey == null) {
        log.warning("No credentials found in background task");
        return Future.value(false);
      }

      // Create FireflyService and sign in (this validates credentials)
      // For background tasks, we still validate to ensure credentials are valid
      final FireflyService fireflyService = FireflyService();
      try {
        await fireflyService.signIn(apiHost, apiKey);
      } catch (e) {
        log.warning("Failed to sign in with stored credentials in background task", e);
        return Future.value(false);
      }
      
      if (!fireflyService.signedIn) {
        log.warning("Sign in completed but signedIn is false");
        return Future.value(false);
      }

      // Initialize services
      final ConnectivityService connectivityService = ConnectivityService();
      final SyncNotifications notifications = SyncNotifications();
      await notifications.initialize();

      // Create sync services
      final SyncService syncService = SyncService(
        isar: isar,
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        notifications: notifications,
        settingsProvider: null, // Settings not available in background
      );

      final UploadService uploadService = UploadService(
        isar: isar,
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        notifications: notifications,
        settingsProvider: null, // Settings not available in background
      );

      // Execute the appropriate task
      if (task == syncTaskName) {
        log.config("Running download sync in background");
        await syncService.sync();
      } else if (task == uploadTaskName) {
        log.config("Running upload sync in background");
        await uploadService.uploadPendingChanges();
      } else {
        log.warning("Unknown task: $task");
        return Future.value(false);
      }

      log.config("Background task completed: $task");
      return Future.value(true);
    } catch (e, stackTrace) {
      log.severe("Background task failed: $task", e, stackTrace);
      return Future.value(false);
    }
  });
}

class WorkManagerSync {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerPeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: workmanager.NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    await Workmanager().registerPeriodicTask(
      uploadTaskName,
      uploadTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: workmanager.NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> registerOneOffSync({
    bool download = true,
    bool upload = true,
  }) async {
    if (download) {
      await Workmanager().registerOneOffTask(
        '${syncTaskName}_onetime',
        syncTaskName,
        constraints: Constraints(
          networkType: workmanager.NetworkType.connected,
        ),
      );
    }

    if (upload) {
      await Workmanager().registerOneOffTask(
        '${uploadTaskName}_onetime',
        uploadTaskName,
        constraints: Constraints(
          networkType: workmanager.NetworkType.connected,
        ),
      );
    }
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}

