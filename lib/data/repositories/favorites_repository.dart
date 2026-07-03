import '../hive/hive_boxes.dart';
import '../models/favorite_item.dart';

class FavoritesRepository {
  List<FavoriteItem> getAll() {
    final items = HiveBoxes.favorites.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  bool isFavoriteSurah(int surahNumber) =>
      HiveBoxes.favorites.containsKey('surah:$surahNumber');

  bool isFavoriteAyah(int surahNumber, int ayahNumberInSurah) =>
      HiveBoxes.favorites.containsKey('ayah:$surahNumber:$ayahNumberInSurah');

  Future<void> toggleSurah(int surahNumber) async {
    final key = 'surah:$surahNumber';
    if (HiveBoxes.favorites.containsKey(key)) {
      await HiveBoxes.favorites.delete(key);
    } else {
      await HiveBoxes.favorites.put(
        key,
        FavoriteItem(
          type: FavoriteType.surah,
          surahNumber: surahNumber,
          addedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> toggleAyah(int surahNumber, int ayahNumberInSurah) async {
    final key = 'ayah:$surahNumber:$ayahNumberInSurah';
    if (HiveBoxes.favorites.containsKey(key)) {
      await HiveBoxes.favorites.delete(key);
    } else {
      await HiveBoxes.favorites.put(
        key,
        FavoriteItem(
          type: FavoriteType.ayah,
          surahNumber: surahNumber,
          ayahNumberInSurah: ayahNumberInSurah,
          addedAt: DateTime.now(),
        ),
      );
    }
  }
}
