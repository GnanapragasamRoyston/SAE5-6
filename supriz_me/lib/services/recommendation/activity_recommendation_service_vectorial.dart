import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';
import '../../models/activity.dart';
import '../../models/activity_rating.dart';
import '../../models/activity_preferences.dart';
import '../../models/activity_vector.dart';
import '../../models/performance_metrics.dart';

/// Service de recommandation vectoriel avec metrics de performance
///
/// **Architecture** :
/// 1. Représentation vectorielle : chaque activité = vecteur 9D
/// 2. Profil utilisateur : moyenne pondérée des vecteurs aimés
/// 3. Calcul similarité : distance cosinus (0-1)
/// 4. Adaptation : poids dynamiques sur chaque dimension
/// 5. Tracking : métriques performance + historique
///
/// **Avantages de cette approche** :
/// - Scalable : facile d'ajouter dimensions
/// - Justifiable : poids visibles et traçables
/// - Efficace : O(n) pour n activités
/// - Adaptable : poids évoluent avec feedback utilisateur
class ActivityRecommendationServiceVectorial {
  final Box<Activity> activityBox;
  final Box<ActivityRating> ratingBox;
  final Box<PerformanceMetrics> metricsBox;

  ActivityPreferences userPreferences =
      ActivityPreferences.defaultPreferences();

  // Poids adaptatifs : évoluent avec l'utilisation
  Map<String, double> _adaptiveWeights = {
    'categoryWeight': 1.0,
    'durationWeight': 1.0,
    'groupWeight': 1.0,
    'difficultyWeight': 1.0,
  };

  // Stats d'utilisation pour adaptation
  int _totalLikes = 0;
  int _totalDislikes = 0;
  final Map<String, int> _categoryLikes = {};
  final Map<String, int> _categoryDislikes = {};

  ActivityRecommendationServiceVectorial({
    required this.activityBox,
    required this.ratingBox,
    required this.metricsBox,
  });

  /// Initialise le service et charge les poids persistés
  void initializePreferences(ActivityPreferences prefs) {
    userPreferences = prefs;
    _loadAdaptiveWeights();
    _loadUsageStats();
  }

  /// Charge les poids adaptatifs depuis les préférences
  void _loadAdaptiveWeights() {
    // Récupérer poids sauvegardés ou utiliser défaults
    _adaptiveWeights = {
      'categoryWeight': userPreferences.categoryWeight ?? 1.0,
      'durationWeight': userPreferences.durationWeight ?? 1.0,
      'groupWeight': userPreferences.groupWeight ?? 1.0,
      'difficultyWeight': userPreferences.difficultyWeight ?? 1.0,
    };
  }

  /// Charge les stats d'utilisation pour visualisation
  void _loadUsageStats() {
    for (final rating in ratingBox.values) {
      if (rating.rating >= 3) {
        _totalLikes++;
        final activity = activityBox.get(rating.activityId);
        if (activity != null) {
          _categoryLikes[activity.category] =
              (_categoryLikes[activity.category] ?? 0) + 1;
        }
      } else {
        _totalDislikes++;
        final activity = activityBox.get(rating.activityId);
        if (activity != null) {
          _categoryDislikes[activity.category] =
              (_categoryDislikes[activity.category] ?? 0) + 1;
        }
      }
    }
  }

  /// Retourne les recommandations basées sur la similarité vectorielle
  /// Avec tracking complet des métriques
  Future<List<Activity>> getRecommendations({int limit = 3}) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Étape 1 : Récupérer les activités aimées pour créer le profil utilisateur
      final likedActivities = _getLikedActivities();

      if (likedActivities.isEmpty) {
        // Si aucune activité aimée, retourner les meilleures activités
        return _getTopActivitiesByDifficulty(limit);
      }

      // Étape 2 : Créer le vecteur profil utilisateur
      final userProfileVector = _createUserProfileVector(likedActivities);

      // Étape 3 : Calculer la similarité pour chaque activité
      final allActivities = activityBox.values.toList();
      final ratedIds = ratingBox.values.map((r) => r.activityId).toSet();

      final scored = <(Activity, double)>[];

