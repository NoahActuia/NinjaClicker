import 'package:flutter/material.dart';
import 'combat_screen.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';

/// Extension du CombatScreen pour la gestion des sessions d'entraînement
class TrainingCombatScreen extends StatefulWidget {
  final Mission mission;
  final int playerPuissance;
  final Function(Map<String, dynamic>) onVictory;
  final List<Technique> enemyTechniques;
  final List<Technique> playerTechniques;
  final String enemyName;

  const TrainingCombatScreen({
    Key? key,
    required this.mission,
    required this.playerPuissance,
    required this.onVictory,
    required this.enemyTechniques,
    required this.playerTechniques,
    required this.enemyName,
  }) : super(key: key);

  @override
  State<TrainingCombatScreen> createState() => _TrainingCombatScreenState();
}

class _TrainingCombatScreenState extends State<TrainingCombatScreen> {
  @override
  Widget build(BuildContext context) {
    // Utilise l'écran de combat standard mais avec des paramètres spécifiques à l'entraînement
    return CombatScreen(
      mission: widget.mission,
      playerPuissance: widget.playerPuissance,
      onVictory: widget.onVictory,
      // Passer les techniques de l'ennemi et du joueur au combat
      customEnemyTechniques: widget.enemyTechniques,
      customPlayerTechniques: widget.playerTechniques,
      customEnemyName: widget.enemyName,
      isTrainingMode: true,
    );
  }
}

/// Fonction utilitaire pour naviguer vers un combat d'entraînement
void navigateToTrainingCombat({
  required BuildContext context,
  required Mission mission,
  required int playerPuissance,
  required Function(Map<String, dynamic>) onVictory,
  required List<Technique> enemyTechniques,
  required List<Technique> playerTechniques,
  required String enemyName,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TrainingCombatScreen(
        mission: mission,
        playerPuissance: playerPuissance,
        onVictory: onVictory,
        enemyTechniques: enemyTechniques,
        playerTechniques: playerTechniques,
        enemyName: enemyName,
      ),
    ),
  );
}
