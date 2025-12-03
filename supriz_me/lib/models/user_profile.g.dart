// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 3;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      username: fields[1] as String,
      age: fields[2] as int,
      preferences: (fields[3] as List).cast<String>(),
      favoriteIds: (fields[4] as List).cast<String>(),
      viewedIds: (fields[5] as List).cast<String>(),
      groupSize: fields[6] as int,
      filmScores: (fields[7] as Map).cast<String, int>(),
      genreScores: (fields[8] as Map).cast<String, int>(),
      setupDone: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.preferences)
      ..writeByte(4)
      ..write(obj.favoriteIds)
      ..writeByte(5)
      ..write(obj.viewedIds)
      ..writeByte(6)
      ..write(obj.groupSize)
      ..writeByte(7)
      ..write(obj.filmScores)
      ..writeByte(8)
      ..write(obj.genreScores)
      ..writeByte(9)
      ..write(obj.setupDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
