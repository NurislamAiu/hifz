import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../../data/providers.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/surahs_provider.dart';
import '../widgets/surah_list_tile.dart';
import 'surah_detail_screen.dart';

/// Full 114-surah browser, reached only after a reciter has been chosen —
/// every surah here plays back with [selectedReciterProvider].
enum _BrowseTab { surahs, juz }

class SurahsBrowseScreen extends ConsumerStatefulWidget {
  const SurahsBrowseScreen({super.key});

  @override
  ConsumerState<SurahsBrowseScreen> createState() => _SurahsBrowseScreenState();
}

class _SurahsBrowseScreenState extends ConsumerState<SurahsBrowseScreen> {
  _BrowseTab _tab = _BrowseTab.surahs;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final reciter = ref.watch(selectedReciterProvider);

    return Scaffold(
      backgroundColor: SoftPalette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
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
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.surahs,
                          style: AppTextStyles.title.copyWith(
                            color: SoftPalette.textDark,
                          ),
                        ),
                        Text(
                          reciter.name,
                          style: AppTextStyles.caption.copyWith(
                            color: SoftPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: _LastReadCard(reciterName: reciter.name),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: _BrowseTabSwitcher(
                current: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: _tab == _BrowseTab.surahs
                  ? _buildSurahTab(reciter)
                  : _buildJuzTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahTab(ReciterInfo reciter) {
    final s = context.s;
    final surahsAsync = ref.watch(filteredSurahsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: _SearchField(
            onChanged: (v) =>
                ref.read(surahSearchQueryProvider.notifier).state = v,
          ),
        ),
        Expanded(
          child: surahsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: SoftPalette.primary),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${s.quranLoadError}\n$err',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: SoftPalette.textSecondary,
                  ),
                ),
              ),
            ),
            data: (surahs) {
              if (surahs.isEmpty) {
                return Center(
                  child: Text(
                    s.nothingFound,
                    style: AppTextStyles.caption.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                itemCount: surahs.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: SoftPalette.track),
                itemBuilder: (context, i) {
                  final surah = surahs[i];
                  final isDownloaded = ref
                      .watch(audioRepositoryProvider)
                      .isSurahDownloaded(
                        reciterFolder: reciter.folder,
                        surahNumber: surah.number,
                        ayahCount: surah.numberOfAyahs,
                      );
                  return SurahListTile(
                    surah: surah,
                    isDownloaded: isDownloaded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SurahDetailScreen(surahNumber: surah.number),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJuzTab() {
    final s = context.s;
    final juzAsync = ref.watch(juzEntriesProvider);

    return juzAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: SoftPalette.primary),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${s.quranLoadError}\n$err',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: SoftPalette.textSecondary,
            ),
          ),
        ),
      ),
      data: (entries) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        itemCount: entries.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: SoftPalette.track),
        itemBuilder: (context, i) {
          final entry = entries[i];
          return _JuzTile(
            entry: entry,
            onTap: () => PlayerScreen.open(
              context,
              surahNumber: entry.startSurahNumber,
              startAyah: entry.startAyahInSurah,
            ),
          );
        },
      ),
    );
  }
}

/// Segmented control switching the browser between the plain surah list and
/// the 30-juz index. Mirrors the toggle used on the progress screen.
class _BrowseTabSwitcher extends StatelessWidget {
  const _BrowseTabSwitcher({required this.current, required this.onChanged});

  final _BrowseTab current;
  final ValueChanged<_BrowseTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tabButton(String label, _BrowseTab tab) {
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
          tabButton(context.s.bySurahs, _BrowseTab.surahs),
          tabButton(context.s.byJuz, _BrowseTab.juz),
        ],
      ),
    );
  }
}

/// A single juz row — number medallion, the surah/ayah it opens at, and a chip
/// with how many surahs it spans. Tapping starts playback from the juz start.
class _JuzTile extends StatelessWidget {
  const _JuzTile({required this.entry, required this.onTap});

  final JuzEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SoftPalette.primary, Color(0xFF3FB6BE)],
                ),
              ),
              child: Text(
                '${entry.juz}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.juz(entry.juz),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: SoftPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.juzStartsAt(entry.startSurahName, entry.startAyahInSurah),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: SoftPalette.light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.juzSurahsCount(entry.surahCount),
                style: AppTextStyles.caption.copyWith(
                  color: SoftPalette.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastReadCard extends ConsumerWidget {
  const _LastReadCard({required this.reciterName});
  final String reciterName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranRepo = ref.watch(quranRepositoryProvider);
    final recent = ref.watch(recentlyPlayedRepositoryProvider).getAll();

    if (recent.isEmpty || !quranRepo.isCached) return const SizedBox.shrink();

    final (surahNumber, ayahNumber) = recent.first;
    final surah = quranRepo.getSurah(surahNumber);

    return GestureDetector(
      onTap: () => PlayerScreen.open(
        context,
        surahNumber: surahNumber,
        startAyah: ayahNumber,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: SoftPalette.heroGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: SoftPalette.softShadow(opacity: 0.16, y: 10, blur: 22),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                right: -6,
                bottom: -10,
                child: Icon(
                  FlutterIslamicIcons.solidQuran2,
                  size: 84,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                FlutterIslamicIcons.quran,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.s.lastReading,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            surah.nameTransliteration,
                            style: AppTextStyles.title.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.s.ayah(ayahNumber),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Iconsax.play,
                        color: SoftPalette.primary,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
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
          hintText: context.s.searchSurah,
          hintStyle: AppTextStyles.caption.copyWith(
            color: SoftPalette.textSecondary,
          ),
          prefixIcon: const Icon(
            Iconsax.search_normal_1,
            color: SoftPalette.primary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
