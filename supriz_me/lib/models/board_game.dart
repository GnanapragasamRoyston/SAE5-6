import 'package:hive/hive.dart';

part 'board_game.g.dart';

@HiveType(typeId: 2)
class BoardGame {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int minPlayers;

  @HiveField(4)
  final int maxPlayers;

  @HiveField(5)
  final double avgDuration; // en minutes

  @HiveField(6)
  final double complexity; // 0-5

  @HiveField(7)
  final double rating;

  @HiveField(8)
  final List<String> tags;

  const BoardGame({
    required this.id,
    required this.title,
    required this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.avgDuration,
    required this.complexity,
    required this.rating,
    required this.tags,
  });
}
