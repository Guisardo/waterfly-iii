import 'package:isar_community/isar.dart';

part 'attachments.g.dart';

@collection
class Attachments {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String attachmentId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
