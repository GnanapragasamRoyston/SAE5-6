import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/movie.dart';
import 'models/activity.dart';
import 'models/board_game.dart';
import 'models/user_profile.dart';
import 'data/data_loader.dart';
import 'films.dart';
import 'jeux.dart';
import 'activites.dart';

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
<<<<<<< Updated upstream
      title: 'Supriz Me',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
=======
      debugShowCheckedModeBanner: false,
      title: "Surpriz'Me",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.poppinsTextTheme(),
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

class HomePage extends StatelessWidget {
  final Box<Movie> movieBox;
  final Box<Activity> activityBox;
  final Box<BoardGame> boardGameBox;
  final Box<UserProfile> userBox;

  const HomePage({
    super.key,
    required this.movieBox,
    required this.activityBox,
    required this.boardGameBox,
    required this.userBox,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6F91), // rose
              Color(0xFF845EC2), // violet
              Color(0xFF2196F3), // bleu
              Color(0xFF00C9A7), // turquoise
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nom application
                    Text(
                      "Surpriz'Me",
                      style: GoogleFonts.bebasNeue(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text(
                      "L'ennui vous gagne et vous ne savez pas quoi faire ?\nLAISSEZ-VOUS SURPRENDRE !",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Boutons FILMS / JEUX / ACTIVITES
                    Column(
                      children: [
                        _buildCategoryBox(
                          context,
                          "FILMS",
                          Colors.orange,
                          FilmsPage(movieBox: movieBox),
                        ),
                        const SizedBox(height: 20),
                        _buildCategoryBox(
                          context,
                          "JEUX",
                          Colors.purple,
                          JeuxPage(boardGameBox: boardGameBox),
                        ),
                        const SizedBox(height: 20),
                        _buildCategoryBox(
                          context,
                          "ACTIVITÉS",
                          Colors.blue,
                          ActivitePage(activityBox: activityBox),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour les boutons cliquables
  Widget _buildCategoryBox(
    BuildContext context,
    String title,
    Color color,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
>>>>>>> Stashed changes
