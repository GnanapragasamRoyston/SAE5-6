import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 3)
class UserProfile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final int age;

  @HiveField(3)
  final List<String> preferences; // genres/catégories préférées

  @HiveField(4)
  final List<String> favoriteIds; // IDs d'items aimés

  @HiveField(5)
  final List<String> viewedIds; // IDs d'items vus

  @HiveField(6)
  final int groupSize; // nb de personnes pour activités/jeux

  const UserProfile({
    required this.id,
    required this.username,
    required this.age,
    required this.preferences,
    required this.favoriteIds,
    required this.viewedIds,
    required this.groupSize,
  });
}
