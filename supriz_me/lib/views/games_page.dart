// games_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'dart:math';

import '../models/board_game.dart';
import 'games_preferences_page.dart';
import 'game_details_page.dart';

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

  int? _preferredPlayers;
  int? _maxDuration;

  Set<String> _likedGamesTitles = {};
  Set<String> _dislikedGamesTitles = {};

  Map<String, double> _tagProfileScores = {};
  List<String>? _initialGenres;

  static const String _preferencesSetKey = 'game_preferences_set';
  static const String _userGenresKey = 'user_game_genres';
  static const String _playersCountKey = 'player_count_preference';
  static const String _maxDurationKey = 'max_duration_preference';

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

  void _loadFeedbackData() {
    final savedLikes =
        List<String>.from(widget.settingsBox.get(_likedGamesKey) ?? []);
    final savedDislikes =
        List<String>.from(widget.settingsBox.get(_dislikedGamesKey) ?? []);
    _likedGamesTitles = savedLikes.toSet();
    _dislikedGamesTitles = savedDislikes.toSet();
  }

  void _checkPreferencesStatus() async {
    final preferencesSet = widget.settingsBox.get(_preferencesSetKey) ?? false;

    if (preferencesSet) {
      final List<String>? savedGenres =
          widget.settingsBox.get(_userGenresKey)?.cast<String>();

      _initialGenres = savedGenres;

      _preferredPlayers = widget.settingsBox.get(_playersCountKey);
      _maxDuration = widget.settingsBox.get(_maxDurationKey);

      _buildTagProfile();

      _loadRecommendations(
        genres: savedGenres,
        playerCount: _preferredPlayers,
        maxDuration: _maxDuration,
      );
    } else {
      _navigateToPreferences(canGoBack: false);
    }
  }

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
      _maxDuration = widget.settingsBox.get(_maxDurationKey);

      final List<String>? savedGenres =
          widget.settingsBox.get(_userGenresKey)?.cast<String>();

      _initialGenres = savedGenres;

      _buildTagProfile();

      _loadRecommendations(
        genres: savedGenres,
        playerCount: _preferredPlayers,
        maxDuration: _maxDuration,
      );
    } else {
      if (!canGoBack && !_isContentLoaded) {
        setState(() {
          _isContentLoaded = true;
        });
      }
    }
  }

  void _navigateToSurpriseGame() {
    final recommendedTitles = _recommendedGames.map((g) => g.title).toSet();
    final allGames = widget.boardGameBox.values.toList();

    final availableSurpriseGames = allGames.where((game) {
      return !recommendedTitles.contains(game.title) &&
          !_likedGamesTitles.contains(game.title) &&
          !_dislikedGamesTitles.contains(game.title);
    }).toList();

    if (availableSurpriseGames.isNotEmpty) {
      final random = Random();
      final surpriseGame =
          availableSurpriseGames[random.nextInt(availableSurpriseGames.length)];

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameDetailsPage(
            game: surpriseGame,
            settingsBox: widget.settingsBox,
            onFeedbackGiven: _reloadRecommendationSystem,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Zut ! Tous les jeux restants sont déjà dans vos recommandations ou vous avez déjà donné un feedback.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.amber,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildSurpriseMeButton() {
    return Column(
      children: [
        // Phrase d'accroche stylée
        Text(
          "🚀 Envie de découvrir des jeux totalement différents de vos goûts ?\nLaissez-vous Supriz'Me!",
          textAlign: TextAlign.center,
          style: GoogleFonts.bebasNeue(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Tooltip(
            message: "Un petit coup de pouce du destin?",
            child: ElevatedButton.icon(
              onPressed: _navigateToSurpriseGame,
              icon: const Icon(Icons.casino, color: Colors.white),
              label: Text(
                "Supriz'Me",
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.purple.shade300, width: 2),
                ),
                elevation: 8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _reloadRecommendationSystem() {
    if (mounted) {
      setState(() {
        _loadFeedbackData();
        _buildTagProfile();
        _loadRecommendations(
          genres: widget.settingsBox.get(_userGenresKey)?.cast<String>(),
          playerCount: _preferredPlayers,
          maxDuration: _maxDuration,
        );
      });
    }
  }

  void _buildTagProfile() {
    Map<String, double> profile = {};

    bool hasUserFeedback =
        _likedGamesTitles.isNotEmpty || _dislikedGamesTitles.isNotEmpty;

    if (hasUserFeedback) {
      for (var title in _likedGamesTitles) {
        final game = widget.boardGameBox.values.firstWhere(
          (g) => g.title == title,
          orElse: () => BoardGame.empty(),
        );
        if (game.title.isNotEmpty) {
          for (var tag in game.genres) {
            profile[tag] = (profile[tag] ?? 0.0) + 1.0;
          }
        }
      }

      for (var title in _dislikedGamesTitles) {
        final game = widget.boardGameBox.values.firstWhere(
          (g) => g.title == title,
          orElse: () => BoardGame.empty(),
        );
        if (game.title.isNotEmpty) {
          for (var tag in game.genres) {
            profile[tag] = (profile[tag] ?? 0.0) - 1.0;
          }
        }
      }
    } else {
      if (_initialGenres != null) {
        for (var genre in _initialGenres!) {
          profile[genre] = (profile[genre] ?? 0.0) + 20.0;
        }
      }
    }

    _tagProfileScores = profile;
  }

  double _calculateRecommendationScore(BoardGame game) {
    if (_tagProfileScores.isEmpty &&
        !_likedGamesTitles.isNotEmpty &&
        !_dislikedGamesTitles.isNotEmpty) {
      return game.rating;
    }

    double tagScoreSum = 0.0;

    for (var tag in game.genres) {
      tagScoreSum += _tagProfileScores[tag] ?? 0.0;
    }

    final affinityScore = tagScoreSum * 5.0;
    final popularityScore = game.rating * 0.5;

    final finalScore = affinityScore + popularityScore;

    return finalScore;
  }

  void _handleGameFeedback(BoardGame game, bool isLiked) async {
    setState(() {
      if (isLiked) {
        if (_likedGamesTitles.contains(game.title)) {
          _likedGamesTitles.remove(game.title);
        } else {
          _likedGamesTitles.add(game.title);
          _dislikedGamesTitles.remove(game.title);
        }
      } else {
        if (_dislikedGamesTitles.contains(game.title)) {
          _dislikedGamesTitles.remove(game.title);
        } else {
          _dislikedGamesTitles.add(game.title);
          _likedGamesTitles.remove(game.title);
        }
      }
    });

    await widget.settingsBox.put(_likedGamesKey, _likedGamesTitles.toList());
    await widget.settingsBox
        .put(_dislikedGamesKey, _dislikedGamesTitles.toList());

    _reloadRecommendationSystem();

    final message = isLiked
        ? (_likedGamesTitles.contains(game.title)
            ? '✓ Jeu favori enregistré'
            : 'Like annulé')
        : (_dislikedGamesTitles.contains(game.title)
            ? '✗ Jeu pénalisé'
            : 'Dislike annulé');

    final color = Colors.grey.shade700;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _loadRecommendations({
    List<String>? genres,
    int? playerCount,
    int? maxDuration,
  }) {
    List<BoardGame> initialRecs = [];
    final allGames = widget.boardGameBox.values.toList();

    Iterable<BoardGame> filteredGames = allGames;

    if (genres != null && genres.isNotEmpty) {
      filteredGames = filteredGames.where((game) {
        return game.genres.any((tag) => genres.contains(tag));
      });
    }

    if (maxDuration != null && maxDuration > 0) {
      filteredGames = filteredGames.where((game) {
        return game.avgDuration <= maxDuration;
      });
    }

    if (playerCount != null && playerCount > 0) {
      filteredGames = filteredGames.where((game) {
        return playerCount >= game.minPlayers && playerCount <= game.maxPlayers;
      });
    }

    if (filteredGames.isNotEmpty) {
      initialRecs = filteredGames.toList();

      initialRecs.sort((a, b) {
        final scoreA = _calculateRecommendationScore(a);
        final scoreB = _calculateRecommendationScore(b);
        return scoreB.compareTo(scoreA);
      });

      initialRecs = initialRecs.take(20).toList();
    } else {
      initialRecs = allGames.toList();
      initialRecs.sort((a, b) => b.rating.compareTo(a.rating));
      initialRecs = initialRecs.take(10).toList();
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
        title: const Text('Jeux'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
              Color(0xFF1A3A52),
              Color(0xFF2563EB),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: !_isContentLoaded
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // BOUTON SUPRIZ'ME (Incluant l'accroche)
                    _buildSurpriseMeButton(),

                    // SECTION DE RECOMMANDATION
                    _buildRecommendationsSection(),
                    const SizedBox(height: 12),

                    // AFFICHAGE DES FILTRES ACTIFS (maintenant après les recommandations)
                    if (_preferredPlayers != null || _maxDuration != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          'Filtres actifs : ${_preferredPlayers != null ? '👤 $_preferredPlayers joueurs' : ''} ${_maxDuration != null ? ' | ⏱️ max ${_maxDuration} min' : ''}'
                          ' (modifier dans les paramètres ⚙️)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    // Suppression de l'ancien texte de feedback ici

                    const SizedBox(height: 24),

                    _buildSectionTitle(
                      icon: Icons.star,
                      label: 'MIEUX NOTÉS',
                    ),
                    const SizedBox(height: 12),
                    _buildHorizontalGameList(
                      _topRatedGames(),
                      Colors.yellow[700],
                      showFeedback: true,
                      showDynamicScore: false,
                      infoType: _GameInfoType.rating,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle(
                      icon: Icons.psychology,
                      label: 'PLUS DIFFICILES',
                    ),
                    const SizedBox(height: 12),
                    _buildHorizontalGameList(
                      _mostComplexGames(),
                      Colors.deepPurple[400],
                      showFeedback: true,
                      showDynamicScore: false,
                      infoType: _GameInfoType.complexity,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle(
                      icon: Icons.new_releases,
                      label: 'PLUS RÉCENTS',
                    ),
                    const SizedBox(height: 12),
                    _buildHorizontalGameList(
                      _mostRecentGames(),
                      Colors.blueGrey,
                      showFeedback: true,
                      showDynamicScore: false,
                      infoType: _GameInfoType.year,
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.grey.shade700,
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.extension, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 8),
          Text(
            'JEUX DE SOCIÉTÉ',
            style: GoogleFonts.bebasNeue(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.bebasNeue(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_recommendedGames.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.favorite,
            label: 'RECOMMANDÉS POUR VOUS',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Aucune recommandation disponible pour le moment. Veuillez vérifier vos filtres ou vos préférences.',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.favorite,
          label: 'RECOMMANDÉS POUR VOUS',
        ),
        const SizedBox(height: 12),
        _buildHorizontalGameList(
          _recommendedGames,
          Colors.redAccent,
          showFeedback: true,
          showDynamicScore: true,
          infoType: _GameInfoType.dynamicScore,
        ),
      ],
    );
  }

  List<BoardGame> _topRatedGames() {
    final games = widget.boardGameBox.values.toList();
    games.sort((a, b) => b.rating.compareTo(a.rating));
    return games.take(20).toList();
  }

  List<BoardGame> _mostComplexGames() {
    final games =
        widget.boardGameBox.values.where((g) => g.complexity > 0.0).toList();
    games.sort((a, b) => b.complexity.compareTo(a.complexity));
    return games.take(20).toList();
  }

  List<BoardGame> _mostRecentGames() {
    final games =
        widget.boardGameBox.values.where((g) => g.releaseYear >= 1900).toList();
    games.sort((a, b) => b.releaseYear.compareTo(a.releaseYear));
    return games.take(20).toList();
  }

  Widget _buildHorizontalGameList(
    List<BoardGame> games,
    Color? color, {
    required bool showFeedback,
    required bool showDynamicScore,
    required _GameInfoType infoType,
  }) {
    if (games.isEmpty) {
      return SizedBox(
        height: 170,
        child: Center(
          child: Text(
            'Aucun jeu trouvé',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          final isLiked = _likedGamesTitles.contains(game.title);
          final isDisliked = _dislikedGamesTitles.contains(game.title);

          Widget extraInfoWidget;
          if (showDynamicScore && infoType == _GameInfoType.dynamicScore) {
            final dynamicScore = _calculateRecommendationScore(game);
            extraInfoWidget = Text(
              'Score: ${dynamicScore.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            );
          } else {
            switch (infoType) {
              case _GameInfoType.rating:
                extraInfoWidget = Text(
                  'Note: ${game.rating.toStringAsFixed(2)}/10',
                  style: GoogleFonts.poppins(
                    color: color == Colors.yellow[700]
                        ? Colors.black
                        : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
                break;
              case _GameInfoType.complexity:
                extraInfoWidget = Text(
                  'Diff: ${game.complexity.toStringAsFixed(2)}/5',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                );
                break;
              case _GameInfoType.year:
                extraInfoWidget = Text(
                  'Année: ${game.releaseYear}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                );
                break;
              case _GameInfoType.duration:
                extraInfoWidget = Text(
                  'Durée: ${game.avgDuration.toStringAsFixed(0)} min',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                );
                break;
              default:
                extraInfoWidget = Text(
                  'Durée: ${game.avgDuration.toStringAsFixed(0)} min',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                );
                break;
            }
          }

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GameDetailsPage(
                    game: game,
                    settingsBox: widget.settingsBox,
                    onFeedbackGiven: _reloadRecommendationSystem,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 150,
              height: 170,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (color ?? Colors.blue).withOpacity(0.9),
                    (color ?? Colors.blue).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: isLiked
                    ? Border.all(color: Colors.greenAccent, width: 2.5)
                    : isDisliked
                        ? Border.all(color: Colors.pinkAccent, width: 2.5)
                        : Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            game.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: color == Colors.yellow[700]
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${game.minPlayers}-${game.maxPlayers} joueurs',
                            style: GoogleFonts.poppins(
                              color: color == Colors.redAccent
                                  ? Colors.yellowAccent
                                  : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          extraInfoWidget,
                        ],
                      ),
                    ),
                    if (showFeedback)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => _handleGameFeedback(game, false),
                            child: Icon(
                              Icons.thumb_down_alt_rounded,
                              size: 20,
                              color: isDisliked
                                  ? Colors.pinkAccent
                                  : Colors.white54,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _handleGameFeedback(game, true),
                            child: Icon(
                              Icons.thumb_up_alt_rounded,
                              size: 20,
                              color:
                                  isLiked ? Colors.greenAccent : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _GameInfoType {
  rating,
  complexity,
  year,
  dynamicScore,
  duration,
}
