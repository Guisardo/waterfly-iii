import 'package:isar_community/isar.dart';

part 'transactions.g.dart';

@collection
class Transactions {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String transactionId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
