import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; 
import 'package:dart:convert';
import 'package:hive/hive.dart';

// Importation des modèles
import '../models/movie.dart';
import '../models/activity.dart';
import '../models/board_game.dart';

// Importation des fonctions de parsing de niveau supérieur pour compute
import 'data_loader_helpers.dart'; 

class DataLoader {
  /// Charge les films depuis le fichier JSON (MAINTENANT ASYNCHRONE via compute)
  static Future<List<Movie>> loadMovies() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/bd_movies.json',
      );
      // Utilisation de compute pour garantir que l'UI n'est pas bloquée
      final List<Movie> movies = await compute(parseMoviesJson, jsonString);
      return movies;
    } catch (e) {
      print('Erreur lors du chargement des films (Isolate): $e');
      return [];
    }
  }

  /// Charge les activités depuis le fichier JSON (MAINTENANT ASYNCHRONE via compute)
  static Future<List<Activity>> loadActivities() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/activite.json',
      );
      // Utilisation de compute pour garantir que l'UI n'est pas bloquée
      final List<Activity> activities = await compute(parseActivitiesJson, jsonString);
      return activities;
    } catch (e) {
      print('Erreur lors du chargement des activités (Isolate): $e');
      return [];
    }
  }

  /// Charge les jeux de société depuis le fichier JSON (ASYNCHRONE / ISOLATE - FIXÉ)
  static Future<List<BoardGame>> loadBoardGames() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/bgg_dataset_clean.json',
      );
      
      // Utilisation de compute pour décoder le JSON lourd sur un autre thread
      final List<BoardGame> games = await compute(parseBoardGamesJson, jsonString);
      
      return games;
    } catch (e) {
      print('Erreur fatale lors du chargement des jeux de société: $e');
      return [];
    }
  }

  /// Charge toutes les données et les sauvegarde dans Hive (Méthode complète)
  static Future<void> loadAllData({
    required Box<Movie> movieBox,
    required Box<Activity> activityBox,
    required Box<BoardGame> boardGameBox,
  }) async {
    try {
      // Chargement des Films
      final movies = await loadMovies();
      for (final movie in movies) {
        await movieBox.put(movie.id, movie);
      }

      // Chargement des Activités
      final activities = await loadActivities();
      for (final activity in activities) {
        await activityBox.put(activity.id, activity);
      }

      // Chargement des Jeux de Société (Maintenant rapide grâce à l'isolate)
      final games = await loadBoardGames();
      for (final game in games) {
        await boardGameBox.put(game.id, game);
      }
    } catch (e) {
      print('Erreur lors du chargement ou de la sauvegarde des données: $e');
    }
  }

  // NOTE IMPORTANTE: Toutes les fonctions d'aide (_parse*, _categorize*) 
  // ont été déplacées dans data_loader_helpers.dart pour la modularité 
  // et l'accessibilité par les Isolates.
}