import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/app_paths.dart';
import '../../core/constants/app_constants.dart';

/// Downloads per-ayah mp3s from EveryAyah.com on demand and caches them under
/// the app's documents directory so playback works fully offline afterwards.
///
/// The on-disk location is fully deterministic from
/// (reciterFolder, surahNumber, ayahNumberInSurah), so "is it downloaded" is
/// answered by checking the file directly rather than through a side registry
/// — a registry can silently fall out of sync (e.g. a file finishes
/// downloading but the write that records it never lands), and on iOS the
/// container UUID changes on every reinstall, which would strand any
/// absolute path saved from a previous install. Deterministic paths sidestep
/// both failure modes entirely.
class AudioRepository {
  AudioRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  String _absolutePath(String reciterFolder, int surahNumber, int ayahNumberInSurah) =>
      '${AppPaths.documentsPath}/audio/$reciterFolder/$surahNumber/$ayahNumberInSurah.mp3';

  Future<Directory> _audioDir(String reciterFolder, int surahNumber) async {
    final dir = Directory('${AppPaths.documentsPath}/audio/$reciterFolder/$surahNumber');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Local file path for an ayah, whether or not it has been downloaded yet.
  Future<String> localPath({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumberInSurah,
  }) async {
    return _absolutePath(reciterFolder, surahNumber, ayahNumberInSurah);
  }

  bool isDownloaded({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumberInSurah,
  }) {
    return File(_absolutePath(reciterFolder, surahNumber, ayahNumberInSurah)).existsSync();
  }

  /// Downloads a single ayah's audio if not already cached. Returns the
  /// local file path.
  Future<String> downloadAyah({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumberInSurah,
    void Function(double progress)? onProgress,
  }) async {
    final filePath = _absolutePath(reciterFolder, surahNumber, ayahNumberInSurah);
    if (await File(filePath).exists()) {
      return filePath;
    }

    await _audioDir(reciterFolder, surahNumber);
    final url = EveryAyahConstants.audioUrl(
      reciterFolder: reciterFolder,
      surahNumber: surahNumber,
      ayahNumber: ayahNumberInSurah,
    );

    await _dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    return filePath;
  }

  /// Downloads every ayah of a surah, skipping ones already cached.
  Future<void> downloadSurah({
    required String reciterFolder,
    required int surahNumber,
    required int ayahCount,
    void Function(int completed, int total)? onProgress,
  }) async {
    for (var i = 1; i <= ayahCount; i++) {
      await downloadAyah(
        reciterFolder: reciterFolder,
        surahNumber: surahNumber,
        ayahNumberInSurah: i,
      );
      onProgress?.call(i, ayahCount);
    }
  }

  bool isSurahDownloaded({
    required String reciterFolder,
    required int surahNumber,
    required int ayahCount,
  }) {
    for (var i = 1; i <= ayahCount; i++) {
      if (!isDownloaded(reciterFolder: reciterFolder, surahNumber: surahNumber, ayahNumberInSurah: i)) {
        return false;
      }
    }
    return true;
  }

  String remoteUrl({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumberInSurah,
  }) =>
      EveryAyahConstants.audioUrl(
        reciterFolder: reciterFolder,
        surahNumber: surahNumber,
        ayahNumber: ayahNumberInSurah,
      );

  Future<void> clearAll() async {
    final dir = Directory('${AppPaths.documentsPath}/audio');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> clearSurah({
    required String reciterFolder,
    required int surahNumber,
  }) async {
    final dir = Directory('${AppPaths.documentsPath}/audio/$reciterFolder/$surahNumber');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Total bytes used by all downloaded audio.
  Future<int> cacheSizeBytes() async {
    final dir = Directory('${AppPaths.documentsPath}/audio');
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
