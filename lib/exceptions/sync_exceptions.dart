import 'package:logging/logging.dart';

/// Base exception for all synchronization-related errors.
///
/// This exception hierarchy provides detailed error classification for
/// sync operations, enabling proper error handling, retry logic, and
/// user feedback.
///
/// Example:
/// ```dart
/// try {
///   await syncManager.synchronize();
/// } on NetworkError catch (e) {
///   // Handle network-specific errors
///   logger.warning('Network error during sync: ${e.message}');
/// } on ConflictError catch (e) {
///   // Handle conflicts
///   await conflictResolver.resolve(e.conflict);
/// }
/// ```
abstract class SyncException implements Exception {
  /// Human-readable error message
  final String message;

  /// Original exception that caused this error (if any)
  final Exception? cause;

  /// Additional context about the error
  final Map<String, dynamic>? context;

  /// Timestamp when the error occurred
  final DateTime timestamp;

  SyncException(this.message, {this.cause, this.context})
    : timestamp = DateTime.now();

  /// Whether this error is retryable
  bool get isRetryable;

  /// Suggested delay before retry (if retryable)
  Duration get retryDelay => const Duration(seconds: 5);

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer('$runtimeType: $message');
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext: $context');
    }
    if (cause != null) {
      buffer.write('\nCaused by: $cause');
    }
    return buffer.toString();
  }

  /// Log this exception with appropriate level
  void log(Logger logger) {
    logger.severe(message, cause, StackTrace.current);
  }
}

/// Network-related errors (connectivity, timeouts, DNS failures).
///
/// These errors are typically retryable and should trigger exponential backoff.
class NetworkError extends SyncException {
  NetworkError(super.message, {super.cause, super.context});

  @override
  bool get isRetryable => true;

  @override
  Duration get retryDelay => const Duration(seconds: 10);

  @override
  void log(Logger logger) {
    logger.warning('Network error: $message', cause, StackTrace.current);
  }
}

/// Server errors (5xx responses, internal server errors).
///
/// These errors are retryable as they indicate temporary server issues.
class ServerError extends SyncException {
  /// HTTP status code
  final int? statusCode;

  /// Server response body
  final String? responseBody;

  ServerError(
    super.message, {
    this.statusCode,
    this.responseBody,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable => true;

  @override
  Duration get retryDelay => const Duration(seconds: 30);

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer(super.toString());
    if (statusCode != null) {
      buffer.write('\nStatus Code: $statusCode');
    }
    if (responseBody != null) {
      buffer.write(
        '\nResponse: ${responseBody!.substring(0, responseBody!.length > 200 ? 200 : responseBody!.length)}',
      );
    }
    return buffer.toString();
  }
}

/// Client errors (4xx responses, invalid requests).
///
/// These errors are typically not retryable as they indicate client-side issues.
class ClientError extends SyncException {
  /// HTTP status code
  final int statusCode;

  /// Server response body
  final String? responseBody;

