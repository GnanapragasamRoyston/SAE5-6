// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supriz_me/main.dart';
import 'package:supriz_me/models/movie.dart';
import 'package:supriz_me/models/activity.dart';
import 'package:supriz_me/models/board_game.dart';
import 'package:supriz_me/models/user_profile.dart';

void main() {
  testWidgets('Supriz Me app launches', (WidgetTester tester) async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(MovieAdapter());
    Hive.registerAdapter(ActivityAdapter());
    Hive.registerAdapter(BoardGameAdapter());
    Hive.registerAdapter(UserProfileAdapter());

    // Open boxes
    final movieBox = await Hive.openBox<Movie>('movies_test');
    final activityBox = await Hive.openBox<Activity>('activities_test');
    final boardGameBox = await Hive.openBox<BoardGame>('board_games_test');
    final userBox = await Hive.openBox<UserProfile>('user_profiles_test');

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        movieBox: movieBox,
        activityBox: activityBox,
        boardGameBox: boardGameBox,
        userBox: userBox,
      ),
    );

    // Verify that the app shows "Supriz Me"
    expect(find.text('Supriz Me'), findsOneWidget);
    expect(find.text('Bienvenue sur Supriz Me!'), findsOneWidget);
  });
}
