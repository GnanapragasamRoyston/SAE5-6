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
    selectedGenres = (widget.settingsBox.get("initial_movie_genres") as List?)
        ?.cast<String>() ??
        [];
    preferredDuration = widget.settingsBox.get("preferred_duration") ?? 120;
    allowSurprise = widget.settingsBox.get("allow_surprise") ?? true;
  }

  // ----- SAVE PREFS -----
  void _savePrefs() {
    widget.settingsBox.put("initial_movie_genres", selectedGenres);
    widget.settingsBox.put("preferred_duration", preferredDuration);
    widget.settingsBox.put("allow_surprise", allowSurprise);

    // FIX CLÉ : Enregistre que les préférences ont été initialisées
    widget.settingsBox.put("movie_prefs_initialized", true);

    Navigator.pop(context);
  }

  // ----- UI -----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            center: Alignment(0, -0.5),
            colors: [
              Color(0xFF101738),
              Color(0xFF050814),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // ✅ HEADER ARCADE
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 120,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff4b81), Color(0xFFff9f4b)],
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "PRÉFÉRENCES FILMS",
                    style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            // ✅ CONTENU
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- DURÉE ---
                    _buildSectionTitle(Icons.access_time, "DURÉE PRÉFÉRÉE"),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121b3a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF3cf2ff), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3cf2ff).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "$preferredDuration MIN",
                            style: GoogleFonts.pressStart2p(
                              fontSize: 28,
                              color: const Color(0xFF3cf2ff),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFF3cf2ff),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFFff4b81),
                              overlayColor:
                              const Color(0xFFff4b81).withOpacity(0.3),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 20),
                            ),
                            child: Slider(
                              value: preferredDuration.toDouble(),
                              min: 30,
                              max: 240,
                              divisions: 14,
                              onChanged: (val) {
                                setState(() {
                                  preferredDuration = val.toInt();
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "30 MIN",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                "240 MIN",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- GENRES ---
                    _buildSectionTitle(Icons.movie_filter, "GENRES PRÉFÉRÉS"),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: allGenres.map((genre) {
                        final isSelected = selectedGenres.contains(genre);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedGenres.remove(genre);
                              } else {
                                selectedGenres.add(genre);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFFff4b81),
                                  Color(0xFFff9f4b)
                                ],
                              )
                                  : null,
                              color: isSelected
                                  ? null
                                  : const Color(0xFF121b3a),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFff4b81)
                                    : const Color(0xFF3cf2ff).withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFFff4b81)
                                      .withOpacity(0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                                  : null,
                            ),
                            child: Text(
                              genre.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // --- SURPRISE ---
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          allowSurprise = !allowSurprise;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121b3a),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: allowSurprise
                                ? const Color(0xFF00ff85)
                                : const Color(0xFF3cf2ff).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: allowSurprise
                              ? [
                            BoxShadow(
                              color: const Color(0xFF00ff85)
                                  .withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: allowSurprise
                                    ? const Color(0xFF00ff85)
                                    : Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                allowSurprise
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: allowSurprise
                                    ? Colors.black87
                                    : Colors.white54,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AUTORISER LES SURPRISES',
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: 10,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Proposer des films inattendus',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- SAVE BUTTON ---
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff0080), Color(0xFFff6600)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFff0080).withOpacity(0.6),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _savePrefs,
                          child: Center(
                            child: Text(
                              "VALIDER",
                              style: GoogleFonts.pressStart2p(
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121b3a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3cf2ff), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.pressStart2p(
              fontSize: 11,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
