import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../models/activity_preferences.dart';
import '../models/activity.dart';
import '../models/activity_rating.dart';

class ActivityPreferencesPage extends StatefulWidget {
  final Box<ActivityPreferences> preferencesBox;
  final Box<Activity> activityBox;
  final Box<ActivityRating> activityRatingBox;

  const ActivityPreferencesPage({
    super.key,
    required this.preferencesBox,
    required this.activityBox,
    required this.activityRatingBox,
  });

  @override
  State<ActivityPreferencesPage> createState() =>
      _ActivityPreferencesPageState();
}

class _ActivityPreferencesPageState extends State<ActivityPreferencesPage> {
  late int availableTime;
  late int groupSize;
  late double preferredDifficulty;
  late List<String> selectedCategories;
  final Set<String> selectedActivityIds = {};
  late List<Activity> suggestedActivities;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    suggestedActivities = [];
  }

  void _loadPreferences() {
    final prefs = widget.preferencesBox.isNotEmpty
        ? widget.preferencesBox.getAt(0) ??
        ActivityPreferences.defaultPreferences()
        : ActivityPreferences.defaultPreferences();

    setState(() {
      availableTime = prefs.availableTime;
      groupSize = prefs.groupSize;
      preferredDifficulty = prefs.preferredDifficulty;
      selectedCategories = List.from(prefs.preferredCategories);
    });
  }

  void _savePreferences() {
    final prefs = ActivityPreferences(
      availableTime: availableTime,
      groupSize: groupSize,
      preferredDifficulty: preferredDifficulty,
      preferredCategories: selectedCategories,
      allowSurprise: false, // Valeur désactivée par défaut
    );

    if (widget.preferencesBox.isNotEmpty) {
      widget.preferencesBox.putAt(0, prefs);
    } else {
      widget.preferencesBox.add(prefs);
    }

    for (final activityId in selectedActivityIds) {
      final existingRating = widget.activityRatingBox.values.firstWhere(
            (r) => r.activityId == activityId,
        orElse: () => ActivityRating(
            activityId: activityId, rating: 0, ratedAt: DateTime.now()),
      );

      if (existingRating.rating == 0) {
        final newRating = ActivityRating(
          activityId: activityId,
          rating: 5,
          ratedAt: DateTime.now(),
        );
        widget.activityRatingBox.add(newRating);
      }
    }

    Navigator.pop(context);
  }

  void _loadSuggestedActivities() {
    if (selectedCategories.isEmpty) {
      setState(() {
        suggestedActivities = [];
        selectedActivityIds.clear();
      });
      return;
    }

    final activities = widget.activityBox.values
        .where((a) => selectedCategories.contains(a.category))
        .toList();

    activities.shuffle();
    setState(() {
      suggestedActivities = activities.take(20).toList();
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
              Color(0xFF101738),
              Color(0xFF050814),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 120,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff4b81), Color(0xFFff9f4b)],
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "PRÉFÉRENCES ACTIVITÉS",
                    style: GoogleFonts.pressStart2p(
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(Icons.access_time, "TEMPS DISPONIBLE"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121b3a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF3cf2ff), width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "$availableTime MIN",
                            style: GoogleFonts.pressStart2p(
                              fontSize: 28,
                              color: const Color(0xFF3cf2ff),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: availableTime.toDouble(),
                            min: 15,
                            max: 360,
                            divisions: 15,
                            onChanged: (value) => setState(() => availableTime = value.toInt()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(Icons.trending_up, "DIFFICULTÉ"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121b3a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFb67dff), width: 2),
                      ),
                      child: Column(
                        children: [
                          Text("${preferredDifficulty.toStringAsFixed(1)} / 5",
                            style: GoogleFonts.pressStart2p(fontSize: 28, color: const Color(0xFFb67dff))),
                          Slider(
                            value: preferredDifficulty,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            onChanged: (value) => setState(() => preferredDifficulty = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(Icons.group, "NOMBRE DE PERSONNES"),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 1; i <= 5; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => setState(() => groupSize = i),
                                child: Container(
                                  width: 70, height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: groupSize == i ? null : const Color(0xFF121b3a),
                                    gradient: groupSize == i ? const LinearGradient(colors: [Color(0xFFff4b81), Color(0xFFff9f4b)]) : null,
                                    border: Border.all(color: groupSize == i ? const Color(0xFFff4b81) : const Color(0xFF3cf2ff).withOpacity(0.5), width: 3),
                                  ),
                                  child: Center(child: Text('$i', style: GoogleFonts.pressStart2p(fontSize: 24, color: Colors.white))),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle(Icons.category, "CATÉGORIES"),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: ActivityPreferences.availableCategories.map((category) {
                        final isSelected = selectedCategories.contains(category);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isSelected ? selectedCategories.remove(category) : selectedCategories.add(category);
                            });
                            _loadSuggestedActivities();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected ? const LinearGradient(colors: [Color(0xFF00ff85), Color(0xFF00c2ff)]) : null,
                              color: isSelected ? null : const Color(0xFF121b3a),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? const Color(0xFF00ff85) : const Color(0xFF3cf2ff).withOpacity(0.5), width: 2),
                            ),
                            child: Text(category.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    if (suggestedActivities.isNotEmpty) ...[
                      _buildSectionTitle(Icons.star, "SÉLECTIONNEZ 5 ACTIVITÉS"),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: suggestedActivities.length,
                        itemBuilder: (context, index) {
                          final activity = suggestedActivities[index];
                          final isSelected = selectedActivityIds.contains(activity.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true && selectedActivityIds.length < 5) {
                                  selectedActivityIds.add(activity.id);
                                } else {
                                  selectedActivityIds.remove(activity.id);
                                }
                              });
                            },
                            title: Text(activity.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                            subtitle: Text(activity.category, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (selectedActivityIds.isEmpty && suggestedActivities.isNotEmpty)
                      _buildWarningMessage(),
                    const SizedBox(height: 16),
                    _buildSubmitButton(),
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

  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFff9f4b).withOpacity(0.2),
        border: Border.all(color: const Color(0xFFff9f4b), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('Veuillez sélectionner au moins 1 activité', style: GoogleFonts.poppins(color: Colors.white)),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        gradient: selectedActivityIds.isEmpty ? null : const LinearGradient(colors: [Color(0xFFff0080), Color(0xFFff6600)]),
        color: selectedActivityIds.isEmpty ? Colors.grey.shade700 : null,
        borderRadius: BorderRadius.circular(30),
      ),
      child: InkWell(
        onTap: selectedActivityIds.isEmpty ? null : _savePreferences,
        child: Center(child: Text("VALIDER", style: GoogleFonts.pressStart2p(fontSize: 16, color: Colors.white))),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121b3a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3cf2ff), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.pressStart2p(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }
}