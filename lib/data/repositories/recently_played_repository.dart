import '../hive/hive_boxes.dart';

/// Tracks the last few opened (surah, ayah) pairs for quick access from the
/// Favorites tab. Stored as `"surahNumber:ayahNumberInSurah"` strings.
class RecentlyPlayedRepository {
  static const _maxEntries = 10;

  List<(int, int)> getAll() {
    return HiveBoxes.recent.values.map((entry) {
      final parts = entry.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    }).toList();
  }

  Future<void> add(int surahNumber, int ayahNumberInSurah) async {
    final entry = '$surahNumber:$ayahNumberInSurah';
    final current = HiveBoxes.recent.values.toList()..remove(entry);
    current.insert(0, entry);
    final trimmed = current.take(_maxEntries).toList();
    await HiveBoxes.recent.clear();
    await HiveBoxes.recent.putAll({for (var i = 0; i < trimmed.length; i++) i: trimmed[i]});
  }
}
