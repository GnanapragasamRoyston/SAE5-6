import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Models
import 'models/movie.dart';
import 'models/activity.dart';
import 'models/board_game.dart';
import 'models/user_profile.dart';

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
  Hive.registerAdapter(UserProfileAdapter());

  // Clear old boxes to force reload with new parsing logic
  try {
    await Hive.deleteBoxFromDisk('activities');
    await Hive.deleteBoxFromDisk('movies');
    await Hive.deleteBoxFromDisk('board_games');
  } catch (e) {
    // Boxes might not exist yet
  }

  // Open boxes
  final movieBox = await Hive.openBox<Movie>('movies');
  final activityBox = await Hive.openBox<Activity>('activities');
  final boardGameBox = await Hive.openBox<BoardGame>('board_games');
  final userBox = await Hive.openBox<UserProfile>('user_profiles');

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
      userBox: userBox,
    ),
  );
}

class SurprizMeApp extends StatelessWidget {
  final Box<Movie> movieBox;
  final Box<Activity> activityBox;
  final Box<BoardGame> boardGameBox;
  final Box<UserProfile> userBox;

  const SurprizMeApp({
    super.key,
    required this.movieBox,
    required this.activityBox,
    required this.boardGameBox,
    required this.userBox,
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
        userBox: userBox,
      ),
    );
  }
}
