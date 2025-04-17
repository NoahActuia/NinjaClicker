import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../welcome_screen.dart';
import '../../../styles/kai_colors.dart';
import 'app_bar_components/app_bar_background.dart';
import 'app_bar_components/player_profile_widget.dart';
import 'app_bar_components/power_indicator_widget.dart';
import 'app_bar_components/app_menu_widget.dart';
import 'app_bar_components/quit_button_widget.dart';
import 'app_bar_components/kai_tabs_widget.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GameState gameState;
  final String playerName;

  const GameAppBar({
    Key? key,
    required this.gameState,
    required this.playerName,
  }) : super(key: key);

  @override
  Size get preferredSize =>
      const Size.fromHeight(120); // Hauteur pour inclure TabBar

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      backgroundColor: KaiColors.background,
      elevation: 12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      flexibleSpace: const AppBarBackground(),
      title: PlayerProfileWidget(
        playerName: playerName,
        playerLevel: gameState.playerLevel,
      ),
      actions: [
        // Indicateur de puissance
        PowerIndicatorWidget(
            power: gameState.power, formatNumber: gameState.formatNumber),

        // Menu des fonctionnalités
        AppMenuWidget(gameState: gameState),

        // Bouton Quitter
        QuitButtonWidget(onPressed: () => _returnToMainMenu(context)),
      ],
      bottom: const KaiTabsWidget(),
    );
  }

  // Méthode pour retourner au menu principal
  void _returnToMainMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Quitter la partie',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text('Voulez-vous vraiment quitter le jeu ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Sauvegarder automatiquement avant de quitter et mettre à jour les dates de connexion
                await gameState.saveGame(updateConnections: true);

                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KaiColors.primaryDark,
              ),
              child: const Text(
                'Quitter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
