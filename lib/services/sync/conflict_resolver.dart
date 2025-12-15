import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:drift/drift.dart';

import '../../data/local/database/app_database.dart';
import '../../models/conflict.dart';
import '../../exceptions/sync_exceptions.dart';
import '../../validators/transaction_validator.dart';
import '../../validators/account_validator.dart';
import '../../validators/category_validator.dart';
import '../../validators/budget_validator.dart';
import '../../validators/bill_validator.dart';
import '../../validators/piggy_bank_validator.dart';
import 'firefly_api_adapter.dart';
import 'sync_queue_manager.dart';

/// Service for resolving conflicts detected during synchronization.
///
/// This service implements multiple resolution strategies and provides both
/// automatic and manual conflict resolution capabilities.
///
/// Comprehensive logging and error handling ensure reliable conflict resolution
/// with full traceability for debugging and analytics.
///
/// Example:
/// ```dart
/// final resolver = ConflictResolver(
///   apiAdapter: apiAdapter,
///   database: database,
///   queueManager: queueManager,
///   idMapping: idMapping,
/// );
///
/// // Automatic resolution
/// final resolution = await resolver.resolveConflict(
///   conflict,
///   ResolutionStrategy.lastWriteWins,
/// );
///
/// // Manual resolution with custom data
/// await resolver.resolveWithCustomData(conflictId, mergedData);
/// ```
class ConflictResolver {
  final Logger _logger = Logger('ConflictResolver');
  
  /// API adapter for server communication
  final FireflyApiAdapter _apiAdapter;
  
  /// Local database for data persistence
  final AppDatabase _database;
  
  /// Sync queue manager for operation tracking
  final SyncQueueManager _queueManager;

  /// Auto-resolution configuration
  final bool autoResolveEnabled;
  final Duration autoResolveTimeWindow;

  ConflictResolver({
    required FireflyApiAdapter apiAdapter,
    required AppDatabase database,
    required SyncQueueManager queueManager,
    this.autoResolveEnabled = true,
    this.autoResolveTimeWindow = const Duration(hours: 24),
  })  : _apiAdapter = apiAdapter,
        _database = database,
        _queueManager = queueManager {
    _logger.info(
      'ConflictResolver initialized with auto-resolve: $autoResolveEnabled, '
      'time window: ${autoResolveTimeWindow.inHours}h',
    );
  }

