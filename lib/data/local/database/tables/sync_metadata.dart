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

  /// Checkpoint of a full read of the transactions that did not finish, so the
  /// next sync continues instead of starting over. All fields are cleared when
  /// the full read completes.
  int? fullReadNextPage;

  DateTime? fullReadStartedAt;

  /// Newest server change seen so far; becomes the delta cursor.
  DateTime? fullReadNewest;

  /// Oldest change skipped so far because a local edit is waiting to upload.
  DateTime? fullReadHeldAt;

  /// A skipped change without a moment: the cursor must not move at all.
  bool fullReadBlocked = false;

  /// Ids read so far, needed to find rows purged on the server at the end.
  List<String>? fullReadSeenIds;

  @Index()
  bool syncPaused = false;

  int retryCount = 0;

  DateTime? nextRetryAt;

  String? lastError;

  bool credentialsValidated = false;

  bool credentialsInvalid = false;
}
