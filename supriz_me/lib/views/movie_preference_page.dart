import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

// --- Liste des genres (Définie localement) ---
const List<String> kUniqueMovieGenres = [
  'ACTION',
  'ADVENTURE',
  'ANIMATION',
  'COMEDY',
  'CRIME',
  'DOCUMENTARY',
  'DRAMA',
  'FAMILY',
  'FANTASY',
  'HISTORY',
  'HORROR',
  'MUSIC',
  'MYSTERY',
  'ROMANCE',
  'SCIENCE FICTION',
  'THRILLER',
  'TV MOVIE',
  'WAR',
  'WESTERN',
];
// ---------------------------------------------

class MoviePreferencePage extends StatefulWidget {
  final Box settingsBox;
  final VoidCallback onPreferencesSaved;

  const MoviePreferencePage({
    super.key,
    required this.settingsBox,
    required this.onPreferencesSaved,
  });

  @override
  State<MoviePreferencePage> createState() => _MoviePreferencePageState();
}

class _MoviePreferencePageState extends State<MoviePreferencePage> {
  Set<String> _selectedGenres = {};
  static const int MIN_GENRES = 3;

  @override
  void initState() {
    super.initState();
    // Charger les préférences existantes si l'utilisateur revient modifier ses choix
    final existingGenres =
        widget.settingsBox.get('initial_movie_genres') as List<dynamic>?;
    if (existingGenres != null) {
      _selectedGenres = existingGenres.cast<String>().toSet();
    }
  }

  /// Enregistre les préférences et notifie MoviesPage pour le rafraîchissement.
  Future<void> _saveInitialMoviePreferences() async {
    final genres = _selectedGenres.toList();

    // 1. Stocker la liste des genres dans settingsBox
    await widget.settingsBox.put('initial_movie_genres', genres);

    // 2. Marquer l'initialisation comme terminée
    await widget.settingsBox.put('movie_prefs_initialized', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Vos ${genres.length} préférences ont été enregistrées !')),
      );

      widget.onPreferencesSaved();

      // Retourner à la page précédente (MoviesPage)
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = MIN_GENRES - _selectedGenres.length;
    final isConfirmButtonEnabled = _selectedGenres.length >= MIN_GENRES;

    return PopScope(
      canPop: false, // Empêche de quitter sans valider
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Configuration des Films",
            style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        // 🎯 FOND UTILISANT LE GRADIENT DE L'APP
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indicateur de progression et instructions
                      Text(
                        'Étape 1 : Définissez votre profil',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Veuillez sélectionner au moins $MIN_GENRES genres. Il vous en manque ${remaining > 0 ? remaining : 0}.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 🎯 AFFICHAGE DES CHIPS AMÉLIORÉ
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: kUniqueMovieGenres.map((genre) {
                          final isSelected = _selectedGenres.contains(genre);
                          return FilterChip(
                            label: Text(genre),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedGenres.add(genre);
                                } else {
                                  _selectedGenres.remove(genre);
                                }
                              });
                            },
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.indigo : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.grey,
                            selectedColor: Colors
                                .amberAccent, // Nouvelle couleur de sélection
                            checkmarkColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.amberAccent
                                    : Colors.white38,
                                width: 1.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // 🎯 BOUTON FIXE DE CONFIRMATION (en bas)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: isConfirmButtonEnabled
                      ? _saveInitialMoviePreferences
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor:
                        isConfirmButtonEnabled ? Colors.amber : Colors.grey,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isConfirmButtonEnabled
                        ? 'Confirmer les préférences (${_selectedGenres.length}/$MIN_GENRES)'
                        : 'Sélectionnez encore $remaining genre${remaining > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
