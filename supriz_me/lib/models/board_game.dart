import 'package:hive/hive.dart';

// IMPORTANT: Assurez-vous d'exécuter la commande pour la génération de code sajith
// si vous modifiez la structure de la classe BoardGame pour Hive.
part 'board_game.g.dart';

@HiveType(typeId: 2)
class BoardGame {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  // Description (courte, basée sur les mécaniques)
  @HiveField(2)
  final String description;

  @HiveField(3)
  final int minPlayers;

  @HiveField(4)
  final int maxPlayers;

  // Durée moyenne de jeu, en minutes (double)
  @HiveField(5)
  final double avgDuration; 

  // Complexité / Difficulté (0-5)
  @HiveField(6)
  final double complexity; 

  // Note BGG
  @HiveField(7)
  final double rating;

  // Tags / Genres BGG (liste de chaînes)
  @HiveField(8)
  final List<String> tags; 
  
  // Année de sortie (Ajouté pour la section "Les Plus Récents")
  @HiveField(9)
  final int releaseYear; 
  
  // NOUVEAU: Age minimum (ajouté car il est dans GamesPreferencesPage)
  @HiveField(10) 
  final int minAge; // On ajoute minAge, essentiel pour les préférences

  const BoardGame({
    required this.id,
    required this.title,
    required this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.avgDuration,
    required this.complexity,
    required this.rating,
    required this.tags,
    required this.releaseYear, 
    required this.minAge, // Ajout de minAge
  });
  
  // CONSTRUCTEUR AJOUTÉ: La correction que GamesPage attend
  // Ce constructeur permet de retourner un BoardGame "vide" pour les cas orElse.
  factory BoardGame.empty() {
    return BoardGame(
      id: '',
      title: '', // Titre vide = marqueur d'objet vide
      description: '',
      minPlayers: 0,
      maxPlayers: 0,
      avgDuration: 0,
      complexity: 0.0,
      rating: 0.0,
      tags: [],
      releaseYear: 0,
      minAge: 0, 
    );
  }
}