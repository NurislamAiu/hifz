import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../../data/models/ayah.dart';
import '../../../../data/models/display_mode.dart';
import '../../../../data/models/favorite_item.dart';
import '../../../../data/models/memorization_status.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../progress/providers/progress_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/ayahs_provider.dart';
import '../../providers/surahs_provider.dart';

class SurahDetailScreen extends ConsumerWidget {
  const SurahDetailScreen({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);
    final ayahsAsync = ref.watch(ayahsForSurahProvider(surahNumber));
    final displayMode = ref.watch(settingsControllerProvider).displayMode;

    final surah = surahsAsync.value?.firstWhere((s) => s.number == surahNumber);
    final isFavoriteSurah = ref.watch(
      favoritesControllerProvider.select(
        (list) => list.any(
          (f) => f.type == FavoriteType.surah && f.surahNumber == surahNumber,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: SoftPalette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SoftPalette.surface,
                        shape: BoxShape.circle,
                        boxShadow: SoftPalette.softShadow(
                          opacity: 0.05,
                          y: 4,
                          blur: 10,
                        ),
                      ),
                      child: const Icon(
                        Iconsax.arrow_left_2,
                        size: 16,
                        color: SoftPalette.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah?.nameTransliteration ?? '',
                          style: AppTextStyles.title.copyWith(
                            color: SoftPalette.textDark,
                          ),
                        ),
                        if (surah != null)
                          Text(
                            context.s.ayahCount(surah.numberOfAyahs),
                            style: AppTextStyles.caption.copyWith(
                              color: SoftPalette.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref
                        .read(favoritesControllerProvider.notifier)
                        .toggleSurah(surahNumber),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SoftPalette.surface,
                        shape: BoxShape.circle,
                        boxShadow: SoftPalette.softShadow(
                          opacity: 0.05,
                          y: 4,
                          blur: 10,
                        ),
                      ),
                      child: Icon(
                        isFavoriteSurah ? Iconsax.star1 : Iconsax.star,
                        color: isFavoriteSurah
                            ? const Color(0xFFE0A83F)
                            : SoftPalette.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => PlayerScreen.open(
                      context,
                      surahNumber: surahNumber,
                      startAyah: 1,
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SoftPalette.primary,
                        shape: BoxShape.circle,
                        boxShadow: SoftPalette.softShadow(
                          opacity: 0.16,
                          y: 6,
                          blur: 14,
                        ),
                      ),
                      child: const Icon(
                        Iconsax.play,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ayahsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: SoftPalette.primary),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '$e',
                    style: AppTextStyles.caption.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                ),
                data: (ayahs) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: ayahs.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: SoftPalette.track),
                  itemBuilder: (context, i) =>
                      _AyahTile(ayah: ayahs[i], displayMode: displayMode),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahTile extends ConsumerWidget {
  const _AyahTile({required this.ayah, required this.displayMode});

  final Ayah ayah;
  final DisplayMode displayMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      progressControllerProvider.select(
        (s) =>
            s['${ayah.surahNumber}:${ayah.numberInSurah}'] ??
            MemorizationStatus.notStarted,
      ),
    );
    final isFavorite = ref.watch(
      favoritesControllerProvider.select(
        (list) => list.any(
          (f) =>
              f.type == FavoriteType.ayah &&
              f.surahNumber == ayah.surahNumber &&
              f.ayahNumberInSurah == ayah.numberInSurah,
        ),
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => PlayerScreen.open(
        context,
        surahNumber: ayah.surahNumber,
        startAyah: ayah.numberInSurah,
      ),
      onLongPress: () => ref
          .read(progressControllerProvider.notifier)
          .cycleStatus(ayah.surahNumber, ayah.numberInSurah),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusDot(status: status),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayMode != DisplayMode.transliteration)
                    Text(
                      '${ayah.textArabic} ﴿${ayah.numberInSurah}﴾',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.arabic.copyWith(
                        color: SoftPalette.textDark,
                      ),
                    ),
                  if (displayMode == DisplayMode.both)
                    const SizedBox(height: 6),
                  if (displayMode != DisplayMode.arabic &&
                      ayah.textTransliteration != null)
                    Text(
                      ayah.textTransliteration!,
                      style: AppTextStyles.transliteration.copyWith(
                        color: SoftPalette.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => ref
                  .read(favoritesControllerProvider.notifier)
                  .toggleAyah(ayah.surahNumber, ayah.numberInSurah),
              icon: Icon(
                isFavorite ? Iconsax.star1 : Iconsax.star,
                color: isFavorite
                    ? const Color(0xFFE0A83F)
                    : SoftPalette.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final MemorizationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MemorizationStatus.notStarted => SoftPalette.track,
      MemorizationStatus.inProgress => const Color(0xFFE0A83F),
      MemorizationStatus.memorized => SoftPalette.primary,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