      for (final activity in allActivities) {
        // Ignorer les activités déjà notées
        if (ratedIds.contains(activity.id)) continue;

        // Calculer le vecteur de l'activité avec poids adaptatifs
        final activityVector = activity.toNormalizedVector(
          categoryWeight: _adaptiveWeights['categoryWeight']!,
          durationWeight: _adaptiveWeights['durationWeight']!,
          groupWeight: _adaptiveWeights['groupWeight']!,
          difficultyWeight: _adaptiveWeights['difficultyWeight']!,
        );

        // Calcul similarité cosinus
        final similarity = VectorUtils.cosineSimilarity(
          userProfileVector,
          activityVector,
        );

        scored.add((activity, similarity));
      }

      stopwatch.stop();

      // Étape 4 : Sauvegarder les métriques
      final metrics = PerformanceMetrics.fromRaw(
        tempsCalculMs: stopwatch.elapsedMilliseconds,
        memoireUsageBytes: _estimateMemoryUsage(allActivities.length),
        nbRecommandations: limit,
        nbActiviteesTraitees: allActivities.length,
        poidsAdaptatifs: _adaptiveWeights,
        raison: 'Recommandation vectorielle',
      );

      await metricsBox.add(metrics);

      // Étape 5 : Retourner les top N activités
      scored.sort((a, b) => b.$2.compareTo(a.$2));
      return scored.take(limit).map((s) => s.$1).toList();
    } catch (e) {
      stopwatch.stop();
      // Erreur silencieuse en production
      return [];
    }
  }

  /// Crée le vecteur profil utilisateur à partir des activités aimées
  List<double> _createUserProfileVector(List<Activity> likedActivities) {
    // Créer les vecteurs de chaque activité aimée
    final vectors = likedActivities
        .map(
          (a) => a.toNormalizedVector(
            categoryWeight: _adaptiveWeights['categoryWeight']!,
            durationWeight: _adaptiveWeights['durationWeight']!,
            groupWeight: _adaptiveWeights['groupWeight']!,
            difficultyWeight: _adaptiveWeights['difficultyWeight']!,
          ),
        )
        .toList();

    // Retourner la moyenne (centroïde du profil)
    return VectorUtils.averageVector(vectors);
  }

  /// Récupère les activités likées par l'utilisateur
  List<Activity> _getLikedActivities() {
    final liked = <Activity>[];
    for (final rating in ratingBox.values) {
      if (rating.rating >= 3) {
        final activity = activityBox.get(rating.activityId);
        if (activity != null) {
          liked.add(activity);
        }
      }
    }
    return liked;
  }

  /// Retourne les activités les meilleures par difficulté croissante
  List<Activity> _getTopActivitiesByDifficulty(int limit) {
    final all = activityBox.values.toList();
    all.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    return all.take(limit).toList();
  }

  /// Estime l'utilisation mémoire en bytes
  int _estimateMemoryUsage(int nbActivities) {
    // Vecteur : 9 doubles = 72 bytes par activité
    // + vecteur profil : 72 bytes
    // + calculs intermédiaires : ~20% supplémentaire
    return (nbActivities * 72 * 1.2).toInt() + 72;
  }

  /// Note une activité et adapte les poids en conséquence
  Future<void> rateActivity(String activityId, int rating) async {
    final activity = activityBox.get(activityId);
    if (activity == null) return;

    // Créer la note
    final newRating = ActivityRating(
      activityId: activityId,
      rating: rating,
      ratedAt: DateTime.now(),
    );

    await ratingBox.add(newRating);

    // Adapter les poids si c'est un like/dislike fort
    if (rating >= 3) {
      // Like détecté : augmenter les poids des caractéristiques similaires
      _adaptiveWeights['categoryWeight'] =
          (_adaptiveWeights['categoryWeight']! + 0.05).clamp(0.5, 2.0);
      _categoryLikes[activity.category] =
          (_categoryLikes[activity.category] ?? 0) + 1;
      _totalLikes++;
    } else {
      // Dislike détecté : diminuer les poids
      _adaptiveWeights['categoryWeight'] =
          (_adaptiveWeights['categoryWeight']! - 0.03).clamp(0.5, 2.0);
      _categoryDislikes[activity.category] =
          (_categoryDislikes[activity.category] ?? 0) + 1;
      _totalDislikes++;
    }

    // Sauvegarder les poids adaptés
    await _saveAdaptiveWeights();
  }

  /// Sauvegarde les poids adaptatifs dans les préférences
  Future<void> _saveAdaptiveWeights() async {
    // Mettre à jour les préférences
    userPreferences.categoryWeight = _adaptiveWeights['categoryWeight'];
    userPreferences.durationWeight = _adaptiveWeights['durationWeight'];
    userPreferences.groupWeight = _adaptiveWeights['groupWeight'];
    userPreferences.difficultyWeight = _adaptiveWeights['difficultyWeight'];
  }

  /// Retourne le profil de poids actuels (pour visualisation)
  Map<String, double> getAdaptiveWeights() => _adaptiveWeights;

  /// Retourne les stats d'utilisation
  Map<String, dynamic> getUsageStats() {
    return {
      'totalLikes': _totalLikes,
      'totalDislikes': _totalDislikes,
      'categoryLikes': _categoryLikes,
      'categoryDislikes': _categoryDislikes,
      'ratioLike': _totalLikes / max(1, _totalLikes + _totalDislikes) * 100,
    };
  }

  /// Retourne l'historique des métriques
  List<PerformanceMetrics> getMetricsHistory({int limit = 50}) {
    return metricsBox.values.toList().reversed.take(limit).toList();
  }

  /// Retourne les stats moyennes
  Map<String, dynamic> getAverageMetrics({int lastNMetrics = 10}) {
    final recent = metricsBox.values
        .toList()
        .reversed
        .take(lastNMetrics)
        .toList();

    if (recent.isEmpty) {
      return {'avgTime': 0, 'avgCPU': 0.0, 'totalBatteryDrain': 0.0};
    }

    return {
      'avgTime': PerformanceMetrics.calculateAverageTime(recent),
      'avgCPU': PerformanceMetrics.calculateAverageCPU(recent),
      'totalBatteryDrain': PerformanceMetrics.calculateTotalBatteryDrain(
        recent,
      ),
    };
  }

  /// Récupère une activité surprise intelligente (OPPOSÉE à tes préférences)
  /// Pour sortir de ta zone de confort
  Future<Activity?> getSurpriseActivity() async {
    if (userPreferences.allowSurprise == false) return null;

    final stopwatch = Stopwatch()..start();

    try {
      final likedActivities = _getLikedActivities();
      final allActivities = activityBox.values.toList();
      final ratedIds = ratingBox.values.map((r) => r.activityId).toSet();

      if (allActivities.isEmpty) return null;

      // Si pas assez d'expérience, retourner aléatoire
      if (likedActivities.isEmpty) {
        final unrated = allActivities
            .where((a) => !ratedIds.contains(a.id))
            .toList();
        if (unrated.isEmpty) return null;
        unrated.shuffle();
        return unrated.first;
      }

      // Créer le vecteur profil utilisateur
      final userProfileVector = _createUserProfileVector(likedActivities);

      // Calculer la DISTANCE (inverse de similarité) pour chaque activité
      final scored = <(Activity, double)>[];

      for (final activity in allActivities) {
        // Ignorer les activités déjà notées
        if (ratedIds.contains(activity.id)) continue;

        // Calculer le vecteur de l'activité
        final activityVector = activity.toNormalizedVector(
          categoryWeight: _adaptiveWeights['categoryWeight']!,
          durationWeight: _adaptiveWeights['durationWeight']!,
          groupWeight: _adaptiveWeights['groupWeight']!,
          difficultyWeight: _adaptiveWeights['difficultyWeight']!,
        );

        // Calcul de la DISTANCE (1 - similarité = différence maximale)
        final similarity = VectorUtils.cosineSimilarity(
          userProfileVector,
          activityVector,
        );
        final distance =
            1.0 - similarity; // INVERSE : plus grand = plus différent

        scored.add((activity, distance));
      }

      stopwatch.stop();

      // Sauvegarder les métriques
      final metrics = PerformanceMetrics.fromRaw(
        tempsCalculMs: stopwatch.elapsedMilliseconds,
        memoireUsageBytes: _estimateMemoryUsage(allActivities.length),
        nbRecommandations: 1,
        nbActiviteesTraitees: allActivities.length,
        poidsAdaptatifs: _adaptiveWeights,
        raison: 'Surprise - Sortir de sa zone',
      );

      await metricsBox.add(metrics);

      // Retourner l'activité la plus différente
      if (scored.isEmpty) return null;
      scored.sort((a, b) => b.$2.compareTo(a.$2)); // Tri décroissant
      return scored.first.$1;
    } catch (e) {
      stopwatch.stop();
      return null;
    }
  }

  /// Récupère toutes les activités
  List<Activity> getAllActivities() {
    return activityBox.values.toList();
  }
}
