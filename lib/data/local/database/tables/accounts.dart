import 'package:isar_community/isar.dart';

part 'accounts.g.dart';

@collection
class Accounts {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String accountId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
