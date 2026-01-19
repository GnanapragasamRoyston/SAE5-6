import 'package:hive/hive.dart';

part 'performance_metrics.g.dart';

/// Modèle Hive pour tracker les métriques de performance
///
/// **Justification des métriques** :
/// - **tempsCalcul** : essentiel pour mesurer l'efficacité de l'algo vectoriel
/// - **cpuUsage** : estime via le temps calcul (100ms = ~5% CPU mobile)
/// - **memoireUsage** : taille des vecteurs stockés en mémoire
/// - **batterieDrainEstimee** : basée sur CPU + durée (mAh)
/// - **timestamp** : pour l'historique et les tendances
@HiveType(typeId: 10)
class PerformanceMetrics extends HiveObject {
  /// Temps de calcul de la recommandation en millisecondes
  @HiveField(0)
  final int tempsCalculMs;

  /// Estimation CPU utilisé en pourcentage (0-100)
  /// Formule : (tempsCalculMs / 100) * 5 (estimation pour mobile)
  @HiveField(1)
  final double cpuUsagePercent;

  /// Mémoire utilisée en bytes (vecteurs + calculs intermédiaires)
  @HiveField(2)
  final int memoireUsageBytes;

  /// Estimation de drain batterie en mAh
  /// Formule : cpuUsage * 0.1 (0.1mAh par % de CPU par seconde)
  @HiveField(3)
  final double batterieDrainEstimeeMAh;

  /// Nombre de recommandations générées
  @HiveField(4)
  final int nbRecommandations;

  /// Nombre d'activités traitées
  @HiveField(5)
  final int nbActiviteesTraitees;

  /// Timestamp du calcul (pour historique)
  @HiveField(6)
  final DateTime timestamp;

  /// Poids adaptatifs utilisés au moment du calcul (pour tracking évolution)
  @HiveField(7)
  final Map<String, double> poidsAdaptatifs;

  /// Raison du calcul (recommandation, surprise, filtrage)
  @HiveField(8)
  final String raison;

  PerformanceMetrics({
    required this.tempsCalculMs,
    required this.cpuUsagePercent,
    required this.memoireUsageBytes,
    required this.batterieDrainEstimeeMAh,
    required this.nbRecommandations,
    required this.nbActiviteesTraitees,
    required this.timestamp,
    required this.poidsAdaptatifs,
    required this.raison,
  });

  /// Factory constructor pour créer une métrique depuis les données brutes
  factory PerformanceMetrics.fromRaw({
    required int tempsCalculMs,
    required int memoireUsageBytes,
    required int nbRecommandations,
    required int nbActiviteesTraitees,
    required Map<String, double> poidsAdaptatifs,
    required String raison,
  }) {
    // Estimation CPU : 1ms = 0.05% CPU (basé sur mobile moyen)
    final cpuUsage = (tempsCalculMs * 0.05).clamp(0.0, 100.0);

    // Estimation drain batterie : 0.1mAh par % CPU par seconde
    final batterieDrain = (cpuUsage * 0.0001 * tempsCalculMs).clamp(0.0, 10.0);

    return PerformanceMetrics(
      tempsCalculMs: tempsCalculMs,
      cpuUsagePercent: cpuUsage,
      memoireUsageBytes: memoireUsageBytes,
      batterieDrainEstimeeMAh: batterieDrain,
      nbRecommandations: nbRecommandations,
      nbActiviteesTraitees: nbActiviteesTraitees,
      timestamp: DateTime.now(),
      poidsAdaptatifs: poidsAdaptatifs,
      raison: raison,
    );
  }

  /// Génère un rapport lisible
  String toReport() {
    return '''
═══ MÉTRIQUES DE PERFORMANCE ═══
⏱️  Temps calcul: ${tempsCalculMs}ms
💻 CPU utilisé: ${cpuUsagePercent.toStringAsFixed(2)}%
💾 Mémoire: ${(memoireUsageBytes / 1024).toStringAsFixed(1)}KB
🔋 Drain batterie: ${batterieDrainEstimeeMAh.toStringAsFixed(3)}mAh
📊 Recommandations: $nbRecommandations
🎯 Activités traitées: $nbActiviteesTraitees
⏰ Raison: $raison
═════════════════════════════
''';
  }

  /// Calcule la charge moyenne sur une période
  static double calculateAverageCPU(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) return 0.0;
    return metrics.fold<double>(0, (sum, m) => sum + m.cpuUsagePercent) /
        metrics.length;
  }

  /// Calcule le drain batterie cumulé
  static double calculateTotalBatteryDrain(List<PerformanceMetrics> metrics) {
    return metrics.fold<double>(0, (sum, m) => sum + m.batterieDrainEstimeeMAh);
  }

  /// Temps de calcul moyen
  static int calculateAverageTime(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) return 0;
    return (metrics.fold<int>(0, (sum, m) => sum + m.tempsCalculMs) /
            metrics.length)
        .toInt();
  }
}
