import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/board_game.dart';

class JeuxPage extends StatelessWidget {
  final Box<BoardGame> boardGameBox;

  const JeuxPage({super.key, required this.boardGameBox});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jeux"),
        backgroundColor: Colors.black,
        elevation: 0,
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
              // Cube orange
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
                      "Jeux",
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

              // Ligne 1 : Tous les Jeux
              const Text(
                "Tous les Jeux",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: boardGameBox.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun jeu chargé",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: boardGameBox.length,
                        itemBuilder: (context, index) {
                          final game = boardGameBox.getAt(index);
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game?.title ?? "Jeu",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "⭐ ${game?.rating.toStringAsFixed(1)}",
                                    style: const TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${game?.minPlayers}-${game?.maxPlayers} joueurs",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${game?.avgDuration.toInt()}min",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),

              // Ligne 2 : Jeux avec les meilleures notes
              const Text(
                "Jeux avec les meilleures notes",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: boardGameBox.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun jeu chargé",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (boardGameBox.length > 5
                            ? 5
                            : boardGameBox.length),
                        itemBuilder: (context, index) {
                          final games = boardGameBox.values.toList();
                          games.sort((a, b) => b.rating.compareTo(a.rating));
                          final game = games[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "⭐ ${game.rating.toStringAsFixed(1)}",
                                    style: const TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${game.minPlayers}-${game.maxPlayers} joueurs",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${game.avgDuration.toInt()}min",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),

              // Ligne 3 : Jeux les plus simples
              const Text(
                "Jeux les plus simples",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: boardGameBox.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun jeu chargé",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (boardGameBox.length > 5
                            ? 5
                            : boardGameBox.length),
                        itemBuilder: (context, index) {
                          final games = boardGameBox.values.toList();
                          games.sort(
                            (a, b) => a.complexity.compareTo(b.complexity),
                          );
                          final game = games[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "⭐ ${game.rating.toStringAsFixed(1)}",
                                    style: const TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${game.minPlayers}-${game.maxPlayers} joueurs",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Complexité: ${game.complexity.toStringAsFixed(1)}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 30),

              // Bouton Home
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.purple,
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
