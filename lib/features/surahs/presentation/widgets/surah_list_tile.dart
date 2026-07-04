import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/localization/app_strings.dart';
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
    required this.onDownload,
    this.downloadProgress,
  });

  final Surah surah;
  final bool isDownloaded;
  final VoidCallback onTap;

  /// Starts downloading the surah. Only invoked from the idle (not-downloaded)
  /// state of the trailing control.
  final VoidCallback onDownload;

  /// Non-null while the surah is downloading — the fraction 0..1 completed.
  final double? downloadProgress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            _NumberSeal(number: surah.number),
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
                    context.s.surahMeta(
                      surah.revelationType,
                      surah.numberOfAyahs,
                    ),
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
            const SizedBox(width: 10),
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
            const SizedBox(width: 4),
            _DownloadControl(
              isDownloaded: isDownloaded,
              downloadProgress: downloadProgress,
              onDownload: onDownload,
            ),
          ],
        ),
      ),
    );
  }
}

/// Trailing download status/action for a surah. A full 44×44 tap target so it
/// never fights the row's tap or clips outside its bounds.
///
/// - downloading → progress ring (not tappable)
/// - downloaded  → green tick (not tappable)
/// - idle        → tappable download button
class _DownloadControl extends StatelessWidget {
  const _DownloadControl({
    required this.isDownloaded,
    required this.onDownload,
    this.downloadProgress,
  });

  final bool isDownloaded;
  final VoidCallback onDownload;
  final double? downloadProgress;

  @override
  Widget build(BuildContext context) {
    if (downloadProgress != null) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: downloadProgress == 0 ? null : downloadProgress,
              strokeWidth: 2.4,
              backgroundColor: SoftPalette.track,
              color: SoftPalette.primary,
            ),
          ),
        ),
      );
    }

    if (isDownloaded) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Icon(Iconsax.tick_circle, size: 22, color: SoftPalette.primary),
      );
    }

    return IconButton(
      onPressed: onDownload,
      visualDensity: VisualDensity.compact,
      splashRadius: 22,
      tooltip: 'Скачать',
      icon: Icon(
        Iconsax.import_1,
        size: 22,
        color: SoftPalette.textSecondary,
      ),
    );
  }
}

/// An 8-point "seal" badge (Rub el Hizb style) — built from two overlapping
/// squares rotated 45° apart, which is the classic way to draw this shape
/// without needing a custom path/painter.
class _NumberSeal extends StatelessWidget {
  const _NumberSeal({required this.number});
  final int number;

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
        ],
      ),
    );
  }
}
