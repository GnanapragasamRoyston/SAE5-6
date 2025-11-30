// home_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../models/movie.dart';
import '../models/activity.dart';
import '../models/board_game.dart';
import '../models/activity_rating.dart';
import '../models/activity_preferences.dart';
import '../models/performance_metrics.dart';
import '../models/movie_rating.dart'; 

// Import pages
import 'movies_page.dart';
import 'games_page.dart';
import 'activities_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  final Box<Movie> movieBox;
  final Box<Activity> activityBox;
  final Box<BoardGame> boardGameBox;
  final Box<ActivityRating> activityRatingBox;
  final Box<ActivityPreferences> activityPreferencesBox;
  final Box<PerformanceMetrics> metricsBox;
  final Box settingsBox;
  final Box<MovieRating>
      movieRatingBox;

  const HomePage({
    super.key,
    required this.movieBox,
    required this.activityBox,
    required this.boardGameBox,
    required this.activityRatingBox,
    required this.activityPreferencesBox,
    required this.metricsBox,
    required this.settingsBox,
    required this.movieRatingBox,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 22),
              onPressed: () {
                // NOTE: Si SettingsPage a besoin des boxes, il faut les passer ici aussi
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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

                  const SizedBox(height: 10),

                  // NOUVEAU LOGO (Image.asset)
                  ClipRRect(
                    // Optionnel: pour appliquer des coins arrondis si l'image le nécessite
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/logo_app.png',
                      height: 200, // Ajustez la taille au besoin
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Text(
                    "L'ennui vous gagne et vous ne savez pas quoi faire ?\n"
                    "LAISSEZ-VOUS SURPRENDRE !",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // BOUTONS
                  _buildCategoryBox(
                    context,
                    "FILMS",
                    Colors.orange,
                    // 🎯 MISE À JOUR : Passez movieRatingBox à MoviesPage
                    MoviesPage(
                      movieBox: movieBox,
                      movieRatingBox: movieRatingBox,
                      settingsBox: settingsBox,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCategoryBox(
                    context,
                    "JEUX",
                    Colors.purple,
                    GamesPage(
                      boardGameBox: boardGameBox,
                      settingsBox: settingsBox,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildCategoryBox(
                    context,
                    "ACTIVITÉS",
                    Colors.blue,
                    ActivitiesPage(
                      activityBox: activityBox,
                      activityRatingBox: activityRatingBox,
                      activityPreferencesBox: activityPreferencesBox,
                      metricsBox: metricsBox,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
