import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ayah.dart';
import '../../../data/providers.dart';

/// Ayahs of a single surah, in order. Assumes the Quran text is already
/// cached (surahs screen triggers that on app start).
final ayahsForSurahProvider = FutureProvider.family<List<Ayah>, int>((
  ref,
  surahNumber,
) async {
  final repo = ref.watch(quranRepositoryProvider);
  await repo.ensureCached();
  return repo.getAyahsForSurah(surahNumber);
});
