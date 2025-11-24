// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_game.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoardGameAdapter extends TypeAdapter<BoardGame> {
  @override
  final int typeId = 2;

  @override
  BoardGame read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoardGame(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      minPlayers: fields[3] as int,
      maxPlayers: fields[4] as int,
      avgDuration: fields[5] as double,
      complexity: fields[6] as double,
      rating: fields[7] as double,
      tags: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, BoardGame obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.minPlayers)
      ..writeByte(4)
      ..write(obj.maxPlayers)
      ..writeByte(5)
      ..write(obj.avgDuration)
      ..writeByte(6)
      ..write(obj.complexity)
      ..writeByte(7)
      ..write(obj.rating)
      ..writeByte(8)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardGameAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
