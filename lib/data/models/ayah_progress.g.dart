// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ayah_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AyahProgressAdapter extends TypeAdapter<AyahProgress> {
  @override
  final int typeId = 4;

  @override
  AyahProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AyahProgress(
      surahNumber: fields[0] as int,
      ayahNumberInSurah: fields[1] as int,
      status: fields[2] as MemorizationStatus,
      updatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AyahProgress obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.surahNumber)
      ..writeByte(1)
      ..write(obj.ayahNumberInSurah)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AyahProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
