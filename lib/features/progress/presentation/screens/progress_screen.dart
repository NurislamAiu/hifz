import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../../data/providers.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../surahs/providers/surahs_provider.dart';
import '../../providers/progress_provider.dart';

enum _ProgressTab { surahs, juz }

final _progressTabProvider = StateProvider<_ProgressTab>(
  (ref) => _ProgressTab.surahs,
);

final _statsSearchQueryProvider = StateProvider<String>((ref) => '');

const _heatmapDays = 91;

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, this.embedded = false});

  /// True when used as a bottom-nav tab (no own Scaffold/back button,
  /// since [RootShell] already provides the shared chrome). False when
  /// pushed as a standalone screen via the "Подробнее" link.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overall = ref.watch(overallProgressProvider);
    final tab = ref.watch(_progressTabProvider);
    final surahsAsync = ref.watch(surahsProvider);
    final juzProgress = ref.watch(juzProgressProvider);

    final statsRepo = ref.watch(listeningStatsRepositoryProvider);
    final goalMinutes = ref.watch(
      settingsControllerProvider.select((s) => s.listeningGoalMinutes),
    );
    final goalSeconds = goalMinutes * 60;
    final streak = statsRepo.currentStreak(goalSeconds: goalSeconds);
    final record = statsRepo.recordStreak(goalSeconds: goalSeconds);
    final totalDays = statsRepo.totalDaysListened;
    final heatmapDays = statsRepo.recentDays(_heatmapDays);

    final header = SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(embedded ? 20 : 8, 4, 20, 4),
        child: Row(
          children: [
            if (!embedded) ...[
              _BackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 8),
            ],
            Text(
              'Статистика',
              style: AppTextStyles.displayTitle.copyWith(color: SoftPalette.textDark),
            ),
          ],
        ),
      ),
    );

    final statsRow = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: _StatChip(
                icon: Icons.local_fire_department_rounded,
                value: '$streak дн',
                label: 'Стрик',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                icon: Icons.emoji_events_rounded,
                value: '$record дн',
                label: 'Рекорд',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                icon: FlutterIslamicIcons.calendar,
                value: '$totalDays',
                label: 'Дней всего',
              ),
            ),
          ],
        ),
      ),
    );

    final heatmap = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: _YearHeatmap(days: heatmapDays, goalSeconds: goalSeconds),
      ),
    );

    final overallCard = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: _OverallProgressCard(percent: overall),
      ),
    );

    final tabSwitcher = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: _TabSwitcher(
          current: tab,
          onChanged: (t) => ref.read(_progressTabProvider.notifier).state = t,
        ),
      ),
    );

    final searchField = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: _SearchField(
          hint: tab == _ProgressTab.surahs ? 'Поиск суры' : 'Поиск джуза',
          onChanged: (v) => ref.read(_statsSearchQueryProvider.notifier).state = v,
        ),
      ),
    );

    final query = ref.watch(_statsSearchQueryProvider).trim().toLowerCase();

    final list = tab == _ProgressTab.surahs
        ? surahsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: SoftPalette.primary),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  '$e',
                  style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                ),
              ),
            ),
            data: (surahs) {
              final filtered = query.isEmpty
                  ? surahs
                  : surahs
                      .where((s) =>
                          s.nameTransliteration.toLowerCase().contains(query) ||
                          s.nameArabic.contains(query) ||
                          s.number.toString() == query)
                      .toList();
              if (filtered.isEmpty) return const _EmptySearchResult();
              return _ProgressSliverList(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final surah = filtered[i];
                  final percent = ref.watch(
                    surahProgressPercentProvider((surah.number, surah.numberOfAyahs)),
                  );
                  return _ProgressRow(
                    title: '${surah.number}. ${surah.nameTransliteration}',
                    subtitle: '${surah.numberOfAyahs} аятов',
                    percent: percent,
                  );
                },
              );
            },
          )
        : _buildJuzList(query: query, juzProgress: juzProgress);

    final content = SafeArea(
      child: CustomScrollView(
        slivers: [
          header,
          statsRow,
          heatmap,
          overallCard,
          tabSwitcher,
          searchField,
          list,
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );

    final page = Container(
      width: double.infinity,
      height: double.infinity,
      color: SoftPalette.background,
      child: content,
    );

    if (embedded) return page;

    return Scaffold(backgroundColor: SoftPalette.background, body: page);
  }
}

