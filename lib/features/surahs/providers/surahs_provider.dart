import 'package:flutter_riverpod/flutter_riverpod.dart';

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
