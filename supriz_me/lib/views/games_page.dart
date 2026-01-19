// games_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'dart:math';

import '../models/board_game.dart';
import 'games_preferences_page.dart';
import 'game_details_page.dart';

class GamesPage extends StatefulWidget {
  final Box boardGameBox;
  final Box settingsBox;
  final bool autoSurprizme; // ✅ NOUVEAU PARAMÈTRE

  const GamesPage({
    super.key,
    required this.boardGameBox,
    required this.settingsBox,
    this.autoSurprizme = false, // ✅ PAR DÉFAUT FALSE
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
  Set<String> _favoriteGamesTitles = {};
  Set<String> _completedGamesTitles = {};
  Map<String, double> _tagProfileScores = {};
  List<String>? _initialGenres;

  static const String _preferencesSetKey = 'game_preferences_set';
  static const String _userGenresKey = 'user_game_genres';
  static const String _playersCountKey = 'player_count_preference';
  static const String _maxDurationKey = 'max_duration_preference';
  static const String _likedGamesKey = 'liked_games_titles';
  static const String _dislikedGamesKey = 'disliked_games_titles';
  static const String _favoriteGamesKey = 'favorite_games_titles';
  static const String _completedGamesKey = 'completed_games_titles';

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
    final savedFavorites =
    List<String>.from(widget.settingsBox.get(_favoriteGamesKey) ?? []);
    final savedCompleted =
    List<String>.from(widget.settingsBox.get(_completedGamesKey) ?? []);

    _likedGamesTitles = savedLikes.toSet();
    _dislikedGamesTitles = savedDislikes.toSet();
    _favoriteGamesTitles = savedFavorites.toSet();
    _completedGamesTitles = savedCompleted.toSet();
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

      // ✅ SEUL DÉCLENCHEMENT ICI (après chargement complet)
      if (widget.autoSurprizme && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _navigateToSurpriseGame();
        }
      }
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
    final allGames = widget.boardGameBox.values.cast<BoardGame>().toList();

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
        final game = widget.boardGameBox.values.cast<BoardGame>().firstWhere(
              (g) => g.title == title,
          orElse: () => BoardGame.empty(),
        );

        if (game.title.isNotEmpty) {
          for (var tag in game.genres) {
            profile[tag] = (profile[tag] ?? 0.0) + 1.0;
          }
          for (var mechanic in game.mechanics) {
            final mechanicKey = 'mechanic:$mechanic';
            profile[mechanicKey] = (profile[mechanicKey] ?? 0.0) + 0.5;
          }
        }
      }

