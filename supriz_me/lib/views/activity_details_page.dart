// activity_details_page.dart

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

    final message = _currentRating.isFavorite
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

    final message = _currentRating.isDone
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
                activity.title,
                style: GoogleFonts.pressStart2p(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
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
                          '${_currentRating.rating}/5',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF00ff85),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.duration.toInt()} min',
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3cf2ff).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF3cf2ff).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            activity.category,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'SYNOPSIS',
                      style: GoogleFonts.pressStart2p(
                        color: const Color(0xFF3cf2ff),
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activity.description.isNotEmpty
                          ? activity.description
                          : 'Description non disponible.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeedbackButton(
                          icon: Icons.thumb_down_alt_rounded,
                          color: Colors.pinkAccent,
                          isActive: isDisliked,
                          onTap: () => _rateActivity(1),
                        ),
                        const SizedBox(width: 10),
                        _buildFeedbackButton(
                          icon: Icons.thumb_up_alt_rounded,
                          color: Colors.greenAccent,
                          isActive: isLiked,
                          onTap: () => _rateActivity(3),
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

                    const SizedBox(height: 30),

                    _buildDoneButton(),

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

  Widget _buildDoneButton() {
    final isDone = _currentRating.isDone;
    return Center(
      child: GestureDetector(
        onTap: _toggleDone,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDone
                  ? [
                const Color(0xFF00FF88),
                const Color(0xFF00CC66),
              ]
                  : [
                const Color(0xFF3cf2ff),
                const Color(0xFF0088ff),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isDone
                    ? const Color(0xFF00FF88)
                    : const Color(0xFF3cf2ff))
                    .withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isDone ? 'COMPLÉTÉE' : 'MARQUER COMPLÉTÉE',
                style: GoogleFonts.pressStart2p(
                  fontSize: 12,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
