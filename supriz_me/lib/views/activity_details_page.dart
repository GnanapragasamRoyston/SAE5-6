import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import '../models/activity.dart';
import '../models/activity_rating.dart';

class ActivityDetailsPage extends StatefulWidget {
  final Activity activity;
  final Box<ActivityRating> activityRatingBox;
  final VoidCallback onFeedbackGiven;

  const ActivityDetailsPage({
    super.key,
    required this.activity,
    required this.activityRatingBox,
    required this.onFeedbackGiven,
  });

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  late ActivityRating _currentRating;

  @override
  void initState() {
    super.initState();
    _loadActivityRating();
  }

  void _loadActivityRating() {
    final existingRating = widget.activityRatingBox.values.firstWhereOrNull(
      (r) => r.activityId == widget.activity.id,
    );

    setState(() {
      _currentRating = existingRating ??
          ActivityRating(
            activityId: widget.activity.id,
            rating: 2,
            ratedAt: DateTime.now(),
            isDone: false,
            isFavorite: false,
          );
    });
  }

  void _rateActivity(int rating) async {
    final updatedRating = _currentRating.copyWith(
      rating: rating,
      ratedAt: DateTime.now(),
    );

    // Sauvegarder ou mettre à jour
    final existingIndex = widget.activityRatingBox.values
        .toList()
        .indexWhere((r) => r.activityId == widget.activity.id);

    if (existingIndex != -1) {
      widget.activityRatingBox.putAt(existingIndex, updatedRating);
    } else {
      widget.activityRatingBox.add(updatedRating);
    }

    setState(() {
      _currentRating = updatedRating;
    });

    final message = rating == 3
        ? '✓ Comme enregistré'
        : rating == 1
            ? '✗ Pas comme enregistré'
            : '📌 Note neutre';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey.shade700,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }

    widget.onFeedbackGiven();
  }

  void _toggleFavorite() async {
    final updatedRating = _currentRating.copyWith(
      isFavorite: !_currentRating.isFavorite,
    );

    final existingIndex = widget.activityRatingBox.values
        .toList()
        .indexWhere((r) => r.activityId == widget.activity.id);

    if (existingIndex != -1) {
      widget.activityRatingBox.putAt(existingIndex, updatedRating);
    } else {
      widget.activityRatingBox.add(updatedRating);
    }

    setState(() {
      _currentRating = updatedRating;
    });

    final message = updatedRating.isFavorite
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

    widget.onFeedbackGiven();
  }

  void _toggleDone() async {
    final updatedRating = _currentRating.copyWith(
      isDone: !_currentRating.isDone,
    );

    final existingIndex = widget.activityRatingBox.values
        .toList()
        .indexWhere((r) => r.activityId == widget.activity.id);

    if (existingIndex != -1) {
      widget.activityRatingBox.putAt(existingIndex, updatedRating);
    } else {
      widget.activityRatingBox.add(updatedRating);
    }

    setState(() {
      _currentRating = updatedRating;
    });

    final message = updatedRating.isDone
        ? '✅ Activité complétée !'
        : '⏸️ Marquer comme non complétée';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey.shade700,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }

    widget.onFeedbackGiven();
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final isLiked = _currentRating.rating == 3;
    final isDisliked = _currentRating.rating == 1;
    final isFavorite = _currentRating.isFavorite;
    final isDone = _currentRating.isDone;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(activity.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.purple,
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
                          activity.title,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 36,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.timer,
                          label: 'Durée',
                          value: '${activity.duration.toInt()} minutes',
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.category,
                          label: 'Catégorie',
                          value: activity.category,
                          color: Colors.cyanAccent,
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
                        onTap: () => _rateActivity(3),
                      ),
                      const SizedBox(height: 10),
                      _buildFeedbackButton(
                        icon: Icons.thumb_down_alt_rounded,
                        color: Colors.pinkAccent,
                        isActive: isDisliked,
                        onTap: () => _rateActivity(1),
                      ),
                      const SizedBox(height: 10),
                      _buildFeedbackButton(
                        icon: Icons.favorite,
                        color: Colors.redAccent,
                        isActive: isFavorite,
                        onTap: _toggleFavorite,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white30),
              const SizedBox(height: 16),

              // Description
              if (activity.description.isNotEmpty) ...[
                Text(
                  'Description',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    activity.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bouton Marquer comme complété
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: Colors.white,
                  ),
                  label: Text(
                    isDone ? 'Complétée ✓' : 'Marquer comme complétée',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _toggleDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDone ? Colors.green : Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

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