      for (var title in _dislikedGamesTitles) {
        final game = widget.boardGameBox.values.cast<BoardGame>().firstWhere(
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

  void _toggleGameFavorite(String gameTitle) {
    if (_favoriteGamesTitles.contains(gameTitle)) {
      _favoriteGamesTitles.remove(gameTitle);
    } else {
      _favoriteGamesTitles.add(gameTitle);
    }

    widget.settingsBox.put(_favoriteGamesKey, _favoriteGamesTitles.toList());
    setState(() {});
  }

  bool _isGameFavorite(String gameTitle) {
    return _favoriteGamesTitles.contains(gameTitle);
  }

  double _calculateRecommendationScore(BoardGame game) {
    if (_tagProfileScores.isEmpty &&
        _likedGamesTitles.isEmpty &&
        _dislikedGamesTitles.isEmpty) {
      return game.rating;
    }

    double tagScoreSum = 0.0;
    for (var tag in game.genres) {
      tagScoreSum += _tagProfileScores[tag] ?? 0.0;
    }

    final affinityScore = tagScoreSum * 5.0;
    final popularityScore = game.rating * 0.5;
    final complexityPreference = _calculateComplexityPreference();
    final complexityScore = game.complexity * complexityPreference * 2.0;
    final durationScore = _calculateDurationFit(game.avgDuration) * 3.0;

    return affinityScore + popularityScore + complexityScore + durationScore;
  }

  double _calculateComplexityPreference() {
    if (_likedGamesTitles.isEmpty) {
      return 1.0;
    }

    double totalComplexity = 0.0;
    for (var title in _likedGamesTitles) {
      final game = widget.boardGameBox.values.cast<BoardGame>().firstWhere(
            (g) => g.title == title,
        orElse: () => BoardGame.empty(),
      );

      if (game.title.isNotEmpty) {
        totalComplexity += game.complexity;
      }
    }

    final avgComplexity = totalComplexity / _likedGamesTitles.length;
    return (avgComplexity / 5.0).clamp(0.5, 1.5);
  }

  double _calculateDurationFit(double gameDuration) {
    if (_maxDuration != null && _maxDuration! > 0) {
      final durationDiff = (_maxDuration! - gameDuration).abs();
      final fit = 1.0 - (durationDiff / _maxDuration!).clamp(0.0, 1.0);
      return fit;
    }

    if (gameDuration < 30 || gameDuration > 120) {
      return 0.7;
    }

    return 1.0;
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey.shade700,
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
    final allGames = widget.boardGameBox.values.cast<BoardGame>().toList();

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
      backgroundColor: const Color(0xFF050814),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            center: Alignment(0, -0.5),
            colors: [
              Color(0xFF0a1628),
              Color(0xFF050814),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildArcadeHeader(),
            Expanded(
              child: !_isContentLoaded
                  ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00d9ff)),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSurpriseMeButton(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0d1b35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF00d9ff), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00d9ff).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '${widget.boardGameBox.length}',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 24,
                              color: const Color(0xFF00d9ff),
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "JEUX DISPO",
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_preferredPlayers != null || _maxDuration != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0d1b35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF00d9ff).withOpacity(0.5)),
                        ),
                        child: Text(
                          'FILTRES : ${_preferredPlayers != null ? '👤 $_preferredPlayers joueurs' : ''}${_maxDuration != null ? ' | ⏱️ ${_maxDuration}min' : ''}',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    const SizedBox(height: 25),

                    _buildRecommendationsSection(),
                    const SizedBox(height: 25),

                    _buildArcadeSectionTitle(Icons.star, 'TOP NOTES'),
                    const SizedBox(height: 12),
                    _buildHorizontalGameList(
                      _topRatedGames(),
                      const Color(0xFFffd700),
                      showFeedback: true,
                      showDynamicScore: false,
                      infoType: _GameInfoType.rating,
                    ),
                    const SizedBox(height: 25),

                    _buildArcadeSectionTitle(Icons.psychology, 'PLUS DURS'),
                    const SizedBox(height: 12),
                    _buildHorizontalGameList(
                      _mostComplexGames(),
                      const Color(0xFFb67dff),
                      showFeedback: true,
                      showDynamicScore: false,
                      infoType: _GameInfoType.complexity,
                    ),
                    const SizedBox(height: 25),

                    _buildArcadeSectionTitle(Icons.new_releases, 'RÉCENTS'),
                    const SizedBox(height: 12),
                    _buildHorizontalGameList(
                      _mostRecentGames(),
                      const Color(0xFF00c2ff),
                      showFeedback: true,
                      showDynamicScore: false,
                      infoType: _GameInfoType.year,
                    ),
                    const SizedBox(height: 25),

                    _buildFavoriteGamesSection(),
                    const SizedBox(height: 25),

                    _buildCompletedGamesSection(),
                    const SizedBox(height: 40),

                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0d1b35),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF00d9ff), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00d9ff).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.home,
                              color: Colors.white, size: 32),
                          onPressed: () => Navigator.popUntil(
                              context, (route) => route.isFirst),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArcadeHeader() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFff0080), Color(0xFFff6600)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.casino, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "JEUX ARCADE",
                style: GoogleFonts.pressStart2p(
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 22),
              onPressed: () => _navigateToPreferences(canGoBack: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurpriseMeButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFff0080), Color(0xFFff6600)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFff0080).withOpacity(0.6),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _navigateToSurpriseGame,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "SURPRIZ'ME",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildArcadeSectionTitle(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1b35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00d9ff), width: 1.5),
      ),
      child: Row(
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

  Widget _buildRecommendationsSection() {
    if (_recommendedGames.isEmpty) {
      return Column(
        children: [
          _buildArcadeSectionTitle(Icons.favorite, 'RECOMMANDÉS'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0d1b35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00d9ff)),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF00d9ff), size: 48),
                const SizedBox(height: 12),
                Text(
                  "Aucune reco pour l'instant",
                  style: GoogleFonts.pressStart2p(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Définis tes prefs ⚙️",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildArcadeSectionTitle(Icons.favorite, 'RECOMMANDÉS'),
        const SizedBox(height: 12),
        _buildHorizontalGameList(
          _recommendedGames,
          const Color(0xFF8b2f4a),
          showFeedback: true,
          showDynamicScore: true,
          infoType: _GameInfoType.dynamicScore,
        ),
      ],
    );
  }

  Widget _buildFavoriteGamesSection() {
    final allGames = widget.boardGameBox.values.cast<BoardGame>().toList();
    final favoriteGames = allGames
        .where((game) => _favoriteGamesTitles.contains(game.title))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0d1b35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFffa940), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.bookmark, color: Color(0xFFffa940), size: 20),
              const SizedBox(width: 10),
              Text(
                'À FAIRE PLUS TARD',
                style: GoogleFonts.pressStart2p(
                  fontSize: 11,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFffa940).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${favoriteGames.length}',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (favoriteGames.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun jeu ajouté',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteGames.length,
              itemBuilder: (context, index) {
                final game = favoriteGames[index];
                return _buildGameCard(game, const Color(0xFFffa940));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCompletedGamesSection() {
    final allGames = widget.boardGameBox.values.cast<BoardGame>().toList();
    final completedGames = allGames
        .where((game) => _completedGamesTitles.contains(game.title))
        .toList();

    if (completedGames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0d1b35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00FF88), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 20),
              const SizedBox(width: 10),
              Text(
                'JEUX COMPLÉTÉS',
                style: GoogleFonts.pressStart2p(
                  fontSize: 11,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${completedGames.length}',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: completedGames.length,
            itemBuilder: (context, index) {
              final game = completedGames[index];
              return _buildGameCard(game, const Color(0xFF00FF88));
            },
          ),
        ),
      ],
    );
  }

  List<BoardGame> _topRatedGames() {
    final games = widget.boardGameBox.values.cast<BoardGame>().toList();
    games.sort((a, b) => b.rating.compareTo(a.rating));
    return games.take(20).toList();
  }

  List<BoardGame> _mostComplexGames() {
    final games = widget.boardGameBox.values
        .cast<BoardGame>()
        .where((g) => g.complexity > 0.0)
        .toList();
    games.sort((a, b) => b.complexity.compareTo(a.complexity));
    return games.take(20).toList();
  }

  List<BoardGame> _mostRecentGames() {
    final games = widget.boardGameBox.values
        .cast<BoardGame>()
        .where((g) => g.releaseYear >= 1900)
        .toList();
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
            'Aucun jeu',
            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
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
          return _buildGameCard(
            game,
            color,
            showFeedback: showFeedback,
            showDynamicScore: showDynamicScore,
            infoType: infoType,
          );
        },
      ),
    );
  }

  Widget _buildGameCard(
      BoardGame game,
      Color? color, {
        bool showFeedback = true,
        bool showDynamicScore = false,
        _GameInfoType infoType = _GameInfoType.rating,
      }) {
    final isLiked = _likedGamesTitles.contains(game.title);
    final isDisliked = _dislikedGamesTitles.contains(game.title);

    Widget extraInfoWidget;

    if (showDynamicScore && infoType == _GameInfoType.dynamicScore) {
      final dynamicScore = _calculateRecommendationScore(game);
      extraInfoWidget = Text(
        '${dynamicScore.toStringAsFixed(1)}',
        style: GoogleFonts.pressStart2p(
          color: Colors.white,
          fontSize: 11,
          letterSpacing: 1,
        ),
      );
    } else {
      switch (infoType) {
        case _GameInfoType.rating:
          extraInfoWidget = Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFffd700), size: 12),
              const SizedBox(width: 4),
              Text(
                '${game.rating.toStringAsFixed(1)}',
                style: GoogleFonts.pressStart2p(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                ),
              ),
            ],
          );
          break;
        case _GameInfoType.complexity:
          extraInfoWidget = Text(
            '${game.complexity.toStringAsFixed(1)}/5',
            style: GoogleFonts.pressStart2p(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
          );
          break;
        case _GameInfoType.year:
          extraInfoWidget = Text(
            '${game.releaseYear.toInt()}',
            style: GoogleFonts.pressStart2p(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
          );
          break;
        default:
          extraInfoWidget = Text(
            '${game.avgDuration.toInt()}min',
            style: GoogleFonts.pressStart2p(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
          );
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
        margin: const EdgeInsets.only(right: 12),
        width: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (color ?? const Color(0xFF00d9ff)).withOpacity(0.3),
              (color ?? const Color(0xFF00d9ff)).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLiked
                ? Colors.greenAccent
                : isDisliked
                ? Colors.pinkAccent
                : (color ?? const Color(0xFF00d9ff)),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (color ?? const Color(0xFF00d9ff)).withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${game.minPlayers}-${game.maxPlayers}j',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    extraInfoWidget,
                  ],
                ),
              ),
              if (showFeedback)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _handleGameFeedback(game, false),
                      child: Icon(
                        Icons.thumb_down,
                        size: 18,
                        color: isDisliked ? Colors.pinkAccent : Colors.white38,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _handleGameFeedback(game, true),
                      child: Icon(
                        Icons.thumb_up,
                        size: 18,
                        color: isLiked ? Colors.greenAccent : Colors.white38,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleGameFavorite(game.title),
                      child: Icon(
                        _isGameFavorite(game.title)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: _isGameFavorite(game.title)
                            ? Colors.red
                            : Colors.white38,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
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
