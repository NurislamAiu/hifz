import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/display_mode.dart';
import '../../../../data/providers.dart';
import '../../../home/providers/prayer_times_provider.dart';
import '../../providers/settings_provider.dart';
import 'sadaqa_screen.dart';

/// Not configured yet — fill in once the app is published to a store.
const _storeUrl = '';

const _gold = Color(0xFFE0A83F);
const _danger = Color(0xFFE0574B);

String _formatPlaybackSpeed(double speed) {
  final fixed = speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 2);
  return '${fixed.replaceFirst(RegExp(r'0$'), '')}x';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openOrNotify(
    BuildContext context,
    String url, {
    String? emptyMessage,
  }) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emptyMessage ?? context.s.linkNotConfigured)),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Container(
      color: SoftPalette.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
          children: [
            Text(
              s.settings,
              style: AppTextStyles.displayTitle.copyWith(
                color: SoftPalette.textDark,
              ),
            ),
            const SizedBox(height: 24),

            _SectionLabel(s.readingSection),
            const _SettingsCard(child: _LanguageRow()),
            const SizedBox(height: 14),
            _ReadingSettingsCard(
              displayMode: settings.displayMode,
              playbackSpeed: settings.playbackSpeed,
              onDisplayModeChanged: controller.setDisplayMode,
              onPlaybackSpeedChanged: controller.setPlaybackSpeed,
            ),

            const SizedBox(height: 22),
            _SectionLabel(s.notificationsSection),
            const _SettingsCard(
              child: Column(
                children: [
                  _NotificationsRow(),
                  _RowDivider(),
                  _AzanRow(),
                  _RowDivider(),
                  _RepentanceToneRow(),
                ],
              ),
            ),

            const SizedBox(height: 22),
            _SectionLabel(s.widgetSection),
            const _SettingsCard(child: _WidgetQuizRow()),

            const SizedBox(height: 22),
            _SectionLabel(s.storageSection),
            const _SettingsCard(child: _CacheManagementRow()),

            const SizedBox(height: 22),
            _SectionLabel(s.supportSection),
            _SettingsCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: FlutterIslamicIcons.zakat,
                    iconColor: _gold,
                    title: s.makeSadaqa,
                    subtitle: s.supportTeam,
                    trailing: const Icon(
                      Iconsax.arrow_right_3,
                      color: SoftPalette.textSecondary,
                      size: 18,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SadaqaScreen(),
                      ),
                    ),
                  ),
                  const _RowDivider(),
                  _SettingsRow(
                    icon: Iconsax.export,
                    iconColor: SoftPalette.primary,
                    title: s.shareApp,
                    trailing: const Icon(
                      Iconsax.arrow_right_3,
                      color: SoftPalette.textSecondary,
                      size: 18,
                    ),
                    onTap: () => SharePlus.instance.share(
                      ShareParams(text: s.shareText),
                    ),
                  ),
                  const _RowDivider(),
                  _SettingsRow(
                    icon: Iconsax.star1,
                    iconColor: _gold,
                    title: s.rateApp,
                    trailing: const Icon(
                      Iconsax.arrow_right_3,
                      color: SoftPalette.textSecondary,
                      size: 18,
                    ),
                    onTap: () => _openOrNotify(
                      context,
                      _storeUrl,
                      emptyMessage: s.appNotPublished,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            _SectionLabel(s.aboutSection),
            _SettingsCard(
              child: Column(
                children: [
                  const _VersionRow(),

                ],
              ),
            ),
          ],
        ),
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
    final s = context.s;
    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MiniHeader(icon: Iconsax.translate, title: s.displayText),
            const SizedBox(height: 12),
            _DisplayModeSwitcher(
              current: displayMode,
              onChanged: onDisplayModeChanged,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _MiniHeader(icon: Iconsax.speedometer, title: s.defaultSpeed),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: SoftPalette.light,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatPlaybackSpeed(playbackSpeed),
                    style: AppTextStyles.caption.copyWith(
                      color: SoftPalette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: SoftPalette.primary,
                inactiveTrackColor: SoftPalette.track,
                thumbColor: SoftPalette.primary,
                overlayColor: SoftPalette.primary.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: playbackSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                onChanged: onPlaybackSpeedChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0.5x',
                    style: AppTextStyles.caption.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                  Text(
                    s.normal,
                    style: AppTextStyles.caption.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                  Text(
                    '2x',
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
    );
  }
}

class _MiniHeader extends StatelessWidget {
  const _MiniHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: SoftPalette.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: SoftPalette.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LanguageRow extends ConsumerWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(
      settingsControllerProvider.select(
        (settings) => AppLanguage.fromCode(settings.appLanguageCode),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SoftPalette.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.language_square,
                  color: SoftPalette.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.s.appLanguage,
                      style: AppTextStyles.body.copyWith(
                        color: SoftPalette.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.s.appLanguageSubtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: SoftPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LanguageSwitcher(
            current: language,
            onChanged: (language) => ref
                .read(settingsControllerProvider.notifier)
                .setAppLanguageCode(language.code),
          ),
        ],
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({required this.current, required this.onChanged});

  final AppLanguage current;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, AppLanguage language) {
      final selected = current == language;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(language),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? SoftPalette.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
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
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          chip(context.s.russian, AppLanguage.ru),
          const SizedBox(width: 4),
          chip(context.s.kazakh, AppLanguage.kk),
        ],
      ),
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
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? SoftPalette.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
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
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          chip(context.s.arabicShort, DisplayMode.arabic),
          const SizedBox(width: 4),
          chip(context.s.transliterationShort, DisplayMode.transliteration),
          const SizedBox(width: 4),
          chip(context.s.both, DisplayMode.both),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.s.allowNotifications)));
        }
        return;
      }
      await controller.setNotificationsEnabled(true);
      await notificationRepo.scheduleDailyRepentanceReminders(
        tone: ref.read(settingsControllerProvider).repentanceReminderTone,
        language: AppLanguage.fromCode(
          ref.read(settingsControllerProvider).appLanguageCode,
        ),
      );
      final prayerTimes = ref.read(prayerTimesProvider).valueOrNull;
      if (prayerTimes != null) {
        await notificationRepo.scheduleTodayPrayerNotifications(
          prayerTimes,
          disabledKeys: ref.read(settingsControllerProvider).disabledPrayerKeys,
          language: AppLanguage.fromCode(
            ref.read(settingsControllerProvider).appLanguageCode,
          ),
          azan: ref.read(settingsControllerProvider).azanNotificationSound,
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
      iconColor: SoftPalette.primary,
      title: context.s.reminders,
      subtitle: context.s.remindersSubtitle,
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SoftPalette.primary,
              ),
            )
          : Switch(
              value: enabled,
              onChanged: _onChanged,
              activeThumbColor: SoftPalette.primary,
        activeTrackColor: Colors.grey[100],
            ),
    );
  }
}

