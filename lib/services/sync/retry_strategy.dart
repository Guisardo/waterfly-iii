import 'dart:math';
import 'package:logging/logging.dart';
import 'package:retry/retry.dart';

import '../../exceptions/sync_exceptions.dart';

/// Service for handling retry logic with exponential backoff.
///
/// Uses the `retry` package for robust retry handling with configurable
/// parameters including max attempts, delays, and jitter.
///
/// Example:
/// ```dart
/// final retryStrategy = RetryStrategy();
///
/// final result = await retryStrategy.retryOperation(
///   () => apiClient.createTransaction(data),
///   operationName: 'create_transaction',
/// );
/// ```
class RetryStrategy {
  final Logger _logger = Logger('RetryStrategy');

  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Initial delay before first retry
  final Duration initialDelay;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Exponential backoff factor
  final double exponentialFactor;

  /// Jitter percentage (0.0 to 1.0)
  final double jitter;

  /// Random number generator for jitter
  final Random _random = Random();

  RetryStrategy({
    this.maxAttempts = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 60),
    this.exponentialFactor = 2.0,
    this.jitter = 0.2,
  });

  /// Retry an operation with exponential backoff.
  ///
  /// Args:
  ///   operation: The async operation to retry
  ///   operationName: Name for logging purposes
  ///   onRetry: Optional callback called before each retry
  ///
  /// Returns:
  ///   Result of the operation
  ///
  /// Throws:
  ///   The last exception if all retries fail
  Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    void Function(Exception, int)? onRetry,
  }) async {
    final name = operationName ?? 'operation';
    int attemptNumber = 0;

    try {
      return await retry(
        () async {
          attemptNumber++;
          try {
            _logger.fine('Attempting $name (attempt $attemptNumber/$maxAttempts)');
            return await operation();
          } catch (e) {
            _logger.warning(
              'Attempt $attemptNumber/$maxAttempts failed for $name: $e',
            );

            // Check if retryable
            if (!isRetryable(e)) {
              _logger.info('Error is not retryable, aborting: $e');
              rethrow;
            }

            // Call onRetry callback if provided
            if (onRetry != null && e is Exception) {
              onRetry(e, attemptNumber);
            }

            rethrow;
          }
        },
        retryIf: (e) => isRetryable(e),
        maxAttempts: maxAttempts,
        delayFactor: initialDelay,
        maxDelay: maxDelay,
        onRetry: (e) {
          final delay = getRetryDelay(attemptNumber);
          _logger.info(
            'Retrying $name in ${delay.inMilliseconds}ms '
            '(attempt $attemptNumber/$maxAttempts)',
          );
        },
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'All retry attempts failed for $name after $attemptNumber attempts',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Retry a batch of operations with individual tracking.
  ///
  /// Each operation is retried independently. Failed operations are collected
  /// and returned.
  ///
  /// Args:
  ///   operations: Map of operation ID to operation function
  ///   onProgress: Optional callback for progress updates
  ///
  /// Returns:
  ///   Map of successful operation results
  ///   Map of failed operation errors
  Future<BatchRetryResult<T>> retryBatch<T>(
    Map<String, Future<T> Function()> operations, {
    void Function(String operationId, int completed, int total)? onProgress,
  }) async {
    _logger.info('Retrying batch of ${operations.length} operations');

    final results = <String, T>{};
    final errors = <String, Exception>{};
    int completed = 0;

    for (final entry in operations.entries) {
      final operationId = entry.key;
      final operation = entry.value;

      try {
        final result = await retryOperation(
          operation,
          operationName: operationId,
        );
        results[operationId] = result;
      } catch (e) {
        _logger.warning('Operation $operationId failed after all retries: $e');
        errors[operationId] = e is Exception ? e : Exception(e.toString());
      }

      completed++;
      if (onProgress != null) {
        onProgress(operationId, completed, operations.length);
      }
    }

    _logger.info(
      'Batch retry completed: ${results.length} succeeded, ${errors.length} failed',
    );

    return BatchRetryResult(
      successes: results,
      failures: errors,
      totalOperations: operations.length,
    );
  }

  /// Determine if an error is retryable.
  ///
  /// Args:
  ///   error: The error to check
  ///
  /// Returns:
  ///   true if the error should be retried
  bool isRetryable(Object error) {
    // Check if it's a SyncException with isRetryable property
    if (error is SyncException) {
      return error.isRetryable;
    }

    // Check specific exception types
    if (error is NetworkError) return true;
    if (error is ServerError) return true;
    if (error is TimeoutError) return true;
    if (error is RateLimitError) return true;

    // Non-retryable exceptions
    if (error is ClientError) return false;
    if (error is ConflictError) return false;
    if (error is AuthenticationError) return false;
    if (error is ValidationError) return false;
    if (error is CircuitBreakerOpenError) return false;

    // Default: don't retry unknown errors
    _logger.fine('Unknown error type, not retrying: ${error.runtimeType}');
    return false;
  }

  /// Calculate retry delay with exponential backoff and jitter.
  ///
  /// Args:
  ///   attemptNumber: Current attempt number (1-based)
  ///
  /// Returns:
  ///   Duration to wait before next retry
  Duration getRetryDelay(int attemptNumber) {
    // Calculate base delay with exponential backoff
    final baseDelayMs = initialDelay.inMilliseconds *
        pow(exponentialFactor, attemptNumber - 1);

    // Cap at max delay
    final cappedDelayMs = min(baseDelayMs, maxDelay.inMilliseconds.toDouble());

    // Add jitter (±jitter%)
    final jitterAmount = cappedDelayMs * jitter;
    final jitterOffset = (_random.nextDouble() * 2 - 1) * jitterAmount;
    final finalDelayMs = cappedDelayMs + jitterOffset;

    return Duration(milliseconds: finalDelayMs.round());
  }

  /// Get retry delay from exception if available.
  ///
  /// Some exceptions (like RateLimitError) may specify a retry delay.
  ///
  /// Args:
  ///   error: The error to check
  ///   attemptNumber: Current attempt number
  ///
  /// Returns:
  ///   Duration to wait before retry
  Duration getRetryDelayFromError(Object error, int attemptNumber) {
    if (error is SyncException) {
      return error.retryDelay ?? getRetryDelay(attemptNumber);
    }
    return getRetryDelay(attemptNumber);
  }

  /// Create a custom retry policy.
  ///
  /// Args:
  ///   maxAttempts: Maximum retry attempts
  ///   initialDelay: Initial delay
  ///   maxDelay: Maximum delay
  ///   exponentialFactor: Backoff factor
  ///
  /// Returns:
  ///   New RetryStrategy instance
  static RetryStrategy createPolicy({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    double? exponentialFactor,
    double? jitter,
  }) {
    return RetryStrategy(
      maxAttempts: maxAttempts ?? 5,
      initialDelay: initialDelay ?? const Duration(seconds: 1),
      maxDelay: maxDelay ?? const Duration(seconds: 60),
      exponentialFactor: exponentialFactor ?? 2.0,
      jitter: jitter ?? 0.2,
    );
  }

  /// Create an aggressive retry policy for critical operations.
  ///
  /// More attempts, shorter delays.
  static RetryStrategy createAggressivePolicy() {
    return RetryStrategy(
      maxAttempts: 10,
      initialDelay: const Duration(milliseconds: 500),
      maxDelay: const Duration(seconds: 30),
      exponentialFactor: 1.5,
      jitter: 0.1,
    );
  }

  /// Create a conservative retry policy for non-critical operations.
  ///
  /// Fewer attempts, longer delays.
  static RetryStrategy createConservativePolicy() {
    return RetryStrategy(
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 2),
      maxDelay: const Duration(seconds: 120),
      exponentialFactor: 3.0,
      jitter: 0.3,
    );
  }
}

/// Result of a batch retry operation.
class BatchRetryResult<T> {
  /// Successfully completed operations
  final Map<String, T> successes;

  /// Failed operations with their errors
  final Map<String, Exception> failures;

  /// Total number of operations
  final int totalOperations;

  const BatchRetryResult({
    required this.successes,
    required this.failures,
    required this.totalOperations,
  });

  /// Number of successful operations
  int get successCount => successes.length;

  /// Number of failed operations
  int get failureCount => failures.length;

  /// Success rate (0.0 to 1.0)
  double get successRate =>
      totalOperations > 0 ? successCount / totalOperations : 0.0;

  /// Whether all operations succeeded
  bool get allSucceeded => failureCount == 0;

  /// Whether all operations failed
  bool get allFailed => successCount == 0;

  @override
  String toString() {
    return 'BatchRetryResult('
        'total: $totalOperations, '
        'succeeded: $successCount, '
        'failed: $failureCount, '
        'success_rate: ${(successRate * 100).toStringAsFixed(1)}%'
        ')';
  }
}
