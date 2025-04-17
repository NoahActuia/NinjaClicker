import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../styles/kai_colors.dart';
import 'victory_sequence.dart';

class CombatScreen extends StatefulWidget {
  final Mission mission;
  final Function onComplete;

  const CombatScreen({
    super.key,
    required this.mission,
    required this.onComplete,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  double _playerHealth = 100;
  double _enemyHealth = 100;
  bool _isPlayerTurn = true;
  bool _showingVictorySequence = false;

  @override
  Widget build(BuildContext context) {
    if (_showingVictorySequence) {
      return VictorySequence(
        onComplete: () {
          widget.onComplete();
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image de fond
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/academy.webp'),
                fit: BoxFit.cover,
                opacity: 0.7,
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // Barre de navigation
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton retour
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // Titre du combat
                      Text(
                        widget.mission.titre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Espace pour symétrie
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Zone de combat
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Barre de vie de l'ennemi
                      _buildHealthBar(_enemyHealth, "Adversaire", Colors.red),

                      // Zone des personnages
                      const SizedBox(height: 40),

                      // Barre de vie du joueur
                      _buildHealthBar(_playerHealth, "Vous", KaiColors.accent),

                      // Actions de combat
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              "Attaque",
                              Icons.sports_kabaddi,
                              () => _performAction('attack'),
                              Colors.red[700]!,
                            ),
                            _buildActionButton(
                              "Défense",
                              Icons.shield,
                              () => _performAction('defend'),
                              Colors.blue[700]!,
                            ),
                            _buildActionButton(
                              "Technique",
                              Icons.auto_awesome,
                              () => _performAction('technique'),
                              Colors.purple[700]!,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(double health, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: health / 100,
                backgroundColor: Colors.black54,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: _isPlayerTurn ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _performAction(String action) {
    if (!_isPlayerTurn) return;

    setState(() {
      switch (action) {
        case 'attack':
          _enemyHealth = (_enemyHealth - 20).clamp(0.0, 100.0);
          break;
        case 'defend':
          _playerHealth = (_playerHealth + 10).clamp(0.0, 100.0);
          break;
        case 'technique':
          _enemyHealth = (_enemyHealth - 30).clamp(0.0, 100.0);
          break;
      }

      _isPlayerTurn = false;
    });

    // Vérifier si le combat est terminé
    if (_enemyHealth <= 0) {
      _showVictoryDialog();
      return;
    }

    // Tour de l'ennemi
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _playerHealth = (_playerHealth - 15).clamp(0.0, 100.0);
        _isPlayerTurn = true;
      });

      // Vérifier si le joueur a perdu
      if (_playerHealth <= 0) {
        _showDefeatDialog();
      }
    });
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "Victoire !",
          style: TextStyle(
            color: KaiColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 64),
            SizedBox(height: 16),
            Text("Vous avez remporté le combat !"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showingVictorySequence = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KaiColors.accent,
            ),
            child: const Text("Continuer"),
          ),
        ],
      ),
    );
  }

  void _showDefeatDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "Défaite",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text("Vous avez perdu le combat..."),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Réessayer"),
          ),
        ],
      ),
    );
  }
} 