/// Prayer-notification sound picker. Tapping opens a sheet with two choices —
/// system default or the azan — and re-schedules today's reminders so the new
/// sound applies to the pending notifications right away.
class _AzanRow extends ConsumerStatefulWidget {
  const _AzanRow();

  @override
  ConsumerState<_AzanRow> createState() => _AzanRowState();
}

class _AzanRowState extends ConsumerState<_AzanRow> {
  Future<void> _select(bool azan) async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setAzanNotificationEnabled(azan);

    final settings = ref.read(settingsControllerProvider);
    if (settings.notificationsEnabled ?? false) {
      final prayerTimes = ref.read(prayerTimesProvider).valueOrNull;
      if (prayerTimes != null) {
        await ref
            .read(notificationRepositoryProvider)
            .scheduleTodayPrayerNotifications(
              prayerTimes,
              disabledKeys: settings.disabledPrayerKeys,
              language: AppLanguage.fromCode(settings.appLanguageCode),
              azan: azan,
            );
      }
    }
  }

  Future<void> _openSheet() async {
    final current = ref.read(settingsControllerProvider).azanNotificationSound;
    final selected = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AzanSoundSheet(azanSelected: current),
    );
    if (selected != null && selected != current) {
      await _select(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final azan = ref.watch(
      settingsControllerProvider.select((s) => s.azanNotificationSound),
    );

    return _SettingsRow(
      icon: Iconsax.volume_high,
      iconColor: SoftPalette.primary,
      title: context.s.azanSound,
      subtitle: azan ? context.s.azanSoundAzan : context.s.azanSoundSystem,
      onTap: _openSheet,
      trailing: const Icon(
        Iconsax.arrow_right_3,
        color: SoftPalette.textSecondary,
        size: 18,
      ),
    );
  }
}

