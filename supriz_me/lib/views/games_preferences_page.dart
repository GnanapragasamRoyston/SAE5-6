// games_preferences_page.dart

import 'package:flutter/material.dart';
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
  // CORRECTION: Ajout du paramètre isEditing au constructeur
  final bool isEditing; 
  
  const GamesPreferencesPage({
    super.key, 
    required this.settingsBox,
    this.isEditing = false, // Défaut à false pour le premier lancement
  });

  @override
  State<GamesPreferencesPage> createState() => _GamesPreferencesPageState();
}

class _GamesPreferencesPageState extends State<GamesPreferencesPage> {
  Set<String> _selectedGenres = {};
  
  // Variable d'état pour le nombre de joueurs unique (par défaut 4)
  double _playersCount = 4; 
  
  // Clés utilisées pour stocker dans la Hive Box
  static const String _preferencesSetKey = 'game_preferences_set';
  static const String _userGenresKey = 'user_game_genres';
  static const String _playersCountKey = 'player_count_preference';


  @override
  void initState() {
    super.initState();
    // NOUVEAU: Si on est en mode édition, on charge les valeurs existantes
    if (widget.isEditing) {
      final savedGenres = widget.settingsBox.get(_userGenresKey)?.cast<String>() ?? [];
      // Si la clé de joueur existe, on la charge, sinon on utilise la valeur par défaut
      final savedPlayers = widget.settingsBox.get(_playersCountKey) ?? 4; 

      _selectedGenres = savedGenres.toSet();
      _playersCount = savedPlayers.toDouble();
    }
  }


  // Sauvegarde les préférences et revient à la page GamesPage
  void _savePreferencesAndNavigate() async {
    // 1. Sauvegarder les genres sélectionnés dans la Box Hive
    await widget.settingsBox.put(_userGenresKey, _selectedGenres.toList());
    
    // 2. Sauvegarder le nombre de joueurs unique
    await widget.settingsBox.put(_playersCountKey, _playersCount.round());
    
    // 3. Marquer que les préférences ont été définies (au cas où c'est le premier lancement)
    await widget.settingsBox.put(_preferencesSetKey, true);
    
    // 4. Retourner à GamesPage avec un indicateur de succès (par exemple, la liste des genres)
    Navigator.of(context).pop(_selectedGenres.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vos Préférences de Jeux"),
        backgroundColor: Colors.purple,
        // CORRECTION: Autorise le bouton retour si l'on est en mode édition
        automaticallyImplyLeading: widget.isEditing, 
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF845EC2), // violet
              Color(0xFFFF6F91), // rose
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isEditing
                    ? "Modifier vos préférences de jeux :"
                    : "👋 Première visite ! Aidez-nous à vous surprendre :",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                
                // --- SLIDER POUR LE NOMBRE DE JOUEURS (UNIQUE) ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "👤 Nombre de joueurs : ${_playersCount.round()}",
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.purple[800]
                        ),
                      ),
                      Slider(
                        value: _playersCount,
                        min: 1, 
                        max: 6, 
                        divisions: 5, 
                        label: _playersCount.round().toString(),
                        activeColor: Colors.purple[700],
                        inactiveColor: Colors.purple[100],
                        onChanged: (double newValue) {
                          setState(() {
                            _playersCount = newValue;
                          });
                        },
                      ),
                      const Text(
                        "(Nous trouverons des jeux pour ce nombre de participants.)",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // --- CHIPS DE GENRES (GARDÉ) ---
                const Text(
                  "✨ Genres préférés :",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0, 
                  runSpacing: 8.0,
                  children: availableGenres.map((genre) {
                    return ChoiceChip(
                      label: Text(genre, style: TextStyle(color: _selectedGenres.contains(genre) ? Colors.white : Colors.black87)),
                      selected: _selectedGenres.contains(genre),
                      selectedColor: Colors.purple[700],
                      backgroundColor: Colors.white,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedGenres.add(genre);
                          } else {
                            _selectedGenres.remove(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                
                // Bouton de validation
                ElevatedButton(
                  onPressed: _selectedGenres.isEmpty
                      ? null
                      : _savePreferencesAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Text(
                      widget.isEditing ? 'Sauvegarder les modifications' : 'C\'est parti ! Afficher mes jeux',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}