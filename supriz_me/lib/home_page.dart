import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import pages
import 'films.dart';
import 'jeux.dart';
import 'activites.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6F91),
              Color(0xFF845EC2),
              Color(0xFF2196F3),
              Color(0xFF00C9A7),
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
                    FilmsPage(),
                  ),
                  const SizedBox(height: 20),

                  _buildCategoryBox(context, "JEUX", Colors.purple, JeuxPage()),
                  const SizedBox(height: 20),

                  _buildCategoryBox(
                    context,
                    "ACTIVITÉS",
                    Colors.blue,
                    ActivitePage(),
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
