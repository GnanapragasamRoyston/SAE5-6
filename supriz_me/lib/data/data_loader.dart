import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/movie.dart';
import '../models/activity.dart';
import '../models/board_game.dart';

class DataLoader {
  /// Charge les films depuis le fichier JSON
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

  /// Charge les activités depuis le fichier JSON
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
            category: item['lieu'] ?? 'General',
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

  /// Charge les jeux de société depuis le fichier JSON
  static Future<List<BoardGame>> loadBoardGames() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/bgg_dataset_clean.json',
      );
      final jsonData = jsonDecode(jsonString) as List;

      final games = <BoardGame>[];
      for (int i = 0; i < jsonData.length && i < 500; i++) {
        // Limit to 500 for performance
        try {
          final item = jsonData[i] as Map<String, dynamic>;
          final game = BoardGame(
            id: '${item['Title']}_$i',
            title: item['Title'] ?? 'Unknown',
            description: item['Mechanics']?.toString().substring(0, 100) ?? '',
            minPlayers: item['Min Players']?.toInt() ?? 1,
            maxPlayers: item['Max Players']?.toInt() ?? 4,
            avgDuration:
                (item['Play Time (moyen)'] as num?)?.toDouble() ?? 60.0,
            complexity: _parseComplexity(item['Difficulty']),
            rating: _parseRatingString(item['Rating']),
            tags: _parseGenres(item['Genre']),
          );
          games.add(game);
        } catch (e) {
          // Skip malformed entries
        }
      }
      return games;
    } catch (e) {
      return [];
    }
  }

  /// Charge toutes les données et les sauvegarde dans Hive
  static Future<void> loadAllData({
    required Box<Movie> movieBox,
    required Box<Activity> activityBox,
    required Box<BoardGame> boardGameBox,
  }) async {
    try {
      final movies = await loadMovies();
      for (final movie in movies) {
        await movieBox.put(movie.id, movie);
      }

      final activities = await loadActivities();
      for (final activity in activities) {
        await activityBox.put(activity.id, activity);
      }

      final games = await loadBoardGames();
      for (final game in games) {
        await boardGameBox.put(game.id, game);
      }
    } catch (e) {
      // Error handling
    }
  }

  // Helper methods
  static double _parseDurationString(String? value) {
    if (value == null || value.isEmpty) return 90.0;

    final cleanValue = value.toLowerCase().trim();

    // Handle "2h" or "1h30" or "1h 30min" format (priority)
    if (cleanValue.contains('h')) {
      double totalMinutes = 0;

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

    // Handle "45min", "45 min", "10min" format
    if (cleanValue.contains('min')) {
      // Extract the number(s) before 'min'
      final minMatch = RegExp(r'(\d+)\s*min').firstMatch(cleanValue);
      if (minMatch != null) {
        final mins = int.tryParse(minMatch.group(1) ?? '0');
        if (mins != null && mins > 0) return mins.toDouble();
      }
    }

    return 90.0;
  }

  static double _parseRating(dynamic value) {
    if (value is num) return (value.toDouble() / 10).clamp(0.0, 5.0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return ((parsed ?? 0) / 10).clamp(0.0, 5.0);
    }
    return 3.0;
  }

  static double _parseRatingString(String? value) {
    if (value == null) return 3.0;
    final cleanedValue = value.replaceAll(',', '.');
    final parsed = double.tryParse(cleanedValue);
    return (parsed ?? 0).clamp(0.0, 10.0) / 2; // Convert from 0-10 to 0-5
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

  static List<String> _parseTags(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((tag) => tag.trim()).toList();
  }

  static List<String> _parseGenres(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((genre) => genre.trim()).toList();
  }
}