/// Which preview, if any, is currently sounding in the picker sheet.
enum _AzanPreview { none, system, azan }

/// Bottom sheet letting the user pick the prayer-notification sound. Each option
/// has a play button to hear it first. Pops `true` for azan, `false` for the
/// system tone, or null when dismissed.
class _AzanSoundSheet extends StatefulWidget {
  const _AzanSoundSheet({required this.azanSelected});

  final bool azanSelected;

  @override
  State<_AzanSoundSheet> createState() => _AzanSoundSheetState();
}

class _AzanSoundSheetState extends State<_AzanSoundSheet> {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  final FlutterRingtonePlayer _ringtone = FlutterRingtonePlayer();
  _AzanPreview _playing = _AzanPreview.none;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((st) {
      if (st.processingState == ja.ProcessingState.completed && mounted) {
        setState(() => _playing = _AzanPreview.none);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    unawaited(_ringtone.stop());
    super.dispose();
  }

  Future<void> _previewAzan() async {
    unawaited(_ringtone.stop());
    if (_playing == _AzanPreview.azan) {
      await _player.stop();
      if (mounted) setState(() => _playing = _AzanPreview.none);
      return;
    }
    setState(() => _playing = _AzanPreview.azan);
    try {
      // Route through the playback ("music") audio category so the azan is
      // audible even with the iOS silent switch on — otherwise AVAudioPlayer
      // stays muted while system sounds still play.
      if (Platform.isIOS || Platform.isAndroid) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        await session.setActive(true);
      }
      await _player.setVolume(1.0);
      // just_audio_background is active app-wide, so every source needs a
      // MediaItem tag — a plain setAsset() would throw and swallow silently.
      await _player.setAudioSource(
        ja.AudioSource.asset(
          'assets/audio/azan.mp3',
          tag: MediaItem(id: 'azan-preview', title: 'Азан'),
        ),
      );
      await _player.seek(Duration.zero);
      unawaited(_player.play());
    } catch (_) {
      if (mounted) setState(() => _playing = _AzanPreview.none);
    }
  }

  Future<void> _previewSystem() async {
    await _player.stop();
    setState(() => _playing = _AzanPreview.system);
    unawaited(_ringtone.playNotification());
    // The ringtone gives no completion callback and is short — clear the active
    // state after a moment so the play icon returns.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted && _playing == _AzanPreview.system) {
      setState(() => _playing = _AzanPreview.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      decoration: const BoxDecoration(
        color: SoftPalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SoftPalette.track,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                s.azanSound,
                style: AppTextStyles.title.copyWith(
                  color: SoftPalette.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _AzanSoundOption(
                label: s.azanSoundSystem,
                selected: !widget.azanSelected,
                playing: _playing == _AzanPreview.system,
                onPreview: _previewSystem,
                onSelect: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 10),
              _AzanSoundOption(
                label: s.azanSoundAzan,
                selected: widget.azanSelected,
                playing: _playing == _AzanPreview.azan,
                onPreview: _previewAzan,
                onSelect: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AzanSoundOption extends StatelessWidget {
  const _AzanSoundOption({
    required this.label,
    required this.selected,
    required this.playing,
    required this.onPreview,
    required this.onSelect,
  });

  final String label;
  final bool selected;
  final bool playing;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SoftPalette.primary.withValues(alpha: 0.10)
          : SoftPalette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? SoftPalette.primary : SoftPalette.track,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Preview button — its own tap target so hearing the sound never
              // also selects the option.
              GestureDetector(
                onTap: onPreview,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftPalette.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playing ? Iconsax.pause : Iconsax.play,
                    size: 18,
                    color: SoftPalette.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: SoftPalette.textDark,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Iconsax.tick_circle,
                  size: 22,
                  color: SoftPalette.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepentanceToneRow extends ConsumerStatefulWidget {
  const _RepentanceToneRow();

  @override
  ConsumerState<_RepentanceToneRow> createState() => _RepentanceToneRowState();
}

class _RepentanceToneRowState extends ConsumerState<_RepentanceToneRow> {
  bool _busy = false;

  Future<void> _onChanged(RepentanceReminderTone tone) async {
    if (_busy) return;
    setState(() => _busy = true);
    final controller = ref.read(settingsControllerProvider.notifier);
    await controller.setRepentanceReminderTone(tone);

    final settings = ref.read(settingsControllerProvider);
    if (settings.notificationsEnabled ?? false) {
      await ref
          .read(notificationRepositoryProvider)
          .scheduleDailyRepentanceReminders(
            tone: tone,
            language: AppLanguage.fromCode(settings.appLanguageCode),
          );
    }

    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final tone = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.repentanceReminderTone,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.message_question, color: _gold, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.s.repentanceTone,
                      style: AppTextStyles.body.copyWith(
                        color: SoftPalette.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.s.repentanceToneSubtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: SoftPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SoftPalette.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ReminderToneSwitcher(current: tone, onChanged: _onChanged),
        ],
      ),
    );
  }
}

class _ReminderToneSwitcher extends StatelessWidget {
  const _ReminderToneSwitcher({required this.current, required this.onChanged});

  final RepentanceReminderTone current;
  final ValueChanged<RepentanceReminderTone> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, RepentanceReminderTone tone) {
      final selected = current == tone;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(tone),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? SoftPalette.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
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
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          chip(context.s.gentle, RepentanceReminderTone.gentle),
          const SizedBox(width: 4),
          chip(context.s.firm, RepentanceReminderTone.firm),
        ],
      ),
    );
  }
}

class _WidgetQuizRow extends ConsumerWidget {
  const _WidgetQuizRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latin = ref.watch(
      settingsControllerProvider.select((s) => s.widgetQuizNameLatin),
    );
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SoftPalette.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.widgets_rounded,
                  color: SoftPalette.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.widgetQuizName,
                      style: AppTextStyles.body.copyWith(
                        color: SoftPalette.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.widgetQuizNameSubtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: SoftPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WidgetNameModeSwitcher(
            latin: latin,
            onChanged: (value) => ref
                .read(settingsControllerProvider.notifier)
                .setWidgetQuizLatin(value),
          ),
        ],
      ),
    );
  }
}

