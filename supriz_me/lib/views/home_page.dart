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
  final Box<MovieRating> movieRatingBox;

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
        title: Text(
          "Surpriz'Me",
          style: GoogleFonts.bebasNeue(
            fontSize: 26,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 22),
              onPressed: () {
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
              Color(0xFF1A3A52), // bleu marine foncé
              Color(0xFF2563EB), // bleu moyen
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header "Surpriz'Me" + tagline
                  _buildHeader(),

                  const SizedBox(height: 24),

                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo_app.png',
                        height: 170,
                        width: 170,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description dans un "bloc" glassmorphism
                  _buildDescription(),

                  const SizedBox(height: 32),

                  // Boutons catégories (cartes modernes)
                  _buildCategoryCard(
                    context: context,
                    title: "FILMS",
                    subtitle: "Sors les pop corns, trouve ton film",
                    color1: const Color(0xFFFFA726),
                    color2: const Color(0xFFFF7043),
                    icon: Icons.local_movies,
                    page: MoviesPage(
                      movieBox: movieBox,
                      movieRatingBox: movieRatingBox,
                      settingsBox: settingsBox,
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildCategoryCard(
                    context: context,
                    title: "JEUX",
                    subtitle: "Rebattez les cartes de l'ennui",
                    color1: const Color(0xFFAB47BC),
                    color2: const Color(0xFF7E57C2),
                    icon: Icons.casino,
                    page: GamesPage(
                      boardGameBox: boardGameBox,
                      settingsBox: settingsBox,
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildCategoryCard(
                    context: context,
                    title: "ACTIVITÉS",
                    subtitle: "Bouge, crée, découvre.",
                    color1: const Color(0xFF29B6F6),
                    color2: const Color(0xFF26C6DA),
                    icon: Icons.flash_on,
                    page: ActivitiesPage(
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

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "Surpriz'Me",
          style: GoogleFonts.bebasNeue(
            fontSize: 44,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Anti-ennui, pro-surprises.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Text(
        "L'ennui vous gagne et vous ne savez pas quoi faire ?\n"
            "LAISSEZ-VOUS SURPRENDRE !",
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color color1,
    required Color color2,
    required IconData icon,
    required Widget page,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color1,
              color2,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 18),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
