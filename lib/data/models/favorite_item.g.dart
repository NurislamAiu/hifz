// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FavoriteItemAdapter extends TypeAdapter<FavoriteItem> {
  @override
  final int typeId = 6;

  @override
  FavoriteItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteItem(
      type: fields[0] as FavoriteType,
      surahNumber: fields[1] as int,
      ayahNumberInSurah: fields[2] as int?,
      addedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.surahNumber)
      ..writeByte(2)
      ..write(obj.ayahNumberInSurah)
      ..writeByte(3)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FavoriteTypeAdapter extends TypeAdapter<FavoriteType> {
  @override
  final int typeId = 5;

  @override
  FavoriteType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FavoriteType.surah;
      case 1:
        return FavoriteType.ayah;
      default:
        return FavoriteType.surah;
    }
  }

  @override
  void write(BinaryWriter writer, FavoriteType obj) {
    switch (obj) {
      case FavoriteType.surah:
        writer.writeByte(0);
        break;
      case FavoriteType.ayah:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
