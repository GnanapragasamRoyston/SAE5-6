import 'dart:convert';
import '../models/movie.dart';
import '../models/activity.dart';
import '../models/board_game.dart';

// --------------------------------------------------------------------------
// FONCTIONS DE PARSING PRINCIPALES (Appelées par compute)
// --------------------------------------------------------------------------

/// Parseur des Jeux de Société.
List<BoardGame> parseBoardGamesJson(String jsonString) {
  final jsonData = jsonDecode(jsonString) as List;

  final games = <BoardGame>[];
  // Limité à 500 entrées pour des raisons de performance.
  for (int i = 0; i < jsonData.length && i < 500; i++) {
    try {
      final item = jsonData[i] as Map<String, dynamic>;

      final mechanics = item['Mechanics']?.toString() ?? '';
      final description =
          mechanics.length > 100 ? mechanics.substring(0, 100) : mechanics;

      final game = BoardGame(
        id: '${item['Title']}_$i',
        title: item['Title'] ?? 'Unknown',
        description: description,
        minPlayers: item['Min Players']?.toInt() ?? 1,
        maxPlayers: item['Max Players']?.toInt() ?? 4,
        avgDuration: (item['Play Time (moyen)'] as num?)?.toDouble() ?? 60.0,
        complexity: _parseComplexity(item['Difficulty']),
        rating: _parseRatingString(item['Rating']),
        genres: item['Genre'],
        mechanics: item['Mechanics'],
        releaseYear: (item['Release Year'] as num?)?.toInt() ?? 0,
        minAge: (item['Min Age'] as num?)?.toInt() ?? 8,
      );
      games.add(game);
    } catch (e) {
      final title = (i < jsonData.length)
          ? (jsonData[i] as Map<String, dynamic>)['Title'] ?? 'Unknown Index $i'
          : 'Unknown';
      print('Erreur lors du parsing du jeu "$title" (Isolate): $e');
      continue;
    }
  }
  return games;
}

/// Parseur des Films.
List<Movie> parseMoviesJson(String jsonString) {
  final lines =
      jsonString.split('\n').where((line) => line.trim().isNotEmpty).toList();

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
        rating: _parseMovieRating(
            jsonData['score']), // Renommé pour éviter les conflits
        tags: _parseMovieTags(
            jsonData['genre']), // Renommé pour éviter les conflits
      );
      movies.add(movie);
    } catch (e) {
      // Skip malformed entries
    }
  }
  return movies;
}

/// Parseur des Activités.
List<Activity> parseActivitiesJson(String jsonString) {
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
}

// --------------------------------------------------------------------------
// FONCTIONS D'AIDE (Top-level pour être accessibles par les Isolates)
// Elles contiennent la logique de parsing pour chaque modèle.
// --------------------------------------------------------------------------

// --- Helpers des Jeux de Société (Dataset 3 - Votre Focus) ---

double _parseRatingString(String? value) {
  if (value == null) return 3.0;
  final cleanedValue = value.replaceAll(',', '.');
  final parsed = double.tryParse(cleanedValue);
  return (parsed ?? 0).clamp(0.0, 10.0) / 2;
}

double _parseComplexity(dynamic value) {
  if (value is num) return (value.toDouble()).clamp(0.0, 5.0);
  if (value is String) {
    final cleanedValue = value.replaceAll(',', '.');
    final parsed = double.tryParse(cleanedValue);
    return (parsed ?? 0).clamp(0.0, 5.0);
  }
  return 2.5;
}

// --- Helpers des Films (Dataset 1) ---

double _parseMovieRating(dynamic value) {
  if (value is num) return (value.toDouble() / 10).clamp(0.0, 5.0);
  if (value is String) {
    final parsed = double.tryParse(value);
    return ((parsed ?? 0) / 10).clamp(0.0, 5.0);
  }
  return 3.0;
}

List<String> _parseMovieTags(String? value) {
  if (value == null || value.isEmpty) return [];
  return value.split(',').map((tag) => tag.trim()).toList();
}

// --- Helpers des Activités (Dataset 2) ---

double _parseDurationString(String? value) {
  if (value == null || value.isEmpty) return 90.0;

  final cleanValue = value.toLowerCase().trim();
  double totalMinutes = 0;

  // 1. Handle "2h" or "1h30" or "1h 30min" format (priority)
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

String _categorizeActivity(Map<String, dynamic> item) {
  final lieu = (item['lieu'] ?? '').toString().toLowerCase();
  final nom = (item['nom'] ?? '').toString().toLowerCase();
  final description = (item['description'] ?? '').toString().toLowerCase();

  // Logique de catégorisation (la même que celle fournie)
  if (lieu.contains('parc') ||
      lieu.contains('extérieur') ||
      nom.contains('rando') ||
      nom.contains('vélo')) {
    return 'Extérieur';
  }
  if (lieu.contains('maison') ||
      lieu.contains('intérieur') ||
      nom.contains('jeu')) {
    return 'Intérieur';
  }
  if (nom.contains('football') ||
      nom.contains('sport') ||
      description.contains('sport')) {
    return 'Sport';
  }
  if (nom.contains('musée') || nom.contains('culture')) {
    return 'Culture';
  }
  if (nom.contains('méditation') || nom.contains('relaxation')) {
    return 'Relaxation';
  }

  // Fallback
  return 'Extérieur';
}
