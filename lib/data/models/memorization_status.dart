import 'package:hive/hive.dart';

part 'memorization_status.g.dart';

@HiveType(typeId: 3)
enum MemorizationStatus {
  @HiveField(0)
  notStarted,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  memorized,
}
