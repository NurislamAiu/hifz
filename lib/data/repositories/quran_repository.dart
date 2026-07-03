import '../api/quran_api_client.dart';
import '../hive/hive_boxes.dart';
import '../models/ayah.dart';
import '../models/surah.dart';

/// Fetches the Quran text once from Al Quran Cloud and serves it from the
/// local Hive cache afterwards. No network call happens if the cache is
/// already populated.
class QuranRepository {
  QuranRepository({QuranApiClient? apiClient})
    : _api = apiClient ?? QuranApiClient();

  final QuranApiClient _api;

  bool get isCached =>
      HiveBoxes.surahs.isNotEmpty && HiveBoxes.ayahs.isNotEmpty;

  List<Surah> getSurahs() {
    final surahs = HiveBoxes.surahs.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return surahs;
  }

  Surah getSurah(int number) => HiveBoxes.surahs.get(number)!;

  List<Ayah> getAllAyahs() => HiveBoxes.ayahs.values.toList();

  List<Ayah> getAyahsForSurah(int surahNumber) {
    final ayahs =
        HiveBoxes.ayahs.values
            .where((a) => a.surahNumber == surahNumber)
            .toList()
          ..sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah));
    return ayahs;
  }

  /// Downloads the surah list + full Arabic text + full transliteration and
  /// stores everything in Hive. Safe to call repeatedly — it's a no-op once
  /// [isCached] is true unless [force] is set.
  Future<void> ensureCached({bool force = false}) async {
    if (isCached && !force) return;

    final surahs = await _api.fetchSurahList();
    final arabicBySurah = await _api.fetchFullQuranArabic();
    final transliterationBySurah = await _api.fetchFullQuranTransliteration();

    final surahsMap = <int, Surah>{for (final s in surahs) s.number: s};
    await HiveBoxes.surahs.putAll(surahsMap);

    final ayahsMap = <int, Ayah>{};
    for (final entry in arabicBySurah.entries) {
      final surahNumber = entry.key;
      final transliterations = transliterationBySurah[surahNumber];
      for (final ayah in entry.value) {
        final withTransliteration =
            transliterations != null &&
                transliterations.length >= ayah.numberInSurah
            ? ayah.copyWithTransliteration(
                transliterations[ayah.numberInSurah - 1],
              )
            : ayah;
        ayahsMap[ayah.number] = withTransliteration;
      }
    }
    await HiveBoxes.ayahs.putAll(ayahsMap);
  }
}
