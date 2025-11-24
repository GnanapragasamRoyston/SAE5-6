import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Models
import 'models/movie.dart';
import 'models/activity.dart';
import 'models/board_game.dart';
import 'models/activity_rating.dart';
import 'models/activity_preferences.dart';
import 'models/performance_metrics.dart';
import 'models/performance_metrics_adapter.dart';

// Data loading
import 'data/data_loader.dart';

// Views
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(MovieAdapter());
  Hive.registerAdapter(ActivityAdapter());
  Hive.registerAdapter(BoardGameAdapter());
  Hive.registerAdapter(ActivityRatingAdapter());
  Hive.registerAdapter(ActivityPreferencesAdapter());
  Hive.registerAdapter(PerformanceMetricsAdapter());

  // Clear old boxes to force reload with new parsing logic
  try {
    await Hive.deleteBoxFromDisk('activities');
    await Hive.deleteBoxFromDisk('movies');
    await Hive.deleteBoxFromDisk('board_games');
    await Hive.deleteBoxFromDisk('activity_ratings');
    await Hive.deleteBoxFromDisk('activity_preferences');
    await Hive.deleteBoxFromDisk('performanceMetrics');
  } catch (e) {
    // Boxes might not exist yet
  }

  // Open boxes
  final movieBox = await Hive.openBox<Movie>('movies');
  final activityBox = await Hive.openBox<Activity>('activities');
  final boardGameBox = await Hive.openBox<BoardGame>('board_games');
  final activityRatingBox = await Hive.openBox<ActivityRating>(
    'activity_ratings',
  );
  final activityPreferencesBox = await Hive.openBox<ActivityPreferences>(
    'activity_preferences',
  );
  final metricsBox = await Hive.openBox<PerformanceMetrics>(
    'performanceMetrics',
  );

  // Load data
  await DataLoader.loadAllData(
    movieBox: movieBox,
    activityBox: activityBox,
    boardGameBox: boardGameBox,
  );

  

  runApp(
    SurprizMeApp(
      movieBox: movieBox,
      activityBox: activityBox,
      boardGameBox: boardGameBox,
      activityRatingBox: activityRatingBox,
      activityPreferencesBox: activityPreferencesBox,
      metricsBox: metricsBox,
    ),
  );
}


class SurprizMeApp extends StatelessWidget {
  final Box<Movie> movieBox;
  final Box<Activity> activityBox;
  final Box<BoardGame> boardGameBox;
  final Box<ActivityRating> activityRatingBox;
  final Box<ActivityPreferences> activityPreferencesBox;
  final Box<PerformanceMetrics> metricsBox;

  const SurprizMeApp({
    super.key,
    required this.movieBox,
    required this.activityBox,
    required this.boardGameBox,
    required this.activityRatingBox,
    required this.activityPreferencesBox,
    required this.metricsBox,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Surpriz'Me",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(
        movieBox: movieBox,
        activityBox: activityBox,
        boardGameBox: boardGameBox,
        activityRatingBox: activityRatingBox,
        activityPreferencesBox: activityPreferencesBox,
        metricsBox: metricsBox,
      ),
    );
  }
}
