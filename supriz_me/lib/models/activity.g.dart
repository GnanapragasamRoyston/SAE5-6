// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityAdapter extends TypeAdapter<Activity> {
  @override
  final int typeId = 6;

  @override
  Activity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Activity(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as ActivityCategory,
      duration: fields[4] as double,
      minParticipants: fields[5] as int,
      maxParticipants: fields[6] as int,
      tags: (fields[7] as List).cast<String>(),
      difficulty: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Activity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.minParticipants)
      ..writeByte(6)
      ..write(obj.maxParticipants)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityCategoryAdapter extends TypeAdapter<ActivityCategory> {
  @override
  final int typeId = 1;

  @override
  ActivityCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityCategory.calme;
      case 1:
        return ActivityCategory.jeu;
      case 2:
        return ActivityCategory.sport;
      case 3:
        return ActivityCategory.social;
      case 4:
        return ActivityCategory.creatif;
      case 5:
        return ActivityCategory.detente;
      case 6:
        return ActivityCategory.outdoor;
      default:
        return ActivityCategory.calme;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityCategory obj) {
    switch (obj) {
      case ActivityCategory.calme:
        writer.writeByte(0);
        break;
      case ActivityCategory.jeu:
        writer.writeByte(1);
        break;
      case ActivityCategory.sport:
        writer.writeByte(2);
        break;
      case ActivityCategory.social:
        writer.writeByte(3);
        break;
      case ActivityCategory.creatif:
        writer.writeByte(4);
        break;
      case ActivityCategory.detente:
        writer.writeByte(5);
        break;
      case ActivityCategory.outdoor:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
