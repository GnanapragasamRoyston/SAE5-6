import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  void _navigateToPreferencePage() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MoviePreferencePage(
        settingsBox: widget.settingsBox,
      ),
    ),
  ).then((_) {
    setState(() {}); // recharge l'écran après retour
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

              // Section 1 : Recommandations pour vous
              _buildSectionTitle(
                icon: Icons.favorite,
                label: 'RECOMMANDATIONS POUR VOUS',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ValueListenableBuilder<Box<MovieRating>>(
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
                          style:
                          GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (recommendedMovies.isEmpty) {
                      return Center(
                        child: Text(
                          'Aimez ou n\'aimez pas des films ci-dessous pour plus de recommandations !',
                          style:
                          GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
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
                          tileColor: Colors.redAccent,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

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
                        );
                      },
                    );
                  },
                ),
              ),

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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
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

  Widget _buildSectionTitle({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
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
}

// =========================================================================
// MovieTile
// =========================================================================

class MovieTile extends StatelessWidget {
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
      width: 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tileColor.withOpacity(0.9),
            tileColor.withOpacity(0.6),
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
                movie.title,
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
                  Text(
                    '${movie.rating.toStringAsFixed(1)} / 5',
                    style: GoogleFonts.poppins(
                      color: Colors.yellow,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${movie.duration.toInt()} min',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                movie.genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
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
// MovieDetailPage (reprend ton code existant, juste légère harmonisation)
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
          appBar: AppBar(
            title: Text(movie.title),
            backgroundColor: Colors.blue,
            elevation: 0,
          ),
          body: Container(
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
            child: SingleChildScrollView(
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

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 20),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          recommender.saveRating(movie.id, false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dislike enregistré !'),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.thumb_down,
                          color: isDisliked ? Colors.white : Colors.red,
                        ),
                        label: const Text(
                          'Dislike',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isDisliked ? Colors.red : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          recommender.saveRating(movie.id, true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Like enregistré !'),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.thumb_up,
                          color: isLiked ? Colors.white : Colors.green,
                        ),
                        label: const Text(
                          'Like',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isLiked ? Colors.green : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
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
