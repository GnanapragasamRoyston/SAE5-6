import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 1)
class Activity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category; // ex: "sports", "art", "outdoor"

  @HiveField(4)
  final double duration; // en minutes

  @HiveField(5)
  final int minParticipants;

  @HiveField(6)
  final int maxParticipants;

  @HiveField(7)
  final List<String> tags;

  @HiveField(8)
  final double difficulty; // 0-5

  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.minParticipants,
    required this.maxParticipants,
    required this.tags,
    required this.difficulty,
  });
}