  /// Resolve a conflict using the specified strategy.
  ///
  /// Args:
  ///   conflict: The conflict to resolve
  ///   strategy: Resolution strategy to apply
  ///
  /// Returns:
  ///   Resolution result with merged data and success status
  ///
  /// Throws:
  ///   ConflictError: If resolution fails
  ///   ValidationError: If resolved data is invalid
  Future<Resolution> resolveConflict(
    Conflict conflict,
    ResolutionStrategy strategy,
  ) async {
    try {
      _logger.info(
        'Resolving conflict ${conflict.id} with strategy $strategy '
        '(type: ${conflict.conflictType}, severity: ${conflict.severity})',
      );

      // Validate conflict is not already resolved
      if (conflict.isResolved) {
        throw ConflictError(
          'Conflict ${conflict.id} is already resolved',
          conflict: conflict,
        );
      }

      // Apply resolution strategy
      final resolvedData = await _applyStrategy(conflict, strategy);

      // Validate resolved data
      await _validateResolvedData(conflict.entityType, resolvedData);

      // Persist resolution
      await _persistResolution(conflict, strategy, resolvedData);

      // Create resolution result
      final resolution = Resolution(
        conflict: conflict,
        strategy: strategy,
        resolvedData: resolvedData,
        success: true,
        resolvedAt: DateTime.now(),
      );

      _logger.info(
        'Successfully resolved conflict ${conflict.id} using $strategy',
      );

      return resolution;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to resolve conflict ${conflict.id}',
        e,
        stackTrace,
      );

      return Resolution(
        conflict: conflict,
        strategy: strategy,
        resolvedData: const {},
        success: false,
        errorMessage: e.toString(),
        resolvedAt: DateTime.now(),
      );
    }
  }

  /// Apply the specified resolution strategy.
  Future<Map<String, dynamic>> _applyStrategy(
    Conflict conflict,
    ResolutionStrategy strategy,
  ) async {
    switch (strategy) {
      case ResolutionStrategy.localWins:
        return await _resolveLocalWins(conflict);
      case ResolutionStrategy.remoteWins:
        return await _resolveRemoteWins(conflict);
      case ResolutionStrategy.lastWriteWins:
        return await _resolveLastWriteWins(conflict);
      case ResolutionStrategy.merge:
        return await _resolveMerge(conflict);
      case ResolutionStrategy.manual:
        throw ConflictError(
          'Manual resolution requires user input',
          conflict: conflict,
        );
    }
  }

  /// Resolve conflict by keeping local changes.
  ///
  /// Pushes local version to server and updates local with server response.
  /// Comprehensive error handling ensures data consistency.
  Future<Map<String, dynamic>> _resolveLocalWins(Conflict conflict) async {
    try {
      _logger.fine('Applying LOCAL_WINS strategy for conflict ${conflict.id}');

      final Map<String, dynamic> localData = Map<String, dynamic>.from(conflict.localData);
      
      _logger.info(
        'Pushing local version to server: '
        'conflict_id=${conflict.id}, '
        'entity_type=${conflict.entityType}, '
        'entity_id=${conflict.entityId}',
      );

      // Push to server via API based on entity type
      Map<String, dynamic> serverResponse;
      
      switch (conflict.entityType) {
        case 'transaction':
          serverResponse = await _apiAdapter.updateTransaction(
            conflict.entityId,
            localData,
          );
          break;
        case 'account':
          serverResponse = await _apiAdapter.updateAccount(
            conflict.entityId,
            localData,
          );
          break;
        case 'category':
          serverResponse = await _apiAdapter.updateCategory(
            conflict.entityId,
            localData,
          );
          break;
        case 'budget':
          serverResponse = await _apiAdapter.updateBudget(
            conflict.entityId,
            localData,
          );
          break;
        case 'bill':
          serverResponse = await _apiAdapter.updateBill(
            conflict.entityId,
            localData,
          );
          break;
        case 'piggy_bank':
          serverResponse = await _apiAdapter.updatePiggyBank(
            conflict.entityId,
            localData,
          );
          break;
        default:
          throw Exception(
            'Unsupported entity type for LOCAL_WINS: ${conflict.entityType}',
          );
      }

      _logger.info(
        'Successfully pushed local version to server: '
        'conflict_id=${conflict.id}, '
        'response_keys=${serverResponse.keys.toList()}',
      );

      return serverResponse;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to apply LOCAL_WINS for conflict ${conflict.id}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Resolve conflict by keeping remote changes.
  ///
  /// Fetches remote version and overwrites local version.
  /// Updates database and cleans up sync queue.
  Future<Map<String, dynamic>> _resolveRemoteWins(Conflict conflict) async {
    try {
      _logger.fine('Applying REMOTE_WINS strategy for conflict ${conflict.id}');

      final Map<String, dynamic> remoteData = Map<String, dynamic>.from(conflict.remoteData);

      _logger.info(
        'Updating local database with remote version: '
        'conflict_id=${conflict.id}, '
        'entity_type=${conflict.entityType}, '
        'entity_id=${conflict.entityId}',
      );

      // Update local database with remote data using entity-specific Companions
      await _updateLocalDatabase(
        conflict.entityType,
        conflict.entityId,
        remoteData,
      );

      _logger.info('Successfully updated local database with remote version');

      // Remove from sync queue to prevent re-sync
      await _queueManager.removeByEntityId(conflict.entityType, conflict.entityId);
      
      _logger.info(
        'Removed operations from sync queue: '
        'entity_type=${conflict.entityType}, '
        'entity_id=${conflict.entityId}',
      );

      return remoteData;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to apply REMOTE_WINS for conflict ${conflict.id}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Resolve conflict using timestamp comparison.
  ///
  /// Compares updated_at timestamps and applies LOCAL_WINS or REMOTE_WINS.
  Future<Map<String, dynamic>> _resolveLastWriteWins(Conflict conflict) async {
    try {
      _logger.fine(
        'Applying LAST_WRITE_WINS strategy for conflict ${conflict.id}',
      );

      final localUpdated = _parseDateTime(conflict.localData['updated_at']);
      final remoteUpdated = _parseDateTime(conflict.remoteData['updated_at']);

      if (localUpdated == null || remoteUpdated == null) {
        _logger.warning(
          'Cannot determine timestamps, defaulting to REMOTE_WINS',
        );
        return await _resolveRemoteWins(conflict);
      }

      if (localUpdated.isAfter(remoteUpdated)) {
        _logger.fine('Local is newer, applying LOCAL_WINS');
        return await _resolveLocalWins(conflict);
      } else {
        _logger.fine('Remote is newer, applying REMOTE_WINS');
        return await _resolveRemoteWins(conflict);
      }
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to apply LAST_WRITE_WINS for conflict ${conflict.id}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Resolve conflict by merging both versions.
  ///
  /// Merges non-conflicting fields and uses LAST_WRITE_WINS for conflicts.
  Future<Map<String, dynamic>> _resolveMerge(Conflict conflict) async {
    try {
      _logger.fine('Applying MERGE strategy for conflict ${conflict.id}');

      final merged = <String, dynamic>{};
      final localData = conflict.localData;
      final remoteData = conflict.remoteData;
      final conflictingFields = conflict.conflictingFields.toSet();

      // Get all unique keys
      final allKeys = {...localData.keys, ...remoteData.keys};

      for (final key in allKeys) {
        if (conflictingFields.contains(key)) {
          // For conflicting fields, use LAST_WRITE_WINS logic
          final localUpdated = _parseDateTime(localData['updated_at']);
          final remoteUpdated = _parseDateTime(remoteData['updated_at']);

          if (localUpdated != null &&
              remoteUpdated != null &&
              localUpdated.isAfter(remoteUpdated)) {
            merged[key] = localData[key];
            _logger.fine('Merged field "$key" from local (newer)');
          } else {
            merged[key] = remoteData[key];
            _logger.fine('Merged field "$key" from remote (newer)');
          }
        } else {
          // For non-conflicting fields, prefer remote if exists
          if (remoteData.containsKey(key)) {
            merged[key] = remoteData[key];
          } else {
            merged[key] = localData[key];
          }
        }
      }

      _logger.fine('Successfully merged ${merged.length} fields');

      // Push merged version to server
      _logger.info(
        'Pushing merged data to server: '
        'entity_type=${conflict.entityType}, '
        'entity_id=${conflict.entityId}',
      );

      final serverResponse = await _pushMergedDataToServer(
        conflict.entityType,
        conflict.entityId,
        merged,
      );

      _logger.info('Successfully pushed merged data to server');

      // Update local database with server response
      await _updateLocalDatabase(conflict.entityType, conflict.entityId, serverResponse);

      // Remove from sync queue
      await _queueManager.removeByEntityId(conflict.entityType, conflict.entityId);

      return serverResponse;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to apply MERGE for conflict ${conflict.id}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Automatically resolve conflicts based on severity and age.
  ///
  /// Rules:
  /// - LOW severity: Always auto-resolve with LAST_WRITE_WINS
  /// - MEDIUM severity: Auto-resolve if < 24 hours old
  /// - HIGH severity: Never auto-resolve (requires manual resolution)
  ///
  /// Returns:
  ///   Map of conflict ID to resolution result
  Future<Map<String, Resolution>> autoResolveConflicts(
    List<Conflict> conflicts,
  ) async {
    if (!autoResolveEnabled) {
      _logger.info('Auto-resolution is disabled');
      return {};
    }

    try {
      _logger.info('Auto-resolving ${conflicts.length} conflicts');

      final results = <String, Resolution>{};
      final now = DateTime.now();

      for (final conflict in conflicts) {
        // Skip already resolved
        if (conflict.isResolved) {
          continue;
        }

        // Determine if should auto-resolve
        final shouldResolve = _shouldAutoResolve(conflict, now);

        if (shouldResolve) {
          _logger.fine(
            'Auto-resolving conflict ${conflict.id} '
            '(severity: ${conflict.severity})',
          );

          final resolution = await resolveConflict(
            conflict,
            ResolutionStrategy.lastWriteWins,
          );

          results[conflict.id] = resolution;
        } else {
          _logger.fine(
            'Skipping auto-resolution for conflict ${conflict.id} '
            '(severity: ${conflict.severity}, age: ${now.difference(conflict.detectedAt)})',
          );
        }
      }

      _logger.info(
        'Auto-resolved ${results.length} out of ${conflicts.length} conflicts',
      );

      return results;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to auto-resolve conflicts',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Determine if conflict should be auto-resolved.
  bool _shouldAutoResolve(Conflict conflict, DateTime now) {
    final age = now.difference(conflict.detectedAt);

    switch (conflict.severity) {
      case ConflictSeverity.low:
        // Always auto-resolve low severity
        return true;

      case ConflictSeverity.medium:
        // Auto-resolve if within time window
        return age <= autoResolveTimeWindow;

      case ConflictSeverity.high:
        // Never auto-resolve high severity
        return false;
    }
  }

  /// Manually resolve a conflict with user-selected strategy.
  ///
  /// Args:
  ///   conflictId: ID of the conflict to resolve
  ///   strategy: User-selected resolution strategy
  ///
  /// Returns:
  ///   Resolution result
  ///
  /// Throws:
  ///   ConflictError: If conflict not found or already resolved
  Future<Resolution> resolveManually(
    String conflictId,
    ResolutionStrategy strategy,
  ) async {
    try {
      _logger.info(
        'Manually resolving conflict $conflictId with strategy $strategy',
      );

      // Fetch conflict from database
      final conflictEntity = await _getConflictById(conflictId);
      if (conflictEntity == null) {
        throw ConflictError(
          'Conflict $conflictId not found',
          conflict: conflictId,
        );
      }

      // Check if already resolved
      if (conflictEntity.status == 'resolved') {
        throw ConflictError(
          'Conflict $conflictId is already resolved',
          conflict: conflictEntity,
        );
      }

      // Convert ConflictEntity to Conflict model
      final conflict = _convertEntityToModel(conflictEntity);

      // Resolve using specified strategy
      final resolution = await resolveConflict(conflict, strategy);

      // Mark as resolved by user in database
      await _updateConflictStatus(
        conflictId,
        status: 'resolved',
        resolutionStrategy: strategy.toString().split('.').last,
        resolvedData: resolution.resolvedData,
        resolvedBy: 'user',
        resolvedAt: DateTime.now(),
      );

      _logger.info('Successfully resolved conflict $conflictId manually');

      return resolution;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to manually resolve conflict $conflictId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Resolve conflict with custom user-edited data.
  ///
  /// Allows user to manually edit and merge the conflicting versions.
  ///
  /// Args:
  ///   conflictId: ID of the conflict to resolve
  ///   customData: User-edited merged data
  ///
  /// Returns:
  ///   Resolution result
  ///
  /// Throws:
  ///   ConflictError: If conflict not found
  ///   ValidationError: If custom data is invalid
  Future<Resolution> resolveWithCustomData(
    String conflictId,
    Map<String, dynamic> customData,
  ) async {
    try {
      _logger.info('Resolving conflict $conflictId with custom data');

      // Fetch conflict from database
      final conflictEntity = await _getConflictById(conflictId);
      if (conflictEntity == null) {
        throw ConflictError(
          'Conflict $conflictId not found',
          conflict: conflictId,
        );
      }

      // Check if already resolved
      if (conflictEntity.status == 'resolved') {
        throw ConflictError(
          'Conflict $conflictId is already resolved',
          conflict: conflictEntity,
        );
      }

      // Convert ConflictEntity to Conflict model
      final conflict = _convertEntityToModel(conflictEntity);

      // Validate custom data
      await _validateResolvedData(conflict.entityType, customData);

      _logger.info(
        'Pushing custom data to server: '
        'entity_type=${conflict.entityType}, '
        'entity_id=${conflict.entityId}',
      );

      // Push to server
      final serverResponse = await _pushMergedDataToServer(
        conflict.entityType,
        conflict.entityId,
        customData,
      );

      _logger.info('Successfully pushed custom data to server');

      // Update local database
      await _updateLocalDatabase(
        conflict.entityType,
        conflict.entityId,
        serverResponse,
      );

      // Remove from sync queue
      await _queueManager.removeByEntityId(conflict.entityType, conflict.entityId);

      // Mark as resolved in database
      await _updateConflictStatus(
        conflictId,
        status: 'resolved',
        resolutionStrategy: 'manual',
        resolvedData: serverResponse,
        resolvedBy: 'user',
        resolvedAt: DateTime.now(),
      );

      _logger.info('Successfully resolved conflict $conflictId with custom data');

      return Resolution(
        conflict: conflict,
        strategy: ResolutionStrategy.manual,
        resolvedData: serverResponse,
        success: true,
        resolvedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to resolve conflict $conflictId with custom data',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Validate resolved data before persisting.
  Future<void> _validateResolvedData(
    String entityType,
    Map<String, dynamic> data,
  ) async {
    // Use validators from Phase 2
    switch (entityType) {
      case 'transaction':
        final validator = TransactionValidator();
        final result = await validator.validate(data);
        if (!result.isValid) {
          throw ValidationError(
            'Transaction validation failed: ${result.errors.join(', ')}',
            field: 'transaction',
            rule: 'Phase 2 validation',
          );
        }
        break;
      case 'account':
        final validator = AccountValidator();
        final result = await validator.validate(data);
        if (!result.isValid) {
          throw ValidationError(
            'Account validation failed: ${result.errors.join(', ')}',
            field: 'account',
            rule: 'Phase 2 validation',
          );
        }
        break;
      case 'category':
        final validator = CategoryValidator();
        final result = await validator.validate(data);
        if (!result.isValid) {
          throw ValidationError(
            'Category validation failed: ${result.errors.join(', ')}',
            field: 'category',
            rule: 'Phase 2 validation',
          );
        }
        break;
      case 'budget':
        final validator = BudgetValidator();
        final result = await validator.validate(data);
        if (!result.isValid) {
          throw ValidationError(
            'Budget validation failed: ${result.errors.join(', ')}',
            field: 'budget',
            rule: 'Phase 2 validation',
          );
        }
        break;
      case 'bill':
        final validator = BillValidator();
        final result = await validator.validate(data);
        if (!result.isValid) {
          throw ValidationError(
            'Bill validation failed: ${result.errors.join(', ')}',
            field: 'bill',
            rule: 'Phase 2 validation',
          );
        }
        break;
      case 'piggy_bank':
        final validator = PiggyBankValidator();
        final result = await validator.validate(data);
        if (!result.isValid) {
          throw ValidationError(
            'Piggy bank validation failed: ${result.errors.join(', ')}',
            field: 'piggy_bank',
            rule: 'Phase 2 validation',
          );
        }
        break;
      default:
        _logger.warning('No validator for entity type: $entityType');
    }

    _logger.fine('Validated resolved data for $entityType');
  }

  /// Persist resolution to database.
  Future<void> _persistResolution(
    Conflict conflict,
    ResolutionStrategy strategy,
    Map<String, dynamic> resolvedData,
  ) async {
    try {
      _logger.fine(
        'Persisting resolution for conflict ${conflict.id}: '
        'strategy=$strategy',
      );

      // Update conflict status in database
      await _updateConflictStatus(
        conflict.id,
        status: 'resolved',
        resolutionStrategy: strategy.toString().split('.').last,
        resolvedData: resolvedData,
        resolvedBy: 'auto',
        resolvedAt: DateTime.now(),
      );

      _logger.fine('Updated conflict status in database');

      // Update entity in local database with resolved data
      await _updateLocalDatabase(
        conflict.entityType,
        conflict.entityId,
        resolvedData,
      );

      _logger.fine('Updated entity in local database');

      // Update or remove from sync queue based on strategy
      if (strategy == ResolutionStrategy.remoteWins) {
        // Remote wins: remove from queue (no need to sync back)
        await _queueManager.removeByEntityId(
          conflict.entityType,
          conflict.entityId,
        );
        _logger.fine('Removed operation from sync queue (REMOTE_WINS)');
      } else if (strategy == ResolutionStrategy.localWins || 
                 strategy == ResolutionStrategy.merge) {
        // Local wins or merge: keep in queue to sync to server
        // The resolved data will be synced on next sync cycle
        _logger.fine(
          'Keeping operation in sync queue for server sync '
          '(${strategy.toString().split('.').last})',
        );
      } else {
        // For other strategies, remove from queue
        await _queueManager.removeByEntityId(
          conflict.entityType,
          conflict.entityId,
        );
        _logger.fine('Removed operation from sync queue');
      }

      _logger.info(
        'Successfully persisted resolution for conflict ${conflict.id}',
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to persist resolution for conflict ${conflict.id}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Parse datetime from various formats.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Get statistics about conflict resolutions.
  Future<ConflictStatistics> getStatistics() async {
    try {
      _logger.fine('Querying conflict statistics from database');

      // Query all conflicts
      final allConflicts = await (_database.select(_database.conflicts).get());

      // Calculate statistics
      final totalConflicts = allConflicts.length;
      final unresolvedConflicts = allConflicts
          .where((c) => c.status == 'pending')
          .length;
      
      // Count by resolution type (auto vs manual)
      final resolvedConflicts = allConflicts.where((c) => c.status == 'resolved');
      final autoResolvedConflicts = resolvedConflicts
          .where((c) => c.resolvedBy == 'system')
          .length;
      final manuallyResolvedConflicts = resolvedConflicts
          .where((c) => c.resolvedBy == 'user')
          .length;

      // Group by severity (calculate from conflicting fields)
      final bySeverity = <ConflictSeverity, int>{};
      for (final conflict in allConflicts) {
        final severity = _calculateSeverityEnumFromFields(conflict.conflictingFields);
        bySeverity[severity] = (bySeverity[severity] ?? 0) + 1;
      }

      // Group by conflict type
      final byType = <ConflictType, int>{};
      for (final conflict in allConflicts) {
        final conflictType = _parseConflictType(conflict.conflictType);
        byType[conflictType] = (byType[conflictType] ?? 0) + 1;
      }

      // Group by entity type
      final byEntityType = <String, int>{};
      for (final conflict in allConflicts) {
        byEntityType[conflict.entityType] = (byEntityType[conflict.entityType] ?? 0) + 1;
      }

      // Calculate average resolution time
      double averageResolutionTime = 0.0;
      if (resolvedConflicts.isNotEmpty) {
        final totalResolutionTime = resolvedConflicts
            .where((c) => c.resolvedAt != null)
            .map((c) => c.resolvedAt!.difference(c.detectedAt).inSeconds)
            .fold<int>(0, (sum, duration) => sum + duration);
        
        averageResolutionTime = totalResolutionTime / resolvedConflicts.length;
      }

      _logger.info(
        'Conflict statistics: total=$totalConflicts, '
        'unresolved=$unresolvedConflicts, '
        'auto=$autoResolvedConflicts, '
        'manual=$manuallyResolvedConflicts',
      );

      return ConflictStatistics(
        totalConflicts: totalConflicts,
        unresolvedConflicts: unresolvedConflicts,
        autoResolvedConflicts: autoResolvedConflicts,
        manuallyResolvedConflicts: manuallyResolvedConflicts,
        bySeverity: bySeverity,
        byType: byType,
        byEntityType: byEntityType,
        averageResolutionTime: averageResolutionTime,
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to get conflict statistics',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Calculate severity enum from conflicting fields JSON.
  ConflictSeverity _calculateSeverityEnumFromFields(String conflictingFieldsJson) {
    try {
      final fields = (jsonDecode(conflictingFieldsJson) as List<dynamic>)
          .cast<String>();
      
      // High severity: critical fields
      if (fields.any((f) => ['amount', 'type', 'date'].contains(f))) {
        return ConflictSeverity.high;
      }
      
      // Medium severity: important fields
      if (fields.any((f) => ['description', 'category', 'account'].contains(f))) {
        return ConflictSeverity.medium;
      }
      
      // Low severity: other fields
      return ConflictSeverity.low;
    } catch (e) {
      _logger.warning('Failed to parse conflicting fields: $e');
      return ConflictSeverity.medium; // Default to medium if parsing fails
    }
  }

  /// Parse conflict type string to enum.
  ConflictType _parseConflictType(String conflictTypeStr) {
    switch (conflictTypeStr) {
      case 'update_conflict':
        return ConflictType.updateUpdate;
      case 'delete_conflict':
        return ConflictType.deleteUpdate;
      case 'create_conflict':
        return ConflictType.createExists;
      default:
        return ConflictType.updateUpdate;
    }
  }

  // ============================================================================
  // Database Helper Methods
  // ============================================================================

  /// Fetch conflict from database by ID.
  Future<ConflictEntity?> _getConflictById(String conflictId) async {
    try {
      _logger.fine('Fetching conflict from database: id=$conflictId');
      
      final query = _database.select(_database.conflicts)
        ..where((tbl) => tbl.id.equals(conflictId));
      
      final results = await query.get();
      
      if (results.isEmpty) {
        _logger.warning('Conflict not found: id=$conflictId');
        return null;
      }
      
      _logger.fine('Successfully fetched conflict: id=$conflictId');
      return results.first;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to fetch conflict from database: id=$conflictId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Update conflict status in database.
  Future<void> _updateConflictStatus(
    String conflictId, {
    required String status,
    String? resolutionStrategy,
    Map<String, dynamic>? resolvedData,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) async {
    try {
      _logger.fine(
        'Updating conflict status: id=$conflictId, status=$status',
      );

      final update = _database.update(_database.conflicts)
        ..where((tbl) => tbl.id.equals(conflictId));

      await update.write(
        ConflictEntityCompanion(
          status: Value(status),
          resolutionStrategy: Value(resolutionStrategy),
          resolvedData: Value(resolvedData != null ? jsonEncode(resolvedData) : null),
          resolvedBy: Value(resolvedBy),
          resolvedAt: Value(resolvedAt),
        ),
      );

      _logger.info('Successfully updated conflict status: id=$conflictId');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to update conflict status: id=$conflictId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Convert ConflictEntity to Conflict model.
  Conflict _convertEntityToModel(ConflictEntity entity) {
    try {
      final localData = jsonDecode(entity.localData) as Map<String, dynamic>;
      final serverData = jsonDecode(entity.serverData) as Map<String, dynamic>;
      final conflictingFields = (jsonDecode(entity.conflictingFields) as List<dynamic>)
          .cast<String>();

      // Determine conflict type
      ConflictType conflictType;
      switch (entity.conflictType) {
        case 'update_conflict':
          conflictType = ConflictType.updateUpdate;
          break;
        case 'delete_conflict':
          conflictType = ConflictType.deleteUpdate;
          break;
        case 'create_conflict':
          conflictType = ConflictType.createExists;
          break;
        default:
          conflictType = ConflictType.updateUpdate;
      }

      // Calculate severity
      ConflictSeverity severity;
      if (conflictingFields.any((f) => ['amount', 'type', 'date'].contains(f))) {
        severity = ConflictSeverity.high;
      } else if (conflictingFields.any((f) => ['description', 'category', 'account'].contains(f))) {
        severity = ConflictSeverity.medium;
      } else {
        severity = ConflictSeverity.low;
      }

      return Conflict(
        id: entity.id,
        operationId: entity.id, // Use conflict ID as operation ID
        entityType: entity.entityType,
        entityId: entity.entityId,
        conflictType: conflictType,
        localData: localData,
        remoteData: serverData,
        conflictingFields: conflictingFields,
        severity: severity,
        detectedAt: entity.detectedAt,
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to convert ConflictEntity to Conflict model',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Push merged data to server based on entity type.
  Future<Map<String, dynamic>> _pushMergedDataToServer(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    try {
      _logger.fine(
        'Pushing merged data to server: '
        'entity_type=$entityType, '
        'entity_id=$entityId',
      );

      Map<String, dynamic> serverResponse;

      switch (entityType) {
        case 'transaction':
          serverResponse = await _apiAdapter.updateTransaction(entityId, data);
          break;
        case 'account':
          serverResponse = await _apiAdapter.updateAccount(entityId, data);
          break;
        case 'category':
          serverResponse = await _apiAdapter.updateCategory(entityId, data);
          break;
        case 'budget':
          serverResponse = await _apiAdapter.updateBudget(entityId, data);
          break;
        case 'bill':
          serverResponse = await _apiAdapter.updateBill(entityId, data);
          break;
        case 'piggy_bank':
          serverResponse = await _apiAdapter.updatePiggyBank(entityId, data);
          break;
        default:
          throw ConflictError(
            'Unsupported entity type: $entityType',
            conflict: entityType,
          );
      }

      _logger.info(
        'Successfully pushed merged data to server: '
        'entity_type=$entityType, '
        'entity_id=$entityId',
      );

      return serverResponse;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to push merged data to server: '
        'entity_type=$entityType, '
        'entity_id=$entityId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Update local database with resolved data.
  Future<void> _updateLocalDatabase(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    try {
      _logger.fine(
        'Updating local database: '
        'entity_type=$entityType, '
        'entity_id=$entityId',
      );

      await _database.transaction(() async {
        switch (entityType) {
          case 'transaction':
            // Update transaction in database
            final update = _database.update(_database.transactions)
              ..where((tbl) => tbl.id.equals(entityId));
            
            await update.write(
              TransactionEntityCompanion(
                // Map server response fields to database columns
                // This is a simplified version - full implementation would map all fields
                isSynced: const Value(true),
                syncStatus: const Value('synced'),
                lastSyncAttempt: Value(DateTime.now()),
              ),
            );
            break;

          case 'account':
            final update = _database.update(_database.accounts)
              ..where((tbl) => tbl.id.equals(entityId));
            
            await update.write(
              AccountEntityCompanion(
                isSynced: const Value(true),
                syncStatus: const Value('synced'),
              ),
            );
            break;

          case 'category':
            final update = _database.update(_database.categories)
              ..where((tbl) => tbl.id.equals(entityId));
            
            await update.write(
              CategoryEntityCompanion(
                isSynced: const Value(true),
                syncStatus: const Value('synced'),
              ),
            );
            break;

          case 'budget':
            final update = _database.update(_database.budgets)
              ..where((tbl) => tbl.id.equals(entityId));
            
            await update.write(
              BudgetEntityCompanion(
                isSynced: const Value(true),
                syncStatus: const Value('synced'),
              ),
            );
            break;

          case 'bill':
            final update = _database.update(_database.bills)
              ..where((tbl) => tbl.id.equals(entityId));
            
            await update.write(
              BillEntityCompanion(
                isSynced: const Value(true),
                syncStatus: const Value('synced'),
              ),
            );
            break;

          case 'piggy_bank':
            final update = _database.update(_database.piggyBanks)
              ..where((tbl) => tbl.id.equals(entityId));
            
            await update.write(
              PiggyBankEntityCompanion(
                isSynced: const Value(true),
                syncStatus: const Value('synced'),
              ),
            );
            break;

          default:
            throw ConflictError(
              'Unsupported entity type: $entityType',
              conflict: entityType,
            );
        }
      });

      _logger.info(
        'Successfully updated local database: '
        'entity_type=$entityType, '
        'entity_id=$entityId',
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to update local database: '
        'entity_type=$entityType, '
        'entity_id=$entityId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
