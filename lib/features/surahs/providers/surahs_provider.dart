import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ayah.dart';
import '../../../data/models/surah.dart';
import '../../../data/providers.dart';

/// Fetches (once) and caches the full Quran text, then exposes the surah list.
final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final repo = ref.watch(quranRepositoryProvider);
  await repo.ensureCached();
  return repo.getSurahs();
});

final surahSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredSurahsProvider = Provider<AsyncValue<List<Surah>>>((ref) {
  final query = ref.watch(surahSearchQueryProvider).trim().toLowerCase();
  final surahsAsync = ref.watch(surahsProvider);
  return surahsAsync.whenData((surahs) {
    if (query.isEmpty) return surahs;
    return surahs
        .where(
          (s) =>
              s.nameTransliteration.toLowerCase().contains(query) ||
              s.nameTranslationEn.toLowerCase().contains(query) ||
              s.nameArabic.contains(query) ||
              s.number.toString() == query,
        )
        .toList();
  });
});

/// One of the 30 juz, resolved to the exact surah/ayah where it begins so the
/// player can jump straight there.
class JuzEntry {
  const JuzEntry({
    required this.juz,
    required this.startSurahNumber,
    required this.startSurahName,
    required this.startAyahInSurah,
    required this.surahCount,
  });

  final int juz;
  final int startSurahNumber;
  final String startSurahName;
  final int startAyahInSurah;

  /// How many distinct surahs this juz spans.
  final int surahCount;
}

/// Builds the 1..30 juz index from the cached ayah→juz mapping — each entry
/// points at the first ayah of that juz.
final juzEntriesProvider = FutureProvider<List<JuzEntry>>((ref) async {
  final repo = ref.watch(quranRepositoryProvider);
  await repo.ensureCached();

  final firstByJuz = <int, Ayah>{};
  final surahsByJuz = <int, Set<int>>{};
  for (final ayah in repo.getAllAyahs()) {
    (surahsByJuz[ayah.juz] ??= <int>{}).add(ayah.surahNumber);
    final existing = firstByJuz[ayah.juz];
    if (existing == null || ayah.number < existing.number) {
      firstByJuz[ayah.juz] = ayah;
    }
  }

  final juzNumbers = firstByJuz.keys.toList()..sort();
  return [
    for (final juz in juzNumbers)
      JuzEntry(
        juz: juz,
        startSurahNumber: firstByJuz[juz]!.surahNumber,
        startSurahName: repo
            .getSurah(firstByJuz[juz]!.surahNumber)
            .nameTransliteration,
        startAyahInSurah: firstByJuz[juz]!.numberInSurah,
        surahCount: surahsByJuz[juz]!.length,
      ),
  ];
});
