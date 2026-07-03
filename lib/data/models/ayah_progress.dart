import 'package:hive/hive.dart';
import 'memorization_status.dart';

part 'ayah_progress.g.dart';

@HiveType(typeId: 4)
class AyahProgress {
  @HiveField(0)
  final int surahNumber;

  @HiveField(1)
  final int ayahNumberInSurah;

  @HiveField(2)
  final MemorizationStatus status;

  @HiveField(3)
  final DateTime updatedAt;

  const AyahProgress({
    required this.surahNumber,
    required this.ayahNumberInSurah,
    required this.status,
    required this.updatedAt,
  });

  String get key => '$surahNumber:$ayahNumberInSurah';

  AyahProgress copyWith({MemorizationStatus? status}) => AyahProgress(
    surahNumber: surahNumber,
    ayahNumberInSurah: ayahNumberInSurah,
    status: status ?? this.status,
    updatedAt: DateTime.now(),
  );
}
