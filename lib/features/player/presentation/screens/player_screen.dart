import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../../data/models/display_mode.dart';
import '../../../../data/models/favorite_item.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/ambiance_provider.dart';
import '../../providers/player_provider.dart';
import '../widgets/ayah_list_sheet.dart';
import '../widgets/player_progress_bar.dart';

const _ayahAccent = Color(0xFFE0A83F);

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, this.surahNumber, this.startAyah});

  final int? surahNumber;
  final int? startAyah;

  static Future<void> open(BuildContext context, {required int surahNumber, required int startAyah}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerScreen(surahNumber: surahNumber, startAyah: startAyah),
    );
  }

  /// Re-opens the sheet for whatever is already loaded/playing — used by the
  /// mini-player island, so tapping it never restarts playback.
  static Future<void> expand(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlayerScreen(),
    );
  }

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    final surahNumber = widget.surahNumber;
    if (surahNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(playerControllerProvider.notifier).loadSurah(surahNumber, startAyah: widget.startAyah ?? 1);
      });
    }
  }

  void _showLoopMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SoftPalette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        final controller = ref.read(playerControllerProvider.notifier);
        Widget option(String label, LoopSettings loop) => ListTile(
              title: Text(label, style: AppTextStyles.body.copyWith(color: SoftPalette.textDark)),
              onTap: () {
                controller.setLoop(loop);
                Navigator.of(sheetContext).pop();
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text('Зациклить аят', style: AppTextStyles.overline.copyWith(color: SoftPalette.textSecondary)),
              const SizedBox(height: 4),
              option('Выключено', LoopSettings.off),
              option('Повторить 3 раза', const LoopSettings(enabled: true, repeatCount: 3)),
              option('Повторить 5 раз', const LoopSettings(enabled: true, repeatCount: 5)),
              option('Повторить 10 раз', const LoopSettings(enabled: true, repeatCount: 10)),
              option('Бесконечно', const LoopSettings(enabled: true, infinite: true)),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  } 

  void _showSpeedMenu(BuildContext context) {
    final controller = ref.read(playerControllerProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: SoftPalette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Скорость воспроизведения',
                style: AppTextStyles.overline.copyWith(color: SoftPalette.textSecondary),
              ),
              for (final s in speeds)
                ListTile(
                  title: Text('${s}x', style: AppTextStyles.body.copyWith(color: SoftPalette.textDark)),
                  onTap: () {
                    controller.setSpeed(s);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final ambianceScene = ref.watch(ambianceControllerProvider);
    final ambianceVideo = ref.read(ambianceControllerProvider.notifier).videoController;

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: const BoxDecoration(
          color: SoftPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ambianceScene != null && ambianceVideo != null)
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: ambianceVideo,
                  builder: (context, video, _) {
                    if (!video.isInitialized || video.size.width <= 0 || video.size.height <= 0) {
                      return const SizedBox.shrink();
                    }
                    return FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: video.size.width,
                        height: video.size.height,
                        child: VideoPlayer(ambianceVideo),
                      ),
                    );
                  },
                ),
              if (ambianceScene != null)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(color: SoftPalette.background.withValues(alpha: 0.42)),
                ),
              SafeArea(
                bottom: false,
                child: playerState == null
                    ? const Center(child: CircularProgressIndicator(color: SoftPalette.primary))
                    : _PlayerContent(
                        state: playerState,
                        onShowLoopMenu: () => _showLoopMenu(context),
                        onShowSpeedMenu: () => _showSpeedMenu(context),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerContent extends ConsumerWidget {
  const _PlayerContent({required this.state, required this.onShowLoopMenu, required this.onShowSpeedMenu});

  final PlayerViewState state;
  final VoidCallback onShowLoopMenu;
  final VoidCallback onShowSpeedMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final reciter = ref.watch(selectedReciterProvider);
    final displayMode = ref.watch(settingsControllerProvider).displayMode;
    final ayah = state.currentAyah;

    final isFavorite = ref.watch(favoritesControllerProvider.select((list) => list.any(
          (f) => f.type == FavoriteType.ayah && f.surahNumber == ayah.surahNumber && f.ayahNumberInSurah == ayah.numberInSurah,
        )));

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(color: SoftPalette.track, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: SoftPalette.light,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Аят ${ayah.numberInSurah} из ${state.ayahs.length}',
            style: AppTextStyles.caption.copyWith(
              color: SoftPalette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Text(
                state.surahNameTransliteration,
                textAlign: TextAlign.center,
                style: AppTextStyles.displayTitle.copyWith(color: SoftPalette.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                state.surahNameArabic,
                textAlign: TextAlign.center,
                style: AppTextStyles.arabic.copyWith(
                  fontSize: 22,
                  height: 1.2,
                  color: SoftPalette.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                if (displayMode != DisplayMode.transliteration)
                  Text(
                    '${ayah.textArabic} ﴿${ayah.numberInSurah}﴾',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.arabic.copyWith(color: SoftPalette.textDark),
                  ),
                if (displayMode == DisplayMode.both) const SizedBox(height: 12),
                if (displayMode != DisplayMode.arabic && ayah.textTransliteration != null)
                  Text(
                    ayah.textTransliteration!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.transliteration.copyWith(color: SoftPalette.textSecondary),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              const _ReciterAvatar(),
              const SizedBox(width: 12),
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
                    ),
                    Text(
                      reciter.nameArabic,
                      style: AppTextStyles.caption.copyWith(
                        fontFamily: AppTextStyles.arabicFontFamily,
                        color: SoftPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.read(favoritesControllerProvider.notifier).toggleAyah(ayah.surahNumber, ayah.numberInSurah),
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorite ? _ayahAccent : SoftPalette.textSecondary,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SpeedButton(speed: state.speed, onTap: onShowSpeedMenu),
              IconButton(
                onPressed: controller.previous,
                icon: const Icon(Icons.skip_previous_rounded, size: 34, color: SoftPalette.textDark),
              ),
              _PlayPauseButton(isPlaying: state.isPlaying, isBuffering: state.isBuffering, onTap: controller.togglePlayPause),
              IconButton(
                onPressed: controller.next,
                icon: const Icon(Icons.skip_next_rounded, size: 34, color: SoftPalette.textDark),
              ),
              _LoopButton(loop: state.loop, onTap: onShowLoopMenu),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: PlayerProgressBar(
            position: state.position,
            duration: state.duration,
            onSeek: controller.seek,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.volume_up_rounded, color: SoftPalette.textSecondary, size: 20),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  final next = switch (displayMode) {
                    DisplayMode.arabic => DisplayMode.transliteration,
                    DisplayMode.transliteration => DisplayMode.both,
                    DisplayMode.both => DisplayMode.arabic,
                  };
                  ref.read(settingsControllerProvider.notifier).setDisplayMode(next);
                },
                icon: const Icon(Icons.translate_rounded, color: SoftPalette.textSecondary, size: 20),
              ),
              _AmbianceToggle(scene: AmbianceScene.rain),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => AyahListSheet.show(context),
                icon: const Icon(Icons.format_list_bulleted_rounded, color: SoftPalette.textSecondary, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReciterAvatar extends StatelessWidget {
  const _ReciterAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(color: SoftPalette.light, shape: BoxShape.circle),
      child: const Icon(FlutterIslamicIcons.muslim, color: SoftPalette.primary, size: 22),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.speed, required this.onTap});
  final double speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          '${speed}x',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: SoftPalette.textDark),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPlaying, required this.isBuffering, required this.onTap});
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBuffering ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: SoftPalette.primary,
          shape: BoxShape.circle,
          boxShadow: SoftPalette.softShadow(opacity: 0.24, y: 8, blur: 18),
        ),
        alignment: Alignment.center,
        child: isBuffering
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 38,
                color: Colors.white,
              ),
      ),
    );
  }
}

class _LoopButton extends StatelessWidget {
  const _LoopButton({required this.loop, required this.onTap});
  final LoopSettings loop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.repeat_one_rounded,
          size: 26,
          color: loop.enabled ? SoftPalette.primary : SoftPalette.textDark,
        ),
      ),
    );
  }
}

/// Toggles a looping ambient background (silent video + ambient sound track,
/// mixed alongside the Quran recitation) on and off.
class _AmbianceToggle extends ConsumerWidget {
  const _AmbianceToggle({required this.scene});
  final AmbianceScene scene;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(ambianceControllerProvider) == scene;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: scene.label,
      onPressed: () => ref.read(ambianceControllerProvider.notifier).toggle(scene),
      icon: Icon(
        Icons.water_drop_rounded,
        color: active ? SoftPalette.primary : SoftPalette.textSecondary,
        size: 20,
      ),
    );
  }
}
