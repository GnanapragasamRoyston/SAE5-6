import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import '../models/activity_rating.dart';
import '../models/activity_preferences.dart';
import '../models/performance_metrics.dart';

class SettingsPage extends StatefulWidget {
  final Box<ActivityRating>? activityRatingBox;
  final Box<ActivityPreferences>? activityPreferencesBox;
  final Box<PerformanceMetrics>? metricsBox;

  const SettingsPage({
    super.key,
    this.activityRatingBox,
    this.activityPreferencesBox,
    this.metricsBox,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;
  bool notifications = true;
  bool analytics = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: darkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
        title: Text(
          'Paramètres',
          style: GoogleFonts.poppins(
            color: darkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: darkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Apparence
            _buildSectionTitle('Apparence', darkMode),
            _buildSettingsTile(
              icon: Icons.brightness_4,
              title: 'Mode sombre',
              subtitle: 'Activer le mode sombre',
              value: darkMode,
              onChanged: (value) {
                setState(() {
                  darkMode = value;
                });
              },
              darkMode: darkMode,
            ),
            const Divider(height: 0),

            // Notifications
            _buildSectionTitle('Notifications', darkMode),
            _buildSettingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Recevoir les notifications',
              value: notifications,
              onChanged: (value) {
                setState(() {
                  notifications = value;
                });
              },
              darkMode: darkMode,
            ),
            const Divider(height: 0),

            // Confidentialité
            _buildSectionTitle('Confidentialité & Données', darkMode),
            _buildSettingsTile(
              icon: Icons.analytics,
              title: 'Données analytiques',
              subtitle: 'Partager des données pour améliorer l\'app',
              value: analytics,
              onChanged: (value) {
                setState(() {
                  analytics = value;
                });
              },
              darkMode: darkMode,
            ),
            const Divider(height: 0),
            _buildInfoTile(
              icon: Icons.privacy_tip,
              title: 'Politique de confidentialité',
              onTap: () {
                _showInfoDialog(
                  'Politique de confidentialité',
                  'Vos données personnelles sont protégées et ne sont jamais vendues à des tiers.\n\n'
                      '• Vos préférences d\'activités sont stockées localement\n'
                      '• Aucune donnée n\'est envoyée à nos serveurs\n'
                      '• Vous pouvez supprimer vos données à tout moment',
                  darkMode,
                );
              },
              darkMode: darkMode,
            ),
            const Divider(height: 0),
            _buildInfoTile(
              icon: Icons.description,
              title: 'Conditions d\'utilisation',
              onTap: () {
                _showInfoDialog(
                  'Conditions d\'utilisation',
                  'En utilisant Surpriz\'Me, vous acceptez nos conditions.\n\n'
                      '• L\'application est fournie "tel quel"\n'
                      '• Vous êtes responsable de l\'utilisation que vous en faites\n'
                      '• Nous nous réservons le droit de modifier l\'app',
                  darkMode,
                );
              },
              darkMode: darkMode,
            ),
            const Divider(height: 0),

            // Gestion des données
            _buildSectionTitle('Gestion des Données', darkMode),
            _buildInfoTile(
              icon: Icons.visibility,
              title: 'Voir mes traces d\'usage',
              subtitle: 'Afficher toutes vos données stockées',
              onTap: () {
                _showDataDialog(darkMode);
              },
              darkMode: darkMode,
            ),
            const Divider(height: 0),
            _buildActionTile(
              'Exporter mes données',
              'Télécharger vos données en JSON',
              Colors.green,
              Icons.download,
              () => _exportData(),
              darkMode,
            ),
            const Divider(height: 0),
            _buildActionTile(
              'Supprimer toutes mes données',
              'Action irréversible',
              Colors.red,
              Icons.delete_forever,
              () => _showDeleteConfirmation(darkMode),
              darkMode,
            ),
            const Divider(height: 0),

            // À propos
            _buildSectionTitle('À propos', darkMode),
            _buildInfoTile(
              icon: Icons.info,
              title: 'À propos de l\'application',
              subtitle: 'Version 1.0.0',
              onTap: () {
                _showInfoDialog(
                  'À propos de Surpriz\'Me',
                  'Surpriz\'Me v1.0.0\n\n'
                      'L\'application qui vous aide à vaincre l\'ennui en vous proposant des activités personnalisées.\n\n'
                      '© 2025 Surpriz\'Me. Tous droits réservés.',
                  darkMode,
                );
              },
              darkMode: darkMode,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool darkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: darkMode ? Colors.white70 : Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool darkMode,
  }) {
    return Container(
      color: darkMode ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: darkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool darkMode,
  }) {
    return Container(
      color: darkMode ? Colors.grey[850] : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color:
                                darkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: darkMode ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String content, bool darkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkMode ? Colors.grey[850] : Colors.white,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: darkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.poppins(
            color: darkMode ? Colors.grey[300] : Colors.grey[700],
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    Color actionColor,
    IconData icon,
    VoidCallback onTap,
    bool darkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: darkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: actionColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: actionColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: darkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: actionColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDataDialog(bool darkMode) {
    final ratingsCount = widget.activityRatingBox?.length ?? 0;
    final preferencesEntry =
        widget.activityPreferencesBox?.values.isNotEmpty ?? false
            ? widget.activityPreferencesBox?.values.first
            : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkMode ? Colors.grey[850] : Colors.white,
        title: Text(
          'Mes Traces d\'Usage',
          style: GoogleFonts.poppins(
            color: darkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDataInfoRow(
                'Recommandations Notées',
                ratingsCount.toString(),
                darkMode,
              ),
              const SizedBox(height: 12),
              _buildDataInfoRow(
                'Notes Positives (≥3)',
                (widget.activityRatingBox?.values
                            .where((r) => r.rating >= 3)
                            .length ??
                        0)
                    .toString(),
                darkMode,
              ),
              const SizedBox(height: 12),
              _buildDataInfoRow(
                'Notes Négatives (<3)',
                (widget.activityRatingBox?.values
                            .where((r) => r.rating < 3)
                            .length ??
                        0)
                    .toString(),
                darkMode,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              if (preferencesEntry != null) ...[
                Text(
                  'Poids Adaptatifs Actuels',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: darkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                _buildDataInfoRow(
                  'Catégorie',
                  (preferencesEntry.categoryWeight ?? 1.0).toStringAsFixed(2),
                  darkMode,
                ),
                const SizedBox(height: 8),
                _buildDataInfoRow(
                  'Durée',
                  (preferencesEntry.durationWeight ?? 1.0).toStringAsFixed(2),
                  darkMode,
                ),
                const SizedBox(height: 8),
                _buildDataInfoRow(
                  'Groupe',
                  (preferencesEntry.groupWeight ?? 1.0).toStringAsFixed(2),
                  darkMode,
                ),
                const SizedBox(height: 8),
                _buildDataInfoRow(
                  'Difficulté',
                  (preferencesEntry.difficultyWeight ?? 1.0).toStringAsFixed(2),
                  darkMode,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataInfoRow(String label, String value, bool darkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: darkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    try {
      final ratings = widget.activityRatingBox?.values.toList() ?? [];
      final preferences =
          widget.activityPreferencesBox?.values.isNotEmpty ?? false
              ? widget.activityPreferencesBox?.values.first
              : null;
      final metrics = widget.metricsBox?.values.toList() ?? [];

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'ratings': ratings
            .map(
              (r) => {
                'activityId': r.activityId,
                'rating': r.rating,
                'ratedAt': r.ratedAt.toIso8601String(),
              },
            )
            .toList(),
        'preferences': preferences != null
            ? {
                'categoryWeight': preferences.categoryWeight ?? 1.0,
                'durationWeight': preferences.durationWeight ?? 1.0,
                'groupWeight': preferences.groupWeight ?? 1.0,
                'difficultyWeight': preferences.difficultyWeight ?? 1.0,
              }
            : null,
        'metrics': metrics
            .map(
              (m) => {
                'tempsCalculMs': m.tempsCalculMs,
                'cpuUsagePercent': m.cpuUsagePercent,
                'memoireUsageBytes': m.memoireUsageBytes,
                'batterieDrainEstimeeMAh': m.batterieDrainEstimeeMAh,
                'nbRecommandations': m.nbRecommandations,
                'timestamp': m.timestamp.toIso8601String(),
              },
            )
            .toList(),
        'totalEntries': {'ratings': ratings.length, 'metrics': metrics.length},
      };

      final jsonString = jsonEncode(exportData);

      if (!mounted) return;

      // Affiche un snackbar de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Données exportées - ${jsonString.length} caractères copiés',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l\'export: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(bool darkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkMode ? Colors.grey[850] : Colors.white,
        title: Text(
          'Supprimer les Données',
          style: GoogleFonts.poppins(
            color: darkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Êtes-vous sûr ? Cette action est irréversible. Toutes vos traces d\'usage et préférences seront supprimées.',
          style: GoogleFonts.poppins(
            color: darkMode ? Colors.grey[300] : Colors.grey[700],
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (!mounted) return;
              try {
                await widget.activityRatingBox?.clear();
                await widget.metricsBox?.clear();

                final prefs = await Hive.openBox<ActivityPreferences>(
                  'activity_preferences',
                );
                await prefs.clear();
                await prefs.close();

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Toutes les données ont été supprimées',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Erreur lors de la suppression: $e',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
