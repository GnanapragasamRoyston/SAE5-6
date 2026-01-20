import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import '../models/activity.dart';
import '../models/activity_rating.dart';
import '../models/activity_preferences.dart';
import '../models/performance_metrics.dart';
import '../services/recommendation/activity_recommendation_service_vectorial.dart';
import 'activity_preferences_page.dart';
import 'activity_details_page.dart';
import 'stats_page.dart';


class ActivitiesPage extends StatefulWidget {
  final Box<Activity> activityBox;
  final Box<ActivityRating> activityRatingBox;
  final Box<ActivityPreferences> activityPreferencesBox;
  final Box<PerformanceMetrics> metricsBox;
  final bool autoSurprizme; // ✅ NOUVEAU PARAMÈTRE

  const ActivitiesPage({
    super.key,
    required this.activityBox,
    required this.activityRatingBox,
    required this.activityPreferencesBox,
    required this.metricsBox,
    this.autoSurprizme = false, // ✅ PAR DÉFAUT FALSE
  });

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

// Remplacez votre classe _ActivitiesPageState par celle-ci

class _ActivitiesPageState extends State<ActivitiesPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ActivityRecommendationServiceVectorial recommendationService;
  late ActivityPreferences userPreferences;
  bool preferencesSet = false;
  bool showAllActivities = false;
  PerformanceMetrics? lastMetrics;

  late AnimationController _surpriseRotationController;
  final Map<String, AnimationController> _bounceControllers = {};
  final Map<String, AnimationController> _fadeControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _surpriseRotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeRecommendationService();

