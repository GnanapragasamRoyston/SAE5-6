// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supriz_me/main.dart';
import 'package:supriz_me/models/movie.dart';
import 'package:supriz_me/models/activity.dart';
import 'package:supriz_me/models/board_game.dart';
import 'package:supriz_me/models/activity_rating.dart';
import 'package:supriz_me/models/activity_preferences.dart';
import 'package:supriz_me/models/performance_metrics.dart';
import 'package:supriz_me/models/performance_metrics_adapter.dart';
import 'package:supriz_me/models/movie_rating.dart';

void main() {
  testWidgets('Supriz Me app launches', (WidgetTester tester) async {
    // Initialize Hive for testing
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(MovieAdapter());
    Hive.registerAdapter(ActivityAdapter());
    Hive.registerAdapter(BoardGameAdapter());
    Hive.registerAdapter(ActivityRatingAdapter());
    Hive.registerAdapter(ActivityPreferencesAdapter());
    Hive.registerAdapter(PerformanceMetricsAdapter());

    // Open boxes
    final movieBox = await Hive.openBox<Movie>('movies_test');
    final activityBox = await Hive.openBox<Activity>('activities_test');
    final boardGameBox = await Hive.openBox<BoardGame>('board_games_test');
    final activityRatingBox = await Hive.openBox<ActivityRating>(
      'activity_ratings_test',
    );
    final activityPreferencesBox = await Hive.openBox<ActivityPreferences>(
      'activity_preferences_test',
    );

    final movieRatingBox = await Hive.openBox<MovieRating>(
      // 🎯 NOUVEAU: Ouverture de la box
      'movie_ratings_test',
    );

    final metricsBox = await Hive.openBox<PerformanceMetrics>(
      'performanceMetrics_test',
    );

    final settingsBox = await Hive.openBox('user_settings_test');

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      SurprizMeApp(
        movieBox: movieBox,
        activityBox: activityBox,
        boardGameBox: boardGameBox,
        activityRatingBox: activityRatingBox,
        activityPreferencesBox: activityPreferencesBox,
        movieRatingBox: movieRatingBox,
        metricsBox: metricsBox,
        settingsBox: settingsBox,
      ),
    );

    // Verify that the app shows "Surpriz'Me"
    expect(find.text("Surpriz'Me"), findsOneWidget);
  });
}
