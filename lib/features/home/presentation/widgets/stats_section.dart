import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/providers.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../../core/theme/soft_palette.dart';

class StatsSection extends ConsumerStatefulWidget {
  const StatsSection({super.key});

  @override
  ConsumerState<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends ConsumerState<StatsSection> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final repo = ref.watch(listeningStatsRepositoryProvider);
    final settings = ref.watch(settingsControllerProvider);
    final listeningGoalMinutes = settings.listeningGoalMinutes;
    final listeningGoalSeconds = listeningGoalMinutes * 60;
    final todaySeconds = repo.todaySeconds;
    final progress = (todaySeconds / listeningGoalSeconds).clamp(0.0, 1.0);
    final weekMinutes = (repo.weekSeconds() / 60).round();
    final weekStatus = repo.weekStatus(goalSeconds: listeningGoalSeconds);
    final todayIndex = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.statistics,
              style: AppTextStyles.title.copyWith(color: SoftPalette.textDark),
            ),
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProgressScreen())),
              child: Text(
                s.details,
                style: const TextStyle(
                  color: SoftPalette.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                icon: Iconsax.flash_1,
                accent: const Color(0xFFF2A03D),
                value: s.daysShort(
                  repo.currentStreak(goalSeconds: listeningGoalSeconds),
                ),
                label: s.streak,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                icon: Iconsax.clock,
                accent: SoftPalette.primary,
                value: s.weekMinuteValue(weekMinutes),
                label: s.thisWeek,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                icon: Iconsax.medal_star,
                accent: const Color(0xFF8E7CF0),
                value: s.daysShort(
                  repo.recordStreak(goalSeconds: listeningGoalSeconds),
                ),
                label: s.record,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _GoalPill(
                icon: Iconsax.headphone,
                label: s.listen,
                value: s.durationMinutes(listeningGoalMinutes),
              ),
            ),
            const SizedBox(width: 10),
            _TuneButton(
              onPressed: () => _showGoalEditor(
                context,
                listeningGoalMinutes: listeningGoalMinutes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1BAAB6), Color(0xFF0B6771)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: SoftPalette.primary.withValues(alpha: 0.32),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  return SizedBox(
                    width: 190,
                    height: 190,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: animatedProgress,
                        trackColor: Colors.white.withValues(alpha: 0.16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.listeningToday,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatMmSs(todaySeconds),
                              style: AppTextStyles.displayTitle.copyWith(
                                fontSize: 42,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.goalMinutes(listeningGoalMinutes),
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _WeekDay(
                      label: s.weekLabels[i],
                      status: weekStatus[i],
                      isToday: i == todayIndex,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMmSs(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showGoalEditor(
    BuildContext context, {
    required int listeningGoalMinutes,
  }) async {
    var listening = listeningGoalMinutes;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoftPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.46,
              minChildSize: 0.35,
              maxChildSize: 0.80,
              builder: (context, scrollController) {
                return SafeArea(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.s.dailyGoals,
                              style: AppTextStyles.title.copyWith(
                                color: SoftPalette.textDark,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(
                              Iconsax.close_circle,
                              color: SoftPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: SoftPalette.light,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.headphone,
                              color: SoftPalette.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.s.listenPerDay,
                            style: AppTextStyles.body.copyWith(
                              color: SoftPalette.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _GoalWheel(
                        minutes: listening,
                        onChanged: (value) =>
                            setSheetState(() => listening = value),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: SoftPalette.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            final controller = ref.read(
                              settingsControllerProvider.notifier,
                            );
                            await controller.setDailyListeningGoalMinutes(
                              listening,
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: Text(context.s.save),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color accent;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: SoftPalette.softShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              color: SoftPalette.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: SoftPalette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPill extends StatelessWidget {
  const _GoalPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SoftPalette.softShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: SoftPalette.light,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: SoftPalette.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: SoftPalette.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    color: SoftPalette.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TuneButton extends StatelessWidget {
  const _TuneButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoftPalette.primary,
        shape: BoxShape.circle,
        boxShadow: SoftPalette.softShadow(opacity: 0.14),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Iconsax.setting_4, color: Colors.white),
        tooltip: context.s.editGoals,
      ),
    );
  }
}

/// Carousel (wheel) minute picker — scroll to pick the daily goal instead of
/// tapping +/-.
class _GoalWheel extends StatefulWidget {
  const _GoalWheel({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  State<_GoalWheel> createState() => _GoalWheelState();
}

class _GoalWheelState extends State<_GoalWheel> {
  static const _min = 1;
  static const _max = 180;

  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: (widget.minutes - _min).clamp(0, _max - _min),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const count = _max - _min + 1;
    const itemExtent = 46.0;

    return Container(
      decoration: BoxDecoration(
        color: SoftPalette.background,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fixed highlight band marking the selected row in the centre.
            Container(
              height: itemExtent,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: SoftPalette.light,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: itemExtent,
              perspective: 0.006,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (i) => widget.onChanged(i + _min),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: count,
                builder: (context, i) {
                  final value = i + _min;
                  final selected = value == widget.minutes;
                  return Center(
                    child: Text(
                      context.s.durationMinutes(value),
                      style: AppTextStyles.title.copyWith(
                        fontSize: selected ? 21 : 17,
                        color: selected
                            ? SoftPalette.primary
                            : SoftPalette.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
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

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.label,
    required this.status,
    required this.isToday,
  });

  final String label;
  final bool? status;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final done = status == true;

    final Widget dot;
    if (done) {
      dot = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 18,
          color: SoftPalette.primaryDark,
        ),
      );
    } else {
      dot = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: isToday ? 0.0 : 0.10),
          border: Border.all(
            color: Colors.white.withValues(alpha: isToday ? 0.95 : 0.35),
            width: isToday ? 2 : 1,
          ),
        ),
      );
    }

    return Column(
      children: [
        dot,
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withValues(
              alpha: isToday || done ? 0.95 : 0.6,
            ),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Rounded progress ring with a bright sweep gradient over a faint track, so
/// the "listened today" figure reads as a glowing arc on the teal hero card.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({required this.progress, required this.trackColor});

  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return;

    const start = -pi / 2;
    final sweep = 2 * pi * clamped;
    final shader = const SweepGradient(
      startAngle: 0,
      endAngle: 2 * pi,
      colors: [Color(0xFF9BF1F6), Colors.white],
      transform: GradientRotation(start),
    ).createShader(rect);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader;
    canvas.drawArc(rect, start, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.trackColor != trackColor;
}
