import 'package:isar_community/isar.dart';

part 'sync_metadata.g.dart';

@collection
class SyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String entityType;

  DateTime? lastDownloadSync;

  DateTime? lastUploadSync;

  /// Moment of the last complete read of the entity. A delta sync only runs
  /// while this is recent, because purged rows never show up in a delta.
  DateTime? lastFullSync;

  /// Newest server change (updated or deleted moment) the delta sync has
  /// applied. The next delta read starts a safety overlap before it.
  DateTime? deltaCursor;

  @Index()
  bool syncPaused = false;

  int retryCount = 0;

  DateTime? nextRetryAt;

  String? lastError;

  bool credentialsValidated = false;

  bool credentialsInvalid = false;
}
