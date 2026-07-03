// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ayah.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AyahAdapter extends TypeAdapter<Ayah> {
  @override
  final int typeId = 1;

  @override
  Ayah read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ayah(
      number: fields[0] as int,
      surahNumber: fields[1] as int,
      numberInSurah: fields[2] as int,
      textArabic: fields[3] as String,
      textTransliteration: fields[4] as String?,
      juz: fields[5] as int,
      page: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Ayah obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.surahNumber)
      ..writeByte(2)
      ..write(obj.numberInSurah)
      ..writeByte(3)
      ..write(obj.textArabic)
      ..writeByte(4)
      ..write(obj.textTransliteration)
      ..writeByte(5)
      ..write(obj.juz)
      ..writeByte(6)
      ..write(obj.page);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AyahAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
