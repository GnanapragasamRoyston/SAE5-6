import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../models/board_game.dart';
import 'games_preferences_page.dart';

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

  Set<String> _likedGamesTitles = {};
  Set<String> _dislikedGamesTitles = {};

  static const String _preferencesSetKey = 'game_preferences_set';
  static const String _userGenresKey = 'user_game_genres';
  static const String _playersCountKey = 'player_count_preference';

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
      _preferredPlayers = widget.settingsBox.get(_playersCountKey);

      _loadRecommendations(
        genres: savedGenres,
        playerCount: _preferredPlayers,
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

  double _calculateDynamicRating(BoardGame game) {
    double score = game.rating;

    if (_likedGamesTitles.contains(game.title)) {
      score += 1.5;
    } else if (_dislikedGamesTitles.contains(game.title)) {
      score -= 3.0;
    }

    for (var likedTitle in _likedGamesTitles) {
      final likedGame = widget.boardGameBox.values.firstWhere(
            (g) => g.title == likedTitle,
        orElse: () => BoardGame.empty(),
      );

      if (likedGame.title.isNotEmpty) {
        final commonTags =
            game.tags.where((tag) => likedGame.tags.contains(tag)).length;
        score += commonTags * 0.2;
      }
    }

    for (var dislikedTitle in _dislikedGamesTitles) {
      final dislikedGame = widget.boardGameBox.values.firstWhere(
            (g) => g.title == dislikedTitle,
        orElse: () => BoardGame.empty(),
      );

      if (dislikedGame.title.isNotEmpty) {
        final commonTags =
            game.tags.where((tag) => dislikedGame.tags.contains(tag)).length;
        score -= commonTags * 0.5;
      }
    }

    return score.clamp(0.0, 10.0);
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

    _loadRecommendations(
      genres: widget.settingsBox.get(_userGenresKey)?.cast<String>(),
      playerCount: _preferredPlayers,
    );

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
  }) {
    List<BoardGame> initialRecs = [];
    final allGames = widget.boardGameBox.values.toList();

    Iterable<BoardGame> filteredGames = allGames;

    if (genres != null && genres.isNotEmpty) {
      filteredGames = filteredGames.where((game) {
        return game.tags.any((tag) => genres.contains(tag));
      });
    }

    if (playerCount != null && playerCount > 0) {
      filteredGames = filteredGames.where((game) {
        return playerCount >= game.minPlayers &&
            playerCount <= game.maxPlayers;
      });
    }

    if (filteredGames.isNotEmpty) {
      initialRecs = filteredGames.toList();

      initialRecs.sort((a, b) {
        final scoreA = _calculateDynamicRating(a);
        final scoreB = _calculateDynamicRating(b);
        return scoreB.compareTo(scoreA);
      });

      initialRecs = initialRecs.take(10).toList();
    } else {
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

              if (_preferredPlayers != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    'Filtre actif : $_preferredPlayers joueurs '
                        '(modifier dans les paramètres ⚙️)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),

              _buildRecommendationsSection(),
              const SizedBox(height: 24),

              if (_dislikedGamesTitles.isNotEmpty ||
                  _likedGamesTitles.isNotEmpty)
                Text(
                  'Votre feedback influence les scores. '
                      '${_dislikedGamesTitles.length} jeu(x) sont pénalisés, '
                      '${_likedGamesTitles.length} sont favorisés.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

              if (_dislikedGamesTitles.isNotEmpty ||
                  _likedGamesTitles.isNotEmpty)
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
                    Navigator.popUntil(
                        context, (route) => route.isFirst);
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
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
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
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
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Aucune recommandation disponible pour le moment.',
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
    return games.take(5).toList();
  }

  List<BoardGame> _mostComplexGames() {
    final games =
    widget.boardGameBox.values.where((g) => g.complexity > 0.0).toList();
    games.sort((a, b) => b.complexity.compareTo(a.complexity));
    return games.take(5).toList();
  }

  List<BoardGame> _mostRecentGames() {
    final games =
    widget.boardGameBox.values.where((g) => g.releaseYear >= 1900).toList();
    games.sort((a, b) => b.releaseYear.compareTo(a.releaseYear));
    return games.take(5).toList();
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
        height: 120,
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
            final dynamicScore = _calculateDynamicRating(game);
            extraInfoWidget = Text(
              'Score: ${dynamicScore.toStringAsFixed(2)}/10',
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

          return Container(
            margin: const EdgeInsets.only(right: 10),
            width: 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (color ?? Colors.blue).withValues(alpha: 0.9),
                  (color ?? Colors.blue).withValues(alpha: 0.6),
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
                color: Colors.white.withValues(alpha: 0.2),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.minPlayers}-${game.maxPlayers} joueurs',
                        style: GoogleFonts.poppins(
                          color: color == Colors.redAccent
                              ? Colors.yellowAccent
                              : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      extraInfoWidget,
                    ],
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
                            color: isLiked
                                ? Colors.greenAccent
                                : Colors.white54,
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

enum _GameInfoType {
  rating,
  complexity,
  year,
  dynamicScore,
  duration,
}