    if (widget.autoSurprizme) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerSurprizme();
      });
    }
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  void _initializeRecommendationService() {
    recommendationService = ActivityRecommendationServiceVectorial(
      activityBox: widget.activityBox,
      ratingBox: widget.activityRatingBox,
      metricsBox: widget.metricsBox,
    );

    if (widget.activityPreferencesBox.isNotEmpty) {
      userPreferences = widget.activityPreferencesBox.getAt(0) ??
          ActivityPreferences.defaultPreferences();
      preferencesSet = true;
      recommendationService.initializePreferences(userPreferences);
    } else {
      userPreferences = ActivityPreferences.defaultPreferences();
      preferencesSet = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPreferencesDialog();
      });
      recommendationService.initializePreferences(userPreferences);
    }
  }

  // ✅ NOUVELLE FONCTION RESET
  void _resetPreferences() async {
    await widget.activityPreferencesBox.clear();
    setState(() {
      _initializeRecommendationService();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préférences réinitialisées')),
    );
  }

  void _loadPreferencesAfterConfiguration() {
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

  void _triggerSurprizme() async {
    // Animation du bouton (comme avant)
    _surpriseRotationController.forward().then((_) {
      _surpriseRotationController.reset();
    });

    // 1. Récupérer les recommandations actuelles (pour les exclure de la surprise)
    // On veut une "vraie" surprise, donc pas ce qui est déjà affiché en top liste.
    final recommendations = await recommendationService.getRecommendationsWithScores(limit: 5);
    final recommendedIds = recommendations.map((r) => r.$1.id).toSet();

    // 2. Récupérer toutes les activités
    final allActivities = widget.activityBox.values.toList();

    // 3. Filtrer pour trouver des candidats valides
    final availableSurprises = allActivities.where((activity) {
      // Exclure celles déjà recommandées en haut de page
      final isRecommended = recommendedIds.contains(activity.id);

      // Vérifier le statut (Noté ou Fait)
      final ratingObj = widget.activityRatingBox.values.firstWhereOrNull(
        (r) => r.activityId == activity.id
      );
      
      // On exclut si c'est "Disliké" (note < 3) ou marqué comme "Fait"
      final isDisliked = ratingObj != null && ratingObj.rating < 3;
      final isDone = ratingObj?.isDone ?? false;

      // La surprise doit être : Pas recommandée ET Pas détestée ET Pas déjà faite
      return !isRecommended && !isDisliked && !isDone;
    }).toList();

    // 4. Sélectionner une activité au hasard
    if (availableSurprises.isNotEmpty) {
      final random = Random();
      final surprise = availableSurprises[random.nextInt(availableSurprises.length)];

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsPage(
              activity: surprise,
              activityRatingBox: widget.activityRatingBox,
              onFeedbackGiven: () {
                setState(() {});
              },
            ),
          ),
        );
      }
    } else {
      // Cas de secours : Si l'utilisateur a tout fait ou tout noté
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zut ! Aucune surprise inédite disponible (tout est déjà noté ou fait).'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  void _rateActivity(String activityId, int rating) {
    if (!_bounceControllers.containsKey(activityId)) {
      _bounceControllers[activityId] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }

    _bounceControllers[activityId]!.forward().then((_) {
      _bounceControllers[activityId]!.reverse();
    });

    recommendationService.rateActivity(activityId, rating);

    final message = rating >= 3 ? '✓ J\'aime !' : '✗ Je n\'aime pas';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey.shade700,
        duration: const Duration(milliseconds: 800),
      ),
    );

    setState(() {});
  }

  // ✅ FONCTION POUR RÉCUPÉRER LE SCORE ACTUEL
  int? _getCurrentRating(String activityId) {
    final rating = widget.activityRatingBox.values.firstWhereOrNull(
      (r) => r.activityId == activityId,
    );
    return rating?.rating;
  }

  void _toggleFavorite(String activityId) {
    final existingRating = widget.activityRatingBox.values.firstWhere(
      (rating) => rating.activityId == activityId,
      orElse: () => ActivityRating(
        activityId: activityId,
        rating: 2,
        ratedAt: DateTime.now(),
        isDone: false,
        isFavorite: false,
      ),
    );

    final updatedRating = existingRating.copyWith(
      isFavorite: !existingRating.isFavorite,
    );

    if (widget.activityRatingBox.values.contains(existingRating)) {
      final index =
          widget.activityRatingBox.values.toList().indexOf(existingRating);
      widget.activityRatingBox.putAt(index, updatedRating);
    } else {
      widget.activityRatingBox.add(updatedRating);
    }

    final message = updatedRating.isFavorite
        ? '⭐ Ajouté aux favoris'
        : '⭐ Retiré des favoris';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey.shade700,
        duration: const Duration(milliseconds: 800),
      ),
    );

    setState(() {});
  }

  bool _isFavorite(String activityId) {
    final rating = widget.activityRatingBox.values.firstWhereOrNull(
      (r) => r.activityId == activityId,
    );
    return rating?.isFavorite ?? false;
  }

  String _buildFiltersText() {
    List<String> filters = [];
    if (userPreferences.availableTime > 0) {
      filters.add('⏱️ ${userPreferences.availableTime}min');
    }
    if (userPreferences.groupSize > 0) {
      filters.add('👥 ${userPreferences.groupSize} pers.');
    }
    if (userPreferences.preferredCategories.isNotEmpty) {
      final categoriesText =
          userPreferences.preferredCategories.take(2).join(', ');
      filters.add('📁 $categoriesText');
    }
    if (!userPreferences.allowSurprise) {
      filters.add('🎲 Surprises OFF');
    }
    return filters.isEmpty ? 'Aucun filtre actif' : filters.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            center: Alignment(0, -0.5),
            colors: [
              Color(0xFF0a1628),
              Color(0xFF050814),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildArcadeHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSurprizmeButton(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0d1b35),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: const Color(0xFF00d9ff), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00d9ff).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '${widget.activityBox.length}',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 24,
                              color: const Color(0xFF00d9ff),
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "ACTIVITÉS DISPO",
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (preferencesSet)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0d1b35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF00d9ff).withOpacity(0.5)),
                        ),
                        child: Text(
                          'FILTRES : ${_buildFiltersText()}',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 25),
                    _buildRecommendationsSection(),
                    const SizedBox(height: 25),
                    const SizedBox(height: 25),
                    _buildCompletedSection(),
                    const SizedBox(height: 25),
                    _buildAllActivitiesSection(),
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0d1b35),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF00d9ff), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00d9ff).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.home,
                              color: Colors.white, size: 32),
                          onPressed: () => Navigator.popUntil(
                              context, (route) => route.isFirst),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArcadeHeader() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFff0080), Color(0xFFff6600)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ACTIVITÉS ARCADE',
                style: GoogleFonts.pressStart2p(
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ✅ REMPLACEMENT DES STATS PAR LE RESET
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
              onPressed: _resetPreferences,
              tooltip: 'Reset Préférences',
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 22),
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
      ),
    );
  }

  Widget _buildSurprizmeButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFff0080), Color(0xFFff6600)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFff0080).withOpacity(0.6),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: _triggerSurprizme,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0)
                          .animate(_surpriseRotationController),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.black87, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "SURPRIZ'ME",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildArcadeSectionTitle(IconData icon, String label,
      {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1b35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00d9ff), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.pressStart2p(
              fontSize: 11,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return FutureBuilder<List<(Activity, double)>>(
      future: recommendationService.getRecommendationsWithScores(limit: 50),
      builder: (context, snapshot) {
        final topThree = snapshot.data?.take(3).toList() ?? [];
        final suggestions = snapshot.data?.skip(3).toList() ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArcadeSectionTitle(Icons.star, 'POUR VOUS'),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00d9ff)))
            else if (!snapshot.hasData || snapshot.data!.isEmpty)
              Center(
                child: Text(
                  'Aucune recommandation',
                  style:
                      GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: topThree.length,
                      itemBuilder: (context, i) {
                        final medals = ['🥇', '🥈', '🥉'];
                        final colors = [
                          const Color(0xFFffd700),
                          const Color(0xFFc0c0c0),
                          const Color(0xFFcd7f32),
                        ];
                        return _buildActivityTile(
                          topThree[i].$1,
                          colors[i],
                          medal: medals[i],
                        );
                      },
                    ),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildArcadeSectionTitle(
                        Icons.lightbulb, 'VOUS POURRIEZ AIMER'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestions.length,
                        itemBuilder: (context, i) => _buildActivityTile(
                            suggestions[i].$1, const Color(0xFF00c2ff)),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildActivityTile(Activity activity, Color tileColor,
      {String? medal}) {
    final currentRating = _getCurrentRating(activity.id);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 160,
      height: 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tileColor.withOpacity(0.3),
            tileColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tileColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: tileColor.withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailsPage(
                activity: activity,
                activityRatingBox: widget.activityRatingBox,
                onFeedbackGiven: () {
                  setState(() {});
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (medal != null) ...[
                          Text(medal, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.pressStart2p(
                              color: Colors.white,
                              fontSize: 10,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.orange, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.duration.toInt()}min',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ DISLIKE ROUGE SI ACTIF
                  GestureDetector(
                    onTap: () => _rateActivity(activity.id, 1),
                    child: Icon(
                      Icons.thumb_down,
                      size: 18,
                      color: (currentRating != null && currentRating < 3)
                          ? Colors.red
                          : Colors.white38,
                    ),
                  ),
                  // ✅ LIKE VERT SI ACTIF
                  GestureDetector(
                    onTap: () => _rateActivity(activity.id, 3),
                    child: Icon(
                      Icons.thumb_up,
                      size: 18,
                      color: (currentRating != null && currentRating >= 3)
                          ? Colors.green
                          : Colors.white38,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleFavorite(activity.id),
                    child: Icon(
                      _isFavorite(activity.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: _isFavorite(activity.id)
                          ? Colors.red
                          : Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedSection() {
    final allActivities = recommendationService.getAllActivities();
    final completedIds = widget.activityRatingBox.values
        .where((r) => r.isDone)
        .map((r) => r.activityId)
        .toSet();

    final completedActivities = allActivities
        .where((activity) => completedIds.contains(activity.id))
        .toList();

    if (completedActivities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildArcadeSectionTitle(
          Icons.check_circle,
          'ACTIVITÉS COMPLÉTÉES',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00ff85).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${completedActivities.length}',
              style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: completedActivities.length,
            itemBuilder: (context, index) {
              return _buildActivityTile(
                  completedActivities[index], const Color(0xFF00ff85));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllActivitiesSection() {
    final activities = recommendationService.getAllActivities();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00d9ff), Color(0xFF00a3cc)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00d9ff).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => showAllActivities = !showAllActivities),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        showAllActivities ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      showAllActivities ? 'MASQUER' : 'TOUTES LES ACTIVITÉS',
                      style: GoogleFonts.pressStart2p(
                          fontSize: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showAllActivities) ...[
          const SizedBox(height: 16),
          _buildArcadeSectionTitle(Icons.list_alt, 'CATALOGUE'),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) => _buildActivityCard(activities[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    final isRated = widget.activityRatingBox.values
        .any((rating) => rating.activityId == activity.id);
    final currentRating = _getCurrentRating(activity.id);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ActivityDetailsPage(
              activity: activity,
              activityRatingBox: widget.activityRatingBox,
              onFeedbackGiven: () => setState(() {}),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0d1b35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00d9ff).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF00d9ff).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.title,
                          style: GoogleFonts.pressStart2p(
                              fontSize: 11, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(activity.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                if (!isRated)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFffa940).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFffa940)),
                    ),
                    child: Text('NOUVEAU',
                        style: GoogleFonts.pressStart2p(
                            fontSize: 8, color: const Color(0xFFffa940))),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${activity.duration.toInt()} min • ${activity.category}',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                ),
                Row(
                  children: [
                    // ✅ LIKE VERT
                    IconButton(
                      onPressed: () => _rateActivity(activity.id, 3),
                      icon: const Icon(Icons.thumb_up),
                      color: (currentRating != null && currentRating >= 3)
                          ? Colors.green
                          : Colors.white60,
                      iconSize: 20,
                    ),
                    // ✅ DISLIKE ROUGE
                    IconButton(
                      onPressed: () => _rateActivity(activity.id, 1),
                      icon: const Icon(Icons.thumb_down),
                      color: (currentRating != null && currentRating < 3)
                          ? Colors.red
                          : Colors.white60,
                      iconSize: 20,
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