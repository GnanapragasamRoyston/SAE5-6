import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/movie.dart';

class FilmsPage extends StatelessWidget {
  final Box<Movie> movieBox;

  const FilmsPage({super.key, required this.movieBox});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Films"),
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
                      "Films",
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
              const Text(
                "Tous les Films (Données Brutes)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Total: ${movieBox.length} films chargés",
                style: const TextStyle(color: Colors.yellow, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: movieBox.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "❌ Aucun film chargé",
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: movieBox.length > 20 ? 20 : movieBox.length,
                        itemBuilder: (context, index) {
                          final movie = movieBox.getAt(index);
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "[FILM ${index + 1}] ${movie?.title ?? 'Sans titre'}",
                                    style: const TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ID: ${movie?.id}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    "Genre: ${movie?.genre ?? 'N/A'}",
                                    style: const TextStyle(
                                      color: Colors.cyan,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "Note: ${(movie?.rating ?? 0).toStringAsFixed(1)}/5",
                                    style: const TextStyle(
                                      color: Colors.lightGreen,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    "Tags: ${(movie?.tags ?? []).join(', ')}",
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    "Desc: ${(movie?.description ?? '').length > 60 ? '${(movie?.description ?? '').substring(0, 60)}...' : movie?.description ?? ''}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 9,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (movieBox.length > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "... et ${movieBox.length - 20} autres films",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 30),
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
