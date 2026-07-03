import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// A background "scene" that plays as a silent, looping video mixed behind
/// (not instead of) the Quran recitation, which keeps playing through its own
/// separate player. Ambient sound is intentionally disabled for now.
enum AmbianceScene {
  rain(label: 'Дождь', videoAsset: 'assets/ambiance/rain/rain_video.mp4');

  const AmbianceScene({required this.label, required this.videoAsset});

  final String label;
  final String videoAsset;
}

/// Manages the optional background video loop. Only one scene can play at a
/// time; toggling the active scene off stops it.
class AmbianceController extends Notifier<AmbianceScene?> {
  VideoPlayerController? _videoController;

  VideoPlayerController? get videoController => _videoController;

  @override
  AmbianceScene? build() {
    ref.onDispose(() {
      _videoController?.removeListener(_resumeIfPaused);
      _videoController?.dispose();
    });
    return null;
  }

  Future<void> toggle(AmbianceScene scene) async {
    if (state == scene) {
      await _stop();
      return;
    }
    await _stop();

    // mixWithOthers is critical on iOS: without it, just_audio activating the
    // audio session (the Quran recitation itself) pauses the muted AVPlayer and
    // the video never renders a frame.
    final video = VideoPlayerController.asset(
      scene.videoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await video.initialize();
      await video.setLooping(true);
      await video.setVolume(0);
      await video.play();
    } catch (e, st) {
      debugPrint('[Ambiance] video init failed for ${scene.videoAsset}: $e\n$st');
      await video.dispose();
      return;
    }
    _videoController = video;

    // The recitation player can activate the iOS audio session *after* we start
    // playing, which pauses the muted AVPlayer. Keep nudging it back into play
    // whenever it stops while the scene is still meant to be active.
    video.addListener(_resumeIfPaused);

    state = scene;
  }

  void _resumeIfPaused() {
    final video = _videoController;
    if (video == null) return;
    final value = video.value;
    if (value.isInitialized && !value.isPlaying && !value.hasError) {
      video.play();
    }
  }

  Future<void> _stop() async {
    _videoController?.removeListener(_resumeIfPaused);
    await _videoController?.pause();
    await _videoController?.dispose();
    _videoController = null;
    state = null;
  }
}

final ambianceControllerProvider = NotifierProvider<AmbianceController, AmbianceScene?>(
  AmbianceController.new,
);
