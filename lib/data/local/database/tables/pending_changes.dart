import 'package:isar_community/isar.dart';

part 'pending_changes.g.dart';

/// Type-safe operation identifiers for pending sync changes.
/// Use `.name` when storing to the `operation` String field.
enum PendingChangeOperation { create, update, delete }

@collection
class PendingChanges {
  Id id = Isar.autoIncrement;

  @Index()
  late String entityType;

  String? entityId;

  @Index()
  late String operation; // CREATE, UPDATE, DELETE

  String? data;

  @Index()
  late DateTime createdAt;

  int retryCount = 0;

  String? lastError;

  @Index()
  bool synced = false;

  /// The local pending-* ID of the entity row created for this change.
  /// Set for CREATE operations so upload_service can find and remove the
  /// placeholder row without fuzzy matching.
  String? localPendingId;
}
