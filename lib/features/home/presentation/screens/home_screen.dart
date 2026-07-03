import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/prayer_city.dart';
import '../../providers/prayer_times_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../../core/theme/soft_palette.dart';
import '../widgets/continue_listening_card.dart';
import '../widgets/prayer_times_card.dart';
import '../widgets/stats_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCityId = ref.watch(
      settingsControllerProvider.select((settings) => settings.selectedCityId),
    );
    final selectedCity = PrayerCities.byId(selectedCityId);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: SoftPalette.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: AppTextStyles.overline.copyWith(color: SoftPalette.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/icon.png', width: 34, height: 34),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hifz',
                    style: AppTextStyles.displayTitle.copyWith(color: SoftPalette.textDark),
                  ),
                  const Spacer(),
                  _CityButton(
                    label: selectedCity?.name ?? 'Гео',
                    onTap: () => _showCityPicker(context, ref, selectedCityId),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const PrayerTimesCard(),
              const SizedBox(height: 24),
              const StatsSection(),
              const SizedBox(height: 24),
              const ContinueListeningCard(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCityPicker(
    BuildContext context,
    WidgetRef ref,
    String? selectedCityId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoftPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        Future<void> selectCity(String? cityId) async {
          await ref
              .read(settingsControllerProvider.notifier)
              .setSelectedCityId(cityId);
          ref.invalidate(prayerTimesProvider);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.35,
          maxChildSize: 0.90,
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
                          'Город для намаза',
                          style: AppTextStyles.title.copyWith(color: SoftPalette.textDark),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded, color: SoftPalette.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CityTile(
                    title: 'Моя геолокация',
                    subtitle: 'Использовать текущее местоположение',
                    selected: selectedCityId == null,
                    onTap: () => selectCity(null),
                  ),
                  Divider(height: 1, color: SoftPalette.track),
                  for (final city in PrayerCities.all) ...[
                    _CityTile(
                      title: city.name,
                      subtitle: city.region,
                      selected: selectedCityId == city.id,
                      onTap: () => selectCity(city.id),
                    ),
                    Divider(height: 1, color: SoftPalette.track),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CityButton extends StatelessWidget {
  const _CityButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SoftPalette.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: SoftPalette.softShadow(opacity: 0.05, y: 4, blur: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, color: SoftPalette.primary, size: 16),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 92),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: SoftPalette.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded, color: SoftPalette.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: selected ? SoftPalette.primary : SoftPalette.textSecondary,
      ),
      title: Text(title, style: AppTextStyles.body.copyWith(color: SoftPalette.textDark)),
      subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary)),
      trailing: selected ? const Icon(Icons.check_rounded, color: SoftPalette.primary) : null,
    );
  }
}
