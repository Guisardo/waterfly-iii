/// Base exception for all offline mode related errors.
///
/// All offline mode exceptions extend this class to provide consistent
/// error handling and logging.
abstract class OfflineException implements Exception {
  /// Creates an offline exception with a message and optional context.
  const OfflineException(this.message, [this.context]);

  /// Human-readable error message.
  final String message;

  /// Additional context information about the error.
  final Map<String, dynamic>? context;

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer('$runtimeType: $message');
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext: $context');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a database operation fails.
///
/// This includes errors from Drift operations, SQL errors, and
/// database connection issues.
class DatabaseException extends OfflineException {
  /// Creates a database exception.
  const DatabaseException(super.message, [super.context]);

  /// Creates a database exception for a failed query.
  factory DatabaseException.queryFailed(
    String query,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    return DatabaseException(
      'Database query failed: $error',
      <String, dynamic>{
        'query': query,
        'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      },
    );
  }

  /// Creates a database exception for a connection error.
  factory DatabaseException.connectionFailed(Object error) {
    return DatabaseException(
      'Failed to connect to database: $error',
      <String, dynamic>{'error': error.toString()},
    );
  }

  /// Creates a database exception for a transaction error.
  factory DatabaseException.transactionFailed(
    String operation,
    Object error,
  ) {
    return DatabaseException(
      'Database transaction failed during $operation: $error',
      <String, dynamic>{
        'operation': operation,
        'error': error.toString(),
      },
    );
  }
}

/// Exception thrown when a synchronization operation fails.
///
/// This includes errors during sync queue processing, server communication,
/// and conflict resolution.
class SyncException extends OfflineException {
  /// Creates a sync exception.
  const SyncException(super.message, [super.context]);

  /// Creates a sync exception for a failed operation.
  factory SyncException.operationFailed(
    String operationId,
    String entityType,
    Object error,
  ) {
    return SyncException(
      'Sync operation failed: $error',
      <String, dynamic>{
        'operationId': operationId,
        'entityType': entityType,
        'error': error.toString(),
      },
    );
  }

  /// Creates a sync exception for a server error.
  factory SyncException.serverError(
    int statusCode,
    String message,
  ) {
    return SyncException(
      'Server returned error: $message',
      <String, dynamic>{
        'statusCode': statusCode,
        'message': message,
      },
    );
  }

  /// Creates a sync exception for a timeout.
  factory SyncException.timeout(String operation) {
    return SyncException(
      'Sync operation timed out: $operation',
      <String, dynamic>{'operation': operation},
    );
  }

  /// Creates a sync exception for max retries exceeded.
  factory SyncException.maxRetriesExceeded(
    String operationId,
    int attempts,
  ) {
    return SyncException(
      'Max sync retries exceeded',
      <String, dynamic>{
        'operationId': operationId,
        'attempts': attempts,
      },
    );
  }
}

/// Exception thrown when connectivity-related operations fail.
///
/// This includes network connectivity checks, server reachability tests,
/// and connectivity monitoring errors.
class ConnectivityException extends OfflineException {
  /// Creates a connectivity exception.
  const ConnectivityException(super.message, [super.context]);

  /// Creates a connectivity exception for no network.
  factory ConnectivityException.noNetwork() {
    return const ConnectivityException(
      'No network connectivity available',
    );
  }

  /// Creates a connectivity exception for server unreachable.
  factory ConnectivityException.serverUnreachable(String serverUrl) {
    return ConnectivityException(
      'Server is unreachable',
      <String, dynamic>{'serverUrl': serverUrl},
    );
  }

  /// Creates a connectivity exception for a timeout.
  factory ConnectivityException.timeout(Duration timeout) {
    return ConnectivityException(
      'Connectivity check timed out',
      <String, dynamic>{'timeout': timeout.toString()},
    );
  }
}

/// Exception thrown when a data conflict is detected during synchronization.
///
/// This occurs when the same entity has been modified both locally and
/// on the server, requiring conflict resolution.
class ConflictException extends OfflineException {
  /// Creates a conflict exception.
  const ConflictException(super.message, [super.context, this.localData, this.serverData]);

  /// The local version of the conflicting entity.
  final Map<String, dynamic>? localData;

