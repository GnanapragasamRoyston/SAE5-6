import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../models/board_game.dart';
import 'games_preferences_page.dart'; 


// =================================================================
// 🎮 GamesPage - Le conteneur principal sajith
// =================================================================

class GamesPage extends StatefulWidget {
  final Box<BoardGame> boardGameBox;
  final Box settingsBox; 

  const GamesPage({
    super.key,
    required this.boardGameBox,
    required this.settingsBox, 
  });

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  bool _isContentLoaded = false; 
  List<BoardGame> _recommendedGames = []; 
  
  // Stocke la préférence de nombre de joueurs unique
  int? _preferredPlayers; 

  // --- Stockage des jeux aimés/non aimés (titres) ---
  Set<String> _likedGamesTitles = {};
  Set<String> _dislikedGamesTitles = {};


  // Clés Hive
  static const String _preferencesSetKey = 'game_preferences_set';
  static const String _userGenresKey = 'user_game_genres';
  static const String _playersCountKey = 'player_count_preference';
  // --- CLÉS HIVE POUR LE FEEDBACK ---
  static const String _likedGamesKey = 'liked_games_titles';
  static const String _dislikedGamesKey = 'disliked_games_titles';


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeedbackData();
      _checkPreferencesStatus();
    });
  }
  
  // Chargement des préférences de l'utilisateur (likes/dislikes)
  void _loadFeedbackData() {
     final savedLikes = widget.settingsBox.get(_likedGamesKey)?.cast<String>() ?? [];
     final savedDislikes = widget.settingsBox.get(_dislikedGamesKey)?.cast<String>() ?? [];
     
     _likedGamesTitles = savedLikes.toSet();
     _dislikedGamesTitles = savedDislikes.toSet();
  }


  // Logique de vérification de l'état initial
  void _checkPreferencesStatus() async {
    final preferencesSet = widget.settingsBox.get(_preferencesSetKey) ?? false; 

    if (preferencesSet) {
      final List<String>? savedGenres = widget.settingsBox.get(_userGenresKey)?.cast<String>();
      _preferredPlayers = widget.settingsBox.get(_playersCountKey); 
      
      _loadRecommendations(
        genres: savedGenres, 
        playerCount: _preferredPlayers, 
      );
    } else {
      _navigateToPreferences(canGoBack: false);
    }
  }

  // Fonction de navigation/modification des préférences
  void _navigateToPreferences({bool canGoBack = false}) async {
    final route = MaterialPageRoute(
      builder: (context) => GamesPreferencesPage(
        settingsBox: widget.settingsBox,
        isEditing: canGoBack, 
      ),
    );
    
    final result = await Navigator.of(context).push(route);

    if (result != null) {
      _preferredPlayers = widget.settingsBox.get(_playersCountKey);
      
      _loadRecommendations(
        genres: widget.settingsBox.get(_userGenresKey)?.cast<String>(), 
        playerCount: _preferredPlayers, 
      );
      
    } else {
      if (!canGoBack && !_isContentLoaded) {
          setState(() {
            _isContentLoaded = true;
          });
      }
    }
  }

  // --- NOUVEAU: Algorithme de calcul du score dynamique ---
  // Calcule un score ajusté basé sur le rating initial + feedback utilisateur
  double _calculateDynamicRating(BoardGame game) {
      double score = game.rating;
      
      // Bonus/Malus si le jeu lui-même a été aimé/non aimé
      if (_likedGamesTitles.contains(game.title)) {
          score += 1.5; // Gros bonus si vous aimez ce jeu spécifique
      } else if (_dislikedGamesTitles.contains(game.title)) {
          score -= 3.0; // Gros malus pour le pousser vers le bas
      }
      
      // Bonus basé sur les jeux aimés dans la même catégorie (Genres/Tags)
      for (var likedTitle in _likedGamesTitles) {
          final likedGame = widget.boardGameBox.values.firstWhere(
              (g) => g.title == likedTitle, 
              orElse: () => BoardGame.empty() 
          );

          if (likedGame.title.isNotEmpty) {
              // Vérifie les genres en commun
              final commonTags = game.tags.where((tag) => likedGame.tags.contains(tag)).length;
              score += commonTags * 0.2; // Bonus modéré par tag commun
          }
      }
      
      // Pénalité basée sur les jeux non aimés dans la même catégorie
      for (var dislikedTitle in _dislikedGamesTitles) {
          final dislikedGame = widget.boardGameBox.values.firstWhere(
              (g) => g.title == dislikedTitle, 
              orElse: () => BoardGame.empty() 
          );

          if (dislikedGame.title.isNotEmpty) {
              final commonTags = game.tags.where((tag) => dislikedGame.tags.contains(tag)).length;
              score -= commonTags * 0.5; // Pénalité plus forte pour les tags que vous n'aimez pas
          }
      }
      
      // Assurer que le score reste dans une fourchette raisonnable
      return score.clamp(0.0, 10.0);
  }

  // --- MISE À JOUR: Gestion du like/dislike ---
  // Ajoute la possibilité d'annuler un like/dislike en recliquant.
  void _handleGameFeedback(BoardGame game, bool isLiked) async {
    setState(() {
      if (isLiked) {
        // L'utilisateur clique sur "J'aime"
        if (_likedGamesTitles.contains(game.title)) {
          // Si déjà aimé, le retirer (annuler le like)
          _likedGamesTitles.remove(game.title);
        } else {
          // Sinon, ajouter le like et retirer l'éventuel dislike
          _likedGamesTitles.add(game.title);
          _dislikedGamesTitles.remove(game.title);
        }
      } else { 
        // L'utilisateur clique sur "Je n'aime pas"
        if (_dislikedGamesTitles.contains(game.title)) {
          // Si déjà non aimé, le retirer (annuler le dislike)
          _dislikedGamesTitles.remove(game.title);
        } else {
          // Sinon, ajouter le dislike et retirer l'éventuel like
          _dislikedGamesTitles.add(game.title);
          _likedGamesTitles.remove(game.title);
        }
      }
    });

    // Sauvegarde immédiate dans Hive
    await widget.settingsBox.put(_likedGamesKey, _likedGamesTitles.toList());
    await widget.settingsBox.put(_dislikedGamesKey, _dislikedGamesTitles.toList());
    
    // Recharge les recommandations pour recalculer les scores dynamiques
    _loadRecommendations(
        genres: widget.settingsBox.get(_userGenresKey)?.cast<String>(), 
        playerCount: _preferredPlayers, 
    );
  }

  
  // Fonction de Recommandation (logique métier)
  void _loadRecommendations({
    List<String>? genres, 
    int? playerCount,
  }) {
    List<BoardGame> initialRecs = [];
    final allGames = widget.boardGameBox.values.toList();
    
    Iterable<BoardGame> filteredGames = allGames;

    // --- Filtre 1: par Tags (Genres) ---
    if (genres != null && genres.isNotEmpty) {
      filteredGames = filteredGames.where((game) {
        return game.tags.any((tag) => genres.contains(tag));
      });
    }

    // --- Filtre 2: par Nombre de Joueurs (UNIQUE) ---
    if (playerCount != null && playerCount > 0) {
      filteredGames = filteredGames.where((game) {
        return playerCount >= game.minPlayers && playerCount <= game.maxPlayers;
      });
    }

    // --- Application du Score Dynamique ---
    if (filteredGames.isNotEmpty) {
        initialRecs = filteredGames.toList();
        
        // Tri par le NOUVEAU score dynamique
        initialRecs.sort((a, b) {
          final scoreA = _calculateDynamicRating(a);
          final scoreB = _calculateDynamicRating(b);
          return scoreB.compareTo(scoreA); // Tri décroissant
        }); 
        
        // On prend les 10 meilleurs parmi le filtre basé sur le score dynamique
        initialRecs = initialRecs.take(10).toList(); 
    } else {
      // Cas de repli si aucun filtre ne correspond
      initialRecs = allGames.toList();
      initialRecs.sort((a, b) => b.rating.compareTo(a.rating)); 
      initialRecs = initialRecs.take(5).toList();
    }


    setState(() {
        _recommendedGames = initialRecs;
        _isContentLoaded = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jeux"),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white), 
            onPressed: () {
              _navigateToPreferences(canGoBack: true); 
            },
          ),
        ],
      ),
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
        child: !_isContentLoaded 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cube orange (Logo/Header)
                    Center(
                      child: Container(
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "Jeux",
                            style: GoogleFonts.bebasNeue(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Affichage des préférences actives
                    if (_preferredPlayers != null) 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Text(
                            "Filtre actif : ${_preferredPlayers} joueurs (modifier dans les paramètres ⚙️)",
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),

                    // Section des Recommandations (Priorité)
                    const Text(
                      "🎯 Vos Recommandations (Score Dynamique)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Le score dynamique est visible dans cette section
                    _buildHorizontalGameList(_recommendedGames, Colors.redAccent, showFeedback: true, showDynamicScore: true),
                    
                    const SizedBox(height: 30),
                    
                    // Affichage du compte de jeux non aimés
                    if (_dislikedGamesTitles.isNotEmpty || _likedGamesTitles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30.0),
                        child: Text(
                          "Votre feedback influence les scores. ${_dislikedGamesTitles.length} jeu(x) sont pénalisés, ${_likedGamesTitles.length} sont favorisés.",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      
                    // ------------------------------------------------------------------
                    // SECTIONS BASÉES SUR LE DATASET (Affichent le feedback aussi)
                    // ------------------------------------------------------------------
                    
                    // Section 1 : ⭐ Les Mieux Notés (Feedback possible)
                    const Text(
                      "⭐ Les Mieux Notés (Feedback possible)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // showFeedback: true pour toutes les sections maintenant
                    _buildHorizontalGameList(
                        widget.boardGameBox.values
                            .toList()
                            ..sort((a, b) => b.rating.compareTo(a.rating)) 
                            ..take(5).toList(), 
                        Colors.yellow[700],
                        showFeedback: true,
                        showDynamicScore: false, // Affichage du rating de base
                    ), 

                    const SizedBox(height: 20),

                    // Section 2 : 🧠 Les Plus Difficiles (Feedback possible)
                    const Text(
                      "🧠 Les Plus Difficiles (Feedback possible)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildHorizontalGameList(
                        widget.boardGameBox.values
                            .where((g) => g.complexity > 0.0) 
                            .toList()
                            ..sort((a, b) => b.complexity.compareTo(a.complexity)) 
                            ..take(5)
                            .toList(),
                        Colors.deepPurple[400],
                        showFeedback: true,
                        showDynamicScore: false, // Affichage de la complexité
                    ),

                    const SizedBox(height: 20),

                    // Section 3 : 📅 Les Plus Récents (Feedback possible)
                    const Text(
                      "📅 Les Plus Récents (Feedback possible)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildHorizontalGameList(
                        widget.boardGameBox.values
                            .where((g) => g.releaseYear >= 1900) 
                            .toList() 
                            ..sort((a, b) => b.releaseYear.compareTo(a.releaseYear)) 
                            ..take(5)
                            .toList(),
                        Colors.blueGrey,
                        showFeedback: true,
                        showDynamicScore: false, // Affichage de l'année
                    ),
                    
                    const SizedBox(height: 30),

                    // Bouton Home
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigue vers la toute première route de la pile (HomePage)
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.purple,
                        ),
                        child: const Icon(Icons.home, color: Colors.white, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  // Fonction utilitaire pour construire les listes horizontales de jeux
  Widget _buildHorizontalGameList(
    List<BoardGame> games, 
    Color? color, 
    {
      bool showFeedback = false, 
      required bool showDynamicScore // Nouveau paramètre
    }
  ) {
    if (games.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Aucun jeu trouvé',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 150, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          
          // Détermination dynamique de la ligne d'information supplémentaire
          Widget extraInfoWidget;
          if (showDynamicScore) {
              final dynamicScore = _calculateDynamicRating(game);
              extraInfoWidget = Text(
                'Score: ${dynamicScore.toStringAsFixed(2)}/10',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
              );
          }
          else if (color == Colors.yellow[700]) {
            extraInfoWidget = Text(
              'Note: ${game.rating.toStringAsFixed(2)}/10',
              style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)
            );
          } else if (color == Colors.deepPurple[400]) {
            extraInfoWidget = Text(
              'Diff: ${game.complexity.toStringAsFixed(2)}/5',
              style: const TextStyle(color: Colors.white70, fontSize: 11)
            );
          } else if (color == Colors.blueGrey) {
            extraInfoWidget = Text(
              'Année: ${game.releaseYear}',
              style: const TextStyle(color: Colors.white70, fontSize: 11)
            );
          } else {
            // Affichage par défaut (si non dynamique et couleur non reconnue)
            extraInfoWidget = Text(
              'Durée: ${game.avgDuration.toStringAsFixed(0)} min',
              style: const TextStyle(color: Colors.white70, fontSize: 11)
            );
          }
          
          // Détermination de l'état aimé/non aimé pour la carte
          final isLiked = _likedGamesTitles.contains(game.title);
          final isDisliked = _dislikedGamesTitles.contains(game.title);

          return Container(
            margin: const EdgeInsets.only(right: 10),
            width: 150,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              // Ajout d'une bordure ou d'une ombre si le jeu est aimé/non aimé
              border: isLiked 
                ? Border.all(color: Colors.greenAccent, width: 3) 
                : isDisliked 
                  ? Border.all(color: Colors.pinkAccent, width: 3) 
                  : null,
              boxShadow: isLiked || isDisliked
                ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]
                : null
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color == Colors.yellow[700] ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.minPlayers}-${game.maxPlayers} joueurs',
                        style: TextStyle(
                          color: color == Colors.redAccent ? Colors.yellowAccent : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      extraInfoWidget,
                    ],
                  ),
                  
                  // --- Boutons de Feedback MAINTENANT pour toutes les sections ---
                  if (showFeedback)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bouton Dislike (Non aimé)
                        GestureDetector(
                          onTap: () => _handleGameFeedback(game, false),
                          child: Icon(
                            Icons.thumb_down_alt_rounded,
                            size: 20,
                            color: isDisliked ? Colors.pinkAccent : Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bouton Like (Aimé)
                        GestureDetector(
                          onTap: () => _handleGameFeedback(game, true),
                          child: Icon(
                            Icons.thumb_up_alt_rounded,
                            size: 20,
                            color: isLiked ? Colors.greenAccent : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}