import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../surahs/presentation/screens/surahs_browse_screen.dart';

final _reciterSearchQueryProvider = StateProvider<String>((ref) => '');

const _avatarPalette = [
  Color(0xFF159AA6),
  Color(0xFF3FB6BE),
  Color(0xFF5FA8D3),
  Color(0xFF6FCF97),
  Color(0xFFE0A83F),
  Color(0xFFE0748C),
];

/// Entry point for browsing the Quran: pick a reciter first, then the surah
/// list opens for that voice — mirrors how the reference app is structured.
class ReciterListScreen extends ConsumerWidget {
  const ReciterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(settingsControllerProvider).reciterId;
    final query = ref.watch(_reciterSearchQueryProvider).trim().toLowerCase();

    final reciters = query.isEmpty
        ? AppConstants.reciters
        : AppConstants.reciters
            .where((r) => r.name.toLowerCase().contains(query) || r.nameArabic.contains(query))
            .toList();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: SoftPalette.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Чтецы',
                style: AppTextStyles.displayTitle.copyWith(color: SoftPalette.textDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Выберите чтеца, чтобы открыть список сур',
                style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _SearchField(
                onChanged: (v) => ref.read(_reciterSearchQueryProvider.notifier).state = v,
              ),
            ),
            Expanded(
              child: reciters.isEmpty
                  ? Center(
                      child: Text(
                        'Ничего не найдено',
                        style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: reciters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final reciter = reciters[i];
                        final isSelected = reciter.id == selectedId;
                        final color = _avatarPalette[i % _avatarPalette.length];
                        return _ReciterTile(
                          reciter: reciter,
                          isSelected: isSelected,
                          avatarColor: color,
                          onTap: () {
                            ref.read(settingsControllerProvider.notifier).setReciter(reciter.id);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SurahsBrowseScreen()),
                            );
                          },
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

class _ReciterTile extends StatelessWidget {
  const _ReciterTile({
    required this.reciter,
    required this.isSelected,
    required this.avatarColor,
    required this.onTap,
  });

  final ReciterInfo reciter;
  final bool isSelected;
  final Color avatarColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SoftPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: SoftPalette.primary, width: 1.6) : null,
          boxShadow: SoftPalette.softShadow(opacity: 0.05, y: 6, blur: 14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [avatarColor, avatarColor.withValues(alpha: 0.65)],
                ),
              ),
              child: Text(
                reciter.name.substring(0, 1),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reciter.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SoftPalette.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reciter.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.arabic.copyWith(
                      fontSize: 14,
                      height: 1.3,
                      color: SoftPalette.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reciter.bio,
                    style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: SoftPalette.primary, size: 22)
            else
              const Icon(Icons.chevron_right_rounded, color: SoftPalette.textSecondary),
          ],
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
          hintText: 'Поиск чтеца',
          hintStyle: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
          prefixIcon: const Icon(Icons.search, color: SoftPalette.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
