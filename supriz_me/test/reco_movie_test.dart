import 'package:hive_flutter/hive_flutter.dart';

// Models
import 'package:supriz_me/models/movie.dart';
import 'package:supriz_me/models/user_profile.dart';

// Recommendation
import 'package:supriz_me/services/recommendation/film_recommendation.dart';

class RecoTest {
  static Future<void> run() async {

    await Hive.initFlutter();

    Hive.registerAdapter(MovieAdapter());
    Hive.registerAdapter(UserProfileAdapter());

    // Ouvrir boxes temporaires pour le test
    final movieBox = await Hive.openBox<Movie>('test_movies');
    final userBox = await Hive.openBox<UserProfile>('test_users');

    // Nettoyer les anciennes données
    await movieBox.clear();
    await userBox.clear();

    // ---------------------------------------
    // Ajouter des films FAKE pour les tests
    // ---------------------------------------
    movieBox.addAll([
      Movie(
        id: "1",
        title: "Conjuring",
        rating: 78,
        genre: "Horror",
        description: "Test", 
        duration: 50, 
        tags: [],
      ),
      Movie(
        id: "2",
        title: "Annabelle",
        rating: 71,
        genre: "Horror",
        description: "Test", 
        duration: 80, 
        tags: [],
      ),
      Movie(
        id: "3",
        title: "Avatar",
        rating: 82,
        genre: "Sci-Fi",
        description: "Test", 
        duration: 50, 
        tags: [],
      ),
      Movie(
        id: "4",
        title: "Inception",
        rating: 86,
        genre: "Action",
        description: "Test",  
        duration: 80, 
        tags: [],
      ),
    ]);

    // ---------------------------------------
    // Créer un utilisateur pour tester
    // ---------------------------------------
    UserProfile user = UserProfile(
      id: "u1",
      username: "TestUser",
      age: 20,
      preferences: [],
      favoriteIds: [],
      viewedIds: [],
      groupSize: 1,
      filmScores: {},
      genreScores: {},
    );

    userBox.put("u1", user);

    final movies = movieBox.values.toList();

    // ---------------------------------------
    // TEST AVANT INTERACTION
    // ---------------------------------------
    print("\n--- AVANT ---");
    var before = FilmRecommendation.recommend(
      allMovies: movies,
      user: user,
      limit: 4,
    );
    before.forEach((m) => print("➡ ${m.title} (${m.genre})"));


    // ---------------------------------------
    // LIKE un film d’horreur
    // ---------------------------------------
    print("\nLIKE Horror…");
    FilmRecommendation.likeMovie(user, movies[0]);


    // ---------------------------------------
    // TEST APRÈS LIKE
    // ---------------------------------------
    print("\n--- APRÈS LIKE HORROR ---");
    var after = FilmRecommendation.recommend(
      allMovies: movies,
      user: user,
      limit: 4,
    );

    after.forEach((m) => print("🔥 ${m.title} (${m.genre})"));

    print("\n===== FIN DU TEST =====");
  }
}
