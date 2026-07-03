// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 8;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      reciterId: fields[0] as String,
      displayMode: fields[1] as DisplayMode,
      playbackSpeed: fields[2] as double,
      hasCompletedOnboarding: fields[3] as bool?,
      notificationsEnabled: fields[4] as bool?,
      dailyListeningGoalMinutes: fields[5] as int?,
      dailyReadingGoalMinutes: fields[6] as int?,
      selectedCityId: fields[7] as String?,
      prayerMethodId: fields[8] as int?,
      fajrAdjustmentMinutes: fields[9] as int?,
      dhuhrAdjustmentMinutes: fields[10] as int?,
      asrAdjustmentMinutes: fields[11] as int?,
      maghribAdjustmentMinutes: fields[12] as int?,
      ishaAdjustmentMinutes: fields[13] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.reciterId)
      ..writeByte(1)
      ..write(obj.displayMode)
      ..writeByte(2)
      ..write(obj.playbackSpeed)
      ..writeByte(3)
      ..write(obj.hasCompletedOnboarding)
      ..writeByte(4)
      ..write(obj.notificationsEnabled)
      ..writeByte(5)
      ..write(obj.dailyListeningGoalMinutes)
      ..writeByte(6)
      ..write(obj.dailyReadingGoalMinutes)
      ..writeByte(7)
      ..write(obj.selectedCityId)
      ..writeByte(8)
      ..write(obj.prayerMethodId)
      ..writeByte(9)
      ..write(obj.fajrAdjustmentMinutes)
      ..writeByte(10)
      ..write(obj.dhuhrAdjustmentMinutes)
      ..writeByte(11)
      ..write(obj.asrAdjustmentMinutes)
      ..writeByte(12)
      ..write(obj.maghribAdjustmentMinutes)
      ..writeByte(13)
      ..write(obj.ishaAdjustmentMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
