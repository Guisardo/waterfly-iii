import 'package:isar_community/isar.dart';

part 'budgets.g.dart';

@collection
class Budgets {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String budgetId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
