import 'package:hive/hive.dart';

part 'ayah.g.dart';

@HiveType(typeId: 1)
class Ayah {
  /// Absolute ayah number across the whole Quran (1..6236).
  @HiveField(0)
  final int number;

  @HiveField(1)
  final int surahNumber;

  /// 1-based ayah index within its surah.
  @HiveField(2)
  final int numberInSurah;

  @HiveField(3)
  final String textArabic;

  /// Null until the transliteration edition has been fetched/cached.
  @HiveField(4)
  final String? textTransliteration;

  @HiveField(5)
  final int juz;

  @HiveField(6)
  final int page;

  const Ayah({
    required this.number,
    required this.surahNumber,
    required this.numberInSurah,
    required this.textArabic,
    this.textTransliteration,
    required this.juz,
    required this.page,
  });

  factory Ayah.fromApiJson(
    Map<String, dynamic> json, {
    required int surahNumber,
  }) {
    return Ayah(
      number: json['number'] as int,
      surahNumber: surahNumber,
      numberInSurah: json['numberInSurah'] as int,
      textArabic: json['text'] as String,
      juz: json['juz'] as int,
      page: json['page'] as int,
    );
  }

  Ayah copyWithTransliteration(String text) => Ayah(
    number: number,
    surahNumber: surahNumber,
    numberInSurah: numberInSurah,
    textArabic: textArabic,
    textTransliteration: text,
    juz: juz,
    page: page,
  );
}
