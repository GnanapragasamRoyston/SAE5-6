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

  static const String _likedGamesKey = 'liked_games_titles';
  static const String _dislikedGamesKey = 'disliked_games_titles';

  @override
  void initState() {
    super.initState();
    _loadFeedbackData();
  }

  void _loadFeedbackData() {
    final savedLikes = List<String>.from(widget.settingsBox.get(_likedGamesKey) ?? []);
    final savedDislikes = List<String>.from(widget.settingsBox.get(_dislikedGamesKey) ?? []);
    setState(() {
      _likedGamesTitles = savedLikes.toSet();
      _dislikedGamesTitles = savedDislikes.toSet();
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
      await widget.settingsBox.put(_dislikedGamesKey, _dislikedGamesTitles.toList());

      widget.onFeedbackGiven();

      final message = isLiked
          ? (_likedGamesTitles.contains(game.title) ? '✓ Like enregistré' : 'Like annulé')
          : (_dislikedGamesTitles.contains(game.title) ? '✗ Dislike enregistré' : 'Dislike annulé');

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

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final isLiked = _likedGamesTitles.contains(game.title);
    final isDisliked = _dislikedGamesTitles.contains(game.title);

    Widget _buildTagList(String title, List<String> tags) {
      final cleanedTags = tags.where((tag) => tag.isNotEmpty).toList();
      if (cleanedTags.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.pinkAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: cleanedTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag, style: GoogleFonts.poppins(fontSize: 12)),
                      backgroundColor: Colors.pink.shade900.withOpacity(0.2),
                      labelStyle: TextStyle(color: Colors.pink.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.pink.shade400),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(game.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.blue,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 36,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.star_rate_rounded,
                          label: 'Note BGG',
                          value: '${game.rating.toStringAsFixed(2)} / 10',
                          color: Colors.yellow,
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          icon: Icons.psychology_rounded,
                          label: 'Difficulté',
                          value: '${game.complexity.toStringAsFixed(2)} / 5',
                          color: Colors.deepPurple[200],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildFeedbackButton(
                        icon: Icons.thumb_up_alt_rounded,
                        color: Colors.greenAccent,
                        isActive: isLiked,
                        onTap: () => _handleGameFeedback(game, true),
                      ),
                      const SizedBox(height: 10),
                      _buildFeedbackButton(
                        icon: Icons.thumb_down_alt_rounded,
                        color: Colors.pinkAccent,
                        isActive: isDisliked,
                        onTap: () => _handleGameFeedback(game, false),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white30),
              const SizedBox(height: 16),

              _buildDetailRow(
                icon: Icons.people_alt,
                label: 'Joueurs',
                value: '${game.minPlayers} - ${game.maxPlayers} joueurs',
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.timer,
                label: 'Durée moyenne',
                value: '${game.avgDuration} minutes',
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.calendar_month,
                label: 'Année de sortie',
                value: '${game.releaseYear.toInt()}',
                color: Colors.tealAccent,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.child_care_rounded,
                label: 'Âge minimum',
                value: '${game.minAge} ans et plus',
                color: Colors.redAccent,
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink.shade900.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade700, width: 1),
                ),
                child: _buildTagList('Tags (Genres & Mécanismes)', game.tags),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 VERSION COMPACTE DU DETAIL ROW (Valeur proche du label)
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          '$label : ',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? color : Colors.white24,
            width: 2,
          ),
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
