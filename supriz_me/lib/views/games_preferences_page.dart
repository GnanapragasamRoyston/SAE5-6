import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

// --- Constantes des genres (pour le widget de sélection) ---
final List<String> availableGenres = [
  'Strategy Games',
  'Thematic Games',
  'Wargames',
  'Family Games',
  'Customizable Games',
  'Abstract Games',
  'Party Games',
  "Children's Games"
];

class GamesPreferencesPage extends StatefulWidget {
  final Box settingsBox;
  final bool isEditing;

  const GamesPreferencesPage({
    super.key,
    required this.settingsBox,
    this.isEditing = false,
  });

  @override
  State<GamesPreferencesPage> createState() => _GamesPreferencesPageState();
}

class _GamesPreferencesPageState extends State<GamesPreferencesPage> {
  Set<String> _selectedGenres = {};
  double _playersCount = 4;
  double _maxDuration = 90;

  // Clés utilisées pour stocker dans la Hive Box
  static const String _preferencesSetKey = 'game_preferences_set';
  static const String _userGenresKey = 'user_game_genres';
  static const String _playersCountKey = 'player_count_preference';
  static const String _maxDurationKey = 'max_duration_preference';

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      final savedGenres = widget.settingsBox.get(_userGenresKey)?.cast<String>() ?? [];
      final savedPlayers = widget.settingsBox.get(_playersCountKey) ?? 4;
      final savedDuration = widget.settingsBox.get(_maxDurationKey) ?? 90;

      _selectedGenres = savedGenres.toSet();
      _playersCount = savedPlayers.toDouble();
      _maxDuration = savedDuration.toDouble();
    }
  }

  void _savePreferencesAndNavigate() async {
    await widget.settingsBox.put(_userGenresKey, _selectedGenres.toList());
    await widget.settingsBox.put(_playersCountKey, _playersCount.round());
    await widget.settingsBox.put(_maxDurationKey, _maxDuration.round());
    await widget.settingsBox.put(_preferencesSetKey, true);

    Navigator.of(context).pop(_selectedGenres.toList());
  }

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
              automaticallyImplyLeading: widget.isEditing,
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
                    "PRÉFÉRENCES JEUX",
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
                    // ✅ MESSAGE SUPPRIMÉ - ESPACEMENT SIMPLE
                    const SizedBox(height: 20),

                    // --- NOMBRE DE JOUEURS ---
                    _buildSectionTitle(Icons.group, "NOMBRE DE JOUEURS"),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121b3a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFb67dff), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFb67dff).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${_playersCount.round()} JOUEUR${_playersCount.round() > 1 ? 'S' : ''}",
                            style: GoogleFonts.pressStart2p(
                              fontSize: 28,
                              color: const Color(0xFFb67dff),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFFb67dff),
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
                              value: _playersCount,
                              min: 1,
                              max: 6,
                              divisions: 5,
                              onChanged: (double newValue) {
                                setState(() {
                                  _playersCount = newValue;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "1",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "Nous trouverons des jeux adaptés",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                "6",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- DURÉE MAXIMALE ---
                    _buildSectionTitle(Icons.access_time, "DURÉE MAXIMALE"),
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
                            "${_maxDuration.round()} MIN",
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
                              value: _maxDuration,
                              min: 30,
                              max: 180,
                              divisions: 5,
                              onChanged: (double newValue) {
                                setState(() {
                                  _maxDuration = (newValue / 30).round() * 30.0;
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
                                "Jeux plus courts privilégiés",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                "180 MIN",
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

                    // --- GENRES PRÉFÉRÉS ---
                    _buildSectionTitle(Icons.category, "GENRES PRÉFÉRÉS"),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableGenres.map((genre) {
                        final isSelected = _selectedGenres.contains(genre);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedGenres.remove(genre);
                              } else {
                                _selectedGenres.add(genre);
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

                    // --- MESSAGE SI AUCUN GENRE ---
                    if (_selectedGenres.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFff9f4b).withOpacity(0.2),
                          border: Border.all(
                              color: const Color(0xFFff9f4b), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Color(0xFFff9f4b), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sélectionnez au moins un genre',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),

                    // --- BOUTON VALIDER ---
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: _selectedGenres.isEmpty
                            ? null
                            : const LinearGradient(
                          colors: [Color(0xFFff0080), Color(0xFFff6600)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        color: _selectedGenres.isEmpty
                            ? Colors.grey.shade700
                            : null,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: _selectedGenres.isEmpty
                            ? null
                            : [
                          BoxShadow(
                            color: const Color(0xFFff0080)
                                .withOpacity(0.6),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _selectedGenres.isEmpty
                              ? null
                              : _savePreferencesAndNavigate,
                          child: Center(
                            child: Text(
                              widget.isEditing
                                  ? "SAUVEGARDER"
                                  : "C'EST PARTI !",
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
