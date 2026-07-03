import 'package:hive/hive.dart';

part 'favorite_item.g.dart';

@HiveType(typeId: 5)
enum FavoriteType {
  @HiveField(0)
  surah,
  @HiveField(1)
  ayah,
}

@HiveType(typeId: 6)
class FavoriteItem {
  @HiveField(0)
  final FavoriteType type;

  @HiveField(1)
  final int surahNumber;

  /// Null when [type] is [FavoriteType.surah].
  @HiveField(2)
  final int? ayahNumberInSurah;

  @HiveField(3)
  final DateTime addedAt;

  const FavoriteItem({
    required this.type,
    required this.surahNumber,
    this.ayahNumberInSurah,
    required this.addedAt,
  });

  String get key => type == FavoriteType.surah
      ? 'surah:$surahNumber'
      : 'ayah:$surahNumber:$ayahNumberInSurah';
}