class _WidgetNameModeSwitcher extends StatelessWidget {
  const _WidgetNameModeSwitcher({
    required this.latin,
    required this.onChanged,
  });

  final bool latin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool value) {
      final selected = latin == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? SoftPalette.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
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
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          chip(context.s.widgetArabic, false),
          const SizedBox(width: 4),
          chip(context.s.widgetLatin, true),
        ],
      ),
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
      icon: Iconsax.music_play,
      iconColor: SoftPalette.primary,
      title: context.s.downloadedAyahs,
      subtitle: _bytes == null ? context.s.counting : _format(_bytes!),
      trailing: _clearing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SoftPalette.primary,
              ),
            )
          : TextButton(
              onPressed: () async {
                setState(() => _clearing = true);
                await ref.read(audioRepositoryProvider).clearAll();
                await _refresh();
                if (mounted) setState(() => _clearing = false);
              },
              child: Text(
                context.s.clear,
                style: const TextStyle(
                  color: _danger,
                  fontWeight: FontWeight.w700,
                ),
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
          iconColor: SoftPalette.textSecondary,
          title: context.s.version,
          trailing: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: SoftPalette.textSecondary,
            ),
          ),
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
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: SoftPalette.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: SoftPalette.textSecondary,
                      ),
                    ),
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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 16,
      color: SoftPalette.track,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: AppTextStyles.overline.copyWith(
          color: SoftPalette.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: SoftPalette.softShadow(),
      ),
      child: Material(
        color: SoftPalette.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
