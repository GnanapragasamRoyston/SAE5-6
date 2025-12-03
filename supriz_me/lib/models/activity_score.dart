import 'activity.dart';

/// Représente une activité avec son score de recommandation
class ActivityScore {
  final Activity activity;
  final double score;

  ActivityScore({
    required this.activity,
    required this.score,
  });
}
