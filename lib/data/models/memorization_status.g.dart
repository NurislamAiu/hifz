// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memorization_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemorizationStatusAdapter extends TypeAdapter<MemorizationStatus> {
  @override
  final int typeId = 3;

  @override
  MemorizationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MemorizationStatus.notStarted;
      case 1:
        return MemorizationStatus.inProgress;
      case 2:
        return MemorizationStatus.memorized;
      default:
        return MemorizationStatus.notStarted;
    }
  }

  @override
  void write(BinaryWriter writer, MemorizationStatus obj) {
    switch (obj) {
      case MemorizationStatus.notStarted:
        writer.writeByte(0);
        break;
      case MemorizationStatus.inProgress:
        writer.writeByte(1);
        break;
      case MemorizationStatus.memorized:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemorizationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
