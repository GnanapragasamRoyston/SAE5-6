import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Police stylée

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
                    // Nom de l'application
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

                    // Texte de description
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

                    // Logo légèrement décalé vers la gauche
                    Align(
                      alignment: const Alignment(-100, 0), // plus à gauche
                      child: Image.asset(
                        'lib/assets/images/logo_app.png.webp',
                        height: 400, // logo agrandi
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Rectangles empilés (FILMS / SERIES / ACTIVITES)
                    Column(
                      children: [
                        _buildCategoryBox("FILMS", Colors.orange),
                        const SizedBox(height: 20),
                        _buildCategoryBox("SÉRIES", Colors.purple),
                        const SizedBox(height: 20),
                        _buildCategoryBox("ACTIVITÉS", Colors.blue),
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

  // Widget réutilisable pour les rectangles
  Widget _buildCategoryBox(String title, Color color) {
    return Container(
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
            fontSize: 24, // texte des rectangles agrandi
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
