import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/performance_metrics.dart';
import '../services/recommendation/activity_recommendation_service_vectorial.dart';

class StatsPage extends StatefulWidget {
  final ActivityRecommendationServiceVectorial recommendationService;

  const StatsPage({super.key, required this.recommendationService});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  Widget build(BuildContext context) {
    final metrics = widget.recommendationService.getMetricsHistory();
    final avgMetrics = widget.recommendationService.getAverageMetrics();
    final usageStats = widget.recommendationService.getUsageStats();
    final weights = widget.recommendationService.getAdaptiveWeights();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Statistiques', style: GoogleFonts.bebasNeue(fontSize: 24)),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section : Performance
            _buildSectionTitle('Performance'),
            _buildPerformanceCard(avgMetrics),
            const SizedBox(height: 20),

            // Section : Historique Temps
            _buildSectionTitle('Historique Temps de Calcul'),
            _buildTimeHistoryChart(metrics),
            const SizedBox(height: 20),

            // Section : Utilisation CPU
            _buildSectionTitle('Utilisation CPU (%)'),
            _buildCPUChart(metrics),
            const SizedBox(height: 20),

            // Section : Drain Batterie
            _buildSectionTitle('Drain Batterie Estimé (mAh)'),
            _buildBatteryChart(metrics),
            const SizedBox(height: 20),

            // Section : Feedback Utilisateur
            _buildSectionTitle('Feedback Utilisateur'),
            _buildFeedbackCard(usageStats),
            const SizedBox(height: 20),

            // Section : Poids Adaptatifs
            _buildSectionTitle('Poids Adaptatifs (Recommandation Vectorielle)'),
            _buildWeightsCard(weights),
            const SizedBox(height: 20),

            // Section : Détails Récents
            _buildSectionTitle('Détails Récents'),
            _buildMetricsDetails(metrics.take(5).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.bebasNeue(
          fontSize: 18,
          color: Colors.black87,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> avgMetrics) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricRow(
            '⏱️ Temps Moyen',
            '${avgMetrics['avgTime']}ms',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            '💻 CPU Moyen',
            '${(avgMetrics['avgCPU'] as double).toStringAsFixed(2)}%',
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            '🔋 Drain Batterie Total',
            '${(avgMetrics['totalBatteryDrain'] as double).toStringAsFixed(3)}mAh',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeHistoryChart(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Aucune métrique disponible',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    final maxTime = metrics
        .map((m) => m.tempsCalculMs)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.reversed.take(10).map((m) {
          final height = (m.tempsCalculMs / maxTime) * 150;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  height: height,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.tempsCalculMs}ms',
                  style: GoogleFonts.poppins(fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCPUChart(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Aucune métrique disponible',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.reversed.take(10).map((m) {
          final height = (m.cpuUsagePercent / 100) * 150;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  height: height,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.cpuUsagePercent.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBatteryChart(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Aucune métrique disponible',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    final maxDrain = metrics
        .map((m) => m.batterieDrainEstimeeMAh)
        .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.reversed.take(10).map((m) {
          final height = (m.batterieDrainEstimeeMAh / maxDrain) * 150;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  height: height,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.batterieDrainEstimeeMAh.toStringAsFixed(2),
                  style: GoogleFonts.poppins(fontSize: 9),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> usageStats) {
    final totalLikes = usageStats['totalLikes'] as int;
    final totalDislikes = usageStats['totalDislikes'] as int;
    final ratioLike = usageStats['ratioLike'] as double;

    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetricRow('👍 J\'aime', '$totalLikes', Colors.green),
          const SizedBox(height: 12),
          _buildMetricRow('👎 J\'aime pas', '$totalDislikes', Colors.red),
          const SizedBox(height: 12),
          _buildMetricRow(
            '📊 Ratio Like',
            '${ratioLike.toStringAsFixed(1)}%',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              widthFactor: ratioLike / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightsCard(Map<String, double> weights) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Poids adaptatifs (évoluent avec les likes/dislikes)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _buildWeightSlider('Catégorie', weights['categoryWeight'] ?? 1.0),
          const SizedBox(height: 12),
          _buildWeightSlider('Durée', weights['durationWeight'] ?? 1.0),
          const SizedBox(height: 12),
          _buildWeightSlider('Groupe', weights['groupWeight'] ?? 1.0),
          const SizedBox(height: 12),
          _buildWeightSlider('Difficulté', weights['difficultyWeight'] ?? 1.0),
        ],
      ),
    );
  }

  Widget _buildWeightSlider(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 13)),
            Text(
              value.toStringAsFixed(2),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / 2.0).clamp(0, 1),
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(
              value > 1.2
                  ? Colors.green
                  : (value < 0.8 ? Colors.red : Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsDetails(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Aucune métrique disponible',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: metrics.map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⏰ ${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    m.raison,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '⏱️ ${m.tempsCalculMs}ms',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '💻 ${m.cpuUsagePercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '🔋 ${m.batterieDrainEstimeeMAh.toStringAsFixed(3)}mAh',
                      style: GoogleFonts.poppins(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
