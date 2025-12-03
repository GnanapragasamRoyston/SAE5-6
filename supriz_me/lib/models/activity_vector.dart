import 'dart:math';
import 'activity.dart';

/// Extension pour convertir une Activity en vecteur normalisé
///
/// **Représentation vectorielle** :
/// Chaque activité est représentée comme un vecteur dans un espace 4D :
/// - dimension 0 : catégorie (encodée numériquement)
/// - dimension 1 : durée (normalisée)
/// - dimension 2 : taille groupe (normalisée)
/// - dimension 3 : difficulté (normalisée)
///
/// Cette représentation vectorielle permet :
/// 1. Calcul de similarité via distance cosinus
/// 2. Adaptabilité : poids peuvent être appliqués à chaque dimension
/// 3. Scalabilité : facile d'ajouter d'autres dimensions
extension ActivityVector on Activity {
  /// Catégories d'activités mappées à des indices numériques
  static const Map<String, int> categoryIndex = {
    'Sport': 0,
    'jeu': 1,
    'Social': 2,
    'Créatif': 3,
    'Relaxation': 4,
    'Aventure': 5,
  };

  /// Retourne le vecteur normalisé de l'activité
  /// Normalization : chaque dimension entre 0 et 1
  List<double> toNormalizedVector({
    // Poids adaptatifs (par défaut 1.0)
    double categoryWeight = 1.0,
    double durationWeight = 1.0,
    double groupWeight = 1.0,
    double difficultyWeight = 1.0,
  }) {
    // Dimension 0 : Catégorie (one-hot encoded sur 6 dimensions)
    final categoryIdx = categoryIndex[category] ?? 0;
    final categoryVector = List<double>.filled(6, 0.0);
    categoryVector[categoryIdx] = categoryWeight;

    // Dimension 1 : Durée normalisée (0-240 min = 0-1)
    // Justification : durée max typique ~4h
    final normalizedDuration =
        (duration / 240.0).clamp(0.0, 1.0) * durationWeight;

    // Dimension 2 : Taille groupe normalisée (0-20 personnes = 0-1)
    final groupSize = ((minParticipants + maxParticipants) / 2).toDouble();
    final normalizedGroup = (groupSize / 20.0).clamp(0.0, 1.0) * groupWeight;

    // Dimension 3 : Difficulté normalisée (1-5 = 0-1)
    final normalizedDifficulty =
        ((difficulty - 1) / 4.0).clamp(0.0, 1.0) * difficultyWeight;

    // Combinaison : 6 (catégorie one-hot) + 3 autres = 9 dimensions
    return [
      ...categoryVector,
      normalizedDuration,
      normalizedGroup,
      normalizedDifficulty,
    ];
  }

  /// Retourne le vecteur brut (non normalisé) pour debug
  List<double> toRawVector() {
    final categoryIdx = categoryIndex[category] ?? 0;
    final categoryVector = List<double>.filled(6, 0.0);
    categoryVector[categoryIdx] = 1.0;

    final groupSize = ((minParticipants + maxParticipants) / 2).toDouble();
    return [...categoryVector, duration, groupSize, difficulty.toDouble()];
  }
}

/// Utilitaires pour calculs vectoriels
class VectorUtils {
  /// **FORMULE DU PROF** : Distance euclidienne pondérée
  /// Score = ||A - U|| × W
  /// Plus petit score = meilleur match
  static double weightedEuclideanDistance(
    List<double> activity, // Vecteur activité A
    List<double> userProfile, // Vecteur utilisateur U (profil)
    List<double> weights, // Vecteur poids W
  ) {
    if (activity.length != userProfile.length ||
        activity.length != weights.length) {
      throw ArgumentError('Les vecteurs doivent avoir la même longueur');
    }

    // Calcul : ||A - U|| × W
    double sumSquares = 0.0;
    for (int i = 0; i < activity.length; i++) {
      final diff = activity[i] - userProfile[i];
      sumSquares += (diff * diff) * (weights[i] * weights[i]);
    }

    // Distance euclidienne = sqrt(somme des carrés)
    return sqrt(sumSquares);
  }

  /// Calcule la distance cosinus entre deux vecteurs
  /// Retourne un score de similarité entre 0 et 1
  /// 1 = très similaire, 0 = complètement différent
  static double cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) {
      throw ArgumentError('Les vecteurs doivent avoir la même longueur');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      norm1 += v1[i] * v1[i];
      norm2 += v2[i] * v2[i];
    }

    norm1 = sqrt(norm1);
    norm2 = sqrt(norm2);

    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }

    return dotProduct / (norm1 * norm2);
  }

  /// Calcule la moyenne de plusieurs vecteurs (profile utilisateur)
  static List<double> averageVector(List<List<double>> vectors) {
    if (vectors.isEmpty) {
      throw ArgumentError('La liste de vecteurs ne peut pas être vide');
    }

    final dimension = vectors[0].length;
    final result = List<double>.filled(dimension, 0.0);

    for (final vector in vectors) {
      for (int i = 0; i < dimension; i++) {
        result[i] += vector[i];
      }
    }

    for (int i = 0; i < dimension; i++) {
      result[i] /= vectors.length;
    }

    return result;
  }

  /// Normalise un vecteur à norme 1
  static List<double> normalize(List<double> vector) {
    double norm = sqrt(vector.fold<double>(0, (a, b) => a + b * b));
    if (norm == 0) return vector;
    return vector.map((x) => x / norm).toList();
  }

  /// Calcul de la magnitude (norme euclidienne) d'un vecteur
  static double magnitude(List<double> vector) {
    return sqrt(vector.fold<double>(0, (a, b) => a + b * b));
  }
}
