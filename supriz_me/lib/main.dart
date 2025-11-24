import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Models
import 'models/movie.dart';
import 'models/activity.dart';
import 'models/board_game.dart';
import 'models/activity_rating.dart';
import 'models/activity_preferences.dart';
import 'models/performance_metrics.dart';
import 'models/performance_metrics_adapter.dart'; // NOTE: Ce modèle doit exister

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

  // --- CORRECTION MAJEURE: Suppression du nettoyage forcé ---
  // Nous ne nettoyons plus les boîtes contenant le dataset (movies, activities, board_games)
  // pour éviter de recharger 1600+ entrées à chaque lancement.
  try {
    // Si vous aviez une erreur dans un modèle, vous pouvez laisser la suppression
    // de la boîte concernée le temps d'une seule exécution, puis la retirer.
    // Pour l'instant, on suppose que les modèles sont stables.
    // NOTE: Si vous rencontrez toujours des erreurs de type (virgule/point),
    // vous pouvez réactiver temporairement: await Hive.deleteBoxFromDisk('board_games');
  } catch (e) {
    // Les boîtes n'existent peut-être pas encore
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
  
  // NOUVEAU : Box pour les réglages utilisateur (incluant les préférences de jeux sajith)
  final settingsBox = await Hive.openBox('user_settings');
  // On laisse cette ligne pour permettre la re-configuration des préférences si besoin
  await settingsBox.delete('game_preferences_set');

  // Load data (Cette fonction doit maintenant vérifier si les boîtes sont vides)
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
      settingsBox: settingsBox,
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
  final Box settingsBox;

  const SurprizMeApp({
    super.key,
    required this.movieBox,
    required this.activityBox,
    required this.boardGameBox,
    required this.activityRatingBox,
    required this.activityPreferencesBox,
    required this.metricsBox,
    required this.settingsBox,
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
        // NOTE: J'ai retiré le movieBox de HomePage dans la correction précédente,
        // mais vu votre structure main.dart, il doit être là. J'ajuste HomePage à nouveau.
        movieBox: movieBox,
        activityBox: activityBox,
        boardGameBox: boardGameBox,
        activityRatingBox: activityRatingBox,
        activityPreferencesBox: activityPreferencesBox,
        metricsBox: metricsBox,
        settingsBox: settingsBox,
      ),
    );
  }
}