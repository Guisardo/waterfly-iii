import 'package:drift/drift.dart';

/// Error log table for storing sync errors for analytics and debugging.
@DataClassName('ErrorLogEntity')
class ErrorLog extends Table {
  /// Unique identifier for the error log entry.
  TextColumn get id => text()();

  /// Error type: 'validation', 'network', 'conflict', 'server', 'database'.
  TextColumn get errorType => text()();

  /// Entity type: 'transaction', 'account', 'category', 'budget', 'bill', 'piggy_bank'.
  TextColumn get entityType => text().nullable()();

  /// Entity ID (local or server ID).
  TextColumn get entityId => text().nullable()();

  /// Operation type: 'CREATE', 'UPDATE', 'DELETE'.
  TextColumn get operationType => text().nullable()();

  /// Error message.
  TextColumn get errorMessage => text()();

  /// Validation field that failed (for validation errors).
  TextColumn get validationField => text().nullable()();

  /// Validation rule that failed (for validation errors).
  TextColumn get validationRule => text().nullable()();

  /// HTTP status code (for network/server errors).
  IntColumn get statusCode => integer().nullable()();

  /// Full error details as JSON.
  TextColumn get errorDetails => text().nullable()();

  /// Stack trace for debugging.
  TextColumn get stackTrace => text().nullable()();

  /// Timestamp when the error occurred.
  DateTimeColumn get occurredAt => dateTime()();

  /// Whether the error was resolved.
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

  /// Timestamp when the error was resolved.
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
        'CHECK (error_type IN (\'validation\', \'network\', \'conflict\', \'server\', \'database\'))',
      ];
}
