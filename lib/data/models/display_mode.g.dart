// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'display_mode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DisplayModeAdapter extends TypeAdapter<DisplayMode> {
  @override
  final int typeId = 7;

  @override
  DisplayMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DisplayMode.arabic;
      case 1:
        return DisplayMode.transliteration;
      case 2:
        return DisplayMode.both;
      default:
        return DisplayMode.arabic;
    }
  }

  @override
  void write(BinaryWriter writer, DisplayMode obj) {
    switch (obj) {
      case DisplayMode.arabic:
        writer.writeByte(0);
        break;
      case DisplayMode.transliteration:
        writer.writeByte(1);
        break;
      case DisplayMode.both:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplayModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
