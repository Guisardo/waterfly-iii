import 'package:isar_community/isar.dart';

part 'pending_changes.g.dart';

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
}
