import 'package:flutter/material.dart';
import '../../models/saved_game.dart';
import 'game_state.dart';
import 'game_screen_view.dart';
import 'game_dialogs.dart';
import '../../services/audio_service.dart';

/// Widget principal de l'écran de jeu
class GameScreen extends StatefulWidget {
  final String playerName;
  final SavedGame? savedGame;
  final bool resetState;

  const GameScreen({
    super.key,
    required this.playerName,
    this.savedGame,
    this.resetState = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // FocusNode pour détecter les changements de focus
  final FocusNode _focusNode = FocusNode();

  // État du jeu
  late GameState gameState;

  @override
  void initState() {
    super.initState();

    // Initialiser l'état du jeu avec un callback pour mettre à jour l'interface
    gameState = GameState(updateState: () {
      if (mounted) {
        setState(() {});
      }
    });

    // S'inscrire comme observateur pour détecter quand l'application revient au premier plan
    WidgetsBinding.instance.addObserver(this);

    // Initialiser l'écran et charger les données
    _initScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Écouter les événements de navigation comme la reprise de focus
    _focusNode.addListener(_onFocusChange);
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // La page a repris le focus, recharger les données du Kaijin
      gameState.saveGame();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'application revient au premier plan, recharger les données
      gameState.saveGame();
    }
  }

  Future<void> _initScreen() async {
    // Initialiser l'audio
    await gameState.audioService.init();
    await gameState.audioService.startAmbiance();

    // Initialiser le jeu
    await gameState.initializeGame();

    // Démarrer le calcul du taux d'XP par seconde
    gameState.startXpRateCalculation();

    // Initialiser les résonances par défaut si nécessaire
    await gameState.initDefaultResonances();

    // Vérifier l'XP hors-ligne
    if (gameState.offlineXpGained > 0 && !gameState.offlineXpClaimed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOfflineXpDialog();
      });
    }
  }

  void _showOfflineXpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('XP Passive Accumulée'),
        content: Text(
          'Pendant votre absence, vos Résonances ont généré ${gameState.offlineXpGained} XP!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              gameState.claimOfflineXp();
            },
            child: const Text('Récupérer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Nettoyer les ressources
    gameState.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();

    // Se désinscrire de l'observateur
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScreenView(
      gameState: gameState,
      playerName: widget.playerName,
      focusNode: _focusNode,
    );
  }
}
