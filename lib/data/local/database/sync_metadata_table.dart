import 'package:drift/drift.dart';

/// Sync metadata table for storing synchronization state and configuration.
///
/// Stores key-value pairs for tracking sync timestamps, versions, and other metadata.
@DataClassName('SyncMetadataEntity')
class SyncMetadata extends Table {
  /// Metadata key (e.g., 'last_full_sync', 'last_partial_sync', 'sync_version').
  TextColumn get key => text()();

  /// Metadata value (stored as string, parse as needed).
  TextColumn get value => text()();

  /// Timestamp when the metadata was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{key};
}
