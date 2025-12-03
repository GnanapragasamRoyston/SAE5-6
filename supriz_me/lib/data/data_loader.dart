import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
// Les trois modèles sont importés pour le chargement de toutes les données
import '../models/movie.dart';
import '../models/activity.dart';
import '../models/board_game.dart';

class DataLoader {
  /// Charge les films depuis le fichier JSON (Logiciel géré par les collègues)
  static Future<List<Movie>> loadMovies() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/bd_movies.json',
      );
      final lines = jsonString
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      final movies = <Movie>[];
      for (final line in lines) {
        try {
          final jsonData = jsonDecode(line) as Map<String, dynamic>;
          final movie = Movie(
            id: jsonData['names'] ?? 'unknown',
            title: jsonData['names'] ?? 'Unknown',
            description: jsonData['overview'] ?? '',
            genre: jsonData['genre'] ?? 'Unknown',
            duration: (jsonData['duration'] as num?)?.toDouble() ?? 120.0,
            rating: _parseRating(jsonData['score']),
            tags: _parseTags(jsonData['genre']),
          );
          movies.add(movie);
        } catch (e) {
          // Skip malformed entries
        }
      }
      return movies;
    } catch (e) {
      return [];
    }
  }

  /// Charge les activités depuis le fichier JSON (Logiciel géré par les collègues)
  static Future<List<Activity>> loadActivities() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/activite.json',
      );
      final jsonData = jsonDecode(jsonString) as List;

      final activities = <Activity>[];
      for (int i = 0; i < jsonData.length; i++) {
        try {
          final item = jsonData[i] as Map<String, dynamic>;
          final activity = Activity(
            id: '${item['nom']}_$i',
            title: item['nom'] ?? 'Unknown',
            description: item['description'] ?? '',
            category: _parseActivityCategory(item['categorie']),
            duration: _parseDurationString(item['duree_moyenne']),
            minParticipants: item['joueurs_min'] ?? 1,
            maxParticipants: item['joueurs_max'] ?? 10,
            tags: [item['lieu'] ?? 'General'],
            difficulty: 2.5, // Default difficulty
          );
          activities.add(activity);
        } catch (e) {
          print('Erreur parsing activité index $i: $e');
          continue;
          // Skip malformed entries
        }
      }
      return activities;
    } catch (e) {
      print('Erreur lors du chargement des activités: $e');
      return [];
    }
  }

  /// Charge les jeux de société depuis le fichier JSON (Focus sur les jeux)
  /// Inclut maintenant l'année de sortie (releaseYear) et l'âge minimum (minAge).
  static Future<List<BoardGame>> loadBoardGames() async {
    try {
      // Chargement du fichier JSON contenant les données des jeux de société.
      final jsonString = await rootBundle.loadString(
        'assets/data/bgg_dataset_clean.json',
      );
      final jsonData = jsonDecode(jsonString) as List;

      final games = <BoardGame>[];
      // Limité à 500 entrées pour des raisons de performance.
      for (int i = 0; i < jsonData.length && i < 500; i++) {
        try {
          final item = jsonData[i] as Map<String, dynamic>;

          // Tronquage de la description pour l'enregistrement
          final mechanics = item['Mechanics']?.toString() ?? '';
          final description = mechanics.length > 100 
              ? mechanics.substring(0, 100) 
              : mechanics;

          final game = BoardGame(
            id: '${item['Title']}_$i',
            title: item['Title'] ?? 'Unknown',
            description: description,
            minPlayers: item['Min Players']?.toInt() ?? 1,
            maxPlayers: item['Max Players']?.toInt() ?? 4,
            avgDuration:
                (item['Play Time (moyen)'] as num?)?.toDouble() ?? 60.0,
            complexity: _parseComplexity(item['Difficulty']),
            rating: _parseRatingString(item['Rating']),
            tags: _parseGenres(item['Genre']),
            // Extraction de l'année de sortie.
            releaseYear: (item['Release Year'] as num?)?.toInt() ?? 0, 
            // CORRECTION: AJOUTÉ l'âge minimum qui manquait dans l'appel du constructeur.
            minAge: (item['Min Age'] as num?)?.toInt() ?? 8, 
          );
          games.add(game);
        } catch (e) {
          // Log pour les entrées mal formées (utile pour le débogage)
          // On suppose que item['Title'] existe ou est null ici
          final title = (i < jsonData.length) ? (jsonData[i] as Map<String, dynamic>)['Title'] ?? 'Unknown Index $i' : 'Unknown';
          print('Erreur lors du parsing du jeu "$title": $e');
          continue; 
        }
      }
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

      // Chargement des Jeux de Société
      final games = await loadBoardGames();
      for (final game in games) {
        await boardGameBox.put(game.id, game);
      }
    } catch (e) {
      print('Erreur lors du chargement ou de la sauvegarde des données: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Helper methods (Méthodes d'aide pour le parsing des différents datasets)
  // -------------------------------------------------------------------------

  // --- Helpers des Films (Dataset 1) ---

  static double _parseRating(dynamic value) {
    // Note sur 10 (Movie) convertie à 0-5
    if (value is num) return (value.toDouble() / 10).clamp(0.0, 5.0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return ((parsed ?? 0) / 10).clamp(0.0, 5.0);
    }
    return 3.0;
  }

  static List<String> _parseTags(String? value) {
    // Tags des Films
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((tag) => tag.trim()).toList();
  }

  // --- Helpers des Activités (Dataset 2) ---

  static ActivityCategory _parseActivityCategory(dynamic value) {
    if (value == null) return ActivityCategory.social;
    final categoryStr = value.toString().toLowerCase().trim();
    
    try {
      return ActivityCategory.values.firstWhere(
        (cat) => cat.toString().split('.').last == categoryStr,
        orElse: () => ActivityCategory.social,
      );
    } catch (e) {
      return ActivityCategory.social;
    }
  }

  static double _parseDurationString(String? value) {
    if (value == null || value.isEmpty) return 90.0;

    final cleanValue = value.toLowerCase().trim();
    double totalMinutes = 0;

    // 1. Handle "2h" or "1h30" or "1h 30min" format (priority)
    if (cleanValue.contains('h')) {
      // Extract hours
      final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(cleanValue);
      if (hourMatch != null) {
        final hours = int.tryParse(hourMatch.group(1) ?? '0') ?? 0;
        totalMinutes += hours * 60;
      }

      // Extract minutes after 'h' (if exists)
      final minMatch = RegExp(r'h\s*(\d+)|(\d+)\s*min').firstMatch(cleanValue);
      if (minMatch != null) {
        final mins = int.tryParse(minMatch.group(1) ?? '0') ?? 0;
        totalMinutes += mins;
      }

      if (totalMinutes > 0) return totalMinutes;
    }

    // 2. Handle "45min", "45 min", "10min" format
    if (cleanValue.contains('min')) {
      final minMatch = RegExp(r'(\d+)\s*min').firstMatch(cleanValue);
      if (minMatch != null) {
        final mins = int.tryParse(minMatch.group(1) ?? '0');
        if (mins != null && mins > 0) return mins.toDouble();
      }
    }

    return 90.0;
  }

  // --- Helpers des Jeux de Société (Dataset 3 - Votre Focus) ---

  /// Analyse la chaîne de caractères de la note et la convertit en double 0-5.
  /// Le dataset utilise une échelle 0-10, séparateur décimal ','
  static double _parseRatingString(String? value) {
    if (value == null) return 3.0;
    // Remplace la virgule par un point pour le parsing
    final cleanedValue = value.replaceAll(',', '.');
    final parsed = double.tryParse(cleanedValue);
    // Convertit de 0-10 à 0-5
    return (parsed ?? 0).clamp(0.0, 10.0) / 2; 
  }

  /// Analyse la valeur de complexité et la convertit en double 0-5.
  /// Le dataset utilise une échelle 0-5, séparateur décimal ','
  static double _parseComplexity(dynamic value) {
    if (value is num) return (value.toDouble()).clamp(0.0, 5.0);
    if (value is String) {
      // Remplace la virgule par un point pour le parsing
      final cleanedValue = value.replaceAll(',', '.'); 
      final parsed = double.tryParse(cleanedValue);
      return (parsed ?? 0).clamp(0.0, 5.0);
    }
    return 2.5;
  }

  /// Convertit une chaîne de genres séparés par des virgules en List<String>.
  static List<String> _parseGenres(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((genre) => genre.trim()).toList();
  }
}