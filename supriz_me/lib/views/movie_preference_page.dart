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
  List<String> selectedGenres = [];
  int preferredDuration = 120;

  final List<String> allGenres = const [
    "action", "adventure", "animation", "comedy", "crime", "documentary",
    "drama", "family", "fantasy", "history", "horror", "music", "mystery",
    "romance", "science fiction", "thriller", "tv_movie", "war", "western",
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() {
    selectedGenres = (widget.settingsBox.get("initial_movie_genres") as List?)
        ?.cast<String>() ?? [];
    preferredDuration = widget.settingsBox.get("preferred_duration") ?? 120;
  }

  void _savePrefs() {
    widget.settingsBox.put("initial_movie_genres", selectedGenres);
    widget.settingsBox.put("preferred_duration", preferredDuration);
    widget.settingsBox.put("movie_prefs_initialized", true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2, center: Alignment(0, -0.5),
            colors: [Color(0xFF101738), Color(0xFF050814)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              expandedHeight: 120,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFff4b81), Color(0xFFff9f4b)]),
                ),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text("PRÉFÉRENCES FILMS", style: GoogleFonts.pressStart2p(fontSize: 14, color: Colors.white)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(Icons.access_time, "DURÉE PRÉFÉRÉE"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121b3a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3cf2ff), width: 2),
                      ),
                      child: Column(
                        children: [
                          Text("$preferredDuration MIN", style: GoogleFonts.pressStart2p(fontSize: 28, color: const Color(0xFF3cf2ff))),
                          Slider(
                            value: preferredDuration.toDouble(),
                            min: 30, max: 240, divisions: 14,
                            onChanged: (val) => setState(() => preferredDuration = val.toInt()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(Icons.movie_filter, "GENRES PRÉFÉRÉS"),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: allGenres.map((genre) {
                        final isSelected = selectedGenres.contains(genre);
                        return GestureDetector(
                          onTap: () => setState(() => isSelected ? selectedGenres.remove(genre) : selectedGenres.add(genre)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected ? const LinearGradient(colors: [Color(0xFFff4b81), Color(0xFFff9f4b)]) : null,
                              color: isSelected ? null : const Color(0xFF121b3a),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? const Color(0xFFff4b81) : const Color(0xFF3cf2ff).withOpacity(0.5), width: 2),
                            ),
                            child: Text(genre.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
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

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFff0080), Color(0xFFff6600)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: InkWell(
        onTap: _savePrefs,
        child: Center(child: Text("VALIDER", style: GoogleFonts.pressStart2p(fontSize: 16, color: Colors.white))),
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
          Text(label, style: GoogleFonts.pressStart2p(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }
}