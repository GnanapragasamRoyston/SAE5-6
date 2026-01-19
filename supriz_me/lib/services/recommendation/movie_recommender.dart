import 'package:hive/hive.dart';
import '../../models/movie.dart';
import '../../models/movie_rating.dart';

class MovieRecommender {
  final Box<Movie> movieBox;
  final Box<MovieRating> movieRatingBox;
  final Box settingsBox; // Pour lire les préférences initiales

  MovieRecommender({
    required this.movieBox,
    required this.movieRatingBox,
    required this.settingsBox,
  });

  /// 🎯 Logique principale pour la recommandation de films.
  List<Movie> getRecommendedMovies({int count = 10}) {
    final allMovies = movieBox.values.toList();
    if (allMovies.isEmpty) return [];

    final userRatings = movieRatingBox.values.toList();
    final ratedMovieIds = userRatings.map((r) => r.movieId).toSet();

    final Map<String, double> genreScores = {};

    // 1. Déterminer les scores de tags basés sur l'historique ou les préférences
    if (userRatings.isNotEmpty) {
      // A. MODE APPRENTISSAGE: Basé sur le Like (+1) / Dislike (-1)
      for (final rating in userRatings) {
        final movie = movieBox.get(rating.movieId);
        if (movie != null) {
          final score = rating.isLiked ? 1.0 : -1.0;
          for (final tag in movie.tags) {
            genreScores[tag] = (genreScores[tag] ?? 0.0) + score;
          }
        }
      }
    } else {
      // B. MODE INITIALISATION: Basé sur la sélection initiale (Bonus TRÈS FORT)
      final initialGenres =
          settingsBox.get('initial_movie_genres') as List<dynamic>?;

      if (initialGenres != null && initialGenres.isNotEmpty) {
        for (final genre in initialGenres.cast<String>()) {
          // 🌟 Bonus très élevé (20) pour dominer le rating IMDb par défaut
          genreScores[genre] = 20.0;
        }
      }
    }

    // Calculer la préférence de durée basée sur les films aimés
    final avgDurationPreference = _calculateAverageDurationOfLikedMovies();

    // 2. Calculer le score de recommandation pour chaque film non noté
    final List<Map<String, dynamic>> scoredMovies = [];

    for (final movie in allMovies) {
      // Ignorer les films déjà notés si l'historique n'est pas vide
      if (userRatings.isNotEmpty && ratedMovieIds.contains(movie.id)) continue;

      double recommendationScore = 0.0;

      // Additionner les scores des tags
      for (final tag in movie.tags) {
        recommendationScore += genreScores[tag] ?? 0.0;
      }

      // 🌟 Poids des Tags (Bonus pour la diversité des correspondances)
      recommendationScore *= 5.0;

      // 🌟 Poids du Rating IMDb par défaut (Diminué pour laisser les préférences dominer)
      recommendationScore +=
          movie.rating * 0.5; // Seulement 50% du poids original

      // 🌟 Bonus de durée: préférer les films de durée similaire à ceux aimés
      final durationBonus =
          _calculateDurationBonus(movie.duration, avgDurationPreference);
      recommendationScore += durationBonus;

      scoredMovies.add({
        'movie': movie,
        'score': recommendationScore,
      });
    }

    // 3. Trier par score de recommandation (descendant)
    scoredMovies.sort((a, b) => b['score'].compareTo(a['score']));

    return scoredMovies
        .map((item) => item['movie'] as Movie)
        .take(count)
        .toList();
  }

  /// Calcule la durée moyenne des films aimés par l'utilisateur
  double _calculateAverageDurationOfLikedMovies() {
    final likedRatings = movieRatingBox.values.where((r) => r.isLiked).toList();

    if (likedRatings.isEmpty) {
      return 120.0; // Défaut: 2h
    }

    double totalDuration = 0.0;
    for (final rating in likedRatings) {
      final movie = movieBox.get(rating.movieId);
      if (movie != null) {
        totalDuration += movie.duration;
      }
    }

    return totalDuration / likedRatings.length;
  }

  /// Calcule un bonus de durée pour un film
  /// Les films proches de la durée préférée ont un bonus
  double _calculateDurationBonus(
      double movieDuration, double preferredDuration) {
    final durationDiff = (movieDuration - preferredDuration).abs();

    // Bonus: -0 to +2 points basé sur la proximité
    final bonus = (2.0 - (durationDiff / preferredDuration)).clamp(0.0, 2.0);

    return bonus;
  }

  /// Méthode pour enregistrer le Like/Dislike.
  Future<void> saveRating(String movieId, bool isLiked) async {
    final existingRating =
        movieRatingBox.values.where((r) => r.movieId == movieId).toList();
    for (final r in existingRating) {
      await r.delete();
    }

    final newRating = MovieRating(
      movieId: movieId,
      isLiked: isLiked,
      timestamp: DateTime.now(),
    );
    // Utiliser l'ID du film comme clé
    await movieRatingBox.put(movieId, newRating);
  }
}
