import 'package:hive/hive.dart';
import '../models/activity.dart';

class ActivityService {
  final Box<Activity> _activityBox;

  ActivityService(this._activityBox);

  /// Ajoute une activité à la base de données
  Future<void> addActivity(Activity activity) async {
    await _activityBox.put(activity.id, activity);
  }

  /// Récupère toutes les activités
  List<Activity> getAllActivities() {
    return _activityBox.values.toList();
  }

  /// Récupère une activité par ID
  Activity? getActivityById(String id) {
    return _activityBox.get(id);
  }

  /// Supprime une activité
  Future<void> deleteActivity(String id) async {
    await _activityBox.delete(id);
  }

  /// Récupère les activités par catégorie
  List<Activity> getActivitiesByCategory(String category) {
    return _activityBox.values
        .where((activity) => activity.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Récupère les activités adaptées à un nombre de participants
  List<Activity> getActivitiesByGroupSize(int groupSize) {
    return _activityBox.values
        .where((activity) => activity.minParticipants <= groupSize && activity.maxParticipants >= groupSize)
        .toList();
  }
}
