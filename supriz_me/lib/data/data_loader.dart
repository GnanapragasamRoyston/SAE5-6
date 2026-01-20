import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/movie.dart';
import '../models/activity.dart';
import '../models/board_game.dart';

class DataLoader {
  /// Charge les données UNIQUEMENT si les boîtes sont vides.
  /// Optimise le démarrage (Point 4.A du rapport).
  static Future<void> loadAllData({
    required Box<Movie> movieBox,
    required Box<Activity> activityBox,
    required Box<BoardGame> boardGameBox,
    required Box settingsBox,
  }) async {
    try {
      // 1. Optimisation Films : On ne charge que si la boîte est vide
      if (movieBox.isEmpty) {
        print('Initialisation de la base de données Films...');
        final movies = await _loadMoviesFromAssets();
        // Optimisation I/O : Insertion groupée (Batch insert)
        final Map<String, Movie> movieMap = {for (var m in movies) m.id: m};
        await movieBox.putAll(movieMap);
      } else {
        print('Films déjà chargés en cache local (${movieBox.length} éléments).');
      }

      // 2. Optimisation Activités
      if (activityBox.isEmpty) {
        print('Initialisation de la base de données Activités...');
        final activities = await _loadActivitiesFromAssets();
        final Map<String, Activity> activityMap = {for (var a in activities) a.id: a};
        await activityBox.putAll(activityMap);
      }

      // 3. Optimisation Jeux de Société
      if (boardGameBox.isEmpty) {
        print('Initialisation de la base de données Jeux...');
        final games = await _loadBoardGamesFromAssets();
        final Map<String, BoardGame> gameMap = {for (var g in games) g.id: g};
        await boardGameBox.putAll(gameMap);
      }
      
    } catch (e) {
      print('Erreur lors du chargement optimisé des données: $e');
    }
  }

  /// Permet de forcer le rechargement (Pour le bouton "Réinitialiser" - Point 3.B du rapport)
  static Future<void> forceReloadData({
    required Box<Movie> movieBox,
    required Box<Activity> activityBox,
    required Box<BoardGame> boardGameBox,
    required Box settingsBox,
  }) async {
    print('Réinitialisation complète demandée...');
    await movieBox.clear();
    await activityBox.clear();
    await boardGameBox.clear();
    // On peut aussi clear la settingsBox si tu veux effacer les préférences
    // await settingsBox.clear(); 
    
    // Relance le chargement propre
    await loadAllData(
      movieBox: movieBox, 
      activityBox: activityBox, 
      boardGameBox: boardGameBox, 
      settingsBox: settingsBox
    );
  }

  // -------------------------------------------------------------------------
  // Méthodes privées de lecture JSON (Renommées pour être internes)
  // -------------------------------------------------------------------------

