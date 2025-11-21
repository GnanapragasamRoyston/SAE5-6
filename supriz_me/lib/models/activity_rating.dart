import 'package:hive/hive.dart';

part 'activity_rating.g.dart';

@HiveType(typeId: 4)
class ActivityRating {
  @HiveField(0)
  final String activityId;

  @HiveField(1)
  final int rating; // 1 = dislike, 2 = neutral, 3 = like

  @HiveField(2)
  final DateTime ratedAt;

  ActivityRating({
    required this.activityId,
    required this.rating,
    required this.ratedAt,
  });
}
