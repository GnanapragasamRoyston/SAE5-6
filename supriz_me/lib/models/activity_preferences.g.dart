// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityPreferencesAdapter extends TypeAdapter<ActivityPreferences> {
  @override
  final int typeId = 5;

  @override
  ActivityPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityPreferences(
      availableTime: fields[0] as int,
      groupSize: fields[1] as int,
      preferredCategories: (fields[2] as List).cast<String>(),
      allowSurprise: fields[3] as bool,
      categoryWeight: fields[4] as double?,
      durationWeight: fields[5] as double?,
      groupWeight: fields[6] as double?,
      difficultyWeight: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityPreferences obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.availableTime)
      ..writeByte(1)
      ..write(obj.groupSize)
      ..writeByte(2)
      ..write(obj.preferredCategories)
      ..writeByte(3)
      ..write(obj.allowSurprise)
      ..writeByte(4)
      ..write(obj.categoryWeight)
      ..writeByte(5)
      ..write(obj.durationWeight)
      ..writeByte(6)
      ..write(obj.groupWeight)
      ..writeByte(7)
      ..write(obj.difficultyWeight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
