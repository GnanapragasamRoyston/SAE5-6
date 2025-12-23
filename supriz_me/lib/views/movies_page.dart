import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math'; // Importation ajoutée pour Random

import '../models/movie.dart';
import '../models/movie_rating.dart';
import '../services/recommendation/movie_recommender.dart';
import 'movie_preference_page.dart';

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
  late MovieRecommender _recommender;
  Set<String> _favoriteMovieTitles = {};

  static const String _favoriteMoviesKey = 'favorite_movies_titles';

  @override
  void initState() {
    super.initState();

    _recommender = MovieRecommender(
      movieBox: widget.movieBox,
      movieRatingBox: widget.movieRatingBox,
      settingsBox: widget.settingsBox,
    );

    _loadFavoriteMovies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptForMoviePreferences();
    });
  }

  void _loadFavoriteMovies() {
    final savedFavorites =
        List<String>.from(widget.settingsBox.get(_favoriteMoviesKey) ?? []);
    _favoriteMovieTitles = savedFavorites.toSet();
  }

  void _toggleMovieFavorite(String movieTitle) {
    if (_favoriteMovieTitles.contains(movieTitle)) {
      _favoriteMovieTitles.remove(movieTitle);
    } else {
      _favoriteMovieTitles.add(movieTitle);
    }
    widget.settingsBox.put(_favoriteMoviesKey, _favoriteMovieTitles.toList());
    setState(() {});
  }

  bool _isMovieFavorite(String movieTitle) {
    return _favoriteMovieTitles.contains(movieTitle);
  }

  void _navigateToPreferencePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoviePreferencePage(
          settingsBox: widget.settingsBox,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _checkAndPromptForMoviePreferences() {
    final hasPrefsBeenSet =
        widget.settingsBox.get('movie_prefs_initialized', defaultValue: false);

    if (!hasPrefsBeenSet) {
      _navigateToPreferencePage();
    }
  }

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
            'Réinitialisation complète effectuée. Veuillez choisir de nouvelles préférences.',
          ),
        ),
      );
      setState(() {
        _navigateToPreferencePage();
      });
    }
  }

  // NOUVELLE MÉTHODE : Navigue directement vers MovieDetailPage avec le film Surprizme
  void _navigateToSurprizmeMovie() {
    final recommendedIds =
        _recommender.getRecommendedMovies(count: 5).map((m) => m.id).toSet();
    final allMovies = widget.movieBox.values.toList();

    final nonRecommendedMovies =
        allMovies.where((m) => !recommendedIds.contains(m.id)).toList();

    if (nonRecommendedMovies.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(nonRecommendedMovies.length);
      final surprizmeMovie = nonRecommendedMovies[randomIndex];

      // NAVIGUE DIRECTEMENT VERS MOVIEDETAILPAGE
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovieDetailPage(
            movie: surprizmeMovie,
            recommender: _recommender,
          ),
        ),
      ).then((_) {
        // Optionnel : Recharger l'écran si nécessaire après le retour
        setState(() {});
      });
    } else {
      // Aucun film non recommandé disponible
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun film "Surprizme" disponible pour le moment.'),
        ),
      );
    }
  }

  // L'ancienne méthode _getRandomNonRecommendedMovie est obsolète,
  // la nouvelle est _navigateToSurprizmeMovie.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Films'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetAppPreferences,
            tooltip: 'Réinitialiser les préférences et les notes',
          ),
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
              Color(0xFF1A3A52),
              Color(0xFF2563EB),
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
              _buildHeader(),
              const SizedBox(height: 24),

              // Section : Surprizme (Bouton uniquement)
              _buildSurprizmeSection(),
              // L'affichage du film surprizme a été retiré de cette page
              const SizedBox(height: 24),

              // Section 1 : Recommandations pour vous
              _buildSectionTitle(
                icon: Icons.favorite,
                label: 'RECOMMANDATIONS POUR VOUS',
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<Box<MovieRating>>(
                valueListenable: widget.movieRatingBox.listenable(),
                builder: (context, box, child) {
                  final recommendedMovies =
                      _recommender.getRecommendedMovies(count: 5);

                  final hasPrefsBeenSet = widget.settingsBox
                      .get('movie_prefs_initialized', defaultValue: false);

                  if (recommendedMovies.isEmpty && !hasPrefsBeenSet) {
                    return Center(
                      child: Text(
                        'Sélectionnez vos genres favoris pour afficher vos premières recommandations.',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (recommendedMovies.isEmpty) {
                    return Center(
                      child: Text(
                        'Aimez ou n\'aimez pas des films ci-dessous pour plus de recommandations !',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedMovies.length,
                      itemBuilder: (context, index) {
                        final movie = recommendedMovies[index];
                        return MovieTile(
                          movie: movie,
                          recommender: _recommender,
                          tileColor: Colors.redAccent,
                          moviesPageRef: this,
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Le reste de votre code (Sections 2, 3, 4 et Bouton Home)
              // ...
              // Section 2 : Tous les films
              _buildSectionTitle(
                icon: Icons.movie,
                label: 'TOUS LES FILMS',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
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
                      tileColor: Colors.blueGrey,
                      moviesPageRef: this,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Section 3 : Films courts (< 120 min)
              _buildSectionTitle(
                icon: Icons.timer,
                label: 'FILMS COURTS (< 120 MIN)',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: Builder(
                  builder: (context) {
                    final shortMovies = widget.movieBox.values
                        .where((m) => m.duration < 120)
                        .take(5)
                        .toList();

                    if (shortMovies.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun film court',
                          style: GoogleFonts.poppins(color: Colors.white),
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
                          moviesPageRef: this,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Section 4 : Films longs (>= 120 min)
              _buildSectionTitle(
                icon: Icons.timelapse,
                label: 'FILMS LONGS (≥ 120 MIN)',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: Builder(
                  builder: (context) {
                    final longMovies = widget.movieBox.values
                        .where((m) => m.duration >= 120)
                        .take(5)
                        .toList();

                    if (longMovies.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun film long',
                          style: GoogleFonts.poppins(color: Colors.white),
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
                          moviesPageRef: this,
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Section À FAIRE PLUS TARD
              _buildFavoriteMoviesSection(),

              const SizedBox(height: 32),

              // Bouton Home
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.grey.shade700,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_movies, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 8),
          Text(
            'FILMS',
            style: GoogleFonts.bebasNeue(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFavoriteMoviesSection() {
    final allMovies = widget.movieBox.values.toList();
    final favoriteMovies = allMovies
        .where((movie) => _favoriteMovieTitles.contains(movie.title))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
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
              const Icon(Icons.bookmark, color: Colors.yellow, size: 24),
              const SizedBox(width: 8),
              Text(
                'À FAIRE PLUS TARD',
                style: GoogleFonts.bebasNeue(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellow.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${favoriteMovies.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (favoriteMovies.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'Aucun film ajouté',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteMovies.length,
              itemBuilder: (context, index) {
                final movie = favoriteMovies[index];
                return MovieTile(
                  movie: movie,
                  recommender: _recommender,
                  tileColor: Colors.orange,
                  moviesPageRef: this,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.bebasNeue(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la section Surprizme (MODIFIÉE)
  Widget _buildSurprizmeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bouton Surprizme (appelle la nouvelle méthode de navigation)
        Center(
          child: ElevatedButton.icon(
            onPressed: _navigateToSurprizmeMovie, // Appel mis à jour
            icon: const Icon(Icons.casino, color: Colors.white),
            label: Text(
              'SURPRIZME !',
              style: GoogleFonts.bebasNeue(
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C4CC),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Le bloc d'affichage du film surprizme a été retiré ici.
        Center(
          child: Text(
            'Appuyez sur "SURPRIZME !" pour une suggestion aléatoire qui vous fera découvrir un autre horizon !',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// Le code pour MovieTile et MovieDetailPage reste le même.

// =========================================================================
// MovieTile
// =========================================================================

class MovieTile extends StatefulWidget {
  final Movie movie;
  final MovieRecommender recommender;
  final Color tileColor;
  final _MoviesPageState? moviesPageRef;

  const MovieTile({
    super.key,
    required this.movie,
    required this.recommender,
    required this.tileColor,
    this.moviesPageRef,
  });

  @override
  State<MovieTile> createState() => _MovieTileState();
}

class _MovieTileState extends State<MovieTile> {
  void _navigateToMovieDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailPage(
          movie: widget.movie,
          recommender: widget.recommender,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void _handleFeedback(bool isLiked) {
    widget.recommender.saveRating(widget.movie.id, isLiked);
    setState(() {});

    final message = isLiked ? '✓ Like enregistré' : '✗ Dislike enregistré';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey.shade700,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRating =
        widget.recommender.movieRatingBox.get(widget.movie.id);
    final isLiked = currentRating?.isLiked ?? false;
    final isDisliked = currentRating != null && !currentRating.isLiked;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 150,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.tileColor.withOpacity(0.9),
            widget.tileColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToMovieDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow, size: 12),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '${widget.movie.rating.toStringAsFixed(1)} / 5',
                      style: GoogleFonts.poppins(
                        color: Colors.yellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${widget.movie.duration.toInt()} min',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.movie.genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildFeedbackIcon(
                    icon: Icons.thumb_down_alt_rounded,
                    color: Colors.pinkAccent,
                    isActive: isDisliked,
                    onTap: () => _handleFeedback(false),
                  ),
                  const SizedBox(width: 4),
                  _buildFeedbackIcon(
                    icon: Icons.thumb_up_alt_rounded,
                    color: Colors.greenAccent,
                    isActive: isLiked,
                    onTap: () => _handleFeedback(true),
                  ),
                  const SizedBox(width: 4),
                  _buildFavoriteIcon(
                    isFavorite: widget.moviesPageRef
                            ?._isMovieFavorite(widget.movie.title) ??
                        false,
                    onTap: () {
                      widget.moviesPageRef
                          ?._toggleMovieFavorite(widget.movie.title);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackIcon({
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? color : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? color : Colors.white70,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildFavoriteIcon({
    required bool isFavorite,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isFavorite ? Colors.red.withOpacity(0.2) : Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(
            color: isFavorite ? Colors.red : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.white70,
          size: 14,
        ),
      ),
    );
  }
}

// =========================================================================
// MovieDetailPage
// =========================================================================

class MovieDetailPage extends StatelessWidget {
// ... votre code MovieDetailPage ...
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
          // 1. Définir le fond du Scaffold comme transparent
          backgroundColor: Colors.transparent,
          body: Container(
            // 2. Appliquer le dégradé au Container body pour qu'il couvre tout
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A3A52),
                  Color(0xFF2563EB),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            // 3. Utiliser CustomScrollView et SliverAppBar pour le défilement et l'AppBar
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text(movie.title),
                  // Rendre l'AppBar transparente pour voir le dégradé en dessous
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 36,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.yellow, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${movie.rating.toStringAsFixed(1)} / 5',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Icon(Icons.access_time,
                                  color: Colors.orange, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${movie.duration.toInt()} min',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            ...movie.tags.map(
                              (tag) => Chip(
                                label: Text(
                                  tag,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Synopsis',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.description.isNotEmpty
                              ? movie.description
                              : 'Description non disponible.',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFeedbackButton(
                              icon: Icons.thumb_down_alt_rounded,
                              color: Colors.pinkAccent,
                              isActive: isDisliked,
                              onTap: () {
                                recommender.saveRating(movie.id, false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✗ Dislike enregistré !'),
                                    backgroundColor: Colors.grey,
                                    duration: Duration(milliseconds: 800),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildFeedbackButton(
                              icon: Icons.thumb_up_alt_rounded,
                              color: Colors.greenAccent,
                              isActive: isLiked,
                              onTap: () {
                                recommender.saveRating(movie.id, true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Like enregistré !'),
                                    backgroundColor: Colors.grey,
                                    duration: Duration(milliseconds: 800),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildFeedbackButton(
                              icon: Icons.favorite,
                              color: Colors.redAccent,
                              isActive: currentRating?.isFavorite ?? false,
                              onTap: () {
                                final updatedRating = currentRating != null
                                    ? currentRating.copyWith(
                                        isFavorite: !currentRating.isFavorite)
                                    : MovieRating(
                                        movieId: movie.id,
                                        isLiked: false,
                                        timestamp: DateTime.now(),
                                        isFavorite: true,
                                      );
                                recommender.movieRatingBox
                                    .put(movie.id, updatedRating);
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
                              },
                            ),
                          ],
                        ),
                        // Espace pour s'assurer que les boutons ne sont pas au bord
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackButton({
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? color : Colors.white24,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? color : Colors.white70,
          size: 28,
        ),
      ),
    );
  }
}
