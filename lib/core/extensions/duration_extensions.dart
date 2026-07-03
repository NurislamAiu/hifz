extension DurationFormatting on Duration {
  /// Formats as `m:ss`, e.g. `2:07`.
  String get mmss {
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
