import 'package:hive/hive.dart';
import '../../models/movie.dart';
import '../../models/movie_rating.dart';

class MovieRecommender {
  final Box<Movie> movieBox;
  final Box<MovieRating> movieRatingBox;
  final Box settingsBox;

  MovieRecommender({
    required this.movieBox,
    required this.movieRatingBox,
    required this.settingsBox,
  });

  List<Movie> getRecommendedMovies({int count = 10}) {
    final allMovies = movieBox.values.toList();
    if (allMovies.isEmpty) return [];

    final userRatings = movieRatingBox.values.toList();
    final ratedMovieIds = userRatings.map((r) => r.movieId).toSet();
    
    // ⏱️ RÉCUPÉRATION DE LA DURÉE MAX (Défaut 120min)
    final int maxDuration = settingsBox.get('preferred_duration', defaultValue: 120);

    final Map<String, double> genreScores = {};

    // 1. MODE INITIALISATION : Score de base élevé pour les genres choisis
    final initialGenres = settingsBox.get('initial_movie_genres') as List<dynamic>?;
    if (initialGenres != null) {
      for (final genre in initialGenres.cast<String>()) {
        genreScores[genre.toLowerCase()] = 15.0; 
      }
    }

    // 2. MODE APPRENTISSAGE : On ajuste selon les Likes/Dislikes réels
    for (final rating in userRatings) {
      final movie = movieBox.get(rating.movieId);
      if (movie != null) {
        final score = rating.isLiked ? 8.0 : -15.0;
        genreScores[movie.genre.toLowerCase()] = (genreScores[movie.genre.toLowerCase()] ?? 0.0) + score;
        for (final tag in movie.tags) {
          genreScores[tag.toLowerCase()] = (genreScores[tag.toLowerCase()] ?? 0.0) + (score / 2);
        }
      }
    }

    final List<Map<String, dynamic>> scoredMovies = [];

    for (final movie in allMovies) {
      // 🚫 FILTRE DE DURÉE STRICT
      if (movie.duration > maxDuration) continue;

      // Ne pas recommander ce qu'on a déjà noté
      if (ratedMovieIds.contains(movie.id)) continue;

      double recommendationScore = 0.0;
      recommendationScore += (genreScores[movie.genre.toLowerCase()] ?? 0.0) * 2;

      for (final tag in movie.tags) {
        recommendationScore += genreScores[tag.toLowerCase()] ?? 0.0;
      }

      // Ajout du rating IMDb pour départager
      recommendationScore += movie.rating * 1.2;

      scoredMovies.add({
        'movie': movie,
        'score': recommendationScore,
      });
    }

    scoredMovies.sort((a, b) => b['score'].compareTo(a['score']));

    return scoredMovies
        .map((item) => item['movie'] as Movie)
        .take(count)
        .toList();
  }

  Future<void> saveRating(String movieId, bool isLiked) async {
    final newRating = MovieRating(
      movieId: movieId,
      isLiked: isLiked,
      timestamp: DateTime.now(),
    );
    await movieRatingBox.put(movieId, newRating);
  }
}