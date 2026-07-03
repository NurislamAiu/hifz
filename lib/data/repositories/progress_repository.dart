import '../hive/hive_boxes.dart';
import '../models/ayah_progress.dart';
import '../models/memorization_status.dart';

/// Persists memorization status per ayah. Aggregation (per-surah, per-juz,
/// overall percentage) is computed on top of this by the progress feature,
/// since it also needs Quran structure data from [QuranRepository].
class ProgressRepository {
  MemorizationStatus getStatus(int surahNumber, int ayahNumberInSurah) {
    final entry = HiveBoxes.progress.get('$surahNumber:$ayahNumberInSurah');
    return entry?.status ?? MemorizationStatus.notStarted;
  }

  Future<void> setStatus(
    int surahNumber,
    int ayahNumberInSurah,
    MemorizationStatus status,
  ) async {
    final key = '$surahNumber:$ayahNumberInSurah';
    await HiveBoxes.progress.put(
      key,
      AyahProgress(
        surahNumber: surahNumber,
        ayahNumberInSurah: ayahNumberInSurah,
        status: status,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// All progress entries for a given surah, keyed by ayah number in surah.
  Map<int, MemorizationStatus> getSurahStatuses(int surahNumber) {
    final result = <int, MemorizationStatus>{};
    for (final entry in HiveBoxes.progress.values) {
      if (entry.surahNumber == surahNumber) {
        result[entry.ayahNumberInSurah] = entry.status;
      }
    }
    return result;
  }

  List<AyahProgress> getAll() => HiveBoxes.progress.values.toList();
}
