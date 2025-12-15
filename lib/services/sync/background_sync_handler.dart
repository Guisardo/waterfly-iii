import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:cronet_http/cronet_http.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/id_mapping/id_mapping_service.dart';
import 'package:waterflyiii/services/sync/sync_manager.dart';
import 'package:waterflyiii/services/sync/sync_progress_tracker.dart';
import 'package:waterflyiii/services/sync/sync_queue_manager.dart';

/// HTTP client for background sync
http.Client get _httpClient =>
    CronetClient.fromCronetEngine(CronetEngine.build(), closeEngine: false);

/// Request interceptor for API authentication
class _BackgroundSyncInterceptor implements Interceptor {
  _BackgroundSyncInterceptor(this.apiKey);

  final String apiKey;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) {
    final Request request = applyHeaders(
      chain.request,
      <String, String>{
        HttpHeaders.authorizationHeader: 'Bearer $apiKey',
        HttpHeaders.acceptHeader: 'application/json',
      },
      override: true,
    );
    request.followRedirects = true;
    request.maxRedirects = 5;
    return chain.proceed(request);
  }
}

/// Background sync handler for workmanager tasks.
///
/// This handler is called by workmanager when a background sync task is triggered.
/// It runs in a separate isolate and must be a top-level function.
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    final Logger logger = Logger('BackgroundSyncHandler');
    
    try {
      logger.info('=== Background sync task started ===');
      logger.info('Task: $task');
      logger.info('Input data: $inputData');

      // Initialize dependencies for background sync
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Check if user is authenticated
      final String? apiUrl = prefs.getString('api_url');
      final String? apiToken = prefs.getString('api_token');
      
      if (apiUrl == null || apiToken == null) {
        logger.warning('Background sync skipped: No credentials found');
        return Future<bool>.value(false);
      }
      
      logger.info('API URL: $apiUrl');
      
      // Parse API URL
      final Uri apiUri = Uri.parse(apiUrl);
      
      // Initialize database connection
      // Note: AppDatabase uses its own connection management
      final AppDatabase database = AppDatabase();
      
      try {
        // Initialize services
        logger.info('Initializing services...');
        final ConnectivityService connectivity = ConnectivityService();
        final SyncQueueManager queueManager = SyncQueueManager(database);
        final IdMappingService idMapping = IdMappingService(database: database);
        final SyncProgressTracker progressTracker = SyncProgressTracker();
        
        // Check pending operations
        final pendingOps = await queueManager.getPendingOperations();
        logger.info('Pending operations in queue: ${pendingOps.length}');
        
        // Initialize API client with stored credentials
        logger.info('Creating API client...');
        final FireflyIii apiClient = FireflyIii.create(
          baseUrl: apiUri,
          httpClient: _httpClient,
          interceptors: <Interceptor>[_BackgroundSyncInterceptor(apiToken)],
        );
        
        // Create API adapter
        final FireflyApiAdapter apiAdapter = FireflyApiAdapter(apiClient);
        
        // Create SyncManager instance
        logger.info('Creating SyncManager...');
        final SyncManager syncManager = SyncManager(
          queueManager: queueManager,
          apiClient: apiAdapter,
          database: database,
          connectivity: connectivity,
          idMapping: idMapping,
          progressTracker: progressTracker,
        );
        
        // Perform incremental sync
        logger.info('Starting synchronization...');
        final result = await syncManager.synchronize(fullSync: false);
        
        logger.info('=== Background sync completed ===');
        logger.info('Success: ${result.success}');
        logger.info('Total operations: ${result.totalOperations}');
        logger.info('Successful: ${result.successfulOperations}');
        logger.info('Failed: ${result.failedOperations}');
        logger.info('Conflicts detected: ${result.conflictsDetected}');
        logger.info('Conflicts resolved: ${result.conflictsResolved}');
        logger.info('Errors: ${result.errors.length}');
        
        return Future<bool>.value(true);
      } finally {
        // Clean up database connection
        logger.info('Closing database connection...');
        await database.close();
      }
    } catch (e, stackTrace) {
      logger.severe('=== Background sync task failed ===', e, stackTrace);
      return Future<bool>.value(false);
    }
  });
}

/// Initialize workmanager for background sync.
///
/// Should be called once during app initialization.
Future<void> initializeBackgroundSync() async {
  final Logger logger = Logger('BackgroundSyncHandler');
  
  try {
    await Workmanager().initialize(
      backgroundSyncCallback,
      isInDebugMode: false,
    );
    
    logger.info('Workmanager initialized successfully');
  } catch (e, stackTrace) {
    logger.severe('Failed to initialize workmanager', e, stackTrace);
    rethrow;
  }
}
