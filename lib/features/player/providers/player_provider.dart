import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_background/just_audio_background.dart';

import '../../../data/models/ayah.dart';
import '../../../data/providers.dart';
import '../../settings/providers/settings_provider.dart';

enum LoopScope { ayah, surah }

class LoopSettings {
  final bool enabled;
  final bool infinite;
  final int repeatCount;
  final LoopScope scope;

  const LoopSettings({
    this.enabled = false,
    this.infinite = false,
    this.repeatCount = 3,
    this.scope = LoopScope.ayah,
  });

  static const off = LoopSettings();

  bool get repeatsAyah => enabled && scope == LoopScope.ayah;
  bool get repeatsSurah => enabled && scope == LoopScope.surah;
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
  final double volume;

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
    this.volume = 1.0,
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
    double? volume,
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
      volume: volume ?? this.volume,
    );
  }
}

class PlayerController extends Notifier<PlayerViewState?> {
  late final ja.AudioPlayer _player;
  Timer? _statsTicker;

  @override
  PlayerViewState? build() {
    _player = ja.AudioPlayer();
    unawaited(_configureAudioSession());
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
      _setKnownDuration(d);
    });
    _player.sequenceStateStream.listen((sequenceState) {
      _setKnownDuration(sequenceState.currentSource?.duration);
    });
    _player.playingStream.listen((playing) {
      final s = state;
      if (s != null) state = s.copyWith(isPlaying: playing);
    });
    _player.currentIndexStream.listen((index) {
      unawaited(_syncCurrentIndex(index));
    });
    _player.processingStateStream.listen((ps) {
      final s = state;
      if (s == null) return;
      state = s.copyWith(
        isBuffering:
            ps == ja.ProcessingState.buffering ||
            ps == ja.ProcessingState.loading,
      );
      if (ps == ja.ProcessingState.completed) {
        unawaited(_handlePlaybackCompleted());
      }
    });

    return null;
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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
    await _player.setLoopMode(ja.LoopMode.off);
    await _loadSurahQueue(autoplay: true);
    await ref
        .read(recentlyPlayedRepositoryProvider)
        .add(surahNumber, state!.currentIndex + 1);
  }

  Future<void> _loadSurahQueue({bool autoplay = false}) async {
    final s = state;
    if (s == null) return;
    final reciter = ref.read(selectedReciterProvider);
    final audioRepo = ref.read(audioRepositoryProvider);
    final sources = <ja.AudioSource>[];

    for (final ayah in s.ayahs) {
      final localPath = await audioRepo.localPath(
        reciterFolder: reciter.folder,
        surahNumber: ayah.surahNumber,
        ayahNumberInSurah: ayah.numberInSurah,
      );
      final uri = await File(localPath).exists()
          ? Uri.file(localPath)
          : Uri.parse(
              audioRepo.remoteUrl(
                reciterFolder: reciter.folder,
                surahNumber: ayah.surahNumber,
                ayahNumberInSurah: ayah.numberInSurah,
              ),
            );

      sources.add(
        ja.AudioSource.uri(
          uri,
          tag: MediaItem(
            id: '${ayah.surahNumber}:${ayah.numberInSurah}',
            album: s.surahNameTransliteration,
            title:
                '${s.surahNameTransliteration} ${ayah.surahNumber}:${ayah.numberInSurah}',
            artist: reciter.name,
            displayTitle: s.surahNameArabic,
            displaySubtitle: 'Аят ${ayah.numberInSurah}',
          ),
        ),
      );
    }

    final duration = await _player.setAudioSources(
      sources,
      initialIndex: s.currentIndex,
      initialPosition: Duration.zero,
    );
    _setKnownDuration(duration ?? _player.duration);

    if (autoplay || s.isPlaying) {
      await _player.play();
    }
  }

  Future<void> _syncCurrentIndex(int? index) async {
    final s = state;
    if (s == null || index == null || index == s.currentIndex) return;
    if (index < 0 || index >= s.ayahs.length) return;

    var loop = s.loop;
    var repeatsRemaining = s.loop.repeatsAyah && !s.loop.infinite
        ? s.loop.repeatCount
        : s.repeatsRemaining;
    final wrappedSurah =
        s.loop.repeatsSurah &&
        s.currentIndex == s.ayahs.length - 1 &&
        index == 0;

    if (index == s.currentIndex + 1 && s.loop.repeatsAyah) {
      if (s.loop.infinite || s.repeatsRemaining > 1) {
        state = s.copyWith(
          repeatsRemaining: s.loop.infinite
              ? s.repeatsRemaining
              : s.repeatsRemaining - 1,
          position: Duration.zero,
        );
        await _player.seek(Duration.zero, index: s.currentIndex);
        if (s.isPlaying) {
          await _player.play();
        }
        return;
      }
      loop = LoopSettings.off;
      repeatsRemaining = 0;
    }

    if (wrappedSurah && !s.loop.infinite) {
      if (s.repeatsRemaining > 1) {
        repeatsRemaining = s.repeatsRemaining - 1;
        if (repeatsRemaining == 1) {
          unawaited(_player.setLoopMode(ja.LoopMode.off));
        }
      } else {
        loop = LoopSettings.off;
        repeatsRemaining = 0;
        unawaited(_player.setLoopMode(ja.LoopMode.off));
      }
    }

    state = s.copyWith(
      currentIndex: index,
      position: Duration.zero,
      loop: loop,
      repeatsRemaining: repeatsRemaining,
    );
    _setKnownDuration(_durationForIndex(index) ?? _player.duration);
  }

  Future<void> _handlePlaybackCompleted() async {
    final s = state;
    if (s == null) return;

    if (s.loop.repeatsSurah && !s.loop.infinite && s.repeatsRemaining <= 1) {
      state = s.copyWith(loop: LoopSettings.off, repeatsRemaining: 0);
      await _player.setLoopMode(ja.LoopMode.off);
      return;
    }

    if (s.loop.repeatsAyah) {
      if (s.loop.infinite || s.repeatsRemaining > 1) {
        state = s.copyWith(
          repeatsRemaining: s.loop.infinite
              ? s.repeatsRemaining
              : s.repeatsRemaining - 1,
        );
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
      if (s.loop.repeatsSurah) {
        state = s.copyWith(currentIndex: 0, position: Duration.zero);
        await _seekToIndex(0);
        await _player.play();
        return;
      }
      await _player.pause();
      await _player.seek(Duration.zero);
      return;
    }
    state = s.copyWith(
      currentIndex: s.currentIndex + 1,
      position: Duration.zero,
      repeatsRemaining: _repeatsRemainingAfterAyahChange(s),
    );
    await _seekToIndex(s.currentIndex + 1);
    await _player.play();
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
      repeatsRemaining: _repeatsRemainingAfterAyahChange(s),
    );
    await _seekToIndex(s.currentIndex - 1);
    await _player.play();
  }

  Future<void> jumpToAyah(int ayahNumberInSurah) async {
    final s = state;
    if (s == null) return;
    final index = ayahNumberInSurah - 1;
    if (index < 0 || index >= s.ayahs.length) return;
    state = s.copyWith(
      currentIndex: index,
      position: Duration.zero,
      repeatsRemaining: _repeatsRemainingAfterAyahChange(s),
    );
    await _seekToIndex(index);
    await _player.play();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) async {
    final s = state;
    if (s == null) return;
    state = s.copyWith(volume: volume);
    await _player.setVolume(volume);
  }

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
    unawaited(
      _player.setLoopMode(
        loop.repeatsSurah ? ja.LoopMode.all : ja.LoopMode.off,
      ),
    );
    state = s.copyWith(
      loop: loop,
      repeatsRemaining: loop.enabled && !loop.infinite ? loop.repeatCount : 0,
    );
  }

  int _repeatsRemainingAfterAyahChange(PlayerViewState s) {
    if (!s.loop.repeatsAyah || s.loop.infinite) return s.repeatsRemaining;
    return s.loop.repeatCount;
  }

  Future<void> _seekToIndex(int index) async {
    await _player.seek(Duration.zero, index: index);
    _setKnownDuration(_durationForIndex(index) ?? _player.duration);
  }

  Duration? _durationForIndex(int index) {
    try {
      final sequence = _player.sequence;
      if (index < 0 || index >= sequence.length) return null;
      return sequence[index].duration;
    } catch (_) {
      return null;
    }
  }

  void _setKnownDuration(Duration? duration) {
    if (duration == null) return;
    final s = state;
    if (s == null || s.duration == duration) return;
    state = s.copyWith(duration: duration);
  }

  void stopAndClear() {
    _player.stop();
    state = null;
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerViewState?>(PlayerController.new);
