import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class MoviePreferencePage extends StatefulWidget {
  final Box settingsBox;

  const MoviePreferencePage({super.key, required this.settingsBox});

  @override
  State<MoviePreferencePage> createState() => _MoviePreferencePageState();
}

class _MoviePreferencePageState extends State<MoviePreferencePage> {
  // ----- VARIABLES -----
  List<String> selectedGenres = [];
  int preferredDuration = 120; // en minutes
  bool allowSurprise = true;

  final List<String> allGenres = const [
    "action",
    "adventure",
    "animation",
    "comedy",
    "crime",
    "documentary",
    "drama",
    "family",
    "fantasy",
    "history",
    "horror",
    "music",
    "mystery",
    "romance",
    "science fiction",
    "thriller",
    "tv_movie",
    "war",
    "western",
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // ----- LOAD EXISTING PREFS -----
  void _loadPrefs() {
    selectedGenres =
        (widget.settingsBox.get("initial_movie_genres") as List?)?.cast<String>() ??
            [];
    preferredDuration = widget.settingsBox.get("preferred_duration") ?? 120;
    allowSurprise = widget.settingsBox.get("allow_surprise") ?? true;
  }

  // ----- SAVE PREFS -----
  void _savePrefs() {
    widget.settingsBox.put("initial_movie_genres", selectedGenres);
    widget.settingsBox.put("preferred_duration", preferredDuration);
    widget.settingsBox.put("allow_surprise", allowSurprise);
    Navigator.pop(context);
  }

  // ----- UI -----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Préférences Films",
          style: GoogleFonts.bebasNeue(fontSize: 26),
        ),
        backgroundColor: const Color.fromARGB(255, 59, 100, 233),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 67, 128, 241), Color.fromARGB(255, 252, 136, 165)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- DURÉE ---
              Text(
                "⏱ Durée préférée",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: preferredDuration.toDouble(),
                min: 30,
                max: 240,
                divisions: 14,
                label: "$preferredDuration min",
                onChanged: (val) {
                  setState(() {
                    preferredDuration = val.toInt();
                  });
                },
              ),
              Text(
                "$preferredDuration minutes",
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 24),

              // --- GENRES ---
              Text(
                "🎬 Genres préférés",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final genre in allGenres)
                    FilterChip(
                      label: Text(
                        genre.toUpperCase(),
                        style: const TextStyle(color: Colors.black),
                      ),
                      selected: selectedGenres.contains(genre),
                      selectedColor: const Color.fromARGB(255, 241, 84, 123),
                      backgroundColor: Colors.white12,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedGenres.add(genre);
                          } else {
                            selectedGenres.remove(genre);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // --- SURPRISE ---
              CheckboxListTile(
                title: const Text(
                  'Autoriser les surprises',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Proposer des films inattendus',
                  style: TextStyle(color: Colors.white70),
                ),
                value: allowSurprise,
                onChanged: (value) {
                  setState(() {
                    allowSurprise = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 30),

              // --- SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePrefs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 241, 84, 123),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    "Valider",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
