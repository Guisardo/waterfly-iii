import 'package:logging/logging.dart';

import '../../models/conflict.dart';
import '../../models/sync_operation.dart';
import '../../exceptions/sync_exceptions.dart';
import '../../validators/transaction_validator.dart';
import '../../validators/account_validator.dart';
import '../../validators/category_validator.dart';
import '../../validators/budget_validator.dart';
import '../../validators/bill_validator.dart';
import '../../validators/piggy_bank_validator.dart';

/// Service for resolving conflicts detected during synchronization.
///
/// This service implements multiple resolution strategies and provides both
/// automatic and manual conflict resolution capabilities.
///
/// Example:
/// ```dart
/// final resolver = ConflictResolver(
///   apiClient: apiClient,
///   localDatabase: database,
///   idMappingService: idMapping,
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
  
  // Dependencies would be injected in real implementation
  // final ApiClient _apiClient;
  // final Database _database;
  // final IdMappingService _idMapping;
  // final SyncQueueManager _queueManager;

  /// Auto-resolution configuration
  final bool autoResolveEnabled;
  final Duration autoResolveTimeWindow;

  ConflictResolver({
    this.autoResolveEnabled = true,
    this.autoResolveTimeWindow = const Duration(hours: 24),
  });

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
  Future<Map<String, dynamic>> _resolveLocalWins(Conflict conflict) async {
    try {
      _logger.fine('Applying LOCAL_WINS strategy for conflict ${conflict.id}');

      final localData = Map<String, dynamic>.from(conflict.localData);

      // TODO: Push to server via API
      // final serverResponse = await _apiClient.update(
      //   conflict.entityType,
      //   conflict.entityId,
      //   localData,
      // );

      // For now, return local data
      // In real implementation, return server response
      _logger.fine('Local version will be pushed to server');

      return localData;
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
  Future<Map<String, dynamic>> _resolveRemoteWins(Conflict conflict) async {
    try {
      _logger.fine('Applying REMOTE_WINS strategy for conflict ${conflict.id}');

      final remoteData = Map<String, dynamic>.from(conflict.remoteData);

      // TODO: Update local database
      // await _database.update(
      //   conflict.entityType,
      //   conflict.entityId,
      //   remoteData,
      // );

      // TODO: Remove from sync queue
      // await _queueManager.removeOperation(conflict.operationId);

      _logger.fine('Remote version will overwrite local');

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

      // TODO: Push merged version to server
      // final serverResponse = await _apiClient.update(
      //   conflict.entityType,
      //   conflict.entityId,
      //   merged,
      // );

      return merged;
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

      // TODO: Fetch conflict from database
      // final conflict = await _database.getConflict(conflictId);
      // if (conflict == null) {
      //   throw ConflictError('Conflict $conflictId not found');
      // }

      // For now, throw not implemented
      throw UnimplementedError('Manual resolution requires database integration');

      // final resolution = await resolveConflict(conflict, strategy);
      //
      // // Mark as resolved by user
      // await _database.updateConflict(
      //   conflictId,
      //   resolvedBy: 'user',
      //   resolvedAt: DateTime.now(),
      //   resolutionStrategy: strategy.name,
      // );
      //
      // return resolution;
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

      // TODO: Fetch conflict from database
      // final conflict = await _database.getConflict(conflictId);
      // if (conflict == null) {
      //   throw ConflictError('Conflict $conflictId not found');
      // }

      // For now, throw not implemented
      throw UnimplementedError('Custom data resolution requires database integration');

      // // Validate custom data
      // await _validateResolvedData(conflict.entityType, customData);
      //
      // // Push to server
      // final serverResponse = await _apiClient.update(
      //   conflict.entityType,
      //   conflict.entityId,
      //   customData,
      // );
      //
      // // Update local
      // await _database.update(
      //   conflict.entityType,
      //   conflict.entityId,
      //   serverResponse,
      // );
      //
      // // Mark as resolved
      // await _database.updateConflict(
      //   conflictId,
      //   resolvedBy: 'user',
      //   resolvedAt: DateTime.now(),
      //   resolutionStrategy: ResolutionStrategy.manual.name,
      // );
      //
      // return Resolution(
      //   conflict: conflict,
      //   strategy: ResolutionStrategy.manual,
      //   resolvedData: serverResponse,
      //   success: true,
      //   resolvedAt: DateTime.now(),
      // );
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
      // TODO: Update conflict in database
      // await _database.updateConflict(
      //   conflict.id,
      //   resolvedBy: 'auto',
      //   resolvedAt: DateTime.now(),
      //   resolutionStrategy: strategy.name,
      // );

      // TODO: Update entity in database
      // await _database.update(
      //   conflict.entityType,
      //   conflict.entityId,
      //   resolvedData,
      // );

      // TODO: Update or remove from sync queue
      // if (strategy == ResolutionStrategy.remoteWins) {
      //   await _queueManager.removeOperation(conflict.operationId);
      // } else {
      //   await _queueManager.updateOperation(
      //     conflict.operationId,
      //     payload: resolvedData,
      //   );
      // }

      _logger.fine('Persisted resolution for conflict ${conflict.id}');
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
      // TODO: Query database for statistics
      // final stats = await _database.getConflictStatistics();

      // For now, return empty statistics
      return const ConflictStatistics(
        totalConflicts: 0,
        unresolvedConflicts: 0,
        autoResolvedConflicts: 0,
        manuallyResolvedConflicts: 0,
        bySeverity: {},
        byType: {},
        byEntityType: {},
        averageResolutionTime: 0.0,
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
}
