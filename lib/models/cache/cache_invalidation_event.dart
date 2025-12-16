/// Cache Invalidation Event Model
///
/// Represents a cache invalidation or refresh event that occurred in the cache system.
/// Used for reactive UI updates through RxDart streams.
///
/// When cache entries are invalidated or refreshed in the background,
/// CacheInvalidationEvent is emitted through the cache service's event stream.
/// UI widgets can subscribe to this stream to automatically update when
/// relevant data changes.
///
/// This enables:
/// - Automatic UI refresh on background updates
/// - Real-time synchronization across multiple widgets
/// - Efficient update propagation (only affected widgets rebuild)
/// - Debugging and monitoring cache invalidation patterns
///
/// Example Usage:
/// ```dart
/// // Subscribe to cache events
/// cacheService.invalidationStream
///   .where((event) =>
///       event.entityType == 'account' &&
///       event.entityId == currentAccountId)
///   .listen((event) {
///     if (event.eventType == CacheEventType.refreshed) {
///       // Background refresh completed, update UI
///       setState(() {
///         account = event.data as Account;
///       });
///     }
///   });
///
/// // Invalidation triggers event
/// await cacheService.invalidate('account', '123');
/// // Event emitted: CacheInvalidationEvent(
/// //   entityType: 'account',
/// //   entityId: '123',
/// //   eventType: CacheEventType.invalidated,
/// //   timestamp: DateTime.now(),
/// // )
/// ```
class CacheInvalidationEvent {
  /// Entity type that was affected
  ///
  /// Format:
  /// - Single entity: 'transaction', 'account', 'budget'
  /// - Collection: 'transaction_list', 'account_list'
  /// - Wildcard: '*' (type-level invalidation affects all IDs)
  ///
  /// Used for stream filtering:
  /// ```dart
  /// events.where((e) => e.entityType == 'account')
  /// ```
  final String entityType;

  /// Entity ID that was affected
  ///
  /// Format:
  /// - Specific entity: '123', 'abc-def-ghi'
  /// - Collection cache key: 'collection_abc123'
  /// - Wildcard: '*' (affects all entities of this type)
  ///
  /// Wildcard is used for type-level operations:
  /// - invalidateType('transaction') → entityId: '*'
  /// - Affects all transactions, not just one
  ///
  /// Used for stream filtering:
  /// ```dart
  /// events.where((e) =>
  ///     e.entityType == 'account' &&
  ///     (e.entityId == accountId || e.entityId == '*'))
  /// ```
  final String entityId;

  /// Type of cache event that occurred
  ///
  /// Values:
  /// - CacheEventType.invalidated: Cache entry marked invalid
  /// - CacheEventType.refreshed: Background refresh completed with new data
  ///
  /// Event type determines UI action:
  /// - invalidated: May show "updating..." indicator
  /// - refreshed: Update UI with new data
  final CacheEventType eventType;

  /// Updated data from background refresh (optional)
  ///
  /// Only populated for CacheEventType.refreshed events.
  /// Null for CacheEventType.invalidated events.
  ///
  /// Contains the fresh data retrieved from API during background refresh.
  /// Subscribers can use this data to update UI without refetching.
  ///
  /// Type: dynamic (any entity type)
  /// Cast to appropriate type in subscriber:
  /// ```dart
  /// final account = event.data as Account;
  /// ```
  ///
  /// Why dynamic:
  /// - Event stream handles multiple entity types
  /// - Dart generics don't support runtime type parameters in streams
  /// - Subscribers know expected type from entityType
  final dynamic data;

  /// Timestamp when the event occurred
  ///
  /// Used for:
  /// - Debugging event timing
  /// - Event ordering (ensure events processed in sequence)
  /// - Staleness detection (ignore old events)
  /// - Performance monitoring (measure event propagation time)
  ///
  /// Format: DateTime in local timezone
  /// Example: 2024-12-15 14:30:00.000
  final DateTime timestamp;

  /// Creates a cache invalidation event
  ///
  /// Parameters:
  /// - [entityType]: Type of entity affected
  /// - [entityId]: ID of entity affected (or '*' for wildcard)
  /// - [eventType]: Type of cache event (invalidated or refreshed)
  /// - [data]: Optional updated data for refreshed events
  /// - [timestamp]: When the event occurred
  ///
  /// Example - Invalidation:
  /// ```dart
  /// final event = CacheInvalidationEvent(
  ///   entityType: 'account',
  ///   entityId: '123',
  ///   eventType: CacheEventType.invalidated,
  ///   timestamp: DateTime.now(),
  /// );
  /// ```
  ///
  /// Example - Background Refresh:
  /// ```dart
  /// final event = CacheInvalidationEvent(
  ///   entityType: 'account',
  ///   entityId: '123',
  ///   eventType: CacheEventType.refreshed,
  ///   data: updatedAccount,
  ///   timestamp: DateTime.now(),
  /// );
  /// ```
  ///
  /// Example - Type-Level Invalidation:
  /// ```dart
  /// final event = CacheInvalidationEvent(
  ///   entityType: 'transaction',
  ///   entityId: '*', // All transactions
  ///   eventType: CacheEventType.invalidated,
  ///   timestamp: DateTime.now(),
  /// );
  /// ```
  CacheInvalidationEvent({
    required this.entityType,
    required this.entityId,
    required this.eventType,
    this.data,
    required this.timestamp,
  });

