import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import des pages
import 'films.dart';
import 'jeux.dart';
import 'activites.dart'; // assure-toi que le fichier contient "ActivitePage"

void main() {
  runApp(const SurprizMeApp());
}

class SurprizMeApp extends StatelessWidget {
  const SurprizMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Surpriz'Me",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
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

                    // Logo
                    Align(
                      alignment: const Alignment(-0.7, 0),
                      child: Image.asset(
                        'assets/images/logo_app.png', // corrige le chemin
                        height: 400,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Boutons FILMS / JEUX / ACTIVITES
                    Column(
                      children: [
                        _buildCategoryBox(
                          context,
                          "FILMS",
                          Colors.orange,
                          FilmsPage(),
                        ),
                        const SizedBox(height: 20),
                        _buildCategoryBox(
                          context,
                          "JEUX",
                          Colors.purple,
                          JeuxPage(),
                        ),
                        const SizedBox(height: 20),
                        _buildCategoryBox(
                          context,
                          "ACTIVITÉS",
                          Colors.blue,
                          ActivitePage(), // <-- nom correct de la classe
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
      BuildContext context, String title, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
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
