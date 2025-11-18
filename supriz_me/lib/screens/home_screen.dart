import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supriz Me'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenue sur Supriz Me!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers l'écran de recommandation
              },
              child: const Text('Obtenir une recommandation'),
            ),
          ],
        ),
      ),
    );
  }
}
