import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/display_mode.dart';
import '../../../../data/providers.dart';
import '../../../home/providers/prayer_times_provider.dart';
import '../../providers/settings_provider.dart';

/// Not configured yet — the user asked for a placeholder until they supply a
/// real donation link (Kaspi / PayPal / Patreon / crypto wallet, etc.).
const _donateUrl = '';

/// Not configured yet — fill in once the app is published to a store.
const _storeUrl = '';

String _formatPlaybackSpeed(double speed) {
  final fixed = speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 2);
  return '${fixed.replaceFirst(RegExp(r'0$'), '')}x';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openOrNotify(
    BuildContext context,
    String url, {
    String emptyMessage = 'Ссылка пока не настроена',
  }) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emptyMessage)));
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
        children: [
          const Text('Настройки', style: AppTextStyles.displayTitle),
          const SizedBox(height: 28),

          const Text('ЧТЕНИЕ', style: AppTextStyles.overline),
          const SizedBox(height: 8),
          _ReadingSettingsCard(
            displayMode: settings.displayMode,
            playbackSpeed: settings.playbackSpeed,
            onDisplayModeChanged: controller.setDisplayMode,
            onPlaybackSpeedChanged: controller.setPlaybackSpeed,
          ),

          const SizedBox(height: 24),
          const Text('УВЕДОМЛЕНИЯ', style: AppTextStyles.overline),
          const SizedBox(height: 8),
          const _SectionCard(child: _NotificationsRow()),

          const SizedBox(height: 24),
          const Text('ХРАНИЛИЩЕ', style: AppTextStyles.overline),
          const SizedBox(height: 8),
          const _SectionCard(child: _CacheManagementRow()),

          const SizedBox(height: 24),
          const Text('ПОДДЕРЖКА ПРОЕКТА', style: AppTextStyles.overline),
          const SizedBox(height: 8),
          _SectionCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: FlutterIslamicIcons.zakat,
                  iconColor: AppColors.warning,
                  title: 'Сделать садака',
                  subtitle: 'Поддержать труд команды — по желанию',
                  trailing: const Icon(
                    Iconsax.arrow_right_3,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () => _openOrNotify(
                    context,
                    _donateUrl,
                    emptyMessage:
                        'Приложение бесплатно. Ссылка для садака скоро появится',
                  ),
                ),
                const Divider(height: 1, indent: 60, endIndent: 16),
                _SettingsRow(
                  icon: Iconsax.export,
                  iconColor: AppColors.accent,
                  title: 'Поделиться приложением',
                  trailing: const Icon(
                    Iconsax.arrow_right_3,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () => SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Hifz — бесплатное приложение для заучивания Корана на слух. '
                          'Без рекламы, без подписок.',
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 60, endIndent: 16),
                _SettingsRow(
                  icon: Iconsax.star1,
                  iconColor: AppColors.success,
                  title: 'Оценить приложение',
                  trailing: const Icon(
                    Iconsax.arrow_right_3,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () => _openOrNotify(
                    context,
                    _storeUrl,
                    emptyMessage: 'Приложение пока не опубликовано в сторе',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('О ПРИЛОЖЕНИИ', style: AppTextStyles.overline),
          const SizedBox(height: 8),
          const _SectionCard(
            child: Column(
              children: [
                _VersionRow(),
                Divider(height: 1, indent: 60, endIndent: 16),
                _SettingsRow(
                  icon: Iconsax.moon,
                  iconColor: AppColors.textSecondary,
                  title: 'Тёмная тема',
                  subtitle: 'Светлая появится позже',
                  trailing: Switch(value: true, onChanged: null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingSettingsCard extends StatelessWidget {
  const _ReadingSettingsCard({
    required this.displayMode,
    required this.playbackSpeed,
    required this.onDisplayModeChanged,
    required this.onPlaybackSpeedChanged,
  });

  final DisplayMode displayMode;
  final double playbackSpeed;
  final ValueChanged<DisplayMode> onDisplayModeChanged;
  final ValueChanged<double> onPlaybackSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _ReadingSettingHeader(
              icon: Iconsax.translate,
              title: 'Отображение текста',
              iconColor: AppColors.accent,
            ),
            const SizedBox(height: 10),
            _DisplayModeSwitcher(
              current: displayMode,
              onChanged: onDisplayModeChanged,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const _ReadingSettingHeader(
                        icon: Iconsax.speedometer,
                        title: 'Скорость по умолчанию',
                        iconColor: AppColors.accent,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Text(
                          _formatPlaybackSpeed(playbackSpeed),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: Slider(
                      value: playbackSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      activeColor: AppColors.accent,
                      inactiveColor: AppColors.trackInactive,
                      onChanged: onPlaybackSpeedChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0.5x', style: AppTextStyles.caption),
                        Text('обычно', style: AppTextStyles.caption),
                        Text('2x', style: AppTextStyles.caption),
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

class _ReadingSettingHeader extends StatelessWidget {
  const _ReadingSettingHeader({
    required this.icon,
    required this.title,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 9),
        Text(title, style: AppTextStyles.body),
      ],
    );
  }
}

class _DisplayModeSwitcher extends StatelessWidget {
  const _DisplayModeSwitcher({required this.current, required this.onChanged});
  final DisplayMode current;
  final ValueChanged<DisplayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, DisplayMode mode) {
      final selected = current == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          chip('Араб.', DisplayMode.arabic),
          const SizedBox(width: 4),
          chip('Транслит.', DisplayMode.transliteration),
          const SizedBox(width: 4),
          chip('Оба', DisplayMode.both),
        ],
      ),
    );
  }
}

class _NotificationsRow extends ConsumerStatefulWidget {
  const _NotificationsRow();

  @override
  ConsumerState<_NotificationsRow> createState() => _NotificationsRowState();
}

class _NotificationsRowState extends ConsumerState<_NotificationsRow> {
  bool _busy = false;

  Future<void> _onChanged(bool value) async {
    setState(() => _busy = true);
    final controller = ref.read(settingsControllerProvider.notifier);
    final notificationRepo = ref.read(notificationRepositoryProvider);

    if (value) {
      final granted = await notificationRepo.requestPermission();
      if (!granted) {
        if (mounted) {
          setState(() => _busy = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Разрешите уведомления в настройках устройства'),
            ),
          );
        }
        return;
      }
      await controller.setNotificationsEnabled(true);
      await notificationRepo.scheduleHourlyRepentanceReminders();
      final prayerTimes = ref.read(prayerTimesProvider).valueOrNull;
      if (prayerTimes != null) {
        await notificationRepo.scheduleTodayPrayerNotifications(
          prayerTimes,
          disabledKeys: ref.read(settingsControllerProvider).disabledPrayerKeys,
        );
      }
    } else {
      await controller.setNotificationsEnabled(false);
      await notificationRepo.cancelAll();
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.notificationsEnabled ?? false),
    );

    return _SettingsRow(
      icon: Iconsax.notification,
      iconColor: AppColors.accent,
      title: 'Напоминания',
      subtitle: 'Намазы и ежечасные аяты о покаянии',
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          : Switch(value: enabled, onChanged: _onChanged),
    );
  }
}

class _CacheManagementRow extends ConsumerStatefulWidget {
  const _CacheManagementRow();

  @override
  ConsumerState<_CacheManagementRow> createState() =>
      _CacheManagementRowState();
}

class _CacheManagementRowState extends ConsumerState<_CacheManagementRow> {
  int? _bytes;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final size = await ref.read(audioRepositoryProvider).cacheSizeBytes();
    if (mounted) setState(() => _bytes = size);
  }

  String _format(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Iconsax.tick_circle,
      iconColor: AppColors.accent,
      title: 'Скачанные аяты',
      subtitle: _bytes == null ? 'Подсчёт…' : _format(_bytes!),
      trailing: _clearing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          : TextButton(
              onPressed: () async {
                setState(() => _clearing = true);
                await ref.read(audioRepositoryProvider).clearAll();
                await _refresh();
                if (mounted) setState(() => _clearing = false);
              },
              child: const Text(
                'Очистить',
                style: TextStyle(color: AppColors.error),
              ),
            ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final value = info == null
            ? '—'
            : '${info.version} (${info.buildNumber})';
        return _SettingsRow(
          icon: Iconsax.info_circle,
          iconColor: AppColors.textSecondary,
          title: 'Версия',
          trailing: Text(value, style: AppTextStyles.caption),
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
