import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../providers/player_provider.dart';

class AyahListSheet extends ConsumerWidget {
  const AyahListSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SoftPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => const AyahListSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    if (playerState == null) return const SizedBox.shrink();

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: SoftPalette.track, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    playerState.surahNameTransliteration,
                    style: AppTextStyles.title.copyWith(color: SoftPalette.textDark),
                  ),
                  const Spacer(),
                  Text(
                    '${playerState.ayahs.length} аятов',
                    style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: SoftPalette.track),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: playerState.ayahs.length,
                itemBuilder: (context, i) {
                  final ayah = playerState.ayahs[i];
                  final isCurrent = i == playerState.currentIndex;
                  return ListTile(
                    onTap: () {
                      ref.read(playerControllerProvider.notifier).jumpToAyah(ayah.numberInSurah);
                      Navigator.of(context).pop();
                    },
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: isCurrent ? SoftPalette.primary : SoftPalette.light,
                      child: Text(
                        '${ayah.numberInSurah}',
                        style: AppTextStyles.caption.copyWith(
                          color: isCurrent ? Colors.white : SoftPalette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      ayah.textArabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontFamily: AppTextStyles.arabicFontFamily,
                        color: isCurrent ? SoftPalette.primary : SoftPalette.textDark,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.equalizer_rounded, color: SoftPalette.primary, size: 18)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
