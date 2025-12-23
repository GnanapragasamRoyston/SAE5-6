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
      appBar: AppBar(
        title: Text(
          'Mes Préférences',
          style: GoogleFonts.bebasNeue(fontSize: 24),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temps disponible
            Text(
              'Temps disponible',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: availableTime.toDouble(),
              min: 15,
              max: 360,
              divisions: 15,
              label: '$availableTime min',
              onChanged: (value) {
                setState(() {
                  availableTime = value.toInt();
                });
              },
            ),
            Text('$availableTime minutes'),
            const SizedBox(height: 24),

            // Difficulté préférée
            Text(
              'Difficulté préférée',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: preferredDifficulty,
              min: 0,
              max: 5,
              divisions: 10,
              label: '${preferredDifficulty.toStringAsFixed(1)}/5',
              onChanged: (value) {
                setState(() {
                  preferredDifficulty = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Facile',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600])),
                Text('${preferredDifficulty.toStringAsFixed(1)}/5',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Difficile',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 24),

            // Nombre de personnes
            Text(
              'Nombre de personnes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: groupSize == i
                                    ? Colors.blue
                                    : Colors.grey[300],
                                border: groupSize == i
                                    ? Border.all(color: Colors.blue, width: 3)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$i',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: groupSize == i
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
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
            const SizedBox(height: 24),

            // Catégories préférées
            Text(
              'Catégories préférées',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (String category in ActivityPreferences.availableCategories)
                  FilterChip(
                    label: Text(category),
                    selected: selectedCategories.contains(category),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                        }
                      });
                      _loadSuggestedActivities();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Section simple : Choix des activités
            if (suggestedActivities.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sélectionnez 5 activités',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${selectedActivityIds.length}/5',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: canSelect
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedActivityIds.add(activity.id);
                                  } else {
                                    selectedActivityIds.remove(activity.id);
                                  }
                                });
                              },
                        title: Text(activity.title),
                        subtitle: Text(activity.category),
                        enabled: !canSelect,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Allow Surprise
            CheckboxListTile(
              title: const Text('Autoriser les surprises'),
              subtitle: const Text('Proposer des activités hors de ma zone'),
              value: allowSurprise,
              onChanged: (value) {
                setState(() {
                  allowSurprise = value ?? true;
                });
              },
            ),
            const SizedBox(height: 32),

            // Message de validation
            if (selectedActivityIds.isEmpty && suggestedActivities.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Veuillez sélectionner au moins 1 activité',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Bouton sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedActivityIds.isEmpty ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedActivityIds.isEmpty ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Valider',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