  static Future<List<Movie>> _loadMoviesFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/bd_movies.json');
      final lines = jsonString.split('\n').where((line) => line.trim().isNotEmpty).toList();

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
        } catch (e) { /* Skip malformed */ }
      }
      return movies;
    } catch (e) { return []; }
  }

  static Future<List<Activity>> _loadActivitiesFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/activite.json');
      final jsonData = jsonDecode(jsonString) as List;

      final activities = <Activity>[];
      for (int i = 0; i < jsonData.length; i++) {
        try {
          final item = jsonData[i] as Map<String, dynamic>;
          final category = _normalizeCategory(item['categorie'] as String?) ?? _categorizeActivity(item);
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
        } catch (e) { /* Skip malformed */ }
      }
      return activities;
    } catch (e) { return []; }
  }

  static Future<List<BoardGame>> _loadBoardGamesFromAssets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/bgg_dataset_clean.json');
      final jsonData = jsonDecode(jsonString) as List;

      final games = <BoardGame>[];
      // Note : Limite à 500 conservée pour la performance initiale, peut être augmentée
      for (int i = 0; i < jsonData.length && i < 500; i++) {
        try {
          final item = jsonData[i] as Map<String, dynamic>;
          final mechanicsString = item['Mechanics']?.toString() ?? '';
          final shortDescription = mechanicsString.length > 100
              ? mechanicsString.substring(0, 100) : mechanicsString;

          final game = BoardGame(
            id: '${item['Title']}_$i',
            title: item['Title'] ?? 'Unknown',
            description: shortDescription,
            minPlayers: item['Min Players']?.toInt() ?? 1,
            maxPlayers: item['Max Players']?.toInt() ?? 4,
            avgDuration: (item['Play Time (moyen)'] as num?)?.toDouble() ?? 60.0,
            complexity: _parseComplexity(item['Difficulty']),
            rating: _parseRatingString(item['Rating']),
            genres: _parseGenres(item['Genre']),
            mechanics: _parseGenres(item['Mechanics']),
            releaseYear: (item['Release Year'] as num?)?.toInt() ?? 0,
            minAge: (item['Min Age'] as num?)?.toInt() ?? 8,
          );
          games.add(game);
        } catch (e) { continue; }
      }
      return games;
    } catch (e) {
      print('Erreur loadBoardGames: $e');
      return [];
    }
  }

  // -------------------------------------------------------------------------
  // Helpers (Inchangés, gardés pour le fonctionnement)
  // -------------------------------------------------------------------------

  static double _parseRating(dynamic value) {
    if (value is num) return (value.toDouble() / 10).clamp(0.0, 5.0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return ((parsed ?? 0) / 10).clamp(0.0, 5.0);
    }
    return 3.0;
  }

  static List<String> _parseTags(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((tag) => tag.trim().toUpperCase()).where((tag) => tag.isNotEmpty).toList();
  }

  static double _parseDurationString(String? value) {
    if (value == null || value.isEmpty) return 90.0;
    final cleanValue = value.toLowerCase().trim();
    double totalMinutes = 0;
    if (cleanValue.contains('h')) {
      final hourMatch = RegExp(r'(\d+)\s*h').firstMatch(cleanValue);
      if (hourMatch != null) totalMinutes += (int.tryParse(hourMatch.group(1) ?? '0') ?? 0) * 60;
      final minMatch = RegExp(r'h\s*(\d+)').firstMatch(cleanValue);
      if (minMatch != null) totalMinutes += (int.tryParse(minMatch.group(1) ?? '0') ?? 0);
      if (totalMinutes > 0) return totalMinutes;
    }
    if (cleanValue.contains('min')) {
      final minMatch = RegExp(r'(\d+)\s*min').firstMatch(cleanValue);
      if (minMatch != null) return (int.tryParse(minMatch.group(1) ?? '0') ?? 90).toDouble();
    }
    return 90.0;
  }

  static String _categorizeActivity(Map<String, dynamic> item) {
    final lieu = (item['lieu'] ?? '').toString().toLowerCase();
    final nom = (item['nom'] ?? '').toString().toLowerCase();
    
    if (lieu.contains('parc') || lieu.contains('jardin') || lieu.contains('exterieur')) return 'Extérieur';
    if (lieu.contains('maison') || lieu.contains('interieur') || lieu.contains('cinema')) return 'Intérieur';
    if (nom.contains('sport') || nom.contains('football') || nom.contains('yoga')) return 'Sport';
    if (nom.contains('musée') || nom.contains('concert') || nom.contains('art')) return 'Culture';
    if (nom.contains('spa') || nom.contains('massage') || nom.contains('détente')) return 'Relaxation';
    return 'Extérieur';
  }

  static String? _normalizeCategory(String? jsonCategory) {
    if (jsonCategory == null || jsonCategory.isEmpty) return null;
    final cat = jsonCategory.toLowerCase().trim();
    final categoryMap = {
      'sport': 'Sport', 'jeu': 'Créatif', 'creatif': 'Créatif', 'créatif': 'Créatif',
      'social': 'Social', 'detente': 'Relaxation', 'détente': 'Relaxation',
      'outdoor': 'Aventure', 'exterieur': 'Aventure', 'extérieur': 'Aventure',
      'interieur': 'Créatif', 'intérieur': 'Créatif',
    };
    return categoryMap[cat];
  }

  static double _parseRatingString(String? value) {
    if (value == null) return 3.0;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    return (parsed ?? 0).clamp(0.0, 10.0) / 2;
  }

  static double _parseComplexity(dynamic value) {
    if (value is num) return (value.toDouble()).clamp(0.0, 5.0);
    if (value is String) return (double.tryParse(value.replaceAll(',', '.')) ?? 0).clamp(0.0, 5.0);
    return 2.5;
  }

  static List<String> _parseGenres(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((genre) => genre.trim()).toList();
  }
}