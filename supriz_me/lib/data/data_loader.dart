import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
// Les trois modèles sont importés pour le chargement de toutes les données sajith
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
          final category = _categorizeActivity(item);
          final activity = Activity(
            id: '${item['nom']}_$i',
            title: item['nom'] ?? 'Unknown',
            description: item['description'] ?? '',
            category: category,
            duration: _parseDurationString(item['duree_moyenne']),
            minParticipants: item['joueurs_min'] ?? 1,
            maxParticipants: item['joueurs_max'] ?? 10,
            tags: [item['lieu'] ?? 'General'],
            difficulty: 2.5, // Default difficulty
          );
          activities.add(activity);
        } catch (e) {
          // Skip malformed entries
        }
      }
      return activities;
    } catch (e) {
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
  /// --- OPTIMISATION: Le chargement du JSON et l'enregistrement dans Hive ne se font
  /// --- que si la Box est vide, évitant ainsi un re-parsing coûteux à chaque démarrage.
  static Future<void> loadAllData({
    required Box<Movie> movieBox,
    required Box<Activity> activityBox,
    required Box<BoardGame> boardGameBox,
  }) async {
    try {
      // Chargement des Films
      if (movieBox.isEmpty) { // Si la Box est vide, on charge et sauvegarde
        final movies = await loadMovies();
        // Utilisation de putAll pour une sauvegarde plus efficace
        final Map<dynamic, Movie> moviesMap = {
          for (var movie in movies) movie.id: movie
        };
        await movieBox.putAll(moviesMap);
        print('${movies.length} films chargés dans Hive (1ère fois).');
      } else {
        print('${movieBox.length} films déjà chargés dans Hive.');
      }

      // Chargement des Activités
      if (activityBox.isEmpty) { // Si la Box est vide, on charge et sauvegarde
        final activities = await loadActivities();
        // Utilisation de putAll pour une sauvegarde plus efficace
        final Map<dynamic, Activity> activitiesMap = {
          for (var activity in activities) activity.id: activity
        };
        await activityBox.putAll(activitiesMap);
        print('${activities.length} activités chargées dans Hive (1ère fois).');
      } else {
        print('${activityBox.length} activités déjà chargées dans Hive.');
      }

      // Chargement des Jeux de Société (La source de la lenteur)
      if (boardGameBox.isEmpty) { // Vérification CRUCIALE
        final games = await loadBoardGames();
        // Utilisation de putAll pour une sauvegarde plus efficace
        final Map<dynamic, BoardGame> gamesMap = {
          for (var game in games) game.id: game
        };
        await boardGameBox.putAll(gamesMap);
        print('${games.length} jeux de société chargés dans Hive (1ère fois).');
      } else {
        print('${boardGameBox.length} jeux de société déjà chargés dans Hive.');
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
      final minMatch = RegExp(r'h\s*(\d+)').firstMatch(cleanValue);
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

  static String _categorizeActivity(Map<String, dynamic> item) {
    final lieu = (item['lieu'] ?? '').toString().toLowerCase();
    final nom = (item['nom'] ?? '').toString().toLowerCase();
    final description = (item['description'] ?? '').toString().toLowerCase();

    if (lieu.contains('parc') ||
        lieu.contains('jardin') ||
        lieu.contains('extérieur') ||
        lieu.contains('exterieur') ||
        nom.contains('rando') ||
        nom.contains('vélo') ||
        nom.contains('velo') ||
        nom.contains('pique')) {
      return 'Extérieur';
    }

    if (lieu.contains('maison') ||
        lieu.contains('intérieur') ||
        lieu.contains('interieur') ||
        lieu.contains('bowling') ||
        lieu.contains('cinéma') ||
        lieu.contains('cinema') ||
        nom.contains('jeu') ||
        nom.contains('film')) {
      return 'Intérieur';
    }

    if (nom.contains('football') ||
        nom.contains('basketball') ||
        nom.contains('tennis') ||
        nom.contains('yoga') ||
        nom.contains('sport') ||
        nom.contains('natation') ||
        nom.contains('boxe') ||
        description.contains('sport')) {
      return 'Sport';
    }

    if (nom.contains('musée') ||
        nom.contains('museum') ||
        nom.contains('théâtre') ||
        nom.contains('theatre') ||
        nom.contains('concert') ||
        nom.contains('galerie') ||
        nom.contains('exposition') ||
        nom.contains('art') ||
        nom.contains('culture')) {
      return 'Culture';
    }

    if (nom.contains('méditation') ||
        nom.contains('meditation') ||
        nom.contains('spa') ||
        nom.contains('massage') ||
        nom.contains('relaxation') ||
        nom.contains('détente') ||
        nom.contains('detente') ||
        description.contains('détente') ||
        description.contains('detente')) {
      return 'Relaxation';
    }

    return 'Extérieur';
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