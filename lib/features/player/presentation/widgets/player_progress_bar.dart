import 'package:flutter/material.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';

class PlayerProgressBar extends StatelessWidget {
  const PlayerProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;
    final value = (position.inMilliseconds / total).clamp(0.0, 1.0);
    final remaining = duration - position;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            activeColor: SoftPalette.primary,
            inactiveColor: SoftPalette.track,
            onChanged: (v) => onSeek(Duration(milliseconds: (v * total).round())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(position.mmss, style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary)),
              Text(
                '-${remaining.isNegative ? Duration.zero.mmss : remaining.mmss}',
                style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
