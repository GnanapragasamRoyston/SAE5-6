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
  late bool allowSurprise;
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
      allowSurprise = prefs.allowSurprise;
    });
  }

  void _savePreferences() {
    final prefs = ActivityPreferences(
      availableTime: availableTime,
      groupSize: groupSize,
      preferredDifficulty: preferredDifficulty,
      preferredCategories: selectedCategories,
      allowSurprise: allowSurprise,
    );

    if (widget.preferencesBox.isNotEmpty) {
      widget.preferencesBox.putAt(0, prefs);
    } else {
      widget.preferencesBox.add(prefs);
    }

    // Sauvegarder les 5 activités sélectionnées comme "liked" pour initialiser le profil
    for (final activityId in selectedActivityIds) {
      final existingRating = widget.activityRatingBox.values.firstWhere(
            (r) => r.activityId == activityId,
        orElse: () => ActivityRating(
            activityId: activityId, rating: 0, ratedAt: DateTime.now()),
      );

      // Si pas encore d'évaluation, créer une avec rating de 5 (top like)
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

  /// Charge les activités suggérées basées sur les catégories sélectionnées
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

    // Mélanger et prendre les 20 premières
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
            // ✅ HEADER ARCADE
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

            // ✅ CONTENU
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TEMPS DISPONIBLE ---
                    _buildSectionTitle(Icons.access_time, "TEMPS DISPONIBLE"),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121b3a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF3cf2ff), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3cf2ff).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "$availableTime MIN",
                            style: GoogleFonts.pressStart2p(
                              fontSize: 28,
                              color: const Color(0xFF3cf2ff),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFF3cf2ff),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFFff4b81),
                              overlayColor:
                              const Color(0xFFff4b81).withOpacity(0.3),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 20),
                            ),
                            child: Slider(
                              value: availableTime.toDouble(),
                              min: 15,
                              max: 360,
                              divisions: 15,
                              onChanged: (value) {
                                setState(() {
                                  availableTime = value.toInt();
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "15 MIN",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                "360 MIN",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- DIFFICULTÉ PRÉFÉRÉE ---
                    _buildSectionTitle(Icons.trending_up, "DIFFICULTÉ"),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121b3a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFb67dff), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFb67dff).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "${preferredDifficulty.toStringAsFixed(1)} / 5",
                            style: GoogleFonts.pressStart2p(
                              fontSize: 28,
                              color: const Color(0xFFb67dff),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFFb67dff),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFFff4b81),
                              overlayColor:
                              const Color(0xFFff4b81).withOpacity(0.3),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 20),
                            ),
                            child: Slider(
                              value: preferredDifficulty,
                              min: 0,
                              max: 5,
                              divisions: 10,
                              onChanged: (value) {
                                setState(() {
                                  preferredDifficulty = value;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "FACILE",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                "DIFFICILE",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- NOMBRE DE PERSONNES ---
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
                                onTap: () {
                                  setState(() {
                                    groupSize = i;
                                  });
                                },
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: groupSize == i
                                        ? const LinearGradient(
                                      colors: [
                                        Color(0xFFff4b81),
                                        Color(0xFFff9f4b)
                                      ],
                                    )
                                        : null,
                                    color: groupSize != i
                                        ? const Color(0xFF121b3a)
                                        : null,
                                    border: Border.all(
                                      color: groupSize == i
                                          ? const Color(0xFFff4b81)
                                          : const Color(0xFF3cf2ff)
                                          .withOpacity(0.5),
                                      width: 3,
                                    ),
                                    boxShadow: groupSize == i
                                        ? [
                                      BoxShadow(
                                        color: const Color(0xFFff4b81)
                                            .withOpacity(0.5),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$i',
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- CATÉGORIES PRÉFÉRÉES ---
                    _buildSectionTitle(Icons.category, "CATÉGORIES"),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ActivityPreferences.availableCategories
                          .map((category) {
                        final isSelected = selectedCategories.contains(category);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedCategories.remove(category);
                              } else {
                                selectedCategories.add(category);
                              }
                            });
                            _loadSuggestedActivities();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFF00ff85),
                                  Color(0xFF00c2ff)
                                ],
                              )
                                  : null,
                              color: isSelected
                                  ? null
                                  : const Color(0xFF121b3a),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00ff85)
                                    : const Color(0xFF3cf2ff).withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFF00ff85)
                                      .withOpacity(0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                                  : null,
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // --- SÉLECTION DES ACTIVITÉS ---
                    if (suggestedActivities.isNotEmpty) ...[
                      _buildSectionTitle(Icons.star, "SÉLECTIONNEZ 5 ACTIVITÉS"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121b3a),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFffa940), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFFffa940), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'SÉLECTIONNÉES: ${selectedActivityIds.length}/5',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 10,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: suggestedActivities.length,
                        itemBuilder: (context, index) {
                          final activity = suggestedActivities[index];
                          final isSelected =
                          selectedActivityIds.contains(activity.id);
                          final canSelect =
                              !isSelected && selectedActivityIds.length >= 5;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00ff85).withOpacity(0.2)
                                  : const Color(0xFF121b3a),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00ff85)
                                    : const Color(0xFF3cf2ff).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: canSelect
                                  ? null
                                  : (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedActivityIds.add(activity.id);
                                  } else {
                                    selectedActivityIds
                                        .remove(activity.id);
                                  }
                                });
                              },
                              title: Text(
                                activity.title,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                activity.category,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              enabled: !canSelect,
                              activeColor: const Color(0xFF00ff85),
                              checkColor: Colors.black87,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- SURPRISE ---
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          allowSurprise = !allowSurprise;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121b3a),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: allowSurprise
                                ? const Color(0xFF00ff85)
                                : const Color(0xFF3cf2ff).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: allowSurprise
                              ? [
                            BoxShadow(
                              color: const Color(0xFF00ff85)
                                  .withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: allowSurprise
                                    ? const Color(0xFF00ff85)
                                    : Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                allowSurprise
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: allowSurprise
                                    ? Colors.black87
                                    : Colors.white54,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AUTORISER LES SURPRISES',
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: 10,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Proposer des activités hors de ma zone',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- MESSAGE D'AVERTISSEMENT ---
                    if (selectedActivityIds.isEmpty &&
                        suggestedActivities.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFff9f4b).withOpacity(0.2),
                          border: Border.all(
                              color: const Color(0xFFff9f4b), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Color(0xFFff9f4b), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Veuillez sélectionner au moins 1 activité',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // --- BOUTON VALIDER ---
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: selectedActivityIds.isEmpty
                            ? null
                            : const LinearGradient(
                          colors: [Color(0xFFff0080), Color(0xFFff6600)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        color: selectedActivityIds.isEmpty
                            ? Colors.grey.shade700
                            : null,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: selectedActivityIds.isEmpty
                            ? null
                            : [
                          BoxShadow(
                            color: const Color(0xFFff0080)
                                .withOpacity(0.6),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: selectedActivityIds.isEmpty
                              ? null
                              : _savePreferences,
                          child: Center(
                            child: Text(
                              "VALIDER",
                              style: GoogleFonts.pressStart2p(
                                fontSize: 16,
                                color: Colors.white,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
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
}
