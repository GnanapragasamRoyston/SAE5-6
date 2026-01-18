import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

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

    // Durée préférée
    final preferredDuration = widget.settingsBox.get('preferred_duration');
    if (preferredDuration != null && preferredDuration > 0) {
      filters.add('⏱️ ${preferredDuration}min');
    }

    // Genres préférés
    final initialGenres =
    widget.settingsBox.get('initial_movie_genres') as List<dynamic>?;
    if (initialGenres != null && initialGenres.isNotEmpty) {
      final genresText = initialGenres
          .cast<String>()
          .take(2)
          .map((g) => g[0].toUpperCase() + g.substring(1))
          .join(', ');
      filters.add('🎬 $genresText');
    }

    // Allow surprise (optionnel)
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
                    // 1️⃣ BOUTON SURPRIZ'ME
                    _buildSurpriseMeButton(),

                    // 2️⃣ COMPTEUR FILMS
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

                    // 3️⃣ FILTRES ACTIFS
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

                    // Section 1 : Recommandations
                    _buildArcadeSectionTitle(Icons.favorite, 'RECOMMANDÉS'),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<Box<MovieRating>>(
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

                    // Section 2 : Tous les films
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

                    // Section 3 : Films courts
                    _buildArcadeSectionTitle(
                        Icons.timer, 'FILMS COURTS < 120MIN'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
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
                                style:
                                GoogleFonts.poppins(color: Colors.white),
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
                                tileColor: const Color(0xFF00ff85),
                                moviesPageRef: this,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Section 4 : Films longs
                    _buildArcadeSectionTitle(
                        Icons.timelapse, 'FILMS LONGS >= 120MIN'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
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
                                style:
                                GoogleFonts.poppins(color: Colors.white),
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
                                tileColor: const Color(0xFFb67dff),
                                moviesPageRef: this,
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Section À FAIRE PLUS TARD
                    _buildFavoriteMoviesSection(),

                    const SizedBox(height: 40),

                    // HOME BUTTON
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
              ], // rose → orange
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
                      Icons.play_arrow, // Bouton PLAY blanc
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

  Widget _buildFavoriteMoviesSection() {
    final allMovies = widget.movieBox.values.toList();
    final favoriteMovies = allMovies
        .where((movie) => _favoriteMovieTitles.contains(movie.title))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121b3a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFffa940), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.bookmark, color: Color(0xFFffa940), size: 20),
              const SizedBox(width: 10),
              Text(
                'À FAIRE PLUS TARD',
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
                  color: const Color(0xFFffa940).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${favoriteMovies.length}',
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
        if (favoriteMovies.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun film ajouté',
                style:
                GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteMovies.length,
              itemBuilder: (context, index) {
                final movie = favoriteMovies[index];
                return MovieTile(
                  movie: movie,
                  recommender: _recommender,
                  tileColor: const Color(0xFFffa940),
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
                    onTap: () {
                      widget.moviesPageRef
                          ?._toggleMovieFavorite(widget.movie.title);
                    },
                    child: Icon(
                      widget.moviesPageRef
                          ?._isMovieFavorite(widget.movie.title) ??
                          false
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: widget.moviesPageRef
                          ?._isMovieFavorite(widget.movie.title) ??
                          false
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
}

// =========================================================================
// MovieDetailPage
// =========================================================================

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
                    movie.title,
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
                          movie.title,
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
                              '${movie.rating.toStringAsFixed(1)} / 5',
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
                              '${movie.duration.toInt()} min',
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
                            ...movie.tags.map(
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
                          movie.description.isNotEmpty
                              ? movie.description
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
                                    duration:
                                    const Duration(milliseconds: 800),
                                  ),
                                );
                              },
                            ),
                          ],
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
          color:
          isActive ? color.withOpacity(0.2) : const Color(0xFF121b3a),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? color : const Color(0xFF3cf2ff),
            width: 2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
          ],
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
