import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/providers.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../../core/theme/soft_palette.dart';

class ContinueListeningCard extends ConsumerWidget {
  const ContinueListeningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranRepo = ref.watch(quranRepositoryProvider);
    final recent = ref.watch(recentlyPlayedRepositoryProvider).getAll();
    final reciter = ref.watch(selectedReciterProvider);

    if (recent.isEmpty || !quranRepo.isCached) return const SizedBox.shrink();

    final (surahNumber, ayahNumber) = recent.first;
    final surah = quranRepo.getSurah(surahNumber);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: SoftPalette.softShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: SoftPalette.light, shape: BoxShape.circle),
            child: const Icon(FlutterIslamicIcons.quran, color: SoftPalette.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Продолжить',
                  style: AppTextStyles.overline.copyWith(color: SoftPalette.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  surah.nameTransliteration,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: SoftPalette.textDark,
                  ),
                ),
                Text(
                  '${reciter.name} · Аят $ayahNumber',
                  style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => PlayerScreen.open(context, surahNumber: surahNumber, startAyah: ayahNumber),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SoftPalette.primary,
                shape: BoxShape.circle,
                boxShadow: SoftPalette.softShadow(opacity: 0.16),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}
