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
          // Utilise la catégorie du JSON, sinon génère automatiquement
          final category = _normalizeCategory(item['categorie'] as String?) ??
              _categorizeActivity(item);
          // Utilise la difficulté du JSON, sinon 2.5 par défaut
          final difficulty = (item['difficulty'] as num?)?.toDouble() ?? 2.5;

          final activity = Activity(
            id: '${item['nom']}_$i',
            title: item['nom'] ?? 'Unknown',
            description: item['description'] ?? '',
            category: category,
            duration: _parseDurationString(item['duree_moyenne']),
            minParticipants: item['joueurs_min'] ?? 1,
            maxParticipants: item['joueurs_max'] ?? 10,
            tags: [item['lieu'] ?? 'General'],
            difficulty: difficulty,
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
  static Future<List<BoardGame>> loadBoardGames() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/bgg_dataset_clean.json',
      );
      final jsonData = jsonDecode(jsonString) as List;

      final games = <BoardGame>[];
      for (int i = 0; i < jsonData.length && i < 500; i++) {
        try {
          final item = jsonData[i] as Map<String, dynamic>;

          final mechanicsString = item['Mechanics']?.toString() ?? '';
          final shortDescription = mechanicsString.length > 100
              ? mechanicsString.substring(0, 100)
              : mechanicsString;

          final game = BoardGame(
            id: '${item['Title']}_$i',
            title: item['Title'] ?? 'Unknown',
            description: shortDescription, // Utilise la description courte
            minPlayers: item['Min Players']?.toInt() ?? 1,
            maxPlayers: item['Max Players']?.toInt() ?? 4,
            avgDuration:
                (item['Play Time (moyen)'] as num?)?.toDouble() ?? 60.0,
            complexity: _parseComplexity(item['Difficulty']),
            rating: _parseRatingString(item['Rating']),

            // ✅ CORRECTION BoardGame: 'tags' devient 'genres'
            genres: _parseGenres(item['Genre']),

            // ✅ CORRECTION BoardGame: Ajout de 'mechanics'
            mechanics: _parseGenres(item['Mechanics']),

            releaseYear: (item['Release Year'] as num?)?.toInt() ?? 0,
            minAge: (item['Min Age'] as num?)?.toInt() ?? 8,
          );
          games.add(game);
        } catch (e) {
          final title = (i < jsonData.length)
              ? (jsonData[i] as Map<String, dynamic>)['Title'] ??
                  'Unknown Index $i'
              : 'Unknown';
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
    required Box settingsBox, // 🎯 settingsBox ajouté pour la cohérence
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

      // Note: Pas de loadAndSaveUniqueMovieTags ici car la liste est hardcodée
    } catch (e) {
      print('Erreur lors du chargement ou de la sauvegarde des données: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Helper methods (Méthodes d'aide pour le parsing des différents datasets)
  // -------------------------------------------------------------------------

  // --- Helpers des Films (Dataset 1) ---

  static double _parseRating(dynamic value) {
    if (value is num) return (value.toDouble() / 10).clamp(0.0, 5.0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return ((parsed ?? 0) / 10).clamp(0.0, 5.0);
    }
    return 3.0;
  }

  static List<String> _parseTags(String? value) {
    // Tags des Films : Normalisation en MAJUSCULE pour le matching
    if (value == null || value.isEmpty) return [];
    return value
        .split(',')
        .map((tag) => tag.trim().toUpperCase())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  // --- Helpers des Activités (Dataset 2) ---

  static double _parseDurationString(String? value) {
    if (value == null || value.isEmpty) return 90.0;

    final cleanValue = value.toLowerCase().trim();
    double totalMinutes = 0;

    if (cleanValue.contains('h')) {
      final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(cleanValue);
      if (hourMatch != null) {
        final hours = int.tryParse(hourMatch.group(1) ?? '0') ?? 0;
        totalMinutes += hours * 60;
      }

      final minMatch = RegExp(r'h\s*(\d+)').firstMatch(cleanValue);
      if (minMatch != null) {
        final mins = int.tryParse(minMatch.group(1) ?? '0') ?? 0;
        totalMinutes += mins;
      }

      if (totalMinutes > 0) return totalMinutes;
    }

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

  /// Normalise les catégories du JSON vers les catégories de l'app
  static String? _normalizeCategory(String? jsonCategory) {
    if (jsonCategory == null || jsonCategory.isEmpty) return null;

    final cat = jsonCategory.toLowerCase().trim();

    // Mapping des catégories JSON vers les catégories de l'app
    final categoryMap = {
      'sport': 'Sport',
      'jeu': 'Créatif',
      'creatif': 'Créatif',
      'créatif': 'Créatif',
      'social': 'Social',
      'detente': 'Relaxation',
      'détente': 'Relaxation',
      'outdoor': 'Aventure',
      'exterieur': 'Aventure',
      'extérieur': 'Aventure',
      'interieur': 'Créatif',
      'intérieur': 'Créatif',
    };

    return categoryMap[cat];
  }

  // --- Helpers des Jeux de Société (Dataset 3) ---

  static double _parseRatingString(String? value) {
    if (value == null) return 3.0;
    final cleanedValue = value.replaceAll(',', '.');
    final parsed = double.tryParse(cleanedValue);
    return (parsed ?? 0).clamp(0.0, 10.0) / 2;
  }

  static double _parseComplexity(dynamic value) {
    if (value is num) return (value.toDouble()).clamp(0.0, 5.0);
    if (value is String) {
      final cleanedValue = value.replaceAll(',', '.');
      final parsed = double.tryParse(cleanedValue);
      return (parsed ?? 0).clamp(0.0, 5.0);
    }
    return 2.5;
  }

  static List<String> _parseGenres(String? value) {
    // NOTE: Ce helper est utilisé pour parser à la fois 'Genre' et 'Mechanics' du JSON BGG
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((genre) => genre.trim()).toList();
  }
}
