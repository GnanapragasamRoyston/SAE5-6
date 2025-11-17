import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/movie.dart';
import 'models/activity.dart';
import 'models/board_game.dart';
import 'models/user_profile.dart';
import 'screens/home_screen.dart';
import 'data/data_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(MovieAdapter());
  Hive.registerAdapter(ActivityAdapter());
  Hive.registerAdapter(BoardGameAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  // Open boxes
  final movieBox = await Hive.openBox<Movie>('movies');
  final activityBox = await Hive.openBox<Activity>('activities');
  final boardGameBox = await Hive.openBox<BoardGame>('board_games');
  final userBox = await Hive.openBox<UserProfile>('user_profiles');

  // Load data if boxes are empty
  if (movieBox.isEmpty) {
    await DataLoader.loadAllData(
      movieBox: movieBox,
      activityBox: activityBox,
      boardGameBox: boardGameBox,
    );
  }

  runApp(MyApp(
    movieBox: movieBox,
    activityBox: activityBox,
    boardGameBox: boardGameBox,
    userBox: userBox,
  ));
}

class MyApp extends StatelessWidget {
  final Box<Movie> movieBox;
  final Box<Activity> activityBox;
  final Box<BoardGame> boardGameBox;
  final Box<UserProfile> userBox;

  const MyApp({
    super.key,
    required this.movieBox,
    required this.activityBox,
    required this.boardGameBox,
    required this.userBox,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supriz Me',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}