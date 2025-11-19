import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
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

              // Section 1 : Tous les jeux
              const Text(
                "Tous les jeux",
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
                  itemCount: boardGameBox.length > 5 ? 5 : boardGameBox.length,
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
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game?.title ?? 'Jeu',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${game?.minPlayers ?? 1}-${game?.maxPlayers ?? 0} joueurs',
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 12,
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

              // Section 2 : Jeux pour 2 joueurs
              const Text(
                "Jeux pour 2 joueurs",
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
                    final twoPlayerGames = boardGameBox.values
                        .where((g) => g.minPlayers <= 2 && g.maxPlayers >= 2)
                        .toList();
                    return twoPlayerGames.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun jeu pour 2',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: twoPlayerGames.length > 5
                                ? 5
                                : twoPlayerGames.length,
                            itemBuilder: (context, index) {
                              final game = twoPlayerGames[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        game.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${game.minPlayers}-${game.maxPlayers} joueurs',
                                        style: const TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Section 3 : Jeux pour groupes (4+ joueurs)
              const Text(
                "Jeux pour groupes (4+ joueurs)",
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
                    final groupGames = boardGameBox.values
                        .where((g) => g.maxPlayers >= 4)
                        .toList();
                    return groupGames.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun jeu de groupe',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: groupGames.length > 5
                                ? 5
                                : groupGames.length,
                            itemBuilder: (context, index) {
                              final game = groupGames[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        game.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${game.minPlayers}-${game.maxPlayers} joueurs',
                                        style: const TextStyle(
                                          color: Colors.lime,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
