// GENERATED CODE - manual adapter (no build step)
part of 'user_profile.dart';

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 3;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return UserProfile(
      id: fields[0] as String,
      username: fields[1] as String,
      age: fields[2] as int,
      preferences: (fields[3] as List).cast<String>(),
      favoriteIds: (fields[4] as List).cast<String>(),
      viewedIds: (fields[5] as List).cast<String>(),
      groupSize: fields[6] as int,
      filmScores: fields[7] as Map<String, int>,
      genreScores: fields[8] as Map<String, int>,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.groupSize);
  }
}
