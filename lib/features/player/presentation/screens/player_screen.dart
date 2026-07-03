import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../../data/models/ayah.dart';
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
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 550),
                  // Force every (incoming/outgoing) child to fill the sheet, so
                  // the video covers the whole background instead of shrinking
                  // to its intrinsic size.
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      ?currentChild,
                    ],
                  ),
                  child: (ambianceScene != null && ambianceVideo != null)
                      ? _AmbianceVideo(key: ValueKey(ambianceScene), controller: ambianceVideo)
                      : const SizedBox.shrink(key: ValueKey('no-ambiance')),
                ),
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
                    : _PlayerContent(state: playerState),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerContent extends ConsumerWidget {
  const _PlayerContent({required this.state});

  final PlayerViewState state;

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
                      style: AppTextStyles.displayTitle.copyWith(color: primaryText, fontSize: 28),
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
        const SizedBox(height: 12),
        Expanded(
          child: displayMode == DisplayMode.none
              ? const SizedBox.shrink()
              : _AyahCarousel(
                  state: state,
                  displayMode: displayMode,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
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
                  isFavorite ? Iconsax.star1 : Iconsax.star,
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
              Builder(
                builder: (btnContext) => _SpeedButton(
                  speed: state.speed,
                  onTap: () => _showSpeedMenu(btnContext, ref, state.speed),
                  color: primaryText,
                ),
              ),
              IconButton(
                onPressed: controller.previous,
                icon: Icon(Iconsax.previous, size: 34, color: primaryText),
              ),
              _PlayPauseButton(isPlaying: state.isPlaying, isBuffering: state.isBuffering, onTap: controller.togglePlayPause),
              IconButton(
                onPressed: controller.next,
                icon: Icon(Iconsax.next, size: 34, color: primaryText),
              ),
              Builder(
                builder: (btnContext) => _LoopButton(
                  loop: state.loop,
                  onTap: () => _showLoopMenu(btnContext, ref, state.loop),
                  color: primaryText,
                ),
              ),
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
              Builder(
                builder: (btnContext) => IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showSoundMenu(btnContext, ref),
                  icon: Icon(Iconsax.volume_high, color: secondaryText, size: 20),
                ),
              ),
              Builder(
                builder: (btnContext) => IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showDisplayModeMenu(btnContext, ref, displayMode),
                  icon: Icon(Iconsax.translate, color: secondaryText, size: 20),
                ),
              ),
              const _AmbianceToggle(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => AyahListSheet.show(context),
                icon: Icon(Iconsax.menu_1, color: secondaryText, size: 20),
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
                  ? const Icon(Iconsax.tick_circle, size: 18, color: SoftPalette.primary)
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
    color: SoftPalette.surface.withValues(alpha: 0.82),
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

/// Small popover above the speed button for picking the playback speed.
Future<void> _showSpeedMenu(BuildContext context, WidgetRef ref, double current) async {
  final button = context.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  final selected = await showMenu<double>(
    context: context,
    position: position,
    color: SoftPalette.surface.withValues(alpha: 0.82),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    items: [
      PopupMenuItem<double>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in speeds)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).pop(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    '${s}x',
                    style: AppTextStyles.body.copyWith(
                      color: current == s ? SoftPalette.primary : SoftPalette.textDark,
                      fontWeight: current == s ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  if (selected != null) {
    ref.read(playerControllerProvider.notifier).setSpeed(selected);
  }
}

/// Small popover above the loop button for picking the ayah repeat mode.
Future<void> _showLoopMenu(BuildContext context, WidgetRef ref, LoopSettings current) async {
  final button = context.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  bool matches(LoopSettings loop) =>
      current.enabled == loop.enabled &&
      current.infinite == loop.infinite &&
      (loop.infinite || !loop.enabled || current.repeatCount == loop.repeatCount);

  PopupMenuItem<LoopSettings> item(LoopSettings loop, String label) => PopupMenuItem<LoopSettings>(
        value: loop,
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: matches(loop)
                  ? const Icon(Iconsax.tick_circle, size: 18, color: SoftPalette.primary)
                  : null,
            ),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: SoftPalette.textDark,
                fontWeight: matches(loop) ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  final selected = await showMenu<LoopSettings>(
    context: context,
    position: position,
    color: SoftPalette.surface.withValues(alpha: 0.82),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    items: [
      item(LoopSettings.off, 'Выключено'),
      item(const LoopSettings(enabled: true, repeatCount: 3), 'Повторить 3 раза'),
      item(const LoopSettings(enabled: true, repeatCount: 5), 'Повторить 5 раз'),
      item(const LoopSettings(enabled: true, repeatCount: 10), 'Повторить 10 раз'),
      item(const LoopSettings(enabled: true, infinite: true), 'Бесконечно'),
    ],
  );

  if (selected != null) {
    ref.read(playerControllerProvider.notifier).setLoop(selected);
  }
}

/// Renders a single ambient video controller, scaled to cover. Kept as its own
/// keyed widget so [AnimatedSwitcher] can crossfade between scenes.
class _AmbianceVideo extends StatelessWidget {
  const _AmbianceVideo({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
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
            child: VideoPlayer(controller),
          ),
        );
      },
    );
  }
}

/// Vertical carousel of every ayah in the surah: the centered (current) ayah
/// is large and bright, the ones above/below shrink and fade the further they
/// are from the centre. Stays in sync with playback and lets the user flick
/// to another ayah to jump there.
class _AyahCarousel extends ConsumerStatefulWidget {
  const _AyahCarousel({
    required this.state,
    required this.displayMode,
    required this.primaryText,
    required this.secondaryText,
  });

  final PlayerViewState state;
  final DisplayMode displayMode;
  final Color primaryText;
  final Color secondaryText;

  @override
  ConsumerState<_AyahCarousel> createState() => _AyahCarouselState();
}

class _AyahCarouselState extends ConsumerState<_AyahCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.6, initialPage: widget.state.currentIndex);
  }

  @override
  void didUpdateWidget(covariant _AyahCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow playback: animate to the ayah that just became current.
    if (oldWidget.state.currentIndex != widget.state.currentIndex && _controller.hasClients) {
      _controller.animateToPage(
        widget.state.currentIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ayahs = widget.state.ayahs;
    final maxWidth = MediaQuery.of(context).size.width - 56;

    return PageView.builder(
      controller: _controller,
      scrollDirection: Axis.vertical,
      itemCount: ayahs.length,
      onPageChanged: (i) {
        // Only react to user-driven changes (a programmatic follow lands exactly
        // on the current index, so this is a no-op then).
        if (i != widget.state.currentIndex) {
          ref.read(playerControllerProvider.notifier).jumpToAyah(ayahs[i].numberInSurah);
        }
      },
      itemBuilder: (context, i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final page = _controller.hasClients && _controller.position.haveDimensions
                ? (_controller.page ?? widget.state.currentIndex.toDouble())
                : widget.state.currentIndex.toDouble();
            final diff = (i - page).abs();
            final scale = (1.0 - diff * 0.26).clamp(0.55, 1.0);
            final opacity = (1.0 - diff * 0.5).clamp(0.2, 1.0);
            return Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: _ayahText(ayahs[i], i == widget.state.currentIndex),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _ayahText(Ayah ayah, bool isCurrent) {
    final mode = widget.displayMode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mode == DisplayMode.arabic || mode == DisplayMode.both)
          Text(
            '${ayah.textArabic} ﴿${ayah.numberInSurah}﴾',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.arabic.copyWith(color: widget.primaryText),
          ),
        if (mode == DisplayMode.both) const SizedBox(height: 10),
        if ((mode == DisplayMode.transliteration || mode == DisplayMode.both) && ayah.textTransliteration != null)
          Text(
            ayah.textTransliteration!,
            textAlign: TextAlign.center,
            style: AppTextStyles.transliteration.copyWith(color: widget.secondaryText),
          ),
      ],
    );
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
                isPlaying ? Iconsax.pause : Iconsax.play,
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
          Iconsax.repeate_one,
          size: 26,
          color: loop.enabled ? SoftPalette.primary : color,
        ),
      ),
    );
  }
}

