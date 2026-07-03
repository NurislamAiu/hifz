import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../../data/models/ayah.dart';
import '../../../data/providers.dart';
import '../../settings/providers/settings_provider.dart';

class LoopSettings {
  final bool enabled;
  final bool infinite;
  final int repeatCount;

  const LoopSettings({this.enabled = false, this.infinite = false, this.repeatCount = 3});

  static const off = LoopSettings();
}

class PlayerViewState {
  final int surahNumber;
  final String surahNameTransliteration;
  final String surahNameArabic;
  final List<Ayah> ayahs;
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double speed;
  final LoopSettings loop;
  final int repeatsRemaining;

  const PlayerViewState({
    required this.surahNumber,
    required this.surahNameTransliteration,
    required this.surahNameArabic,
    required this.ayahs,
    required this.currentIndex,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.speed,
    required this.loop,
    required this.repeatsRemaining,
  });

  Ayah get currentAyah => ayahs[currentIndex];
  bool get hasNext => currentIndex < ayahs.length - 1;
  bool get hasPrevious => currentIndex > 0;

  PlayerViewState copyWith({
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? speed,
    LoopSettings? loop,
    int? repeatsRemaining,
  }) {
    return PlayerViewState(
      surahNumber: surahNumber,
      surahNameTransliteration: surahNameTransliteration,
      surahNameArabic: surahNameArabic,
      ayahs: ayahs,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      loop: loop ?? this.loop,
      repeatsRemaining: repeatsRemaining ?? this.repeatsRemaining,
    );
  }
}

class PlayerController extends Notifier<PlayerViewState?> {
  late final ja.AudioPlayer _player;
  Timer? _statsTicker;

  @override
  PlayerViewState? build() {
    _player = ja.AudioPlayer();
    ref.onDispose(_player.dispose);

    _statsTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state?.isPlaying == true) {
        ref.read(listeningStatsRepositoryProvider).addSeconds(1);
      }
    });
    ref.onDispose(() => _statsTicker?.cancel());

    _player.positionStream.listen((pos) {
      final s = state;
      if (s != null) state = s.copyWith(position: pos);
    });
    _player.durationStream.listen((d) {
      final s = state;
      if (s != null && d != null) state = s.copyWith(duration: d);
    });
    _player.playingStream.listen((playing) {
      final s = state;
      if (s != null) state = s.copyWith(isPlaying: playing);
    });
    _player.processingStateStream.listen((ps) {
      final s = state;
      if (s == null) return;
      state = s.copyWith(isBuffering: ps == ja.ProcessingState.buffering || ps == ja.ProcessingState.loading);
      if (ps == ja.ProcessingState.completed) {
        _onAyahCompleted();
      }
    });

    return null;
  }

  Future<void> loadSurah(int surahNumber, {int startAyah = 1}) async {
    final quranRepo = ref.read(quranRepositoryProvider);
    await quranRepo.ensureCached();
    final surah = quranRepo.getSurah(surahNumber);
    final ayahs = quranRepo.getAyahsForSurah(surahNumber);
    final settings = ref.read(settingsControllerProvider);

    state = PlayerViewState(
      surahNumber: surahNumber,
      surahNameTransliteration: surah.nameTransliteration,
      surahNameArabic: surah.nameArabic,
      ayahs: ayahs,
      currentIndex: (startAyah - 1).clamp(0, ayahs.length - 1),
      isPlaying: false,
      isBuffering: true,
      position: Duration.zero,
      duration: Duration.zero,
      speed: settings.playbackSpeed,
      loop: LoopSettings.off,
      repeatsRemaining: 0,
    );

    await _player.setSpeed(settings.playbackSpeed);
    await _loadCurrentAyah(autoplay: true);
    await ref.read(recentlyPlayedRepositoryProvider).add(surahNumber, state!.currentIndex + 1);
  }

  Future<void> _loadCurrentAyah({bool autoplay = false}) async {
    final s = state;
    if (s == null) return;
    final ayah = s.currentAyah;
    final reciter = ref.read(selectedReciterProvider);
    final audioRepo = ref.read(audioRepositoryProvider);

    final localPath = await audioRepo.localPath(
      reciterFolder: reciter.folder,
      surahNumber: ayah.surahNumber,
      ayahNumberInSurah: ayah.numberInSurah,
    );

    if (await File(localPath).exists()) {
      await _player.setFilePath(localPath);
    } else {
      final url = audioRepo.remoteUrl(
        reciterFolder: reciter.folder,
        surahNumber: ayah.surahNumber,
        ayahNumberInSurah: ayah.numberInSurah,
      );
      await _player.setUrl(url);
      unawaited(audioRepo.downloadAyah(
        reciterFolder: reciter.folder,
        surahNumber: ayah.surahNumber,
        ayahNumberInSurah: ayah.numberInSurah,
      ));
    }

    if (autoplay || s.isPlaying) {
      await _player.play();
    }
  }

  Future<void> _onAyahCompleted() async {
    final s = state;
    if (s == null) return;

    if (s.loop.enabled) {
      if (s.loop.infinite || s.repeatsRemaining > 1) {
        state = s.copyWith(repeatsRemaining: s.loop.infinite ? s.repeatsRemaining : s.repeatsRemaining - 1);
        await _player.seek(Duration.zero);
        await _player.play();
        return;
      }
      state = s.copyWith(loop: LoopSettings.off, repeatsRemaining: 0);
    }

    await next();
  }

  Future<void> togglePlayPause() async {
    final s = state;
    if (s == null) return;
    if (s.isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> next() async {
    final s = state;
    if (s == null) return;
    if (!s.hasNext) {
      await _player.pause();
      await _player.seek(Duration.zero);
      return;
    }
    state = s.copyWith(
      currentIndex: s.currentIndex + 1,
      position: Duration.zero,
      repeatsRemaining: s.loop.enabled && !s.loop.infinite ? s.loop.repeatCount : 0,
    );
    await _loadCurrentAyah(autoplay: s.isPlaying || true);
  }

  Future<void> previous() async {
    final s = state;
    if (s == null) return;
    if (s.position.inSeconds > 2) {
      await _player.seek(Duration.zero);
      return;
    }
    if (!s.hasPrevious) {
      await _player.seek(Duration.zero);
      return;
    }
    state = s.copyWith(
      currentIndex: s.currentIndex - 1,
      position: Duration.zero,
      repeatsRemaining: s.loop.enabled && !s.loop.infinite ? s.loop.repeatCount : 0,
    );
    await _loadCurrentAyah(autoplay: true);
  }

  Future<void> jumpToAyah(int ayahNumberInSurah) async {
    final s = state;
    if (s == null) return;
    final index = ayahNumberInSurah - 1;
    if (index < 0 || index >= s.ayahs.length) return;
    state = s.copyWith(
      currentIndex: index,
      position: Duration.zero,
      repeatsRemaining: s.loop.enabled && !s.loop.infinite ? s.loop.repeatCount : 0,
    );
    await _loadCurrentAyah(autoplay: true);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setSpeed(double speed) async {
    final s = state;
    if (s == null) return;
    state = s.copyWith(speed: speed);
    await _player.setSpeed(speed);
    await ref.read(settingsControllerProvider.notifier).setPlaybackSpeed(speed);
  }

  void setLoop(LoopSettings loop) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      loop: loop,
      repeatsRemaining: loop.infinite ? 0 : loop.repeatCount,
    );
  }

  void stopAndClear() {
    _player.stop();
    state = null;
  }
}

final playerControllerProvider = NotifierProvider<PlayerController, PlayerViewState?>(
  PlayerController.new,
);
