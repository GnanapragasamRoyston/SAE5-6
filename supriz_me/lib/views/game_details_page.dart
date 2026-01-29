// game_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import '../models/board_game.dart';

class GameDetailsPage extends StatefulWidget {
  final BoardGame game;
  final Box settingsBox;
  final VoidCallback onFeedbackGiven;

  const GameDetailsPage({
    super.key,
    required this.game,
    required this.settingsBox,
    required this.onFeedbackGiven,
  });

  @override
  State<GameDetailsPage> createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  Set<String> _likedGamesTitles = {};
  Set<String> _dislikedGamesTitles = {};
  Set<String> _favoriteGamesTitles = {};

  static const String _likedGamesKey = 'liked_games_titles';
  static const String _dislikedGamesKey = 'disliked_games_titles';
  static const String _favoriteGamesKey = 'favorite_games_titles';

  @override
  void initState() {
    super.initState();
    _loadFeedbackData();
  }

  void _loadFeedbackData() {
    final savedLikes =
    List<String>.from(widget.settingsBox.get(_likedGamesKey) ?? []);
    final savedDislikes =
    List<String>.from(widget.settingsBox.get(_dislikedGamesKey) ?? []);
    final savedFavorites =
    List<String>.from(widget.settingsBox.get(_favoriteGamesKey) ?? []);

    setState(() {
      _likedGamesTitles = savedLikes.toSet();
      _dislikedGamesTitles = savedDislikes.toSet();
      _favoriteGamesTitles = savedFavorites.toSet();
    });
  }

  void _handleGameFeedback(BoardGame game, bool isLiked) async {
    bool feedbackChanged = false;

    setState(() {
      if (isLiked) {
        if (_likedGamesTitles.contains(game.title)) {
          _likedGamesTitles.remove(game.title);
          feedbackChanged = true;
        } else {
          _likedGamesTitles.add(game.title);
          if (_dislikedGamesTitles.contains(game.title)) {
            _dislikedGamesTitles.remove(game.title);
          }
          feedbackChanged = true;
        }
      } else {
        if (_dislikedGamesTitles.contains(game.title)) {
          _dislikedGamesTitles.remove(game.title);
          feedbackChanged = true;
        } else {
          _dislikedGamesTitles.add(game.title);
          if (_likedGamesTitles.contains(game.title)) {
            _likedGamesTitles.remove(game.title);
          }
          feedbackChanged = true;
        }
      }
    });

    if (feedbackChanged) {
      await widget.settingsBox.put(_likedGamesKey, _likedGamesTitles.toList());
      await widget.settingsBox
          .put(_dislikedGamesKey, _dislikedGamesTitles.toList());

      widget.onFeedbackGiven();

      final message = isLiked
          ? (_likedGamesTitles.contains(game.title)
          ? '✓ Like enregistré'
          : 'Like annulé')
          : (_dislikedGamesTitles.contains(game.title)
          ? '✗ Dislike enregistré'
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
  }

  void _toggleFavorite() async {
    setState(() {
      if (_favoriteGamesTitles.contains(widget.game.title)) {
        _favoriteGamesTitles.remove(widget.game.title);
      } else {
        _favoriteGamesTitles.add(widget.game.title);
      }
    });

    await widget.settingsBox
        .put(_favoriteGamesKey, _favoriteGamesTitles.toList());

    widget.onFeedbackGiven();

    final message = _favoriteGamesTitles.contains(widget.game.title)
        ? '⭐ Ajouté au favoris'
        : '⭐ Retiré des favoris';

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

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isLiked = _likedGamesTitles.contains(game.title);
    final isDisliked = _dislikedGamesTitles.contains(game.title);
    final isFavorite = _favoriteGamesTitles.contains(game.title);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            SliverAppBar(
              title: Text(
                game.title,
                style: GoogleFonts.pressStart2p(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFffd700),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${game.rating.toStringAsFixed(1)}/10',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.psychology_rounded,
                          color: Color(0xFF00ff85),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Diff: ${game.complexity.toStringAsFixed(1)}/5',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        ...game.genres.map(
                              (genre) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3cf2ff).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                  const Color(0xFF3cf2ff).withOpacity(0.5)),
                            ),
                            child: Text(
                              genre,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        ...game.mechanics.map(
                              (mechanic) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3cf2ff).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                  const Color(0xFF3cf2ff).withOpacity(0.5)),
                            ),
                            child: Text(
                              mechanic,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'INFORMATIONS',
                      style: GoogleFonts.pressStart2p(
                        color: const Color(0xFF3cf2ff),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.people_alt,
                      label: 'Joueurs',
                      value: '${game.minPlayers} - ${game.maxPlayers}',
                      color: const Color(0xFF00ff85),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Durée',
                      value: '${game.avgDuration.toInt()} min',
                      color: const Color(0xFF00ff85),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Année',
                      value: '${game.releaseYear.toInt()}',
                      color: const Color(0xFF3cf2ff),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.child_care_rounded,
                      label: 'Âge min',
                      value: '${game.minAge} ans',
                      color: const Color(0xFFffd700),
                    ),
                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeedbackButton(
                          icon: Icons.thumb_down_alt_rounded,
                          color: Colors.pinkAccent,
                          isActive: isDisliked,
                          onTap: () => _handleGameFeedback(game, false),
                        ),
                        const SizedBox(width: 10),
                        _buildFeedbackButton(
                          icon: Icons.thumb_up_alt_rounded,
                          color: Colors.greenAccent,
                          isActive: isLiked,
                          onTap: () => _handleGameFeedback(game, true),
                        ),
                        const SizedBox(width: 10),
                        _buildFeedbackButton(
                          icon: Icons.favorite,
                          color: Colors.redAccent,
                          isActive: isFavorite,
                          onTap: _toggleFavorite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // BOUTON HOME AJOUTÉ
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF121b3a),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF3cf2ff), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00e0ff).withOpacity(0.4),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : const Color(0xFF121b3a),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? color : const Color(0xFF3cf2ff),
            width: 2,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? color : Colors.white70,
          size: 28,
        ),
      ),
    );
  }
}