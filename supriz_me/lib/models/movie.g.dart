// GENERATED CODE - manual adapter (no build step)
part of 'movie.dart';

class MovieAdapter extends TypeAdapter<Movie> {
  @override
  final int typeId = 0;

  @override
  Movie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Movie(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      genre: fields[3] as String,
      duration: fields[4] as double,
      rating: fields[5] as double,
      tags: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Movie obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.genre)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.rating)
      ..writeByte(6)
      ..write(obj.tags);
  }
}
