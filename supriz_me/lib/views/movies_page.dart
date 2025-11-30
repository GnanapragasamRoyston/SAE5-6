import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/movie.dart';
import '../models/movie_rating.dart';
import '../services/recommendation/movie_recommender.dart';
import 'movie_preference_page.dart';

// --- 1. MoviesPage (StatefulWidget) ---

class MoviesPage extends StatefulWidget {
  final Box<Movie> movieBox;
  final Box<MovieRating> movieRatingBox;
  final Box settingsBox;

  const MoviesPage({
    super.key,
    required this.movieBox,
    required this.movieRatingBox,
    required this.settingsBox,
  });

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  // Set<String> _selectedGenres = {}; // ❌ PLUS BESOIN
  late MovieRecommender _recommender;

  @override
  void initState() {
    super.initState();

    _recommender = MovieRecommender(
      movieBox: widget.movieBox,
      movieRatingBox: widget.movieRatingBox,
      settingsBox: widget.settingsBox,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptForMoviePreferences();
    });
  }

  /// 🎯 Nouveau gestionnaire de navigation vers la page de préférences
  void _navigateToPreferencePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoviePreferencePage(
          settingsBox: widget.settingsBox,
          // Le callback force le rafraîchissement de MoviesPage après la sauvegarde
          onPreferencesSaved: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  /// Vérifie si l'utilisateur a déjà initialisé ses préférences de films.
  void _checkAndPromptForMoviePreferences() {
    final hasPrefsBeenSet =
        widget.settingsBox.get('movie_prefs_initialized', defaultValue: false);

    if (!hasPrefsBeenSet) {
      // 🎯 NAVIGUER VERS LA PAGE
      _navigateToPreferencePage();
    }
  }

  /// 🎯 AJOUT DE LA RÉINITIALISATION (Appel au navigation pour resélectionner)
  Future<void> _resetAppPreferences() async {
    await widget.movieRatingBox.clear();

    await Future.wait([
      widget.settingsBox.delete('movie_prefs_initialized'),
      widget.settingsBox.delete('initial_movie_genres'),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Réinitialisation complète effectuée. Veuillez choisir de nouvelles préférences.'),
        ),
      );
      // Forcer le re-check, ce qui naviguera vers la page de préférences
      setState(() {
        _navigateToPreferencePage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Films"),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetAppPreferences,
            tooltip: 'Réinitialiser les préférences et les notes',
          ),
          // 🎯 Bouton pour accéder aux préférences à tout moment
          IconButton(
            icon:
                const Icon(Icons.settings_input_component, color: Colors.white),
            onPressed: _navigateToPreferencePage,
            tooltip: 'Modifier les préférences initiales',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6F91),
              Color(0xFF845EC2),
              Color(0xFF2196F3),
              Color(0xFF00C9A7),
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
              // Cube orange avec "Film" (Code inchangé)
              Center(
                child: Container(
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Film",
                      style: GoogleFonts.bebasNeue(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 🌟 SECTION 1 : Recommandations pour vous 🌟 (Code inchangé)
              const Text(
                "Recommandations pour vous",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ValueListenableBuilder<Box<MovieRating>>(
                  valueListenable: widget.movieRatingBox.listenable(),
                  builder: (context, box, child) {
                    final recommendedMovies =
                        _recommender.getRecommendedMovies(count: 5);

                    if (recommendedMovies.isEmpty &&
                        !widget.settingsBox.get('movie_prefs_initialized',
                            defaultValue: false)) {
                      return const Center(
                        child: Text(
                          'Veuillez sélectionner vos genres favoris pour afficher les premières recommandations.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (recommendedMovies.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aimez ou n\'aimez pas des films ci-dessous pour plus de recommandations !',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedMovies.length,
                      itemBuilder: (context, index) {
                        final movie = recommendedMovies[index];
                        return MovieTile(
                          movie: movie,
                          recommender: _recommender,
                          tileColor: Colors.blueGrey,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ... (Reste des sections [Tous les films, Courts, Longs] restent inchangées,
              // elles utilisent déjà _recommender et widget.movieBox)

              // Section 2 : Tous les films
              const Text(
                "Tous les films",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      widget.movieBox.length > 5 ? 5 : widget.movieBox.length,
                  itemBuilder: (context, index) {
                    final movie = widget.movieBox.getAt(index);
                    if (movie == null) return const SizedBox.shrink();

                    return MovieTile(
                      movie: movie,
                      recommender: _recommender,
                      tileColor: Colors.grey[800]!,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Section 3 : Films courts (< 120 min)
              const Text(
                "Films courts",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: Builder(
                  builder: (context) {
                    final shortMovies = widget.movieBox.values
                        .where((m) => m.duration < 120)
                        .take(5)
                        .toList();

                    if (shortMovies.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun film court',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: shortMovies.length,
                      itemBuilder: (context, index) {
                        final movie = shortMovies[index];
                        return MovieTile(
                          movie: movie,
                          recommender: _recommender,
                          tileColor: Colors.green,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Section 4 : Films longs (>= 120 min)
              const Text(
                "Films longs",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: Builder(
                  builder: (context) {
                    final longMovies = widget.movieBox.values
                        .where((m) => m.duration >= 120)
                        .take(5)
                        .toList();

                    if (longMovies.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun film long',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: longMovies.length,
                      itemBuilder: (context, index) {
                        final movie = longMovies[index];
                        return MovieTile(
                          movie: movie,
                          recommender: _recommender,
                          tileColor: Colors.purple,
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Bouton Home intégré
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.orange,
                  ),
                  child: const Icon(Icons.home, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGETS MovieTile et MovieDetailPage sont inchangés, mais restent dans ce fichier
// =========================================================================

class MovieTile extends StatelessWidget {
// ... (reste inchangé)
  final Movie movie;
  final MovieRecommender recommender;
  final Color tileColor;

  const MovieTile({
    super.key,
    required this.movie,
    required this.recommender,
    required this.tileColor,
  });

  void _navigateToMovieDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(
          movie: movie,
          recommender: recommender,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 150,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToMovieDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow, size: 10),
                  Text(
                    '${movie.rating.toStringAsFixed(1)} / 5',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${movie.duration.toInt()}min',
                    style: TextStyle(
                      color: tileColor.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                movie.genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MovieDetailPage extends StatelessWidget {
  final Movie movie;
  final MovieRecommender recommender;

  const MovieDetailPage({
    super.key,
    required this.movie,
    required this.recommender,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<MovieRating>>(
      valueListenable: recommender.movieRatingBox.listenable(),
      builder: (context, box, child) {
        final currentRating = recommender.movieRatingBox.get(movie.id);
        final isLiked = currentRating?.isLiked ?? false;
        final isDisliked = currentRating != null && !currentRating.isLiked;

        return Scaffold(
          appBar: AppBar(
            title: Text(movie.title),
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF845EC2),
                  Color(0xFF2196F3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et Note
                  Text(
                    movie.title,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 36,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.rating.toStringAsFixed(1)} / 5',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(width: 20),
                      const Icon(Icons.access_time,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.duration.toInt()} min',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tags (Affichage des tags individuels sans redondance)
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      ...movie.tags.map((tag) => Chip(
                            label: Text(tag,
                                style: TextStyle(color: Colors.black)),
                            backgroundColor: Colors.grey[300],
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    "Synopsis",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.description.isNotEmpty
                        ? movie.description
                        : "Description non disponible.",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 40),

                  // Boutons Like/Dislike
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Bouton Dislike
                      ElevatedButton.icon(
                        onPressed: () {
                          recommender.saveRating(movie.id, false);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Dislike enregistré !')));
                        },
                        icon: Icon(Icons.thumb_down,
                            color: isDisliked ? Colors.white : Colors.red),
                        label: const Text("Dislike",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDisliked ? Colors.red : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                      ),

                      // Bouton Like
                      ElevatedButton.icon(
                        onPressed: () {
                          recommender.saveRating(movie.id, true);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Like enregistré !')));
                        },
                        icon: Icon(Icons.thumb_up,
                            color: isLiked ? Colors.white : Colors.green),
                        label: const Text("Like",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLiked ? Colors.green : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
