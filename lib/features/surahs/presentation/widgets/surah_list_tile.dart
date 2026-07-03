import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../../data/models/surah.dart';

/// The API's Arabic name comes prefixed with the word "Surah" (سورة)
/// plus tashkeel marks — strip it so the list shows just the surah name,
/// e.g. "الفاتحة" not "سُورَةُ الْفَاتِحَة".
final _tashkeel = RegExp('[ً-ْٰ]');
const _surahWord = 'سورة';

String _shortArabicName(String full) {
  final parts = full.trim().split(RegExp(r'\s+'));
  if (parts.length > 1 && parts.first.replaceAll(_tashkeel, '') == _surahWord) {
    return parts.sublist(1).join(' ');
  }
  return full;
}

class SurahListTile extends StatelessWidget {
  const SurahListTile({
    super.key,
    required this.surah,
    required this.isDownloaded,
    required this.onTap,
  });

  final Surah surah;
  final bool isDownloaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Row(
          children: [
            _NumberSeal(number: surah.number, isDownloaded: isDownloaded),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameTransliteration,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: SoftPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(surah.revelationType == 'Meccan' ? 'МЕККАНСКАЯ' : 'МЕДИНСКАЯ')} • ${surah.numberOfAyahs} АЯТОВ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: SoftPalette.textSecondary,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: Text(
                _shortArabicName(surah.nameArabic),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.arabic.copyWith(
                  fontSize: 19,
                  height: 1,
                  color: SoftPalette.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An 8-point "seal" badge (Rub el Hizb style) — built from two overlapping
/// squares rotated 45° apart, which is the classic way to draw this shape
/// without needing a custom path/painter.
class _NumberSeal extends StatelessWidget {
  const _NumberSeal({required this.number, required this.isDownloaded});
  final int number;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    Widget square(double angle) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: SoftPalette.surface,
            border: Border.all(color: SoftPalette.primary, width: 1.4),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          square(0),
          square(0.785398),
          Text(
            '$number',
            style: AppTextStyles.body.copyWith(
              color: SoftPalette.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          if (isDownloaded)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 15,
                height: 15,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SoftPalette.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: SoftPalette.surface, width: 1.5),
                ),
                child: const Icon(Iconsax.tick_circle, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
