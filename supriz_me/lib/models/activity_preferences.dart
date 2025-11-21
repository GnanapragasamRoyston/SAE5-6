import 'package:hive/hive.dart';

part 'activity_preferences.g.dart';

@HiveType(typeId: 5)
class ActivityPreferences {
  @HiveField(0)
  final int availableTime; // en minutes (ex: 60, 120, 180)

  @HiveField(1)
  final int groupSize; // nombre de personnes

  @HiveField(2)
  final List<String> preferredCategories; // catégories aimées

  @HiveField(3)
  final bool allowSurprise; // permettre les recommandations hors zone

  // Poids adaptatifs pour le système vectoriel
  // Évoluent avec les likes/dislikes
  @HiveField(4)
  double? categoryWeight; // poids des catégories aimées

  @HiveField(5)
  double? durationWeight; // poids de la durée préférée

  @HiveField(6)
  double? groupWeight; // poids de la taille groupe

  @HiveField(7)
  double? difficultyWeight; // poids de la difficulté

  ActivityPreferences({
    required this.availableTime,
    required this.groupSize,
    required this.preferredCategories,
    required this.allowSurprise,
    this.categoryWeight = 1.0,
    this.durationWeight = 1.0,
    this.groupWeight = 1.0,
    this.difficultyWeight = 1.0,
  });

  // Constructeur par défaut
  factory ActivityPreferences.defaultPreferences() {
    return ActivityPreferences(
      availableTime: 120,
      groupSize: 1,
      preferredCategories: [],
      allowSurprise: true,
      categoryWeight: 1.0,
      durationWeight: 1.0,
      groupWeight: 1.0,
      difficultyWeight: 1.0,
    );
  }
}