/// Opens the scene picker to switch the silent looping background video
/// between the available ambiences (or turn it off).
class _AmbianceToggle extends ConsumerWidget {
  const _AmbianceToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(ambianceControllerProvider);
    return Builder(
      builder: (btnContext) => IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Фон',
        onPressed: () => _showAmbianceMenu(btnContext, ref, active),
        icon: Icon(
          active?.icon ?? Iconsax.gallery,
          color: active != null ? Colors.white : SoftPalette.textDark,
          size: 20,
        ),
      ),
    );
  }
}

/// Small popover above the background button for picking the ambient scene.
Future<void> _showAmbianceMenu(BuildContext context, WidgetRef ref, AmbianceScene? current) async {
  final button = context.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  final notifier = ref.read(ambianceControllerProvider.notifier);

  PopupMenuItem<void> row(IconData icon, String label, bool selected, VoidCallback onTap) => PopupMenuItem<void>(
        height: 44,
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? SoftPalette.primary : SoftPalette.textDark),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: SoftPalette.textDark,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  await showMenu<void>(
    context: context,
    position: position,
    color: SoftPalette.surface.withValues(alpha: 0.82),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    items: [
      for (final scene in AmbianceScene.values)
        row(scene.icon, scene.label, current == scene, () => notifier.select(scene)),
      row(Iconsax.video_slash, 'Выключить', current == null, notifier.stop),
    ],
  );
}

/// Popover above the sound button with two volume sliders: one for the Quran
/// recitation, one for the ambient noise track.
Future<void> _showSoundMenu(BuildContext context, WidgetRef ref) async {
  final button = context.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  await showMenu<void>(
    context: context,
    position: position,
    color: SoftPalette.surface.withValues(alpha: 0.82),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    items: const [
      PopupMenuItem<void>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: _SoundControls(),
      ),
    ],
  );
}

/// The two volume rows inside the sound popover. Keeps local slider values so
/// dragging stays smooth regardless of the surrounding popup route rebuilds.
class _SoundControls extends ConsumerStatefulWidget {
  const _SoundControls();

  @override
  ConsumerState<_SoundControls> createState() => _SoundControlsState();
}

class _SoundControlsState extends ConsumerState<_SoundControls> {
  late double _quran;
  late double _noise;

  @override
  void initState() {
    super.initState();
    _quran = ref.read(playerControllerProvider)?.volume ?? 1.0;
    _noise = ref.read(ambianceNoiseVolumeProvider);
  }

  Widget _slider(IconData icon, String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: SoftPalette.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: SoftPalette.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            activeTrackColor: SoftPalette.primary,
            inactiveTrackColor: SoftPalette.track,
            thumbColor: SoftPalette.primary,
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _slider(Iconsax.microphone_2, 'Коран', _quran, (v) {
              setState(() => _quran = v);
              ref.read(playerControllerProvider.notifier).setVolume(v);
            }),
            _slider(Iconsax.wind, 'Фоновый шум', _noise, (v) {
              setState(() => _noise = v);
              ref.read(ambianceNoiseVolumeProvider.notifier).state = v;
            }),
          ],
        ),
      ),
    );
  }
}
