import 'package:flutter/material.dart';
import '../../game_state.dart';
import '../../../../widgets/settings_dialog.dart';
import '../../../story/story_screen.dart';
import '../../../ranking_screen.dart';
import '../../../technique_tree_screen.dart';
import '../../../combat_techniques_screen.dart';

/// Widget pour le bouton du menu
class AppMenuWidget extends StatelessWidget {
  final GameState gameState;

  const AppMenuWidget({
    Key? key,
    required this.gameState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.white),
      offset: const Offset(0, 40),
      onSelected: (value) {
        switch (value) {
          case 'ranking':
            _openRankingScreen(context);
            break;
          case 'story':
            _goToStoryMode(context);
            break;
          case 'technique_tree':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TechniqueTreeScreen(),
              ),
            ).then((_) {
              // Rafraîchir les données après le retour de l'écran de l'arbre des techniques
              gameState.saveGame(updateConnections: true);
            });
            break;
          case 'combat_techniques':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CombatTechniquesScreen(),
              ),
            ).then((_) {
              // Rafraîchir aussi après le retour de l'écran des techniques de combat
              gameState.saveGame(updateConnections: true);
            });
            break;
          case 'settings':
            _showSettingsDialog(context);
            break;
        }
      },
      itemBuilder: (context) => _buildMenuItems(),
    );
  }

  // Construire les éléments du menu
  List<PopupMenuItem<String>> _buildMenuItems() {
    return [
      const PopupMenuItem(
        value: 'ranking',
        child: Row(
          children: [
            Icon(Icons.emoji_events),
            SizedBox(width: 8),
            Text('Classement'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'story',
        child: Row(
          children: [
            Icon(Icons.book),
            SizedBox(width: 8),
            Text('Mode Histoire'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'technique_tree',
        child: Row(
          children: [
            Icon(Icons.account_tree),
            SizedBox(width: 8),
            Text('Arbre des Techniques'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'combat_techniques',
        child: Row(
          children: [
            Icon(Icons.sports_kabaddi),
            SizedBox(width: 8),
            Text('Techniques de Combat'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'settings',
        child: Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Paramètres'),
          ],
        ),
      ),
    ];
  }

  // Méthode pour ouvrir l'écran de classement
  void _openRankingScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RankingScreen()),
    );
  }

  // Méthode pour aller au mode histoire
  void _goToStoryMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryScreen(
          puissance: gameState.power,
          onMissionComplete: (
            missionPuissance,
            missionClones,
            missionTechniques,
          ) {
            gameState.power += missionPuissance;

            // Ajouter les techniques gagnées
            for (var technique in missionTechniques) {
              // Vérifier si la technique existe déjà
              var existingTechnique = gameState.techniques.firstWhere(
                (t) => t.id == technique.id,
                orElse: () => technique,
              );

              if (!gameState.techniques.contains(existingTechnique)) {
                gameState.techniques.add(existingTechnique);
              }

              existingTechnique.niveau += 1;

              // Sauvegarder immédiatement la technique
              if (gameState.currentKaijin != null) {
                gameState.kaijinService.addTechniqueToKaijin(
                  gameState.currentKaijin!.id,
                  existingTechnique.id,
                );
              }
            }

            // Sauvegarde complète après la mission
            gameState.saveGame(updateConnections: true);
          },
        ),
      ),
    );
  }

  // Méthode pour afficher la boîte de dialogue des paramètres
  void _showSettingsDialog(BuildContext context) {
    showSettingsDialog(context: context, audioService: gameState.audioService);
  }
}
