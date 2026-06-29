import 'package:flutter/material.dart';
import '../styles/kai_colors.dart';

/// Affiché quand Firebase n'est pas supporté (ex: Linux desktop).
class UnsupportedPlatformScreen extends StatelessWidget {
  final String message;

  const UnsupportedPlatformScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.desktop_windows, size: 72, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Plateforme non supportée',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText(
                  'cd NinjaClicker\nflutter run -d chrome',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  final String error;

  const FirebaseErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              const Text(
                'Erreur Firebase',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error.isNotEmpty
                    ? error
                    : 'Impossible d\'initialiser Firebase',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaiColors.primaryDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayez avec Chrome : flutter run -d chrome'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
