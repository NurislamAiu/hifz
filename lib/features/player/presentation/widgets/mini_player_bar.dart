import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/soft_palette.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/player_provider.dart';
import '../screens/player_screen.dart';

/// A floating "now playing" island above the bottom nav bar — the same
/// persistent-mini-player language Apple Music/Spotify use, so playback stays
/// reachable after the full player sheet is swiped away.
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, alignment: Alignment.topCenter, child: child),
      ),
      child: state == null ? const SizedBox.shrink(key: ValueKey('empty')) : _MiniPlayerContent(state: state),
    );
  }
}

class _MiniPlayerContent extends ConsumerWidget {
  const _MiniPlayerContent({required this.state});

  final PlayerViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final reciter = ref.watch(selectedReciterProvider);
    final ayah = state.currentAyah;

    return Padding(
      key: const ValueKey('mini-player'),
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => PlayerScreen.expand(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: SoftPalette.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: SoftPalette.softShadow(opacity: 0.14, y: 8, blur: 20),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: SoftPalette.light, shape: BoxShape.circle),
                child: const Icon(FlutterIslamicIcons.muslim, color: SoftPalette.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.surahNameTransliteration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SoftPalette.textDark,
                      ),
                    ),
                    Text(
                      'Аят ${ayah.numberInSurah} • ${reciter.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: SoftPalette.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: controller.togglePlayPause,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftPalette.primary,
                    shape: BoxShape.circle,
                    boxShadow: SoftPalette.softShadow(opacity: 0.16, y: 4, blur: 10),
                  ),
                  child: Icon(
                    state.isPlaying ? Iconsax.pause : Iconsax.play,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.next,
                icon: const Icon(
                  Iconsax.next,
                  color: SoftPalette.textSecondary,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
