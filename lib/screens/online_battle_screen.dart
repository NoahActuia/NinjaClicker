import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/kaijin.dart';
import '../models/technique.dart';
import '../styles/kai_colors.dart';
import '../services/kaijin_service.dart';
import '../services/challenge_service.dart';
import 'combat/combat_appbar_background.dart';

class OnlineBattleScreen extends StatefulWidget {
  final String challengeId;
  final String opponentId;
  final bool isChallenger;
  final String kaijinId;

  const OnlineBattleScreen({
    Key? key,
    required this.challengeId,
    required this.opponentId,
    required this.isChallenger,
    required this.kaijinId,
  }) : super(key: key);

  @override
  _OnlineBattleScreenState createState() => _OnlineBattleScreenState();
}

class _OnlineBattleScreenState extends State<OnlineBattleScreen>
    with TickerProviderStateMixin {
  final KaijinService _kaijinService = KaijinService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription _battleSubscription;

  // État du combat
  Kaijin? _playerKaijin;
  Kaijin? _opponentKaijin;
  List<Technique> _playerTechniques = [];
  List<Technique> _opponentTechniques = [];
  bool _isPlayerTurn = false;
  bool _isLoading = true;
  String _battleStatus = '';
  double _playerKai = 100;
  double _opponentKai = 100;
  double _playerMaxKai = 100;
  double _opponentMaxKai = 100;
  bool _isAttacking = false;
  bool _isDefending = false;
  int _playerShieldTurns = 0;
  int _opponentShieldTurns = 0;
  Map<String, int> _cooldowns = {};
  String _combatMessage = "Le combat commence!";
  List<String> _combatLog = [];

  // Contrôleurs d'animation
  late AnimationController _playerAttackController;
  late AnimationController _enemyAttackController;
  late AnimationController _playerKaiRegenController;
  late AnimationController _enemyKaiRegenController;
  late AnimationController _playerHealController;
  late AnimationController _enemyHealController;
  late AnimationController _shieldController;

  // Animations
  late Animation<double> _playerAttackAnimation;
  late Animation<double> _enemyAttackAnimation;
  late Animation<double> _playerKaiRegenAnimation;
  late Animation<double> _enemyKaiRegenAnimation;
  late Animation<double> _playerHealAnimation;
  late Animation<double> _enemyHealAnimation;
  late Animation<double> _shieldAnimation;

  // Audio players
  late AudioPlayer _attackPlayer;
  late AudioPlayer _shieldPlayer;
  late AudioPlayer _healPlayer;
  late AudioPlayer _kaiRegenPlayer;
  late AudioPlayer _victoryPlayer;
  late AudioPlayer _defeatPlayer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAudioPlayers();
    _initializeBattle();
    _listenToBattleUpdates();
  }

  void _initializeAnimations() {
    // Initialiser les contrôleurs d'animation
    _playerAttackController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _enemyAttackController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _playerKaiRegenController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _enemyKaiRegenController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _playerHealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _enemyHealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shieldController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Configurer les animations
    _playerAttackAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _playerAttackController,
        curve: Curves.easeInOut,
      ),
    );
    _enemyAttackAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enemyAttackController,
        curve: Curves.easeInOut,
      ),
    );
    _playerKaiRegenAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _playerKaiRegenController,
        curve: Curves.easeInOut,
      ),
    );
    _enemyKaiRegenAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enemyKaiRegenController,
        curve: Curves.easeInOut,
      ),
    );
    _playerHealAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _playerHealController,
        curve: Curves.easeInOut,
      ),
    );
    _enemyHealAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enemyHealController,
        curve: Curves.easeInOut,
      ),
    );
    _shieldAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _shieldController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initializeAudioPlayers() {
    _attackPlayer = AudioPlayer();
    _shieldPlayer = AudioPlayer();
    _healPlayer = AudioPlayer();
    _kaiRegenPlayer = AudioPlayer();
    _victoryPlayer = AudioPlayer();
    _defeatPlayer = AudioPlayer();
  }

  Future<void> _initializeBattle() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Charger les données des deux Kaijins
      final playerKaijin = await _kaijinService.getKaijinById(widget.kaijinId);
      final opponentKaijin =
          await _kaijinService.getKaijinById(widget.opponentId);

      if (playerKaijin == null || opponentKaijin == null) {
        throw Exception('Impossible de charger les données des combattants');
      }

      // Charger les techniques des deux Kaijins
      final playerTechniques =
          await _kaijinService.getKaijinTechniques(widget.kaijinId);
      final opponentTechniques =
          await _kaijinService.getKaijinTechniques(widget.opponentId);

      // Initialiser l'état du combat dans Firestore
      await _firestore.collection('battles').doc(widget.challengeId).set({
        'challengeId': widget.challengeId,
        'player1Id': widget.isChallenger ? userId : widget.opponentId,
        'player2Id': widget.isChallenger ? widget.opponentId : userId,
        'player1Kai': 100,
        'player2Kai': 100,
        'player1Shield': 0,
        'player2Shield': 0,
        'player1Techniques':
            playerTechniques.map((t) => t.toFirestore()).toList(),
        'player2Techniques':
            opponentTechniques.map((t) => t.toFirestore()).toList(),
        'player1Cooldowns': playerTechniques
            .map((t) => {t.id: 0})
            .reduce((a, b) => {...a, ...b}),
        'player2Cooldowns': opponentTechniques
            .map((t) => {t.id: 0})
            .reduce((a, b) => {...a, ...b}),
        'currentTurn': widget.isChallenger ? 'player1' : 'player2',
        'status': 'active',
        'lastAction': null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _playerKaijin = playerKaijin;
        _opponentKaijin = opponentKaijin;
        _playerTechniques = playerTechniques;
        _opponentTechniques = opponentTechniques;
        _isPlayerTurn = widget.isChallenger;
        _isLoading = false;
      });

      // Son de début de combat
      await _attackPlayer.play(AssetSource('sounds/battle_start.mp3'));
    } catch (e) {
      print('Erreur lors de l\'initialisation du combat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'initialisation du combat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _listenToBattleUpdates() {
    _battleSubscription = _firestore
        .collection('battles')
        .doc(widget.challengeId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final isPlayer1 = widget.isChallenger;
      final lastAction = data['lastAction'] as Map<String, dynamic>?;

      // Jouer les animations appropriées selon l'action
      if (lastAction != null) {
        final actionType = lastAction['type'] as String;
        final isPlayerAction = (data['currentTurn'] == 'player2') == isPlayer1;

        if (!isPlayerAction) {
          switch (actionType) {
            case 'attack':
              await _enemyAttackController.forward();
              await _enemyAttackController.reverse();
              await _attackPlayer.play(AssetSource('sounds/attack.mp3'));
              break;
            case 'shield':
              await _shieldController.forward();
              await Future.delayed(Duration(milliseconds: 500));
              await _shieldController.reverse();
              await _shieldPlayer.play(AssetSource('sounds/shield.mp3'));
              break;
          }
        }
      }

      setState(() {
        // S'assurer que les points de vie ne descendent pas en dessous de 0
        _playerKai =
            max(0.0, isPlayer1 ? data['player1Kai'] : data['player2Kai']);
        _opponentKai =
            max(0.0, isPlayer1 ? data['player2Kai'] : data['player1Kai']);
        _playerShieldTurns =
            isPlayer1 ? data['player1Shield'] : data['player2Shield'];
        _opponentShieldTurns =
            isPlayer1 ? data['player2Shield'] : data['player1Shield'];
        _isPlayerTurn = (data['currentTurn'] == 'player1') == isPlayer1;
        _battleStatus = data['status'];

        // Mettre à jour les cooldowns
        final playerCooldowns =
            isPlayer1 ? data['player1Cooldowns'] : data['player2Cooldowns'];
        _cooldowns = Map<String, int>.from(playerCooldowns);

        // Mettre à jour le message de combat
        if (lastAction != null) {
          final actionType = lastAction['type'] as String;
          final isPlayerAction =
              (data['currentTurn'] == 'player2') == isPlayer1;

          if (!isPlayerAction) {
            _combatMessage = actionType == 'shield'
                ? "L'adversaire se protège !"
                : "L'adversaire attaque !";
          }
        }

        // Vérifier si le combat est terminé
        if (_battleStatus == 'finished' && data['winner'] != null) {
          _showBattleResult(
              data['winner'] == (isPlayer1 ? 'player1' : 'player2'));
        }
        // Double vérification pour s'assurer qu'un combat se termine si les points de vie sont à 0
        else if (_playerKai <= 0 || _opponentKai <= 0) {
          _endBattle(_opponentKai <= 0);
        }
      });
    });
  }

  Future<void> _performAttack() async {
    if (!_isPlayerTurn || _isAttacking) return;

    setState(() {
      _isAttacking = true;
    });

    try {
      final damage = 20 + (DateTime.now().millisecondsSinceEpoch % 10);

      // Jouer l'animation et le son
      await _attackPlayer.play(AssetSource('sounds/attack.mp3'));
      await _playerAttackController.forward();
      await _playerAttackController.reverse();

      setState(() {
        _combatMessage = "Vous attaquez l'adversaire !";
      });

      // Calculer les nouveaux points de vie (ne pas descendre en dessous de 0)
      final newOpponentKai =
          max(0.0, widget.isChallenger ? _playerKai - damage : _opponentKai);
      final newPlayerKai =
          max(0.0, widget.isChallenger ? _opponentKai : _playerKai - damage);

      // Vérifier si l'attaque va terminer le combat avant de l'envoyer
      final willEndBattle = newOpponentKai <= 0 || newPlayerKai <= 0;

      if (willEndBattle) {
        // Mettre à jour les points de vie et terminer le combat immédiatement
        await _firestore.collection('battles').doc(widget.challengeId).update({
          'player1Kai': widget.isChallenger ? newOpponentKai : newPlayerKai,
          'player2Kai': widget.isChallenger ? newPlayerKai : newOpponentKai,
          'status': 'finished',
          'winner': widget.isChallenger
              ? (newOpponentKai <= 0 ? 'player2' : 'player1')
              : (newPlayerKai <= 0 ? 'player1' : 'player2'),
          'lastAction': {
            'type': 'attack',
            'damage': damage,
            'timestamp': FieldValue.serverTimestamp(),
          },
        });

        // Afficher le résultat immédiatement
        await _endBattle(newOpponentKai <= 0);
      } else {
        // Continuer le combat normalement
        await _firestore.collection('battles').doc(widget.challengeId).update({
          'player1Kai': widget.isChallenger ? newOpponentKai : newPlayerKai,
          'player2Kai': widget.isChallenger ? newPlayerKai : newOpponentKai,
          'currentTurn': widget.isChallenger ? 'player2' : 'player1',
          'lastAction': {
            'type': 'attack',
            'damage': damage,
            'timestamp': FieldValue.serverTimestamp(),
          },
        });
      }
    } catch (e) {
      print('Erreur lors de l\'attaque: $e');
    } finally {
      setState(() {
        _isAttacking = false;
      });
    }
  }

  Future<void> _performDefense() async {
    if (!_isPlayerTurn || _isDefending) return;

    setState(() {
      _isDefending = true;
    });

    try {
      final healing = 15;

      // Jouer l'animation et le son
      await _shieldPlayer.play(AssetSource('sounds/shield.mp3'));
      await _shieldController.forward();
      await Future.delayed(Duration(milliseconds: 500));
      await _shieldController.reverse();

      setState(() {
        _combatMessage = "Vous vous protégez !";
        _playerShieldTurns = 2;
      });

      await _firestore.collection('battles').doc(widget.challengeId).update({
        'player1Shield': widget.isChallenger ? 2 : _playerShieldTurns,
        'player2Shield': widget.isChallenger ? _playerShieldTurns : 2,
        'currentTurn': widget.isChallenger ? 'player2' : 'player1',
        'lastAction': {
          'type': 'defense',
          'healing': healing,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      print('Erreur lors de la défense: $e');
    } finally {
      setState(() {
        _isDefending = false;
      });
    }
  }

  Future<void> _endBattle(bool playerWon) async {
    if (_battleStatus == 'finished') return; // Éviter les appels multiples

    try {
      // Jouer le son de victoire/défaite
      await _victoryPlayer.play(
        AssetSource(playerWon ? 'sounds/victory.mp3' : 'sounds/defeat.mp3'),
      );

      // Mettre à jour le statut du combat
      await _firestore.collection('battles').doc(widget.challengeId).update({
        'status': 'finished',
        'winner': widget.isChallenger
            ? (playerWon ? 'player1' : 'player2')
            : (playerWon ? 'player2' : 'player1'),
        'endedAt': FieldValue.serverTimestamp(),
      });

      // Afficher le résultat immédiatement
      if (mounted) {
        setState(() {
          _battleStatus = 'finished';
          _showBattleResult(playerWon);
        });
      }
    } catch (e) {
      print('Erreur lors de la fin du combat: $e');
    }
  }

  void _showBattleResult(bool playerWon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: KaiColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                color: playerWon ? KaiColors.success : KaiColors.error,
                width: 2,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  playerWon ? Icons.emoji_events : Icons.warning,
                  color: playerWon ? KaiColors.success : KaiColors.error,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  playerWon ? 'Victoire !' : 'Défaite...',
                  style: TextStyle(
                    color: playerWon ? KaiColors.success : KaiColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerWon
                      ? 'Vous avez vaincu votre adversaire !'
                      : 'Votre adversaire vous a vaincu...',
                  style: TextStyle(
                    color: KaiColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Kai final:',
                  style: TextStyle(
                    color: KaiColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Vous',
                          style: TextStyle(color: KaiColors.textSecondary),
                        ),
                        Text(
                          '${_playerKai.toInt()}',
                          style: TextStyle(
                            color: KaiColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'VS',
                      style: TextStyle(
                        color: KaiColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'Adversaire',
                          style: TextStyle(color: KaiColors.textSecondary),
                        ),
                        Text(
                          '${_opponentKai.toInt()}',
                          style: TextStyle(
                            color: KaiColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      // Retourner à l'écran des défis
                      Navigator.of(context).pop(); // Fermer le dialogue
                      Navigator.of(context)
                          .pop(); // Retourner à l'écran précédent
                    },
                    child: Text(
                      'Retour aux défis',
                      style: TextStyle(
                        color: KaiColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Retourner à l'accueil
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          playerWon ? KaiColors.success : KaiColors.error,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'Retour à l\'accueil',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _useTechnique(Technique technique) async {
    if (!_isPlayerTurn || _cooldowns[technique.id] != 0) return;

    final isPlayer1 = widget.isChallenger;
    final damage = technique.damage + (technique.level * 5);

    try {
      // Jouer l'animation et le son appropriés
      if (technique.conditionGenerated == 'shield') {
        await _shieldPlayer.play(AssetSource('sounds/shield.mp3'));
        await _shieldController.forward();
        await Future.delayed(Duration(milliseconds: 500));
        await _shieldController.reverse();

        setState(() {
          _combatMessage = "Vous activez ${technique.name} !";
        });
      } else {
        await _attackPlayer.play(AssetSource('sounds/attack.mp3'));
        await _playerAttackController.forward();
        await _playerAttackController.reverse();

        setState(() {
          _combatMessage = "Vous utilisez ${technique.name} !";
        });
      }

      // Calculer les nouveaux points de vie (ne pas descendre en dessous de 0)
      final newOpponentKai = technique.conditionGenerated == 'shield'
          ? _opponentKai
          : max(0.0, _opponentKai - damage);

      // Vérifier si la technique va terminer le combat
      final willEndBattle =
          newOpponentKai <= 0 && technique.conditionGenerated != 'shield';

      if (willEndBattle) {
        // Mettre à jour les points de vie et terminer le combat immédiatement
        await _firestore.collection('battles').doc(widget.challengeId).update({
          'status': 'finished',
          'winner': isPlayer1 ? 'player1' : 'player2',
          [isPlayer1 ? 'player2Kai' : 'player1Kai']: newOpponentKai,
          'lastAction': {
            'type': 'attack',
            'technique': technique.toFirestore(),
            'damage': damage,
            'timestamp': FieldValue.serverTimestamp(),
          },
        });

        // Afficher le résultat immédiatement
        await _endBattle(true);
      } else {
        // Préparer les données de mise à jour pour continuer le combat
        Map<String, dynamic> updateData = {
          'currentTurn': isPlayer1 ? 'player2' : 'player1',
          'lastAction': {
            'type':
                technique.conditionGenerated == 'shield' ? 'shield' : 'attack',
            'technique': technique.toFirestore(),
            'damage': damage,
            'timestamp': FieldValue.serverTimestamp(),
          },
        };

        // Ajouter les mises à jour spécifiques selon le type de technique
        if (technique.conditionGenerated == 'shield') {
          updateData[isPlayer1 ? 'player1Shield' : 'player2Shield'] = 2;
        } else {
          updateData[isPlayer1 ? 'player2Kai' : 'player1Kai'] = newOpponentKai;
        }

        // Ajouter la mise à jour du cooldown
        updateData[isPlayer1
            ? 'player1Cooldowns.${technique.id}'
            : 'player2Cooldowns.${technique.id}'] = technique.cooldown;

        // Mettre à jour l'état du combat
        await _firestore
            .collection('battles')
            .doc(widget.challengeId)
            .update(updateData);
      }
    } catch (e) {
      print('Erreur lors de l\'utilisation de la technique: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'utilisation de la technique'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _battleSubscription.cancel();
    _playerAttackController.dispose();
    _enemyAttackController.dispose();
    _playerKaiRegenController.dispose();
    _enemyKaiRegenController.dispose();
    _playerHealController.dispose();
    _enemyHealController.dispose();
    _shieldController.dispose();
    _attackPlayer.dispose();
    _shieldPlayer.dispose();
    _healPlayer.dispose();
    _kaiRegenPlayer.dispose();
    _victoryPlayer.dispose();
    _defeatPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: KaiColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KaiColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: KaiColors.primaryDark,
          elevation: 10,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          flexibleSpace: CombatAppBarBackground(
            missionName: "Combat en ligne",
          ),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Combat en ligne',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: Colors.red.withOpacity(0.5), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _playerKaijin?.power.toString() ?? "0",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/combat_background.png'),
            fit: BoxFit.cover,
            opacity: 0.7,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Effets visuels de fond
                  if (_isPlayerTurn)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              KaiColors.accent.withOpacity(0.1),
                              Colors.transparent,
                              KaiColors.accent.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Joueur
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _playerAttackAnimation,
                        _playerHealAnimation,
                        _playerKaiRegenAnimation,
                      ]),
                      builder: (context, child) {
                        double translateX = _playerAttackAnimation.value * 30.0;
                        double scale = 1.0 + (_playerHealAnimation.value * 0.1);
                        double opacity = 1.0;

                        if (_playerKaiRegenAnimation.value > 0) {
                          opacity =
                              0.8 + (_playerKaiRegenAnimation.value * 0.2);
                        }

                        return Stack(
                          children: [
                            // Effet de bouclier
                            if (_playerShieldTurns > 0)
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _shieldAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            KaiColors.sealColor.withOpacity(
                                                0.5 +
                                                    (_shieldAnimation.value *
                                                        0.3)),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            Transform.translate(
                              offset: Offset(translateX, 0),
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Stack(
                                    children: [
                                      _buildFighterCard(_playerKaijin!,
                                          _playerKai.toInt(), true),

                                      // Effet de régénération
                                      if (_playerKaiRegenAnimation.value > 0)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.green.withOpacity(0.3 *
                                                      _playerKaiRegenAnimation
                                                          .value),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Ennemi
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _enemyAttackAnimation,
                        _enemyHealAnimation,
                        _enemyKaiRegenAnimation,
                      ]),
                      builder: (context, child) {
                        double translateX = _enemyAttackAnimation.value * -30.0;
                        double scale = 1.0 + (_enemyHealAnimation.value * 0.1);
                        double opacity = 1.0;

                        if (_enemyKaiRegenAnimation.value > 0) {
                          opacity = 0.8 + (_enemyKaiRegenAnimation.value * 0.2);
                        }

                        return Stack(
                          children: [
                            // Effet de bouclier
                            if (_opponentShieldTurns > 0)
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _shieldAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            KaiColors.sealColor.withOpacity(
                                                0.5 +
                                                    (_shieldAnimation.value *
                                                        0.3)),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                            Transform.translate(
                              offset: Offset(translateX, 0),
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Stack(
                                    children: [
                                      _buildFighterCard(_opponentKaijin!,
                                          _opponentKai.toInt(), false),

                                      // Effet de régénération
                                      if (_enemyKaiRegenAnimation.value > 0)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.green.withOpacity(0.3 *
                                                      _enemyKaiRegenAnimation
                                                          .value),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Message de combat
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _combatMessage.isNotEmpty ? 1.0 : 0.0,
                        duration: Duration(milliseconds: 300),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: KaiColors.accent.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _combatMessage,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: KaiColors.accent.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Zone des actions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KaiColors.primaryDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Liste des techniques
                  Container(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _playerTechniques.length,
                      itemBuilder: (context, index) {
                        final technique = _playerTechniques[index];
                        final cooldown = _cooldowns[technique.id] ?? 0;
                        final isDisabled = cooldown > 0 || !_isPlayerTurn;

                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: isDisabled
                                ? null
                                : () => _useTechnique(technique),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getTechniqueColor(technique)
                                  .withOpacity(0.8),
                              disabledBackgroundColor: Colors.grey,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  technique.conditionGenerated == 'shield'
                                      ? Icons.shield
                                      : Icons.flash_on,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(technique.name),
                                if (cooldown > 0) ...[
                                  SizedBox(width: 4),
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      cooldown.toString(),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  // Boutons d'action classiques
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        'Attaquer',
                        Icons.flash_on,
                        Colors.red,
                        _performAttack,
                        _isAttacking,
                      ),
                      _buildActionButton(
                        'Défendre',
                        Icons.shield,
                        Colors.blue,
                        _performDefense,
                        _isDefending,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFighterCard(Kaijin kaijin, int kai, bool isPlayer) {
    final shieldTurns = isPlayer ? _playerShieldTurns : _opponentShieldTurns;
    final maxKai = isPlayer ? _playerMaxKai : _opponentMaxKai;

    return Container(
      width: 180,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KaiColors.cardBackground.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isPlayer ? KaiColors.accent : Colors.red,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPlayer ? KaiColors.accent : Colors.red).withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar et nom
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPlayer ? KaiColors.primaryDark : Colors.red.shade900,
                  border: Border.all(
                    color: isPlayer ? KaiColors.accent : Colors.red,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPlayer ? KaiColors.accent : Colors.red)
                          .withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: isPlayer ? KaiColors.accent : Colors.red,
                  size: 30,
                ),
              ),
              if (shieldTurns > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: KaiColors.sealColor,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        shieldTurns.toString(),
                        style: TextStyle(
                          color: KaiColors.sealColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            kaijin.name,
            style: TextStyle(
              color: KaiColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            'Puissance: ${kaijin.power}',
            style: TextStyle(
              color: KaiColors.textSecondary,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 12),

          // Barre de Kai
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kai',
                    style: TextStyle(
                      color: KaiColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$kai / ${maxKai.toInt()}',
                    style: TextStyle(
                      color: KaiColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: kai / maxKai,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    kai > 50
                        ? Colors.green
                        : (kai > 25 ? Colors.orange : Colors.red),
                  ),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isLoading,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton(
          onPressed: _isPlayerTurn && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.8),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLoading) ...[
                SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTechniqueColor(Technique technique) {
    switch (technique.affinity) {
      case 'Flux':
        return KaiColors.fluxColor;
      case 'Fracture':
        return KaiColors.fractureColor;
      case 'Sceau':
        return KaiColors.sealColor;
      case 'Dérive':
        return KaiColors.driftColor;
      case 'Frappe':
        return KaiColors.strikeColor;
      default:
        return KaiColors.accent;
    }
  }
}