Widget _buildJuzList({required String query, required Map<int, double> juzProgress}) {
  final allJuz = List.generate(30, (i) => i + 1);
  final filtered = query.isEmpty
      ? allJuz
      : allJuz.where((juz) => 'джуз $juz'.contains(query) || juz.toString() == query).toList();
  if (filtered.isEmpty) return const _EmptySearchResult();
  return _ProgressSliverList(
    itemCount: filtered.length,
    itemBuilder: (context, i) {
      final juz = filtered[i];
      final percent = juzProgress[juz] ?? 0;
      return _ProgressRow(title: 'Джуз $juz', subtitle: null, percent: percent);
    },
  );
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Ничего не найдено',
            style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: SoftPalette.softShadow(opacity: 0.05, y: 4, blur: 12),
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body.copyWith(color: SoftPalette.textDark),
        cursorColor: SoftPalette.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
          prefixIcon: const Icon(Icons.search, color: SoftPalette.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// Lazily-built sliver list with a thin divider between rows — behaves like
/// `ListView.separated` but lives inside the outer [CustomScrollView] so the
/// whole screen (header + heatmap + list) scrolls as one.
class _ProgressSliverList extends StatelessWidget {
  const _ProgressSliverList({required this.itemCount, required this.itemBuilder});
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          if (i.isOdd) return Divider(height: 1, color: SoftPalette.track);
          return itemBuilder(context, i ~/ 2);
        }, childCount: itemCount * 2 - 1),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SoftPalette.surface,
          shape: BoxShape.circle,
          boxShadow: SoftPalette.softShadow(opacity: 0.05, y: 4, blur: 10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: SoftPalette.primary,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SoftPalette.softShadow(),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: SoftPalette.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.title.copyWith(fontSize: 15, color: SoftPalette.primary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Real per-day listening history rendered as a compact heatmap grid —
/// darker teal = closer to (or past) the daily goal, matching the "year
/// overview" idea without inventing data we don't actually track (there's
/// no per-reciter or per-hour breakdown recorded, only daily totals).
class _YearHeatmap extends StatelessWidget {
  const _YearHeatmap({required this.days, required this.goalSeconds});
  final List<int> days;
  final int goalSeconds;

  @override
  Widget build(BuildContext context) {
    final activeDays = days.where((s) => s > 0).length;
    final percent = days.isEmpty ? 0.0 : activeDays / days.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: SoftPalette.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FlutterIslamicIcons.calendar, size: 16, color: SoftPalette.primary),
              const SizedBox(width: 8),
              Text(
                'Обзор за ${days.length} дней',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: SoftPalette.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final seconds in days)
                _HeatCell(
                  intensity: goalSeconds <= 0 ? 0 : seconds / goalSeconds,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Слушали $activeDays из ${days.length} дн. — ${(percent * 100).round()}%',
            style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.intensity});
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final clamped = intensity.clamp(0.0, 1.0);
    final color = clamped <= 0
        ? SoftPalette.track
        : Color.lerp(SoftPalette.light, SoftPalette.primary, clamped.clamp(0.25, 1.0))!;
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    final memorized = (percent * 6236).round();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: SoftPalette.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: SoftPalette.softShadow(opacity: 0.16, y: 12, blur: 26),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -34,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Icon(
                FlutterIslamicIcons.solidQuran2,
                size: 56,
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: Center(
                      child: Text(
                        '${(percent * 100).round()}%',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Прогресс по всему Корану',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Заучено $memorized из 6236 аятов',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.current, required this.onChanged});
  final _ProgressTab current;
  final ValueChanged<_ProgressTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tabButton(String label, _ProgressTab tab) {
      final selected = current == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? SoftPalette.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : SoftPalette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SoftPalette.light,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          tabButton('По сурам', _ProgressTab.surahs),
          tabButton('По джузам', _ProgressTab.juz),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.title,
    required this.subtitle,
    required this.percent,
  });
  final String title;
  final String? subtitle;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final done = percent >= 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SoftPalette.textDark,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: SoftPalette.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (done)
                const Icon(
                  Icons.check_circle_rounded,
                  color: SoftPalette.primary,
                  size: 20,
                )
              else
                Text(
                  '${(percent * 100).round()}%',
                  style: AppTextStyles.caption.copyWith(
                    color: SoftPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: SoftPalette.track,
              valueColor: const AlwaysStoppedAnimation(SoftPalette.primary),
            ),
          ),
        ],
      ),
    );
  }
}
