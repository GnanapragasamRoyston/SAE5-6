// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_rating.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityRatingAdapter extends TypeAdapter<ActivityRating> {
  @override
  final int typeId = 4;

  @override
  ActivityRating read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityRating(
      activityId: fields[0] as String,
      rating: fields[1] as int,
      ratedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityRating obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.activityId)
      ..writeByte(1)
      ..write(obj.rating)
      ..writeByte(2)
      ..write(obj.ratedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityRatingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
