// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SurahAdapter extends TypeAdapter<Surah> {
  @override
  final int typeId = 0;

  @override
  Surah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Surah(
      number: fields[0] as int,
      nameArabic: fields[1] as String,
      nameTransliteration: fields[2] as String,
      nameTranslationEn: fields[3] as String,
      revelationType: fields[4] as String,
      numberOfAyahs: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Surah obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.nameArabic)
      ..writeByte(2)
      ..write(obj.nameTransliteration)
      ..writeByte(3)
      ..write(obj.nameTranslationEn)
      ..writeByte(4)
      ..write(obj.revelationType)
      ..writeByte(5)
      ..write(obj.numberOfAyahs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
