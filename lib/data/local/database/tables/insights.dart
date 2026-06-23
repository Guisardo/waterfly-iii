import 'package:isar_community/isar.dart';

part 'insights.g.dart';

@collection
class Insights {
  Id id = Isar.autoIncrement;

  @Index()
  late String insightType;

  @Index()
  late String insightSubtype;

  @Index()
  late DateTime startDate;

  @Index()
  late DateTime endDate;

  late String data;

  late DateTime cachedAt;

  @Index()
  bool stale = false;
}
