import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 1)
enum ActivityCategory {
  @HiveField(0)
  calme,
  @HiveField(1)
  jeu,
  @HiveField(2)
  sport,
  @HiveField(3)
  social,
  @HiveField(4)
  creatif,
  @HiveField(5)
  detente,
  @HiveField(6)
  outdoor,
}
@HiveType(typeId: 6)
class Activity {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final ActivityCategory category; 

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
