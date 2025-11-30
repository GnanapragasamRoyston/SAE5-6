// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_rating.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MovieRatingAdapter extends TypeAdapter<MovieRating> {
  @override
  final int typeId = 7;

  @override
  MovieRating read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MovieRating(
      movieId: fields[0] as String,
      isLiked: fields[1] as bool,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MovieRating obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.movieId)
      ..writeByte(1)
      ..write(obj.isLiked)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieRatingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
