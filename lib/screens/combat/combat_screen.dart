import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../theme/app_colors.dart';

class CombatScreen extends StatefulWidget {
  final Mission mission;
  final int playerPuissance;
  final Function(Map<String, dynamic>) onVictory;

  const CombatScreen({
    super.key,
    required this.mission,
    required this.playerPuissance,
    required this.onVictory,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  bool _isLoading = false;
  double _playerHealth = 100;
  double _enemyHealth = 100;

  void _simulateCombat() {
    setState(() => _isLoading = true);

    // Simuler un combat basé sur la puissance du joueur et le niveau de l'ennemi
    Future.delayed(const Duration(seconds: 2), () {
      final bool playerWins = widget.playerPuissance >= widget.mission.enemyLevel * 100;

      if (playerWins) {
        widget.onVictory(widget.mission.rewards);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isLoading = false;
          _playerHealth = 0;
        });
      }
    });
  }

  void _instantWin() {
    widget.onVictory(widget.mission.rewards);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(widget.mission.name),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barres de vie
            _buildHealthBar("Joueur", _playerHealth, Colors.blue),
            const SizedBox(height: 16),
            _buildHealthBar("Ennemi", _enemyHealth, Colors.red),
            
            const Spacer(),
            
            // Description de la mission
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.mission.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons
            if (!_isLoading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _instantWin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text(
                      'VICTOIRE INSTANTANÉE',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _simulateCombat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kaiEnergy,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Text(
                      'COMBATTRE',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 20,
          ),
        ),
      ],
    );
  }
} 