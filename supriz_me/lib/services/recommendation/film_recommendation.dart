import 'dart:math';
import '../../models/movie.dart';
import '../../models/user_profile.dart';

class FilmRecommendation {
  /// Génère une liste de films recommandés
  static List<Movie> recommend({
    required List<Movie> allMovies,
    required UserProfile user,
    int limit = 10,
  }) {
    List<Map<String, dynamic>> scoredMovies = [];

    for (var m in allMovies) {
      int score = 0;

      // -----------------------------------------------------
      // (1) Score individuel du film (apprentissage dynamique)
      // -----------------------------------------------------
      score += user.filmScores[m.id] ?? 0;

      // -----------------------------------------------------
      // (2) Score par genre (apprentissage dynamique)
      // -----------------------------------------------------
      final genre = m.genre.split(",").first.trim();
      score += user.genreScores[genre] ?? 0;

      // (3) Note du film (dataset "rating")
      int movieRating = 0;

      double rawRating = double.tryParse(m.rating.toString()) ?? 0;

      // On normalise /10 (ex : 73 → 7)
      movieRating = (rawRating / 10).round();

      score += movieRating;



      // -----------------------------------------------------
      // (4) Boost si c'est un favori
      // -----------------------------------------------------
      if (user.favoriteIds.contains(m.id)) {
        score += 3;
      }

      // -----------------------------------------------------
      // (5) L'utilisateur l'a déjà vu -> boost léger
      // -----------------------------------------------------
      if (user.viewedIds.contains(m.id)) {
        score += 1;
      }

      // -----------------------------------------------------
      // (6) Variation aléatoire pour éviter les listes répétées
      // -----------------------------------------------------
      score += Random().nextInt(2); // 0 ou +1

      scoredMovies.add({
        "movie": m,
        "score": score,
      });
    }

    // Trier du meilleur score au pire
    scoredMovies.sort((a, b) => b["score"] - a["score"]);

    // Retourner les X meilleurs films
    return scoredMovies
        .take(limit)
        .map((e) => e["movie"] as Movie)
        .toList();
  }

  /// Appelé quand l’utilisateur LIKE un film
  static void likeMovie(UserProfile user, Movie movie) {
    _addToListIfAbsent(user.favoriteIds, movie.id);

    // Boost film
    user.filmScores[movie.id] =
        (user.filmScores[movie.id] ?? 0) + 5;

    // Boost genre
    final genre = movie.genre.split(",").first.trim();
    user.genreScores[genre] =
        (user.genreScores[genre] ?? 0) + 2;

    user.save();
  }

  /// Appelé quand l’utilisateur DISLIKE un film
  static void dislikeMovie(UserProfile user, Movie movie) {
    user.filmScores[movie.id] =
        (user.filmScores[movie.id] ?? 0) - 5;

    final genre = movie.genre.split(",").first.trim();
    user.genreScores[genre] =
        (user.genreScores[genre] ?? 0) - 2;

    // Retirer des favoris si présent
    user.favoriteIds.remove(movie.id);

    user.save();
  }

  /// Appelé quand l’utilisateur consulte la fiche d’un film
  static void viewedMovie(UserProfile user, Movie movie) {
    _addToListIfAbsent(user.viewedIds, movie.id);

    // Petit boost pour consultation
    user.filmScores[movie.id] =
        (user.filmScores[movie.id] ?? 0) + 1;

    user.save();
  }

  /// Utilitaire
  static void _addToListIfAbsent(List<String> list, String id) {
    if (!list.contains(id)) {
      list.add(id);
    }
  }
}