  ClientError(
    super.message, {
    required this.statusCode,
    this.responseBody,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable => statusCode == 429; // Only retry rate limits

  @override
  Duration get retryDelay {
    // For rate limits, use longer delay
    if (statusCode == 429) {
      return const Duration(minutes: 1);
    }
    return super.retryDelay;
  }

  @override
  void log(Logger logger) {
    logger.warning(
      'Client error ($statusCode): $message',
      cause,
      StackTrace.current,
    );
  }
}

/// Conflict errors (409 responses, concurrent modifications).
///
/// These errors require conflict resolution and are not automatically retryable.
class ConflictError extends SyncException {
  /// The conflict that was detected
  final dynamic conflict;

  /// Local version of the entity
  final Map<String, dynamic>? localVersion;

  /// Remote version of the entity
  final Map<String, dynamic>? remoteVersion;

  ConflictError(
    super.message, {
    required this.conflict,
    this.localVersion,
    this.remoteVersion,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable => false; // Requires manual resolution

  @override
  void log(Logger logger) {
    logger.warning('Conflict detected: $message', cause, StackTrace.current);
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer(super.toString());
    if (localVersion != null) {
      buffer.write('\nLocal Version: $localVersion');
    }
    if (remoteVersion != null) {
      buffer.write('\nRemote Version: $remoteVersion');
    }
    return buffer.toString();
  }
}

/// Authentication errors (401 responses, invalid tokens).
///
/// These errors are not retryable and require user intervention.
class AuthenticationError extends SyncException {
  AuthenticationError(super.message, {super.cause, super.context});

  @override
  bool get isRetryable => false;

  @override
  void log(Logger logger) {
    logger.severe('Authentication error: $message', cause, StackTrace.current);
  }
}

/// Validation errors (invalid data, business rule violations).
///
/// These errors are not retryable and indicate data quality issues.
class ValidationError extends SyncException {
  /// Field that failed validation
  final String? field;

  /// Validation rule that was violated
  final String? rule;

  /// Suggested fix for the validation error
  final String? suggestedFix;

  ValidationError(
    super.message, {
    this.field,
    this.rule,
    this.suggestedFix,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable => false;

  @override
  void log(Logger logger) {
    logger.warning(
      'Validation error${field != null ? " on field '$field'" : ""}: $message',
      cause,
      StackTrace.current,
    );
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer(super.toString());
    if (field != null) {
      buffer.write('\nField: $field');
    }
    if (rule != null) {
      buffer.write('\nRule: $rule');
    }
    if (suggestedFix != null) {
      buffer.write('\nSuggested Fix: $suggestedFix');
    }
    return buffer.toString();
  }
}

/// Rate limit errors (429 responses, too many requests).
///
/// These errors are retryable after a delay specified by the server.
class RateLimitError extends SyncException {
  /// Time to wait before retrying (from Retry-After header)
  final Duration retryAfter;

  /// Number of requests allowed per period
  final int? limit;

  /// Number of requests remaining
  final int? remaining;

  /// Time when the rate limit resets
  final DateTime? resetTime;

  RateLimitError(
    super.message, {
    required this.retryAfter,
    this.limit,
    this.remaining,
    this.resetTime,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable => true;

  @override
  Duration get retryDelay => retryAfter;

  @override
  void log(Logger logger) {
    logger.warning(
      'Rate limit exceeded: $message (retry after ${retryAfter.inSeconds}s)',
      cause,
      StackTrace.current,
    );
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer(super.toString());
    buffer.write('\nRetry After: ${retryAfter.inSeconds}s');
    if (limit != null) {
      buffer.write('\nLimit: $limit');
    }
    if (remaining != null) {
      buffer.write('\nRemaining: $remaining');
    }
    if (resetTime != null) {
      buffer.write('\nResets At: $resetTime');
    }
    return buffer.toString();
  }
}

/// Timeout errors (request took too long).
///
/// These errors are retryable with exponential backoff.
class TimeoutError extends SyncException {
  /// Duration that was exceeded
  final Duration timeout;

  TimeoutError(
    super.message, {
    required this.timeout,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable => true;

  @override
  Duration get retryDelay => Duration(seconds: timeout.inSeconds * 2);

  @override
  void log(Logger logger) {
    logger.warning(
      'Timeout error after ${timeout.inSeconds}s: $message',
      cause,
      StackTrace.current,
    );
  }
}

/// Data consistency errors (referential integrity violations, orphaned records).
///
/// These errors require data repair and are not automatically retryable.
class ConsistencyError extends SyncException {
  /// Type of consistency issue
  final String issueType;

  /// Affected entity IDs
  final List<String>? affectedIds;

  ConsistencyError(
    super.message, {
    required this.issueType,
    this.affectedIds,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable => false;

  @override
  void log(Logger logger) {
    logger.severe(
      'Data consistency error ($issueType): $message',
      cause,
      StackTrace.current,
    );
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer(super.toString());
    buffer.write('\nIssue Type: $issueType');
    if (affectedIds != null && affectedIds!.isNotEmpty) {
      buffer.write('\nAffected IDs: ${affectedIds!.join(", ")}');
    }
    return buffer.toString();
  }
}

/// Sync operation errors (general sync failures).
///
/// These errors wrap other exceptions and provide sync-specific context.
class SyncOperationError extends SyncException {
  /// ID of the operation that failed
  final String operationId;

  /// Type of entity being synced
  final String entityType;

  /// Type of operation (CREATE, UPDATE, DELETE)
  final String operationType;

  SyncOperationError(
    super.message, {
    required this.operationId,
    required this.entityType,
    required this.operationType,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable {
    // Delegate to cause if available
    if (cause is SyncException) {
      return (cause as SyncException).isRetryable;
    }
    return true; // Default to retryable
  }

  @override
  Duration get retryDelay {
    if (cause is SyncException) {
      return (cause as SyncException).retryDelay;
    }
    return super.retryDelay;
  }

  @override
  void log(Logger logger) {
    logger.severe(
      'Sync operation failed ($operationType $entityType): $message',
      cause,
      StackTrace.current,
    );
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer(super.toString());
    buffer.write('\nOperation ID: $operationId');
    buffer.write('\nEntity Type: $entityType');
    buffer.write('\nOperation Type: $operationType');
    return buffer.toString();
  }
}

/// Circuit breaker open error (too many failures, circuit is open).
///
/// These errors indicate the circuit breaker is protecting the system.
class CircuitBreakerOpenError extends SyncException {
  /// Time when the circuit will attempt to close
  final DateTime resetTime;

  /// Number of consecutive failures that opened the circuit
  final int failureCount;

  CircuitBreakerOpenError(
    super.message, {
    required this.resetTime,
    required this.failureCount,
    super.cause,
    super.context,
  });

  @override
  bool get isRetryable => true;

  @override
  Duration get retryDelay {
    final DateTime now = DateTime.now();
    if (resetTime.isAfter(now)) {
      return resetTime.difference(now);
    }
    return const Duration(seconds: 60);
  }

  @override
  void log(Logger logger) {
    logger.warning(
      'Circuit breaker open after $failureCount failures: $message',
      cause,
      StackTrace.current,
    );
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer(super.toString());
    buffer.write('\nFailure Count: $failureCount');
    buffer.write('\nReset Time: $resetTime');
    return buffer.toString();
  }
}
