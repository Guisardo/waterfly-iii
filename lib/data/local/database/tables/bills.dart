import 'package:isar_community/isar.dart';

part 'bills.g.dart';

@collection
class Bills {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String billId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
