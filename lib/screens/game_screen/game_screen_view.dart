import 'package:flutter/material.dart';
import 'game_state.dart';
import '../../styles/kai_colors.dart';
import '../../widgets/kai_button.dart';
import '../../widgets/settings_dialog.dart';
import 'game_dialogs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../story/story_screen.dart';
import '../ranking_screen.dart';
import '../technique_tree_screen.dart';
import '../combat_techniques_screen.dart';
import '../welcome_screen.dart';
import 'widgets/game_app_bar.dart';
import 'widgets/senseis_tab.dart';
import 'widgets/resonances_tab.dart';

/// Widget qui définit l'interface de l'écran de jeu
class GameScreenView extends StatelessWidget {
  final GameState gameState;
  final String playerName;
  final FocusNode focusNode;

  const GameScreenView({
    Key? key,
    required this.gameState,
    required this.playerName,
    required this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: GameAppBar(
          gameState: gameState,
          playerName: playerName,
        ),
        body: GameScreenMainContent(gameState: gameState),
      ),
    );
  }
}

/// Widget pour le contenu principal de l'écran de jeu
class GameScreenMainContent extends StatefulWidget {
  final GameState gameState;

  const GameScreenMainContent({
    Key? key,
    required this.gameState,
  }) : super(key: key);

  @override
  State<GameScreenMainContent> createState() => _GameScreenMainContentState();
}

class _GameScreenMainContentState extends State<GameScreenMainContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.7),
              Colors.white.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            // Partie supérieure avec le bouton de kai et les stats
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Indicateur de génération XP passive
                  PassiveXpIndicator(
                    xpPerSecond: widget.gameState.xpPerSecondPassive,
                    resonancesCount: widget.gameState.playerResonances
                        .where((r) => r.isUnlocked)
                        .length,
                    hasResonances: widget.gameState.playerResonances.isNotEmpty,
                  ),

                  // Bouton kai
                  Expanded(
                    child: Center(
                      child: KaiButton(
                        onTap: (gainXp) =>
                            widget.gameState.incrementerXp(gainXp),
                        puissance: widget.gameState.currentCombo,
                        totalXP: widget.gameState.totalXP,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section des onglets avec TabBarView
            Expanded(
              flex: 2, // Agrandir la section des Résonances/Senseis
              child: TabBarView(
                children: [
                  // Premier onglet: Résonances
                  ResonancesTab(
                    gameState: widget.gameState,
                    totalXP: widget.gameState.totalXP,
                    resonances: widget.gameState.allResonances,
                    onUnlockResonance: widget.gameState.unlockResonance,
                    onUpgradeResonance: widget.gameState.upgradeResonance,
                    onRefresh: widget.gameState.loadPlayerResonances,
                  ),

                  // Deuxième onglet: Senseis
                  SenseisTab(
                    gameState: widget.gameState,
                    totalXP: widget.gameState.totalXP,
                    senseis: widget.gameState.senseis,
                    onUpdateState: () => setState(() {}),
                    currentKaijin: widget.gameState.currentKaijin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour l'indicateur de génération XP passive
class PassiveXpIndicator extends StatelessWidget {
  final double xpPerSecond;
  final int resonancesCount;
  final bool hasResonances;

  const PassiveXpIndicator({
    Key? key,
    required this.xpPerSecond,
    required this.resonancesCount,
    required this.hasResonances,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: KaiColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: KaiColors.accent.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time,
                color: KaiColors.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Génération passive: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: KaiColors.primaryDark,
                ),
              ),
              Text(
                '${xpPerSecond.toStringAsFixed(3)} XP/s',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          if (hasResonances) ...[
            const SizedBox(height: 4),
            Text(
              'Somme des résonances actives ($resonancesCount)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
