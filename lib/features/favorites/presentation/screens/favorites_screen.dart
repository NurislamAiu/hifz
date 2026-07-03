import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../../data/models/favorite_item.dart';
import '../../../../data/providers.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../surahs/presentation/screens/surah_detail_screen.dart';
import '../../providers/favorites_provider.dart';

enum _FavoritesFilter { all, surahs, ayahs }

final _favoritesFilterProvider = StateProvider<_FavoritesFilter>((ref) => _FavoritesFilter.all);

const _ayahAccent = Color(0xFFE0A83F);

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesControllerProvider);
    final quranRepo = ref.watch(quranRepositoryProvider);
    final recent = ref.watch(recentlyPlayedRepositoryProvider).getAll();
    final filter = ref.watch(_favoritesFilterProvider);

    final filtered = switch (filter) {
      _FavoritesFilter.all => favorites,
      _FavoritesFilter.surahs => favorites.where((f) => f.type == FavoriteType.surah).toList(),
      _FavoritesFilter.ayahs => favorites.where((f) => f.type == FavoriteType.ayah).toList(),
    };

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: SoftPalette.background,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Избранное',
                  style: AppTextStyles.displayTitle.copyWith(color: SoftPalette.textDark),
                ),
              ),
            ),
            if (recent.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Недавно прослушано',
                    style: AppTextStyles.overline.copyWith(color: SoftPalette.textSecondary),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 104,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final (surahNumber, ayahNumber) = recent[i];
                        if (!quranRepo.isCached) return const SizedBox.shrink();
                        final surah = quranRepo.getSurah(surahNumber);
                        return _RecentCard(
                          title: surah.nameTransliteration,
                          subtitle: 'Аят $ayahNumber',
                          onTap: () => PlayerScreen.open(context, surahNumber: surahNumber, startAyah: ayahNumber),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Сохранённое',
                      style: AppTextStyles.overline.copyWith(color: SoftPalette.textSecondary),
                    ),
                    if (favorites.isNotEmpty)
                      _FilterSwitcher(
                        current: filter,
                        onChanged: (f) => ref.read(_favoritesFilterProvider.notifier).state = f,
                      ),
                  ],
                ),
              ),
            ),
            if (favorites.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyFavorites(),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Ничего нет в этой категории',
                      style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    if (!quranRepo.isCached) return const SizedBox.shrink();
                    final surah = quranRepo.getSurah(item.surahNumber);
                    final isAyah = item.type == FavoriteType.ayah;
                    return _FavoriteTile(
                      isAyah: isAyah,
                      title: surah.nameTransliteration,
                      nameArabic: surah.nameArabic,
                      subtitle: isAyah ? 'Аят ${item.ayahNumberInSurah}' : '${surah.numberOfAyahs} аятов',
                      onRemove: () => isAyah
                          ? ref.read(favoritesControllerProvider.notifier).toggleAyah(item.surahNumber, item.ayahNumberInSurah!)
                          : ref.read(favoritesControllerProvider.notifier).toggleSurah(item.surahNumber),
                      onTap: () => isAyah
                          ? PlayerScreen.open(context, surahNumber: item.surahNumber, startAyah: item.ayahNumberInSurah!)
                          : Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SurahDetailScreen(surahNumber: item.surahNumber)),
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

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.isAyah,
    required this.title,
    required this.nameArabic,
    required this.subtitle,
    required this.onRemove,
    required this.onTap,
  });

  final bool isAyah;
  final String title;
  final String nameArabic;
  final String subtitle;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isAyah ? _ayahAccent : SoftPalette.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SoftPalette.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: SoftPalette.softShadow(opacity: 0.05, y: 6, blur: 14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(
                isAyah ? Icons.bookmark_rounded : FlutterIslamicIcons.quran,
                color: badgeColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SoftPalette.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        nameArabic,
                        style: AppTextStyles.arabic.copyWith(
                          fontSize: 15,
                          height: 1,
                          color: SoftPalette.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary)),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.star_rounded, color: _ayahAccent, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSwitcher extends StatelessWidget {
  const _FilterSwitcher({required this.current, required this.onChanged});
  final _FavoritesFilter current;
  final ValueChanged<_FavoritesFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _FavoritesFilter filter) {
      final selected = current == filter;
      return GestureDetector(
        onTap: () => onChanged(filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? SoftPalette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: selected ? Colors.white : SoftPalette.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: SoftPalette.light, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('Все', _FavoritesFilter.all),
          chip('Суры', _FavoritesFilter.surahs),
          chip('Аяты', _FavoritesFilter.ayahs),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: SoftPalette.light, shape: BoxShape.circle),
              child: const Icon(Icons.star_outline_rounded, color: SoftPalette.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет избранного',
              style: AppTextStyles.body.copyWith(color: SoftPalette.textDark, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Отмечайте суры и аяты звёздочкой — они появятся здесь',
              style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SoftPalette.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: SoftPalette.softShadow(opacity: 0.05, y: 6, blur: 14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: SoftPalette.light, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: SoftPalette.primary, size: 18),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: SoftPalette.textDark),
            ),
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary)),
          ],
        ),
      ),
    );
  }
}
