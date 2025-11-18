import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(description),
            if (onTap != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onTap,
                child: const Text('Plus de détails'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
