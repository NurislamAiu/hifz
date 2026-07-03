import 'package:hive/hive.dart';

part 'display_mode.g.dart';

@HiveType(typeId: 7)
enum DisplayMode {
  @HiveField(0)
  arabic,
  @HiveField(1)
  transliteration,
  @HiveField(2)
  both,
  @HiveField(3)
  none,
}
