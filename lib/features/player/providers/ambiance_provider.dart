import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'player_provider.dart';

/// A background "scene": a silent looping video plus a looping ambient sound
/// (white noise — e.g. crackling fire, rain, birds, wind) mixed behind the
/// Quran recitation, which keeps playing through its own separate player.
enum AmbianceScene {
  fire(
    label: 'Огонь',
    icon: Iconsax.candle,
    videoAsset: 'assets/ambiance/fire/fire_video.mp4',
    audioAsset: 'assets/ambiance/fire/fire_audio.mp3',
  ),
  rain(
    label: 'Дождь',
    icon: Iconsax.drop,
    videoAsset: 'assets/ambiance/rain/rain_video.mp4',
    audioAsset: 'assets/ambiance/rain/rain_audio.mp3',
  ),
  bird(
    label: 'Птица',
    icon: Iconsax.tree,
    videoAsset: 'assets/ambiance/bird/bird_video.mp4',
    audioAsset: 'assets/ambiance/bird/bird_audio.mp3',
  ),
  wind(
    label: 'Ветер',
    icon: Iconsax.wind,
    videoAsset: 'assets/ambiance/wind/wind_video.mp4',
    audioAsset: 'assets/ambiance/wind/wind_audio.mp3',
  );

  const AmbianceScene({
    required this.label,
    required this.icon,
    required this.videoAsset,
    required this.audioAsset,
  });

  final String label;
  final IconData icon;
  final String videoAsset;
  final String audioAsset;
}

/// Volume (0..1) of the ambient noise track, independent of the Quran volume.
final ambianceNoiseVolumeProvider = StateProvider<double>((ref) => 0.6);

/// Manages the optional background video loop plus its ambient sound. Only one
/// scene can play at a time. The ambient sound is chained to the recitation:
/// it plays/pauses together with the Quran player.
class AmbianceController extends Notifier<AmbianceScene?> {
  VideoPlayerController? _videoController;
  VideoPlayerController? _soundController;

  /// Bumped on every switch/stop so a slower, superseded [select] (e.g. the
  /// user tapping a second scene while the first is still initializing) can
  /// detect it lost the race and discard its half-built players.
  int _generation = 0;

  VideoPlayerController? get videoController => _videoController;

  @override
  AmbianceScene? build() {
    // Keep the ambient noise level in sync with its slider.
    ref.listen(
      ambianceNoiseVolumeProvider,
      (_, next) => _soundController?.setVolume(next),
    );
    // Chain the whole ambience (video + noise) to the recitation's play/pause
    // state (only react when it actually flips, not on every position tick).
    ref.listen(playerControllerProvider, (prev, next) {
      final was = prev?.isPlaying ?? false;
      final now = next?.isPlaying ?? false;
      if (was != now) _syncPlayback(now);
    });

    ref.onDispose(() {
      _videoController?.removeListener(_resumeIfPaused);
      _videoController?.dispose();
      _soundController?.dispose();
    });
    return null;
  }

  Future<void> toggle(AmbianceScene scene) async {
    if (state == scene) {
      await stop();
      return;
    }
    await select(scene);
  }

  /// Turns the ambient background off entirely, fading the current scene out.
  Future<void> stop() async {
    _generation++;
    final prevVideo = _videoController;
    final prevSound = _soundController;
    _videoController = null;
    _soundController = null;
    state = null;
    _retire(prevVideo, prevSound);
  }

  /// Switches to [scene], starting its silent looping video and ambient sound.
  /// If it is already the active scene this is a no-op.
  ///
  /// The new scene is fully built *before* the old one is dropped, so the
  /// outgoing scene keeps rendering (letting the UI crossfade) instead of
  /// flashing the empty background, and the previous players are retired with a
  /// short delay so the fade can finish.
  Future<void> select(AmbianceScene scene) async {
    if (state == scene) return;
    final gen = ++_generation;

    // mixWithOthers is critical on iOS: without it, just_audio activating the
    // audio session (the Quran recitation itself) pauses the muted AVPlayer and
    // the video never renders a frame.
    final video = VideoPlayerController.asset(
      scene.videoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    final quranPlaying = ref.read(playerControllerProvider)?.isPlaying ?? false;
    try {
      await video.initialize();
      await video.setLooping(true);
      await video.setVolume(0);
      // Show the first frame either way; only run it if the recitation is on.
      await video.play();
      if (!quranPlaying) await video.pause();
    } catch (e, st) {
      debugPrint(
        '[Ambiance] video init failed for ${scene.videoAsset}: $e\n$st',
      );
      await video.dispose();
      return;
    }
    // A newer switch happened while this one was initializing — discard ours.
    if (gen != _generation) {
      await video.dispose();
      return;
    }

    // Keep ambience out of just_audio_background. That plugin supports only
    // one just_audio player, so the Quran recitation owns system controls.
    VideoPlayerController? sound;
    try {
      sound = VideoPlayerController.asset(
        scene.audioAsset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await sound.initialize();
      await sound.setLooping(true);
      await sound.setVolume(ref.read(ambianceNoiseVolumeProvider));
      if (quranPlaying) {
        await sound.play();
      }
    } catch (e, st) {
      debugPrint(
        '[Ambiance] audio init failed for ${scene.audioAsset}: $e\n$st',
      );
      await sound?.dispose();
      sound = null;
    }
    if (gen != _generation) {
      await video.dispose();
      await sound?.dispose();
      return;
    }

    // Swap the new scene in and retire the outgoing one with a short fade-out.
    final prevVideo = _videoController;
    final prevSound = _soundController;

    _videoController = video;
    // The recitation player can activate the iOS audio session *after* we start
    // playing, which pauses the muted AVPlayer. Keep nudging it back into play
    // whenever it stops while the scene is still meant to be active.
    video.addListener(_resumeIfPaused);
    _soundController = sound;

    state = scene;

    _retire(prevVideo, prevSound);
  }

  /// Keeps the outgoing scene's players alive briefly so the UI crossfade can
  /// finish, then disposes them.
  void _retire(VideoPlayerController? video, VideoPlayerController? sound) {
    if (video == null && sound == null) return;
    video?.removeListener(_resumeIfPaused);
    sound?.pause();
    Future.delayed(const Duration(milliseconds: 750), () {
      video?.dispose();
      sound?.dispose();
    });
  }

  void _syncPlayback(bool playing) {
    if (state == null) return;
    if (playing) {
      _videoController?.play();
      _soundController?.play();
    } else {
      _videoController?.pause();
      _soundController?.pause();
    }
  }

  void _resumeIfPaused() {
    final video = _videoController;
    if (video == null) return;
    // Only fight iOS interruptions while the recitation itself is playing —
    // otherwise this would undo an intentional pause.
    final quranPlaying = ref.read(playerControllerProvider)?.isPlaying ?? false;
    if (!quranPlaying) return;
    final value = video.value;
    if (value.isInitialized && !value.isPlaying && !value.hasError) {
      video.play();
    }
  }
}

final ambianceControllerProvider =
    NotifierProvider<AmbianceController, AmbianceScene?>(
      AmbianceController.new,
    );
