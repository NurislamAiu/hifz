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
    final displayMode = ref.watch(settingsControllerProvider).displayMode;

    // "Ничего" hides all text and drops the blur/scrim so the raw video shows.
    final showScrim = displayMode != DisplayMode.none;

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: const BoxDecoration(
          color: SoftPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAliasWithSaveLayer,
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
              if (ambianceScene != null && showScrim)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.22),
                            Colors.black.withValues(alpha: 0.34),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
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

    // When the ambient video background is on, the sheet turns dark, so switch
    // text and controls to light colors for contrast.
    final onDark = ref.watch(ambianceControllerProvider) != null;
    final primaryText = onDark ? Colors.white : SoftPalette.textDark;
    final secondaryText = onDark ? Colors.white : SoftPalette.textDark;
    final accent = onDark ? Colors.white : SoftPalette.primary;

    final isFavorite = ref.watch(favoritesControllerProvider.select((list) => list.any(
          (f) => f.type == FavoriteType.ayah && f.surahNumber == ayah.surahNumber && f.ayahNumberInSurah == ayah.numberInSurah,
        )));

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: onDark ? Colors.white.withValues(alpha: 0.55) : SoftPalette.track,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.surahNameTransliteration,
                      style: AppTextStyles.displayTitle.copyWith(color: primaryText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.surahNameArabic,
                      style: AppTextStyles.arabic.copyWith(
                        fontSize: 20,
                        height: 1.2,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: onDark ? Colors.white.withValues(alpha: 0.16) : SoftPalette.light,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${ayah.numberInSurah}:${state.ayahs.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: onDark ? Colors.white : SoftPalette.primary,
                    fontWeight: FontWeight.w700,
                  ),
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
                if (displayMode == DisplayMode.arabic || displayMode == DisplayMode.both)
                  Text(
                    '${ayah.textArabic} ﴿${ayah.numberInSurah}﴾',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.arabic.copyWith(color: primaryText),
                  ),
                if (displayMode == DisplayMode.both) const SizedBox(height: 12),
                if ((displayMode == DisplayMode.transliteration || displayMode == DisplayMode.both) &&
                    ayah.textTransliteration != null)
                  Text(
                    ayah.textTransliteration!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.transliteration.copyWith(color: secondaryText),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              _ReciterAvatar(onDark: onDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reciter.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    Text(
                      reciter.nameArabic,
                      style: AppTextStyles.caption.copyWith(
                        fontFamily: AppTextStyles.arabicFontFamily,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.read(favoritesControllerProvider.notifier).toggleAyah(ayah.surahNumber, ayah.numberInSurah),
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorite ? _ayahAccent : secondaryText,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SpeedButton(speed: state.speed, onTap: onShowSpeedMenu, color: primaryText),
              IconButton(
                onPressed: controller.previous,
                icon: Icon(Icons.skip_previous_rounded, size: 34, color: primaryText),
              ),
              _PlayPauseButton(isPlaying: state.isPlaying, isBuffering: state.isBuffering, onTap: controller.togglePlayPause),
              IconButton(
                onPressed: controller.next,
                icon: Icon(Icons.skip_next_rounded, size: 34, color: primaryText),
              ),
              _LoopButton(loop: state.loop, onTap: onShowLoopMenu, color: primaryText),
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
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.volume_up_rounded, color: secondaryText, size: 20),
              Builder(
                builder: (btnContext) => IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showDisplayModeMenu(btnContext, ref, displayMode),
                  icon: Icon(Icons.translate_rounded, color: secondaryText, size: 20),
                ),
              ),
              _AmbianceToggle(scene: AmbianceScene.rain),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => AyahListSheet.show(context),
                icon: Icon(Icons.format_list_bulleted_rounded, color: secondaryText, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small popover ("island") shown above the translate button letting the user
/// pick what recitation text to display — or hide it entirely to reveal the
/// ambient video background.
Future<void> _showDisplayModeMenu(BuildContext context, WidgetRef ref, DisplayMode current) async {
  final button = context.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  PopupMenuItem<DisplayMode> item(DisplayMode mode, String label) => PopupMenuItem<DisplayMode>(
        value: mode,
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: current == mode
                  ? const Icon(Icons.check_rounded, size: 18, color: SoftPalette.primary)
                  : null,
            ),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: SoftPalette.textDark,
                fontWeight: current == mode ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  final selected = await showMenu<DisplayMode>(
    context: context,
    position: position,
    color: SoftPalette.surface,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    items: [
      item(DisplayMode.arabic, 'Арабский'),
      item(DisplayMode.both, 'Арабский + Транскрипция'),
      item(DisplayMode.transliteration, 'Транскрипция'),
      item(DisplayMode.none, 'Ничего'),
    ],
  );

  if (selected != null) {
    ref.read(settingsControllerProvider.notifier).setDisplayMode(selected);
  }
}

class _ReciterAvatar extends StatelessWidget {
  const _ReciterAvatar({required this.onDark});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.18) : SoftPalette.light,
        shape: BoxShape.circle,
      ),
      child: Icon(
        FlutterIslamicIcons.muslim,
        color: onDark ? Colors.white : SoftPalette.primary,
        size: 22,
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.speed, required this.onTap, required this.color});
  final double speed;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          '${speed}x',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: color),
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
  const _LoopButton({required this.loop, required this.onTap, required this.color});
  final LoopSettings loop;
  final VoidCallback onTap;
  final Color color;

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
          color: loop.enabled ? SoftPalette.primary : color,
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
        color: active ? Colors.white : SoftPalette.textDark,
        size: 20,
      ),
    );
  }
}
