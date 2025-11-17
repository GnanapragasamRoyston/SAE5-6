import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final Box<UserProfile> _userBox;

  UserProfileService(this._userBox);

  /// Crée ou met à jour un profil utilisateur
  Future<void> saveUserProfile(UserProfile profile) async {
    await _userBox.put(profile.id, profile);
  }

  /// Récupère le profil utilisateur actif
  UserProfile? getUserProfile(String userId) {
    return _userBox.get(userId);
  }

  /// Met à jour les préférences d'un utilisateur
  Future<void> updatePreferences(String userId, List<String> preferences) async {
    final user = _userBox.get(userId);
    if (user != null) {
      final updated = UserProfile(
        id: user.id,
        username: user.username,
        age: user.age,
        preferences: preferences,
        favoriteIds: user.favoriteIds,
        viewedIds: user.viewedIds,
        groupSize: user.groupSize,
      );
      await _userBox.put(userId, updated);
    }
  }

  /// Ajoute un item aux favoris
  Future<void> addFavorite(String userId, String itemId) async {
    final user = _userBox.get(userId);
    if (user != null) {
      final favorites = user.favoriteIds..add(itemId);
      final updated = UserProfile(
        id: user.id,
        username: user.username,
        age: user.age,
        preferences: user.preferences,
        favoriteIds: favorites,
        viewedIds: user.viewedIds,
        groupSize: user.groupSize,
      );
      await _userBox.put(userId, updated);
    }
  }

  /// Ajoute un item aux vus
  Future<void> addViewed(String userId, String itemId) async {
    final user = _userBox.get(userId);
    if (user != null) {
      final viewed = user.viewedIds..add(itemId);
      final updated = UserProfile(
        id: user.id,
        username: user.username,
        age: user.age,
        preferences: user.preferences,
        favoriteIds: user.favoriteIds,
        viewedIds: viewed,
        groupSize: user.groupSize,
      );
      await _userBox.put(userId, updated);
    }
  }
}
