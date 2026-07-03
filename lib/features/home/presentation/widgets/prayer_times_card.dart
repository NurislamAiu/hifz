import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/daily_prayer_times.dart';
import '../../../../data/providers.dart';
import '../../providers/prayer_times_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../../core/theme/soft_palette.dart';

class PrayerTimesCard extends ConsumerStatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  ConsumerState<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends ConsumerState<PrayerTimesCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatCountdown(Duration d) {
    final duration = d.isNegative ? Duration.zero : d;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '$hours ч $minutes мин';
    return '$minutes мин';
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'fajr':
        return Iconsax.sun_fog;
      case 'sunrise':
        return Iconsax.sun_1;
      case 'dhuhr':
        return Iconsax.sun_1;
      case 'asr':
        return Iconsax.cloud;
      case 'maghrib':
        return Iconsax.moon;
      case 'isha':
        return Iconsax.moon;
      default:
        return Iconsax.clock;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);

    return prayerTimesAsync.when(
      loading: () => const _PrayerCardShell(
        child: SizedBox(
          height: 64,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      ),
      error: (e, _) => _PrayerCardShell(
        child: _PrayerTimesMessage(
          icon: Iconsax.cloud_cross,
          message: _logPrayerError(e),
          actionLabel: 'Повторить',
          onAction: () => ref.invalidate(prayerTimesProvider),
        ),
      ),
      data: (prayerTimes) {
        if (prayerTimes == null) {
          debugPrint('[PrayerTimes][UI] data=null');
          return _PrayerCardShell(
            child: _PrayerTimesMessage(
              icon: Iconsax.location,
              message: 'Разрешите доступ к геолокации, чтобы увидеть время намазов',
              actionLabel: 'Включить',
              onAction: () => ref.invalidate(prayerTimesProvider),
            ),
          );
        }
        debugPrint(
          '[PrayerTimes][UI] data city=${prayerTimes.cityName} '
          'next=${prayerTimes.next.label} at=${prayerTimes.next.time} '
          'entries=${prayerTimes.entries.length}',
        );
        return _PrayerCardShell(
          onTune: () => _showPrayerSettings(context),
          cityName: prayerTimes.cityName,
          dateLabel: prayerTimes.dateLabel,
          countdownLabel:
              '${prayerTimes.next.label} через ${_formatCountdown(prayerTimes.timeUntilNext)}',
          methodName: prayerTimes.methodName,
          child: Row(
            children: [
              for (final entry in prayerTimes.entries)
                Expanded(
                  child: _PrayerColumn(
                    entry: entry,
                    isActive: entry.key == prayerTimes.next.key,
                    icon: _iconForKey(entry.key),
                    formatTime: _formatTime,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _logPrayerError(Object error) {
    debugPrint('[PrayerTimes][UI] error=$error');
    return 'Не удалось показать время намаза. Попробуйте ещё раз';
  }

  Future<void> _rescheduleNotifications() async {
    final settings = ref.read(settingsControllerProvider);
    if (!(settings.notificationsEnabled ?? false)) return;
    final prayerTimes = ref.read(prayerTimesProvider).valueOrNull;
    if (prayerTimes == null) return;
    await ref.read(notificationRepositoryProvider).scheduleTodayPrayerNotifications(
          prayerTimes,
          disabledKeys: settings.disabledPrayerKeys,
        );
  }

  Future<void> _showPrayerSettings(BuildContext context) async {
    const prayers = <(String, String)>[
      ('fajr', 'Фаджр'),
      ('dhuhr', 'Зухр'),
      ('asr', 'Аср'),
      ('maghrib', 'Магриб'),
      ('isha', 'Иша'),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SoftPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer(
            builder: (context, sheetRef, _) {
              final settings = sheetRef.watch(settingsControllerProvider);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Настройки намаза',
                            style: AppTextStyles.title.copyWith(color: SoftPalette.textDark),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Iconsax.close_circle, color: SoftPalette.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Уведомления о намазе',
                      style: AppTextStyles.overline.copyWith(color: SoftPalette.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Выключите намазы, о которых не нужно напоминать',
                      style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    for (final (key, label) in prayers)
                      _PrayerNotifyRow(
                        label: label,
                        icon: _iconForKey(key),
                        value: settings.isPrayerNotificationEnabled(key),
                        onChanged: (value) async {
                          await ref
                              .read(settingsControllerProvider.notifier)
                              .setPrayerNotificationEnabled(key, value);
                          await _rescheduleNotifications();
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PrayerNotifyRow extends StatelessWidget {
  const _PrayerNotifyRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: SoftPalette.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: value ? SoftPalette.primary : SoftPalette.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: SoftPalette.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            activeTrackColor: Colors.white,
            value: value,
            activeThumbColor: SoftPalette.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Soft turquoise gradient "sky" shell shared by the loading, error, empty
/// and data states of the prayer card — keeps the card's shape/backdrop
/// consistent no matter what's inside it.
class _PrayerCardShell extends StatelessWidget {
  const _PrayerCardShell({
    required this.child,
    this.onTune,
    this.cityName,
    this.dateLabel,
    this.countdownLabel,
    this.methodName,
  });

  final Widget child;
  final VoidCallback? onTune;
  final String? cityName;
  final String? dateLabel;
  final String? countdownLabel;
  final String? methodName;

  @override
  Widget build(BuildContext context) {
    final hasHeader = cityName != null || onTune != null;

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
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 0,
              child: Icon(
                FlutterIslamicIcons.solidMosque,
                size: 44,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              right: 58,
              bottom: 2,
              child: Icon(
                FlutterIslamicIcons.crescentMoon,
                size: 24,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasHeader) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cityName ?? 'Время намаза',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (dateLabel != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  dateLabel!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (countdownLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              countdownLabel!,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (onTune != null)
                          IconButton(
                            onPressed: onTune,
                            icon: const Icon(Iconsax.setting_4, size: 20),
                            color: Colors.white,
                            tooltip: 'Настройки намаза',
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  child,
                  const SizedBox(height: 6),
                  if (methodName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        methodName!,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
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

class _PrayerColumn extends StatelessWidget {
  const _PrayerColumn({
    required this.entry,
    required this.isActive,
    required this.icon,
    required this.formatTime,
  });

  final PrayerTimeEntry entry;
  final bool isActive;
  final IconData icon;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: EdgeInsets.symmetric(vertical: isActive ? 10 : 6, horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.22) : null,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              entry.label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: Colors.white.withValues(alpha: isActive ? 1 : 0.7),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatTime(entry.time),
              style: TextStyle(
                fontSize: isActive ? 16 : 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: isActive ? 1 : 0.85),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, size: isActive ? 20 : 16, color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.55)),
        ],
      ),
    );
  }
}

class _PrayerTimesMessage extends StatelessWidget {
  const _PrayerTimesMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

