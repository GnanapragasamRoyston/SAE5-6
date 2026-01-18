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
      backgroundColor: const Color(0xFF0A0A1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF1A1A3A),
              Color(0xFF0A0A1A),
              Color(0xFF0D0D2B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Rien en haut pour l’instant
              const SizedBox(height: 0),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Logo pixel art
                      _buildPixelLogo(),
                      const SizedBox(height: 20),

                      // Nouvelle phrase sous le logo
                      Text(
                        "l'ennui vous gagne et vous ne savez pas quoi faire ? Laissez vous surprendre",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Compteur "score" avec vraies données
                      _buildScoreCounter(),
                      const SizedBox(height: 30),

                      // Bouton principal "Surpriz'Me"
                      _buildPlayButton(context),
                      const SizedBox(height: 35),

                      // Menu catégories "gamepad"
                      _buildGamepadMenu(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPixelLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.cyan.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo_app.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCounter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("🎬", "Films", movieBox.length.toString()),
          _statItem("🎲", "Jeux", boardGameBox.length.toString()),
          _statItem("⚡", "Activités", activityBox.length.toString()),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.pressStart2p(
            fontSize: 16,
            color: Colors.cyanAccent,
            letterSpacing: 1,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF0080), Color(0xFFFF6600)],
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0080).withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivitiesPage(
                activityBox: activityBox,
                activityRatingBox: activityRatingBox,
                activityPreferencesBox: activityPreferencesBox,
                metricsBox: metricsBox,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Color(0xFFFF0080),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Surpriz'Me",
                style: GoogleFonts.bebasNeue(
                  fontSize: 28,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamepadMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Choisis ta catégorie",
          style: GoogleFonts.pressStart2p(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(
              flex: 3,
              child: _gameButton(
                context,
                label: "FILMS",
                color: const Color(0xFF00DDFF),
                icon: Icons.movie,
                page: MoviesPage(
                  movieBox: movieBox,
                  movieRatingBox: movieRatingBox,
                  settingsBox: settingsBox,
                ),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _gameButton(
                context,
                label: "JEUX DE SOCIÉTÉ",
                color: const Color(0xFFFFAA00),
                icon: Icons.casino,
                page: GamesPage(
                  boardGameBox: boardGameBox,
                  settingsBox: settingsBox,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _gameButton(
                context,
                label: "ACTIVITÉS",
                color: const Color(0xFF00FF88),
                icon: Icons.flash_on,
                page: ActivitiesPage(
                  activityBox: activityBox,
                  activityRatingBox: activityRatingBox,
                  activityPreferencesBox: activityPreferencesBox,
                  metricsBox: metricsBox,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gameButton(
      BuildContext context, {
        required String label,
        required Color color,
        required IconData icon,
        required Widget page,
      }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: Colors.white,
                      height: 1.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_forward, color: color, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
