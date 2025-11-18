import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/activity.dart';

class ActivitePage extends StatelessWidget {
  final Box<Activity> activityBox;

  const ActivitePage({super.key, required this.activityBox});

  /// Formate la durée en minutes vers un format lisible (ex: "2h 30min")
  String _formatDuration(double minutes) {
    final mins = minutes.toInt();
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;

    if (hours == 0) {
      return '${remainingMins}min';
    } else if (remainingMins == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${remainingMins}min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activité"),
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
                      "Activité",
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

              // Ligne 1 : Toutes les Activités
              const Text(
                "Toutes les Activités",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: activityBox.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucune activité chargée",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: activityBox.length,
                        itemBuilder: (context, index) {
                          final activity = activityBox.getAt(index);
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
                                    activity?.title ?? "Activité",
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
                                    "📍 ${activity?.category}",
                                    style: const TextStyle(
                                      color: Colors.cyan,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${activity?.minParticipants}-${activity?.maxParticipants} pers.",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "⏱️ ${_formatDuration(activity?.duration ?? 0)}",
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

              // Ligne 2 : Activités rapides (< 1h)
              const Text(
                "Activités rapides (< 1h)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: activityBox.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucune activité chargée",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final rapidActivities = activityBox.values
                              .where((a) => a.duration < 60)
                              .toList();
                          if (rapidActivities.isEmpty) {
                            return const Center(
                              child: Text(
                                "Aucune activité rapide",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: rapidActivities.length > 5
                                ? 5
                                : rapidActivities.length,
                            itemBuilder: (context, index) {
                              final activity = rapidActivities[index];
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.title,
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
                                        "📍 ${activity.category}",
                                        style: const TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "${activity.minParticipants}-${activity.maxParticipants} pers.",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "⏱️ ${_formatDuration(activity.duration)}",
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
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),

              // Ligne 3 : Activités pour groupes
              const Text(
                "Activités pour groupes",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: activityBox.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucune activité chargée",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final groupActivities = activityBox.values
                              .where((a) => a.minParticipants > 1)
                              .toList();
                          if (groupActivities.isEmpty) {
                            return const Center(
                              child: Text(
                                "Aucune activité groupe",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: groupActivities.length > 5
                                ? 5
                                : groupActivities.length,
                            itemBuilder: (context, index) {
                              final activity = groupActivities[index];
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.title,
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
                                        "📍 ${activity.category}",
                                        style: const TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "${activity.minParticipants}-${activity.maxParticipants} pers.",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "⏱️ ${_formatDuration(activity.duration)}",
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
                    backgroundColor: Colors.blue,
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
