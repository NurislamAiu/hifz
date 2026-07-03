import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/memorization_status.dart';
import '../../../data/providers.dart';
import '../../surahs/providers/surahs_provider.dart';

class ProgressController extends Notifier<Map<String, MemorizationStatus>> {
  @override
  Map<String, MemorizationStatus> build() {
    final repo = ref.read(progressRepositoryProvider);
    return {
      for (final p in repo.getAll())
        '${p.surahNumber}:${p.ayahNumberInSurah}': p.status,
    };
  }

  MemorizationStatus statusOf(int surahNumber, int ayahNumberInSurah) =>
      state['$surahNumber:$ayahNumberInSurah'] ?? MemorizationStatus.notStarted;

  Future<void> setStatus(
    int surahNumber,
    int ayahNumberInSurah,
    MemorizationStatus status,
  ) async {
    await ref
        .read(progressRepositoryProvider)
        .setStatus(surahNumber, ayahNumberInSurah, status);
    state = {...state, '$surahNumber:$ayahNumberInSurah': status};
  }

  /// Cycles: notStarted -> inProgress -> memorized -> notStarted.
  Future<void> cycleStatus(int surahNumber, int ayahNumberInSurah) {
    final current = statusOf(surahNumber, ayahNumberInSurah);
    final next = switch (current) {
      MemorizationStatus.notStarted => MemorizationStatus.inProgress,
      MemorizationStatus.inProgress => MemorizationStatus.memorized,
      MemorizationStatus.memorized => MemorizationStatus.notStarted,
    };
    return setStatus(surahNumber, ayahNumberInSurah, next);
  }
}

final progressControllerProvider =
    NotifierProvider<ProgressController, Map<String, MemorizationStatus>>(
      ProgressController.new,
    );

/// Overall memorized-ayah percentage across the entire Quran (6236 ayahs).
final overallProgressProvider = Provider<double>((ref) {
  final statuses = ref.watch(progressControllerProvider);
  const totalAyahs = 6236;
  final memorized = statuses.values
      .where((s) => s == MemorizationStatus.memorized)
      .length;
  return memorized / totalAyahs;
});

final surahProgressPercentProvider =
    Provider.family<double, (int surahNumber, int ayahCount)>((ref, args) {
      final (surahNumber, ayahCount) = args;
      if (ayahCount == 0) return 0;
      final statuses = ref.watch(progressControllerProvider);
      var memorized = 0;
      for (var i = 1; i <= ayahCount; i++) {
        if (statuses['$surahNumber:$i'] == MemorizationStatus.memorized) {
          memorized++;
        }
      }
      return memorized / ayahCount;
    });

/// Percentage memorized per juz (1..30), derived from cached ayah->juz mapping.
final juzProgressProvider = Provider<Map<int, double>>((ref) {
  final statuses = ref.watch(progressControllerProvider);
  // Depend on the Quran text being cached: this triggers the one-time download
  // and, crucially, recomputes the juz breakdown once the ayahs are available
  // (otherwise it would stay empty forever on first run).
  final cached = ref.watch(surahsProvider).hasValue;
  final quranRepo = ref.watch(quranRepositoryProvider);
  if (!cached || !quranRepo.isCached) return {};

  final totalsByJuz = <int, int>{};
  final memorizedByJuz = <int, int>{};
  for (final ayah in quranRepo.getAllAyahs()) {
    totalsByJuz[ayah.juz] = (totalsByJuz[ayah.juz] ?? 0) + 1;
    if (statuses['${ayah.surahNumber}:${ayah.numberInSurah}'] ==
        MemorizationStatus.memorized) {
      memorizedByJuz[ayah.juz] = (memorizedByJuz[ayah.juz] ?? 0) + 1;
    }
  }
  return {
    for (final juz in totalsByJuz.keys)
      juz: (memorizedByJuz[juz] ?? 0) / totalsByJuz[juz]!,
  };
});
