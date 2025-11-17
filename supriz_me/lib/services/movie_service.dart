import 'package:hive/hive.dart';
import '../models/movie.dart';

class MovieService {
  final Box<Movie> _movieBox;

  MovieService(this._movieBox);

  /// Ajoute un film à la base de données
  Future<void> addMovie(Movie movie) async {
    await _movieBox.put(movie.id, movie);
  }

  /// Récupère tous les films
  List<Movie> getAllMovies() {
    return _movieBox.values.toList();
  }

  /// Récupère un film par ID
  Movie? getMovieById(String id) {
    return _movieBox.get(id);
  }

  /// Supprime un film
  Future<void> deleteMovie(String id) async {
    await _movieBox.delete(id);
  }

  /// Récupère les films par genre
  List<Movie> getMoviesByGenre(String genre) {
    return _movieBox.values
        .where((movie) => movie.genre.toLowerCase() == genre.toLowerCase())
        .toList();
  }
}
