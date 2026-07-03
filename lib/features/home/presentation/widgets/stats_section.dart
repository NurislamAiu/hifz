import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  static const _weekLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
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
            Text('Статистика', style: AppTextStyles.title.copyWith(color: SoftPalette.textDark)),
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProgressScreen())),
              child: const Text(
                'Подробнее',
                style: TextStyle(color: SoftPalette.primary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                value: '${repo.currentStreak(goalSeconds: listeningGoalSeconds)} дн',
                label: 'Стрик',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(value: '$weekMinutes мин', label: 'Эта неделя'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                value: '${repo.recordStreak(goalSeconds: listeningGoalSeconds)} дн',
                label: 'Рекорд',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _GoalPill(
                icon: Icons.headphones_rounded,
                label: 'Слушать',
                value: '$listeningGoalMinutes мин',
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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: SoftPalette.light,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  return SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: animatedProgress,
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation(SoftPalette.primary),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Слушание сегодня',
                              style: AppTextStyles.caption.copyWith(color: SoftPalette.primaryDark),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatMmSs(todaySeconds),
                              style: AppTextStyles.displayTitle.copyWith(
                                fontSize: 32,
                                color: SoftPalette.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'цель $listeningGoalMinutes мин',
                              style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _WeekDay(
                      label: _weekLabels[i],
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
                              'Цели на день',
                              style: AppTextStyles.title.copyWith(color: SoftPalette.textDark),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded, color: SoftPalette.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _GoalStepper(
                        icon: Icons.headphones_rounded,
                        label: 'Слушать',
                        minutes: listening,
                        onChanged: (value) => setSheetState(() => listening = value),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: SoftPalette.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () async {
                            final controller = ref.read(settingsControllerProvider.notifier);
                            await controller.setDailyListeningGoalMinutes(listening);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: const Text('Сохранить'),
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
  const _StatChip({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: SoftPalette.softShadow(),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.title.copyWith(fontSize: 17, color: SoftPalette.primary),
          ),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary)),
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
            decoration: const BoxDecoration(color: SoftPalette.light, shape: BoxShape.circle),
            child: Icon(icon, color: SoftPalette.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary, fontSize: 11)),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(color: SoftPalette.textDark, fontWeight: FontWeight.w700, fontSize: 13),
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
        icon: const Icon(Icons.tune_rounded, color: Colors.white),
        tooltip: 'Изменить цели',
      ),
    );
  }
}

class _GoalStepper extends StatelessWidget {
  const _GoalStepper({
    required this.icon,
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    void change(int delta) => onChanged((minutes + delta).clamp(1, 180));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SoftPalette.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: SoftPalette.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: AppTextStyles.body.copyWith(color: SoftPalette.textDark)),
          ),
          IconButton(
            onPressed: () => change(-5),
            icon: const Icon(Icons.remove_rounded, color: SoftPalette.primary),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$minutes мин',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: SoftPalette.textDark),
            ),
          ),
          IconButton(
            onPressed: () => change(5),
            icon: const Icon(Icons.add_rounded, color: SoftPalette.primary),
          ),
        ],
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

    final dot = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? SoftPalette.primary : Colors.white,
        border: Border.all(
          color: done ? SoftPalette.primary : (isToday ? SoftPalette.primary : SoftPalette.track),
          width: isToday && !done ? 2 : 1,
        ),
      ),
    );

    return Column(
      children: [
        dot,
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isToday ? SoftPalette.textDark : SoftPalette.textSecondary,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