  /// The server version of the conflicting entity.
  final Map<String, dynamic>? serverData;

  /// Creates a conflict exception with entity data.
  ConflictException.withData(
    String message,
    this.localData,
    this.serverData, [
    Map<String, dynamic>? context,
  ]) : super(message, context);

  /// Creates a conflict exception for a modified entity.
  factory ConflictException.entityModified(
    String entityType,
    String entityId,
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    return ConflictException.withData(
      'Entity was modified both locally and on server',
      localData,
      serverData,
      <String, dynamic>{
        'entityType': entityType,
        'entityId': entityId,
      },
    );
  }

  /// Creates a conflict exception for a deleted entity.
  factory ConflictException.entityDeleted(
    String entityType,
    String entityId,
  ) {
    return ConflictException(
      'Entity was deleted on server but modified locally',
      <String, dynamic>{
        'entityType': entityType,
        'entityId': entityId,
      },
    );
  }
}

/// Exception thrown when data validation fails.
///
/// This includes validation errors for entity fields, business rule
/// violations, and data integrity checks.
class ValidationException extends OfflineException {
  /// Creates a validation exception.
  const ValidationException(super.message, [super.context, this.field, this.value]);

  /// The field that failed validation.
  final String? field;

  /// The invalid value.
  final dynamic value;

  /// Creates a validation exception with field information.
  ValidationException.withField(
    String message,
    this.field,
    this.value, [
    Map<String, dynamic>? context,
  ]) : super(message, context);

  /// Creates a validation exception for a required field.
  factory ValidationException.requiredField(String field) {
    return ValidationException.withField(
      'Required field is missing',
      field,
      null,
      <String, dynamic>{'field': field},
    );
  }

  /// Creates a validation exception for an invalid value.
  factory ValidationException.invalidValue(
    String field,
    dynamic value,
    String reason,
  ) {
    return ValidationException.withField(
      'Invalid value for field $field: $reason',
      field,
      value,
      <String, dynamic>{
        'field': field,
        'value': value?.toString(),
        'reason': reason,
      },
    );
  }

  /// Creates a validation exception for a type mismatch.
  factory ValidationException.typeMismatch(
    String field,
    Type expected,
    Type actual,
  ) {
    return ValidationException.withField(
      'Type mismatch for field $field: expected $expected, got $actual',
      field,
      null,
      <String, dynamic>{
        'field': field,
        'expected': expected.toString(),
        'actual': actual.toString(),
      },
    );
  }
}

/// Exception thrown when a configuration error occurs.
///
/// This includes missing configuration, invalid settings, and
/// initialization errors.
class ConfigurationException extends OfflineException {
  /// Creates a configuration exception.
  const ConfigurationException(super.message, [super.context]);

  /// Creates a configuration exception for missing configuration.
  factory ConfigurationException.missingConfig(String key) {
    return ConfigurationException(
      'Required configuration is missing',
      <String, dynamic>{'key': key},
    );
  }

  /// Creates a configuration exception for invalid configuration.
  factory ConfigurationException.invalidConfig(
    String key,
    String reason,
  ) {
    return ConfigurationException(
      'Invalid configuration for $key: $reason',
      <String, dynamic>{
        'key': key,
        'reason': reason,
      },
    );
  }
}

/// Exception thrown when storage operations fail.
///
/// This includes disk full errors, permission errors, and file system issues.
class StorageException extends OfflineException {
  /// Creates a storage exception.
  const StorageException(super.message, [super.context]);

  /// Creates a storage exception for insufficient space.
  factory StorageException.insufficientSpace(int required, int available) {
    return StorageException(
      'Insufficient storage space',
      <String, dynamic>{
        'required': required,
        'available': available,
      },
    );
  }

  /// Creates a storage exception for permission denied.
  factory StorageException.permissionDenied(String path) {
    return StorageException(
      'Permission denied accessing storage',
      <String, dynamic>{'path': path},
    );
  }

  /// Creates a storage exception for a corrupted database.
  factory StorageException.corruptedDatabase(String path) {
    return StorageException(
      'Database file is corrupted',
      <String, dynamic>{'path': path},
    );
  }
}
