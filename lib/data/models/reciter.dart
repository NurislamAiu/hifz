import 'package:hive/hive.dart';

part 'reciter.g.dart';

@HiveType(typeId: 2)
class Reciter {
  @HiveField(0)
  final String id;

  /// Folder name on EveryAyah.com, e.g. "Alafasy_128kbps".
  @HiveField(1)
  final String folder;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String nameArabic;

  const Reciter({
    required this.id,
    required this.folder,
    required this.name,
    required this.nameArabic,
  });
}