  /// Check if this event affects a specific entity
  ///
  /// Returns true if:
  /// - Entity type matches AND
  /// - Entity ID matches OR is wildcard (*)
  ///
  /// This allows efficient stream filtering for specific entities
  /// while respecting type-level invalidations.
  ///
  /// Parameters:
  /// - [type]: Entity type to check
  /// - [id]: Entity ID to check
  ///
  /// Returns:
  /// - true if event affects the specified entity
  /// - false otherwise
  ///
  /// Example:
  /// ```dart
  /// // Specific invalidation
  /// final event = CacheInvalidationEvent(
  ///   entityType: 'account',
  ///   entityId: '123',
  ///   eventType: CacheEventType.invalidated,
  ///   timestamp: DateTime.now(),
  /// );
  /// event.affects('account', '123'); // true
  /// event.affects('account', '456'); // false
  ///
  /// // Type-level invalidation
  /// final event = CacheInvalidationEvent(
  ///   entityType: 'account',
  ///   entityId: '*',
  ///   eventType: CacheEventType.invalidated,
  ///   timestamp: DateTime.now(),
  /// );
  /// event.affects('account', '123'); // true (wildcard)
  /// event.affects('account', '456'); // true (wildcard)
  /// event.affects('transaction', '123'); // false (wrong type)
  /// ```
  bool affects(String type, String id) {
    return entityType == type && (entityId == id || entityId == '*');
  }

  /// Check if this is an invalidation event
  ///
  /// Convenience getter for readability.
  ///
  /// Example:
  /// ```dart
  /// if (event.isInvalidation) {
  ///   showRefreshIndicator();
  /// }
  /// ```
  bool get isInvalidation => eventType == CacheEventType.invalidated;

  /// Check if this is a refresh event
  ///
  /// Convenience getter for readability.
  ///
  /// Example:
  /// ```dart
  /// if (event.isRefresh && event.data != null) {
  ///   updateUiWithData(event.data);
  /// }
  /// ```
  bool get isRefresh => eventType == CacheEventType.refreshed;

  /// Check if this is a type-level event (affects all entities of type)
  ///
  /// Returns true if entityId is wildcard (*).
  ///
  /// Example:
  /// ```dart
  /// if (event.isTypeLevelEvent) {
  ///   // Invalidate all widgets showing this entity type
  ///   refreshAllWidgets(event.entityType);
  /// }
  /// ```
  bool get isTypeLevelEvent => entityId == '*';

  /// Get event age in milliseconds
  ///
  /// Returns time elapsed since event was created.
  ///
  /// Used for:
  /// - Event staleness detection
  /// - Performance monitoring
  /// - Debugging event propagation delays
  ///
  /// Example:
  /// ```dart
  /// if (event.ageMilliseconds > 5000) {
  ///   log.warning('Stale event: ${event.ageMilliseconds}ms old');
  /// }
  /// ```
  int get ageMilliseconds {
    return DateTime.now().difference(timestamp).inMilliseconds;
  }

  /// Convert to map for logging and debugging
  ///
  /// Useful for:
  /// - Structured logging
  /// - Event debugging
  /// - Analytics tracking
  ///
  /// Example:
  /// ```dart
  /// log.info('Cache event: ${event.toMap()}');
  /// ```
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'entityType': entityType,
      'entityId': entityId,
      'eventType': eventType.name,
      'hasData': data != null,
      'timestamp': timestamp.toIso8601String(),
      'ageMs': ageMilliseconds,
    };
  }

  /// Convert to string for debugging
  ///
  /// Provides concise event description.
  ///
  /// Example output:
  /// ```
  /// CacheInvalidationEvent(
  ///   account:123,
  ///   type: refreshed,
  ///   hasData: true,
  ///   age: 150ms
  /// )
  /// ```
  @override
  String toString() {
    return 'CacheInvalidationEvent('
        '$entityType:$entityId, '
        'type: ${eventType.name}, '
        'hasData: ${data != null}, '
        'age: ${ageMilliseconds}ms'
        ')';
  }
}

/// Cache Event Type
///
/// Defines the type of cache event that occurred.
///
/// Used for:
/// - Stream filtering (only listen to specific event types)
/// - UI update decisions (how to respond to event)
/// - Event routing (different handlers for different types)
/// - Monitoring and debugging
///
/// Values:
/// - invalidated: Cache entry marked as invalid (needs refresh)
/// - refreshed: Background refresh completed (new data available)
enum CacheEventType {
  /// Cache entry was invalidated
  ///
  /// Occurs when:
  /// - cacheService.invalidate() called
  /// - cacheService.invalidateType() called
  /// - Related entity mutated (cascade invalidation)
  /// - Sync operation completed
  /// - User performed pull-to-refresh
  ///
  /// UI Response:
  /// - May show "updating..." indicator
  /// - May trigger data refetch
  /// - May gray out data temporarily
  ///
  /// Data field: Always null
  ///
  /// Example:
  /// ```dart
  /// events
  ///   .where((e) => e.eventType == CacheEventType.invalidated)
  ///   .listen((e) {
  ///     showRefreshIndicator();
  ///   });
  /// ```
  invalidated,

  /// Background refresh completed with new data
  ///
  /// Occurs when:
  /// - Stale-while-revalidate background fetch completed
  /// - Background refresh succeeded
  /// - Cache updated with fresh data
  ///
  /// UI Response:
  /// - Update UI with new data
  /// - Hide refresh indicator
  /// - Animate data change (optional)
  ///
  /// Data field: Contains fresh data from API
  ///
  /// Example:
  /// ```dart
  /// events
  ///   .where((e) => e.eventType == CacheEventType.refreshed)
  ///   .listen((e) {
  ///     if (e.data != null) {
  ///       setState(() {
  ///         account = e.data as Account;
  ///       });
  ///       hideRefreshIndicator();
  ///     }
  ///   });
  /// ```
  refreshed,
}
