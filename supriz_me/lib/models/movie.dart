import 'package:hive/hive.dart';

part 'movie.g.dart';

@HiveType(typeId: 0)
class Movie {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String genre;

  @HiveField(4)
  final double duration; // en minutes

  @HiveField(5)
  final double rating;

  @HiveField(6)
  final List<String> tags;

  const Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.duration,
    required this.rating,
    required this.tags,
  });
}
