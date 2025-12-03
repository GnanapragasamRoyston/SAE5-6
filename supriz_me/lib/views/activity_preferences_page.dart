import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../models/activity_preferences.dart';

class ActivityPreferencesPage extends StatefulWidget {
  final Box<ActivityPreferences> preferencesBox;

  const ActivityPreferencesPage({super.key, required this.preferencesBox});

  @override
  State<ActivityPreferencesPage> createState() =>
      _ActivityPreferencesPageState();
}

class _ActivityPreferencesPageState extends State<ActivityPreferencesPage> {
  late int availableTime;
  late int groupSize;
  late List<String> selectedCategories;
  late bool allowSurprise;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final prefs = widget.preferencesBox.isNotEmpty
        ? widget.preferencesBox.getAt(0) ??
              ActivityPreferences.defaultPreferences()
        : ActivityPreferences.defaultPreferences();

    setState(() {
      availableTime = prefs.availableTime;
      groupSize = prefs.groupSize;
      selectedCategories = List.from(prefs.preferredCategories);
      allowSurprise = prefs.allowSurprise;
    });
  }

  void _savePreferences() {
    final prefs = ActivityPreferences(
      availableTime: availableTime,
      groupSize: groupSize,
      preferredCategories: selectedCategories,
      allowSurprise: allowSurprise,
    );

    if (widget.preferencesBox.isNotEmpty) {
      widget.preferencesBox.putAt(0, prefs);
    } else {
      widget.preferencesBox.add(prefs);
    }

    Navigator.pop(context);
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
              max: 480,
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
                for (String category in [
                  'Extérieur',
                  'Intérieur',
                  'Sport',
                  'Culture',
                  'Relaxation',
                ])
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
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),

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

            // Bouton sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
