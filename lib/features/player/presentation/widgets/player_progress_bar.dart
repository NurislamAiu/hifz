import 'package:flutter/material.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';

class PlayerProgressBar extends StatefulWidget {
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
  State<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<PlayerProgressBar> {
  // While the user is dragging the thumb we drive the slider from this local
  // value instead of the streamed position. Otherwise the position stream keeps
  // emitting the *old* playback position under the finger, so the thumb fights
  // the drag and snaps back — the lag felt when scrubbing backward.
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final duration = widget.duration;
    final hasDuration = duration > Duration.zero;
    final clampedPosition = hasDuration && widget.position > duration
        ? duration
        : widget.position;
    final total = hasDuration ? duration.inMilliseconds : 1;
    final streamValue = hasDuration
        ? (clampedPosition.inMilliseconds / total).clamp(0.0, 1.0)
        : 0.0;
    final value = _dragValue ?? streamValue;

    // Labels track the thumb during a drag so the elapsed/remaining times move
    // with the finger rather than lagging behind on the real position.
    final shownPosition = _dragValue != null
        ? Duration(milliseconds: (value * total).round())
        : clampedPosition;
    final remaining = hasDuration ? duration - shownPosition : Duration.zero;

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
            onChangeStart: hasDuration
                ? (v) => setState(() => _dragValue = v)
                : null,
            onChanged: hasDuration
                ? (v) => setState(() => _dragValue = v)
                : null,
            onChangeEnd: hasDuration
                ? (v) {
                    widget.onSeek(Duration(milliseconds: (v * total).round()));
                    setState(() => _dragValue = null);
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shownPosition.mmss,
                style: AppTextStyles.caption.copyWith(
                  color: SoftPalette.textSecondary,
                ),
              ),
              Text(
                hasDuration ? '-${remaining.mmss}' : Duration.zero.mmss,
                style: AppTextStyles.caption.copyWith(
                  color: SoftPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
