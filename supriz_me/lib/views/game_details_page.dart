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
  Set<String> _toDoGamesTitles = {};

  static const String _likedGamesKey = 'liked_games_titles';
  static const String _dislikedGamesKey = 'disliked_games_titles';
  static const String _favoriteGamesKey = 'favorite_games_titles';
  static const String _toDoGamesKey = 'todo_games_titles';

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
    final savedToDo =
        List<String>.from(widget.settingsBox.get(_toDoGamesKey) ?? []);
    setState(() {
      _likedGamesTitles = savedLikes.toSet();
      _dislikedGamesTitles = savedDislikes.toSet();
      _favoriteGamesTitles = savedFavorites.toSet();
      _toDoGamesTitles = savedToDo.toSet();
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

  void _toggleFavorite(BoardGame game) async {
    setState(() {
      if (_favoriteGamesTitles.contains(game.title)) {
        _favoriteGamesTitles.remove(game.title);
      } else {
        _favoriteGamesTitles.add(game.title);
      }
    });

    await widget.settingsBox
        .put(_favoriteGamesKey, _favoriteGamesTitles.toList());
    widget.onFeedbackGiven();

    final message = _favoriteGamesTitles.contains(game.title)
        ? '⭐ Ajouté aux favoris'
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

  void _toggleToDo(BoardGame game) async {
    setState(() {
      if (_toDoGamesTitles.contains(game.title)) {
        _toDoGamesTitles.remove(game.title);
      } else {
        _toDoGamesTitles.add(game.title);
      }
    });

    await widget.settingsBox.put(_toDoGamesKey, _toDoGamesTitles.toList());
    widget.onFeedbackGiven();

    final message = _toDoGamesTitles.contains(game.title)
        ? '✅ Ajouté à faire plus tard'
        : '⏸️ Retiré de faire plus tard';

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
    final isToDo = _toDoGamesTitles.contains(game.title);

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
            mainAxisSize: MainAxisSize.min,
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
                          label: 'Note',
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
                ],
              ),

              const SizedBox(height: 24),

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
                    onTap: () => _toggleFavorite(game),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bouton Marquer comme complété
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(
                    isToDo ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: Colors.white,
                  ),
                  label: Text(
                    isToDo ? 'À faire ✓' : 'À faire plus tard',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => _toggleToDo(game),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isToDo ? Colors.green : Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
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

              // NOUVEAU : Affichage séparé des Genres
              _buildTagDetailRow(
                'Genres',
                game.genres,
                Colors.amberAccent,
              ),

              // NOUVEAU : Affichage séparé des Mécanismes
              _buildTagDetailRow(
                'Mécanismes',
                game.mechanics,
                Colors.limeAccent,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 NOUVELLE FONCTION : Affiche la liste de tags avec le style des détails (Couleurs Rose/Beige)
  Widget _buildTagDetailRow(String title, List<String> tags, Color color) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_rounded, color: Colors.pinkAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                '$title : ',
                style: GoogleFonts.poppins(
                  color: Colors.pink.shade50, // Beige/Rose clair
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: tags
                .where((tag) => tag.isNotEmpty)
                .map(
                  (tag) => Chip(
                    label: Text(tag, style: GoogleFonts.poppins(fontSize: 12)),
                    // 🔥 Fond du chip : Beige/Rose très clair
                    backgroundColor: Colors.pink.shade50.withOpacity(0.1),
                    // 🔥 Couleur du texte : Rose plus soutenu
                    labelStyle: TextStyle(color: Colors.pink.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      // 🔥 Bordure : Rose clair
                      side: BorderSide(
                          color: Colors.pink.shade300.withOpacity(0.5)),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// VERSION COMPACTE DU DETAIL ROW (Valeur proche du label)
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label : ',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
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
