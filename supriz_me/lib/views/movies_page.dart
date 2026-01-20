import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

import '../models/movie.dart';
import '../models/movie_rating.dart';
import '../services/recommendation/movie_recommender.dart';
import 'movie_preference_page.dart';

class MoviesPage extends StatefulWidget {
  final Box movieBox;
  final Box movieRatingBox;
  final Box settingsBox;
  final bool autoSurprizme; // ✅ NOUVEAU PARAMÈTRE

  const MoviesPage({
    super.key,
    required this.movieBox,
    required this.movieRatingBox,
    required this.settingsBox,
    this.autoSurprizme = false, // ✅ PAR DÉFAUT FALSE
  });

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  late MovieRecommender _recommender;
  Set<String> _favoriteMovieTitles = {};
  Set<String> _completedMovieTitles = {};

  static const String _favoriteMoviesKey = 'favorite_movies_titles';
  static const String _completedMoviesKey = 'completed_movies_titles';

  @override
  void initState() {
    super.initState();
    _recommender = MovieRecommender(
      movieBox: widget.movieBox as Box<Movie>,
      movieRatingBox: widget.movieRatingBox as Box<MovieRating>,
      settingsBox: widget.settingsBox,
    );
    _loadFavoriteMovies();
    _loadCompletedMovies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptForMoviePreferences();

      // ✅ AUTO-DÉCLENCHE SURPRIZ'ME SI DEMANDÉ
      if (widget.autoSurprizme) {
        _navigateToSurprizmeMovie();
      }
    });
  }

  void _loadFavoriteMovies() {
    final savedFavorites =
    List<String>.from(widget.settingsBox.get(_favoriteMoviesKey) ?? []);
    _favoriteMovieTitles = savedFavorites.toSet();
  }

  void _loadCompletedMovies() {
    final savedCompleted =
    List<String>.from(widget.settingsBox.get(_completedMoviesKey) ?? []);
    _completedMovieTitles = savedCompleted.toSet();
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

  void _toggleMovieCompleted(String movieTitle) {
    if (_completedMovieTitles.contains(movieTitle)) {
      _completedMovieTitles.remove(movieTitle);
    } else {
      _completedMovieTitles.add(movieTitle);
    }

    widget.settingsBox.put(_completedMoviesKey, _completedMovieTitles.toList());
    setState(() {});
  }

  bool _isMovieCompleted(String movieTitle) {
    return _completedMovieTitles.contains(movieTitle);
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
      widget.settingsBox.delete('preferred_duration'),
      widget.settingsBox.delete('allow_surprise'),
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovieDetailPage(
            movie: surprizmeMovie,
            recommender: _recommender,
            moviesPageRef: this,
          ),
        ),
      ).then((_) {
        setState(() {});
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun film "Surprizme" disponible pour le moment.'),
        ),
      );
    }
  }

  String _buildFiltersText() {
    List<String> filters = [];
    final hasPrefsBeenSet =
    widget.settingsBox.get('movie_prefs_initialized', defaultValue: false);
    if (!hasPrefsBeenSet) {
      return 'Aucun filtre actif';
    }

    final preferredDuration = widget.settingsBox.get('preferred_duration');
    if (preferredDuration != null && preferredDuration > 0) {
      filters.add('⏱️ ${preferredDuration}min');
    }

    final initialGenres =
    widget.settingsBox.get('initial_movie_genres') as List?;
    if (initialGenres != null && initialGenres.isNotEmpty) {
      final genresText = initialGenres
          .cast<String>()
          .take(2)
          .map((g) => g[0].toUpperCase() + g.substring(1))
          .join(', ');
      filters.add('🎬 $genresText');
    }

    final allowSurprise = widget.settingsBox.get('allow_surprise');
    if (allowSurprise != null && !allowSurprise) {
      filters.add('🎲 Surprises OFF');
    }

    return filters.isEmpty ? 'Aucun filtre actif' : filters.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final hasPrefsBeenSet =
    widget.settingsBox.get('movie_prefs_initialized', defaultValue: false);
    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            center: Alignment(0, -0.5),
            colors: [
              Color(0xFF101738),
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
                    _buildSurpriseMeButton(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121b3a),
                        borderRadius: BorderRadius.circular(16),
                        border:
                        Border.all(color: const Color(0xFF3cf2ff), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00e0ff).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '${widget.movieBox.length}',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 24,
                              color: const Color(0xFF3cf2ff),
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "FILMS DISPO",
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (hasPrefsBeenSet)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121b3a),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF3cf2ff).withOpacity(0.5)),
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

                    _buildArcadeSectionTitle(Icons.favorite, 'RECOMMANDÉS'),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<Box>(
                      valueListenable: widget.movieRatingBox.listenable(),
                      builder: (context, box, child) {
                        final recommendedMovies =
                        _recommender.getRecommendedMovies(count: 5);

                        if (recommendedMovies.isEmpty && !hasPrefsBeenSet) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'Sélectionnez vos genres favoris pour afficher vos premières recommandations.',
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        if (recommendedMovies.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'Aimez ou n\'aimez pas des films ci-dessous pour plus de recommandations !',
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 170,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recommendedMovies.length,
                            itemBuilder: (context, index) {
                              final movie = recommendedMovies[index];
                              return MovieTile(
                                movie: movie,
                                recommender: _recommender,
                                tileColor: const Color(0xFFff4b81),
                                moviesPageRef: this,
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 25),

                    _buildArcadeSectionTitle(Icons.movie, 'TOUS LES FILMS'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.movieBox.length > 5
                            ? 5
                            : widget.movieBox.length,
                        itemBuilder: (context, index) {
                          final movie = widget.movieBox.getAt(index);
                          if (movie == null) return const SizedBox.shrink();
                          return MovieTile(
                            movie: movie,
                            recommender: _recommender,
                            tileColor: const Color(0xFF00c2ff),
                            moviesPageRef: this,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),

                   if (hasPrefsBeenSet) ...(() {
                    // 1. Récupérer la liste des genres choisis par l'utilisateur
                    final List<String> selectedGenres = 
                        (widget.settingsBox.get('initial_movie_genres') as List?)?.cast<String>() ?? [];

                    // 2. Créer une section pour chaque genre
                    return selectedGenres.map((genreName) {
                      // Filtrer les films de la base de données pour ce genre précis
                      final genreMovies = widget.movieBox.values
                          .where((m) => m.genre.toLowerCase() == genreName.toLowerCase())
                          .take(6) // On en prend 6 pour la ligne
                          .toList();

                      // Si on n'a pas de films pour ce genre, on n'affiche pas la catégorie
                      if (genreMovies.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildArcadeSectionTitle(Icons.label_important, 'TOP ${genreName.toUpperCase()}'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 170,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: genreMovies.length,
                              itemBuilder: (context, index) {
                                return MovieTile(
                                  movie: genreMovies[index],
                                  recommender: _recommender,
                                  tileColor: const Color(0xFF00ff85), // Couleur arcade verte
                                  moviesPageRef: this,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 25),
                        ],
                      );
                    }).toList();
                  }()),

                    const SizedBox(height: 25),

                    _buildCompletedMoviesSection(),

                    const SizedBox(height: 40),

                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF121b3a),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF3cf2ff), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00e0ff).withOpacity(0.4),
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
          colors: [Color(0xFFff4b81), Color(0xFFff9f4b)],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
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
              child: const Icon(Icons.movie, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "FILMS ARCADE",
                style: GoogleFonts.pressStart2p(
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
              onPressed: _resetAppPreferences,
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 22),
              onPressed: _navigateToPreferencePage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurpriseMeButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFff0080),
                Color(0xFFff6600)
              ],
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
              onTap: _navigateToSurprizmeMovie,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.black87,
                      size: 24,
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

  Widget _buildArcadeSectionTitle(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121b3a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3cf2ff), width: 1.5),
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
        ],
      ),
    );
  }

  Widget _buildCompletedMoviesSection() {
    final allMovies = widget.movieBox.values.toList();
    final completedMovies = allMovies
        .where((movie) => _completedMovieTitles.contains(movie.title))
        .toList();

    if (completedMovies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121b3a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00FF88), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 20),
              const SizedBox(width: 10),
              Text(
                'FILMS COMPLÉTÉS',
                style: GoogleFonts.pressStart2p(
                  fontSize: 11,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${completedMovies.length}',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: completedMovies.length,
            itemBuilder: (context, index) {
              final movie = completedMovies[index];
              return MovieTile(
                movie: movie,
                recommender: _recommender,
                tileColor: const Color(0xFF00FF88),
                moviesPageRef: this,
              );
            },
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// MovieTile - AUCUN CHANGEMENT
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
          moviesPageRef: widget.moviesPageRef,
        ),
      ),
    ).then((_) {
      widget.moviesPageRef?.setState(() {});
      setState(() {});
    });
  }

  void _handleFeedback(bool isLiked) {
    final currentRating = widget.recommender.movieRatingBox.get(widget.movie.id);
    if (currentRating != null && currentRating.isLiked == isLiked) {
      widget.recommender.movieRatingBox.delete(widget.movie.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating supprimé'),
          backgroundColor: Colors.grey,
          duration: Duration(milliseconds: 800),
        ),
      );
    } else {
      widget.recommender.saveRating(widget.movie.id, isLiked);
      final message = isLiked ? '✓ Like enregistré' : '✗ Dislike enregistré';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.grey.shade700,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void _handleFavoriteToggle() {
    widget.moviesPageRef?._toggleMovieFavorite(widget.movie.title);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        widget.moviesPageRef?._isMovieFavorite(widget.movie.title) ?? false;

    return ValueListenableBuilder<Box>(
      valueListenable: widget.recommender.movieRatingBox.listenable(),
      builder: (context, box, child) {
        final currentRating =
        widget.recommender.movieRatingBox.get(widget.movie.id);
        final isLiked = currentRating?.isLiked ?? false;
        final isDisliked = currentRating != null && !currentRating.isLiked;

        return Container(
          margin: const EdgeInsets.only(right: 12),
          width: 160,
          height: 170,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.tileColor.withOpacity(0.3),
                widget.tileColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.tileColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.tileColor.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _navigateToMovieDetail(context),
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
                        Text(
                          widget.movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFffd700), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.movie.rating.toStringAsFixed(1)}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFffd700),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.movie.duration.toInt()}min',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.movie.genre,
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
                      GestureDetector(
                        onTap: () => _handleFeedback(false),
                        child: Icon(
                          Icons.thumb_down,
                          size: 18,
                          color: isDisliked ? Colors.pinkAccent : Colors.white38,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _handleFeedback(true),
                        child: Icon(
                          Icons.thumb_up,
                          size: 18,
                          color: isLiked ? Colors.greenAccent : Colors.white38,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleFavoriteToggle,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? Colors.red : Colors.white38,
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

// =========================================================================
// MovieDetailPage - AUCUN CHANGEMENT
// =========================================================================
class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  final MovieRecommender recommender;
  final _MoviesPageState? moviesPageRef;

  const MovieDetailPage({
    super.key,
    required this.movie,
    required this.recommender,
    this.moviesPageRef,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  bool get _isFavorite =>
      widget.moviesPageRef?._isMovieFavorite(widget.movie.title) ?? false;

  bool get _isCompleted =>
      widget.moviesPageRef?._isMovieCompleted(widget.movie.title) ?? false;

  void _toggleFavorite() {
    widget.moviesPageRef?._toggleMovieFavorite(widget.movie.title);
    setState(() {});
  }

  void _toggleCompleted() {
    widget.moviesPageRef?._toggleMovieCompleted(widget.movie.title);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: widget.recommender.movieRatingBox.listenable(),
      builder: (context, box, child) {
        final currentRating =
        widget.recommender.movieRatingBox.get(widget.movie.id);
        final isLiked = currentRating?.isLiked ?? false;
        final isDisliked = currentRating != null && !currentRating.isLiked;
        final isFavorite = _isFavorite;
        final isCompleted = _isCompleted;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                radius: 1.2,
                center: Alignment(0, -0.5),
                colors: [
                  Color(0xFF101738),
                  Color(0xFF050814),
                ],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text(
                    widget.movie.title,
                    style: GoogleFonts.pressStart2p(
                        fontSize: 12, color: Colors.white),
                  ),
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
                          widget.movie.title,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFffd700), size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.movie.rating.toStringAsFixed(1)} / 5',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Icon(Icons.access_time,
                                color: Color(0xFF00ff85), size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.movie.duration.toInt()} min',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: [
                            ...widget.movie.tags.map(
                                  (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3cf2ff)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFF3cf2ff)
                                          .withOpacity(0.5)),
                                ),
                                child: Text(
                                  tag,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'SYNOPSIS',
                          style: GoogleFonts.pressStart2p(
                            color: const Color(0xFF3cf2ff),
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.movie.description.isNotEmpty
                              ? widget.movie.description
                              : 'Description non disponible.',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.6,
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
                                if (currentRating != null &&
                                    !currentRating.isLiked) {
                                  widget.recommender.movieRatingBox
                                      .delete(widget.movie.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Dislike supprimé'),
                                      backgroundColor: Colors.grey,
                                      duration: Duration(milliseconds: 800),
                                    ),
                                  );
                                } else {
                                  widget.recommender
                                      .saveRating(widget.movie.id, false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✗ Dislike enregistré !'),
                                      backgroundColor: Colors.grey,
                                      duration: Duration(milliseconds: 800),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildFeedbackButton(
                              icon: Icons.thumb_up_alt_rounded,
                              color: Colors.greenAccent,
                              isActive: isLiked,
                              onTap: () {
                                if (currentRating != null &&
                                    currentRating.isLiked) {
                                  widget.recommender.movieRatingBox
                                      .delete(widget.movie.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Like supprimé'),
                                      backgroundColor: Colors.grey,
                                      duration: Duration(milliseconds: 800),
                                    ),
                                  );
                                } else {
                                  widget.recommender
                                      .saveRating(widget.movie.id, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✓ Like enregistré !'),
                                      backgroundColor: Colors.grey,
                                      duration: Duration(milliseconds: 800),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildFeedbackButton(
                              icon: Icons.favorite,
                              color: Colors.redAccent,
                              isActive: isFavorite,
                              onTap: _toggleFavorite,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // --- AJOUTER CE BLOC ICI ---
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF121b3a),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF3cf2ff), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00e0ff).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.home, color: Colors.white, size: 32),
                              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                            ),
                          ),
                        ),


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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : const Color(0xFF121b3a),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? color : const Color(0xFF3cf2ff),
            width: 2,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
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