import 'package:hive/hive.dart';

part 'movie_rating.g.dart';

@HiveType(typeId: 7) // Assurez-vous que l'ID est unique
class MovieRating extends HiveObject {
  @HiveField(0)
  final String movieId;

  @HiveField(1)
  final bool isLiked; // true pour Like, false pour Dislike

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final bool isFavorite;

  MovieRating({
    required this.movieId,
    required this.isLiked,
    required this.timestamp,
    this.isFavorite = false,
  });

  MovieRating copyWith({
    String? movieId,
    bool? isLiked,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return MovieRating(
      movieId: movieId ?? this.movieId,
      isLiked: isLiked ?? this.isLiked,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
