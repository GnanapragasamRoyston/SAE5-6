import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../models/activity.dart';
import '../models/activity_rating.dart';
import '../models/activity_preferences.dart';
import '../models/performance_metrics.dart';
import '../services/recommendation/activity_recommendation_service_vectorial.dart';
import 'activity_preferences_page.dart';
import 'stats_page.dart';

class ActivitiesPage extends StatefulWidget {
  final Box<Activity> activityBox;
  final Box<ActivityRating> activityRatingBox;
  final Box<ActivityPreferences> activityPreferencesBox;
  final Box<PerformanceMetrics> metricsBox;

  const ActivitiesPage({
    super.key,
    required this.activityBox,
    required this.activityRatingBox,
    required this.activityPreferencesBox,
    required this.metricsBox,
  });

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ActivityRecommendationServiceVectorial recommendationService;
  late ActivityPreferences userPreferences;
  bool preferencesSet = false;
  bool showAllActivities = false;
  PerformanceMetrics? lastMetrics;

  // Controllers pour animations
  late AnimationController _surpriseRotationController;
  final Map<String, AnimationController> _bounceControllers = {};
  final Map<String, AnimationController> _fadeControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialiser le controller pour la rotation du bouton Surprise
    _surpriseRotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeRecommendationService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _surpriseRotationController.dispose();
    for (var controller in _bounceControllers.values) {
      controller.dispose();
    }
    for (var controller in _fadeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Recalcule les recommendations à chaque fois qu'on revient à la page
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        // Forcer le rebuild pour recalculer les recommendations
      });
    }
  }

  void _initializeRecommendationService() {
    recommendationService = ActivityRecommendationServiceVectorial(
      activityBox: widget.activityBox,
      ratingBox: widget.activityRatingBox,
      metricsBox: widget.metricsBox,
    );

    // Charger les préférences existantes ou utiliser les defaults
    if (widget.activityPreferencesBox.isNotEmpty) {
      userPreferences = widget.activityPreferencesBox.getAt(0) ??
          ActivityPreferences.defaultPreferences();
      preferencesSet = true;
      recommendationService.initializePreferences(userPreferences);
    } else {
      // Première fois : afficher le dialog pour configuration
      userPreferences = ActivityPreferences.defaultPreferences();
      preferencesSet = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPreferencesDialog();
      });
      recommendationService.initializePreferences(userPreferences);
    }
  }

  void _loadPreferencesAfterConfiguration() {
    // Charger les préférences sauvegardées
    if (widget.activityPreferencesBox.isNotEmpty) {
      userPreferences = widget.activityPreferencesBox.getAt(0) ??
          ActivityPreferences.defaultPreferences();
      preferencesSet = true;
    } else {
      userPreferences = ActivityPreferences.defaultPreferences();
      preferencesSet = false;
    }

    recommendationService.initializePreferences(userPreferences);
  }

  void _showPreferencesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionnez vos préférences'),
        content: const Text(
          'Avant de continuer, veuillez sélectionner vos préférences.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityPreferencesPage(
                    preferencesBox: widget.activityPreferencesBox,
                    activityBox: widget.activityBox,
                    activityRatingBox: widget.activityRatingBox,
                  ),
                ),
              ).then((_) {
                // Charger les préférences après configuration (pas de réinitialization)
                setState(() {
                  _loadPreferencesAfterConfiguration();
                });
              });
            },
            child: const Text('Choisir'),
          ),
        ],
      ),
    );
  }

  void _rateActivity(String activityId, int rating) {
    // Créer un bounce controller s'il n'existe pas
    if (!_bounceControllers.containsKey(activityId)) {
      _bounceControllers[activityId] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }

    // Lancer l'animation bounce
    _bounceControllers[activityId]!.forward().then((_) {
      _bounceControllers[activityId]!.reverse();
    });

    // Sauvegarder la note
    recommendationService.rateActivity(activityId, rating);

    // Feedback visuel : SnackBar de confirmation
    final message = rating >= 3 ? '✓ J\'aime !' : '✗ Je n\'aime pas';
    final color = Colors.grey.shade700; // Gris unifié

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(milliseconds: 800),
      ),
    );

    // Recalculer les recommandations EN TEMPS RÉEL
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activités"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiques',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StatsPage(recommendationService: recommendationService),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityPreferencesPage(
                    preferencesBox: widget.activityPreferencesBox,
                    activityBox: widget.activityBox,
                    activityRatingBox: widget.activityRatingBox,
                  ),
                ),
              ).then((_) {
                setState(() {
                  _initializeRecommendationService();
                });
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A3A52), // Bleu marine foncé
              Color(0xFF2563EB), // Bleu moyen
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Recommandations
              _buildRecommendationsSection(),
              const SizedBox(height: 24),

              // Section Surprise
              _buildSurpriseSection(),
              const SizedBox(height: 24),

              // Section Toutes les activités
              _buildAllActivitiesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return FutureBuilder<List<(Activity, double)>>(
      future: recommendationService.getRecommendationsWithScores(limit: 50),
      builder: (context, snapshot) {
        // Récupérer la dernière métrique
        final metrics = recommendationService.getMetricsHistory();
        if (metrics.isNotEmpty) {
          lastMetrics = metrics.first;
        }

        final topThree = snapshot.data?.take(3).toList() ?? [];
        final suggestions = snapshot.data?.skip(3).toList() ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre avec fond - TOP 3
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'POUR VOUS',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // Badge de performance
                  if (lastMetrics != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        '⏱️ ${lastMetrics!.tempsCalculMs}ms',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const CircularProgressIndicator(),
              )
            else if (snapshot.hasError)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              )
            else if (!snapshot.hasData || snapshot.data!.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Aucune recommandation disponible',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
            else
              Column(
                children: [
                  // Top 3
                  for (int i = 0; i < topThree.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRecommendationCard(
                        topThree[i].$1,
                        i,
                        topThree[i].$2,
                      ),
                    ),
                  // Section "Vous pourriez aimer"
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb,
                              color: Colors.amber, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'VOUS POURRIEZ AIMER',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < suggestions.length; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(
                                width: 260,
                                height: 180,
                                child: _buildRecommendationCard(
                                  suggestions[i].$1,
                                  i + 3,
                                  suggestions[i].$2,
                                  isSuggestion: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationCard(Activity activity, int index, double score,
      {bool isSuggestion = false}) {
    final medals = ['🥇', '🥈', '🥉'];
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];

    final cardColor = isSuggestion
        ? const Color(0xFF4A90E2).withValues(alpha: 0.15)
        : colors[index].withValues(alpha: 0.15);
    final borderColor = isSuggestion
        ? const Color(0xFF4A90E2).withValues(alpha: 0.6)
        : colors[index].withValues(alpha: 0.6);
    final gradientColor1 = isSuggestion
        ? const Color(0xFF4A90E2).withValues(alpha: 0.25)
        : colors[index].withValues(alpha: 0.25);
    final gradientColor2 = isSuggestion
        ? const Color(0xFF4A90E2).withValues(alpha: 0.1)
        : colors[index].withValues(alpha: 0.1);
    final shadowColor = isSuggestion
        ? const Color(0xFF4A90E2).withValues(alpha: 0.4)
        : colors[index].withValues(alpha: 0.4);

    // Créer un fade controller si n'existe pas
    if (!_fadeControllers.containsKey(activity.id)) {
      _fadeControllers[activity.id] = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _fadeControllers[activity.id]!.forward();
    }

    return FadeTransition(
      opacity: _fadeControllers[activity.id] ?? AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
          CurvedAnimation(
            parent:
                _fadeControllers[activity.id] ?? AlwaysStoppedAnimation(1.0),
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          width: double.infinity,
          height: isSuggestion ? 140 : 190,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cardColor,
            gradient: LinearGradient(
              colors: [
                gradientColor1,
                gradientColor2,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuggestion ? '💡' : medals[index],
                      style: TextStyle(fontSize: isSuggestion ? 20 : 28),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: isSuggestion ? 13 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (!isSuggestion) ...[
                            const SizedBox(height: 4),
                            Text(
                              activity.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${activity.duration.toInt()} min • ${activity.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: isSuggestion ? 10 : 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _rateActivity(activity.id, 3),
                          icon: const Icon(Icons.thumb_up),
                          color: Colors.grey,
                          iconSize: isSuggestion ? 18 : 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _rateActivity(activity.id, 1),
                          icon: const Icon(Icons.thumb_down),
                          color: Colors.grey,
                          iconSize: isSuggestion ? 18 : 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurpriseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bouton Surprise compact et épuré
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                _surpriseRotationController.forward().then((_) {
                  _surpriseRotationController.reset();
                });

                final surprise =
                    await recommendationService.getSurpriseActivity();
                if (surprise != null && mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(surprise.title),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(surprise.description),
                          const SizedBox(height: 12),
                          Text('Durée: ${surprise.duration.toInt()} min'),
                          Text('Catégorie: ${surprise.category}'),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            _rateActivity(surprise.id, 3);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text('J\'aime'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _rateActivity(surprise.id, 1);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text('Je n\'aime pas'),
                        ),
                      ],
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFD862A6,
                  ), // Rose-violet uni (moyenne du dégradé)
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD862A6).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: Tween(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(_surpriseRotationController),
                      child: const Icon(
                        Icons.casino,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Surprise Me',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllActivitiesSection() {
    final activities = recommendationService.getAllActivities();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bouton pour afficher/masquer
        ElevatedButton.icon(
          icon: Icon(showAllActivities ? Icons.expand_less : Icons.expand_more),
          label: Text(
            showAllActivities
                ? 'Masquer les activités'
                : 'Voir toutes les activités',
          ),
          onPressed: () {
            setState(() {
              showAllActivities = !showAllActivities;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        if (showAllActivities) ...[
          const SizedBox(height: 16),
          // Titre simple
          Text(
            'TOUTES LES ACTIVITÉS',
            style: GoogleFonts.bebasNeue(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _buildActivityCard(activities[index]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    // Vérifier si l'activité a été testée
    final isRated = widget.activityRatingBox.values.any(
      (rating) => rating.activityId == activity.id,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRated)
                  GestureDetector(
                    onTap: () {
                      // Placeholder pour action future
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${activity.title} - À découvrir!'),
                          duration: const Duration(milliseconds: 1500),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange, width: 1.5),
                      ),
                      child: Text(
                        'À découvrir',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${activity.duration.toInt()} min • ${activity.category}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                Row(
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.3).animate(
                        _bounceControllers[activity.id] ??
                            AlwaysStoppedAnimation(1.0),
                      ),
                      child: IconButton(
                        onPressed: () => _rateActivity(activity.id, 3),
                        icon: const Icon(Icons.thumb_up),
                        color: Colors.grey,
                        iconSize: 24,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.3).animate(
                        _bounceControllers[activity.id] ??
                            AlwaysStoppedAnimation(1.0),
                      ),
                      child: IconButton(
                        onPressed: () => _rateActivity(activity.id, 1),
                        icon: const Icon(Icons.thumb_down),
                        color: Colors.grey,
                        iconSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
