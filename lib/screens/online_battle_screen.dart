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
import '../theme/app_colors.dart';
import 'online_battle_widgets.dart';

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
  Timer? _turnTimer;

  // État du combat
  Kaijin? _playerKaijin;
  Kaijin? _opponentKaijin;
  List<Technique> _playerTechniques = [];
  List<Technique> _opponentTechniques = [];
  bool _isPlayerTurn = false;
  bool _isLoading = true;
  String _battleStatus = '';

  // Points de vie
  double _playerHP = 1000;
  double _opponentHP = 1000;
  double _playerMaxHP = 1000;
  double _opponentMaxHP = 1000;

  // Ressource Kai
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
  late Animation<Offset> _playerAttackAnimation;
  late Animation<Offset> _enemyAttackAnimation;
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
    _playerAttackAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.3, 0),
    ).animate(
      CurvedAnimation(
        parent: _playerAttackController,
        curve: Curves.easeInOut,
      ),
    );
    _enemyAttackAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).animate(
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
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Charger les données des deux Kaijins
      final playerKaijin = await _kaijinService.getKaijinById(widget.kaijinId);
      final opponentKaijin =
          await _kaijinService.getKaijinById(widget.opponentId);

      if (playerKaijin == null || opponentKaijin == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Erreur : Impossible de charger les données des combattants'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Charger toutes les techniques disponibles
      final allTechniques =
          await _kaijinService.getKaijinTechniques(widget.kaijinId);
      final opponentTechniques =
          await _kaijinService.getKaijinTechniques(widget.opponentId);

      // Récupérer les techniques actives sélectionnées pour le joueur
      final snapshot = await FirebaseFirestore.instance
          .collection('kaijins')
          .doc(widget.kaijinId)
          .collection('combat_settings')
          .doc('techniques')
          .get();

      List<Technique> selectedTechniques = [];
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final List<String> activeIds =
            List<String>.from(data['active_techniques'] ?? []);
        selectedTechniques = allTechniques
            .where((t) => activeIds.contains(t.id) && t.type == 'active')
            .toList();
      }

      // Si aucune technique n'est sélectionnée, utiliser les techniques actives par défaut
      if (selectedTechniques.isEmpty) {
        selectedTechniques = allTechniques
            .where((t) => t.type == 'active' && t.isDefault)
            .take(4)
            .toList();
      }

      // Faire de même pour l'adversaire
      final opponentSnapshot = await FirebaseFirestore.instance
          .collection('kaijins')
          .doc(widget.opponentId)
          .collection('combat_settings')
          .doc('techniques')
          .get();

      List<Technique> selectedOpponentTechniques = [];
      if (opponentSnapshot.exists) {
        final data = opponentSnapshot.data() as Map<String, dynamic>;
        final List<String> activeIds =
            List<String>.from(data['active_techniques'] ?? []);
        selectedOpponentTechniques = opponentTechniques
            .where((t) => activeIds.contains(t.id) && t.type == 'active')
            .toList();
      }

      // Si aucune technique n'est sélectionnée pour l'adversaire, utiliser les techniques actives par défaut
      if (selectedOpponentTechniques.isEmpty) {
        selectedOpponentTechniques = opponentTechniques
            .where((t) => t.type == 'active' && t.isDefault)
            .take(4)
            .toList();
      }

      // Initialiser les cooldowns
      Map<String, int> initialCooldowns = {};
      for (var technique in selectedTechniques) {
        initialCooldowns[technique.id] = 0;
      }

      // Initialiser l'état du combat dans Firestore
      await _firestore.collection('battles').doc(widget.challengeId).set({
        'challengeId': widget.challengeId,
        'player1Id': widget.isChallenger ? userId : widget.opponentId,
        'player2Id': widget.isChallenger ? widget.opponentId : userId,
        'player1HP': 1000,
        'player2HP': 1000,
        'player1Kai': 100,
        'player2Kai': 100,
        'player1Shield': 0,
        'player2Shield': 0,
        'player1Techniques':
            selectedTechniques.map((t) => t.toFirestore()).toList(),
        'player2Techniques':
            selectedOpponentTechniques.map((t) => t.toFirestore()).toList(),
        'player1Cooldowns': initialCooldowns,
        'player2Cooldowns': Map.fromEntries(
            selectedOpponentTechniques.map((t) => MapEntry(t.id, 0))),
        'currentTurn': widget.isChallenger ? 'player1' : 'player2',
        'status': 'active',
        'lastAction': null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _playerKaijin = playerKaijin;
          _opponentKaijin = opponentKaijin;
          _playerTechniques = selectedTechniques;
          _opponentTechniques = selectedOpponentTechniques;
          _isPlayerTurn = widget.isChallenger;
          _isLoading = false;
          _cooldowns = initialCooldowns;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du combat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'initialisation du combat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      final currentTurn = data['currentTurn'] as String;
      final previousTurn = _isPlayerTurn;
      final newIsPlayerTurn = (currentTurn == 'player1') == isPlayer1;

      // Si c'est un nouveau tour
      if (newIsPlayerTurn != previousTurn) {
        if (newIsPlayerTurn) {
          // C'est notre tour qui commence
          _startTurnTimer();

          // Décrémenter les cooldowns
          Map<String, int> newCooldowns = {};
          for (var entry in _cooldowns.entries) {
            newCooldowns[entry.key] = max(0, entry.value - 1);
          }

          // Mettre à jour les cooldowns dans Firestore
          if (isPlayer1) {
            await _firestore
                .collection('battles')
                .doc(widget.challengeId)
                .update({'player1Cooldowns': newCooldowns});
          } else {
            await _firestore
                .collection('battles')
                .doc(widget.challengeId)
                .update({'player2Cooldowns': newCooldowns});
          }

          // Régénérer le Kai
          final newKai = min(_playerKai + 10, _playerMaxKai);
          if (isPlayer1) {
            await _firestore
                .collection('battles')
                .doc(widget.challengeId)
                .update({'player1Kai': newKai});
          } else {
            await _firestore
                .collection('battles')
                .doc(widget.challengeId)
                .update({'player2Kai': newKai});
          }

          // Vérifier si on peut utiliser des techniques
          if (!_canUseAnyTechnique()) {
            print(
                "Aucune technique utilisable - Attaque automatique après délai");
            _performAutoAttack();
          }
        } else {
          // Notre tour est fini, annuler le timer
          _turnTimer?.cancel();
        }
      }

      // Récupérer l'action précédente pour les logs
      if (lastAction != null) {
        final actionType = lastAction['type'] as String;
        final damage = lastAction['damage'] as num?;
        final technique = lastAction['technique'] as Map<String, dynamic>?;
        final actionPlayer = lastAction['player'] as String?;

        if (actionType != null) {
          final timestamp =
              "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
          final wasPlayerAction =
              actionPlayer == (isPlayer1 ? 'player1' : 'player2');

          String logMessage;
          if (actionType == 'technique' && technique != null) {
            final techniqueName =
                technique['name'] as String? ?? 'une technique';
            if (wasPlayerAction) {
              logMessage =
                  "Vous utilisez $techniqueName et infligez ${damage?.toInt() ?? 0} points de dégâts !";
            } else {
              logMessage =
                  "L'adversaire utilise $techniqueName et vous inflige ${damage?.toInt() ?? 0} points de dégâts !";
            }
          } else if (actionType == 'attack') {
            if (wasPlayerAction) {
              logMessage =
                  "Vous attaquez et infligez ${damage?.toInt() ?? 0} points de dégâts !";
            } else {
              logMessage =
                  "L'adversaire attaque et vous inflige ${damage?.toInt() ?? 0} points de dégâts !";
            }
          } else if (actionType == 'shield') {
            if (wasPlayerAction) {
              logMessage = "Vous activez votre bouclier !";
            } else {
              logMessage = "L'adversaire active son bouclier !";
            }
          } else {
            if (wasPlayerAction) {
              logMessage =
                  "Vous infligez ${damage?.toInt() ?? 0} points de dégâts !";
            } else {
              logMessage =
                  "L'adversaire vous inflige ${damage?.toInt() ?? 0} points de dégâts !";
            }
          }

          setState(() {
            _combatLog.add("$timestamp - $logMessage");
            // Garder seulement les 5 derniers messages
            if (_combatLog.length > 5) {
              _combatLog.removeAt(0);
            }
          });
        }
      }

      setState(() {
        // Mettre à jour les HP avec animation
        final newPlayerHP = max<double>(
            0.0,
            (isPlayer1 ? data['player1HP'] : data['player2HP'])?.toDouble() ??
                0.0);
        final newOpponentHP = max<double>(
            0.0,
            (isPlayer1 ? data['player2HP'] : data['player1HP'])?.toDouble() ??
                0.0);

        if (_playerHP != newPlayerHP || _opponentHP != newOpponentHP) {
          print(
              "Mise à jour des points de vie - Joueur: ${_playerHP.toInt()} -> ${newPlayerHP.toInt()}, Adversaire: ${_opponentHP.toInt()} -> ${newOpponentHP.toInt()}");
        }

        _playerHP = newPlayerHP;
        _opponentHP = newOpponentHP;

        // Mettre à jour le Kai
        _playerKai = max<double>(
            0.0,
            (isPlayer1 ? data['player1Kai'] : data['player2Kai'])?.toDouble() ??
                0.0);
        _opponentKai = max<double>(
            0.0,
            (isPlayer1 ? data['player2Kai'] : data['player1Kai'])?.toDouble() ??
                0.0);

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
      });

      // Vérifier si le combat est terminé
      if (_battleStatus == 'finished' && data['winner'] != null) {
        final isWinner = data['winner'] == (isPlayer1 ? 'player1' : 'player2');
        print(
            "Combat terminé - Winner: ${data['winner']}, isPlayer1: $isPlayer1, isWinner: $isWinner");
        _showBattleResult(isWinner);
      }
      // Double vérification pour s'assurer qu'un combat se termine si les points de vie sont à 0
      else if (_playerHP <= 0 || _opponentHP <= 0) {
        final hasWon = _opponentHP <= 0;
        print(
            "Combat terminé par KO - playerHP: ${_playerHP.toInt()}, opponentHP: ${_opponentHP.toInt()}, hasWon: $hasWon");
        _endBattle(hasWon);
      }
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
      final newOpponentHP = max(0.0, _opponentHP - damage);
      final newPlayerHP = max(0.0, _playerHP - damage);

      // Vérifier si l'attaque va terminer le combat avant de l'envoyer
      final willEndBattle = newOpponentHP <= 0 || newPlayerHP <= 0;

      final Map<String, dynamic> lastAction = {
        'type': 'attack',
        'damage': damage,
        'player': widget.isChallenger ? 'player1' : 'player2',
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (willEndBattle) {
        // Mettre à jour les points de vie et terminer le combat immédiatement
        await _firestore.collection('battles').doc(widget.challengeId).update({
          'player1HP': widget.isChallenger ? newPlayerHP : newOpponentHP,
          'player2HP': widget.isChallenger ? newOpponentHP : newPlayerHP,
          'status': 'finished',
          'winner': widget.isChallenger
              ? (newOpponentHP <= 0 ? 'player2' : 'player1')
              : (newPlayerHP <= 0 ? 'player1' : 'player2'),
          'lastAction': lastAction,
        });

        // Afficher le résultat immédiatement
        await _endBattle(newOpponentHP <= 0);
      } else {
        // Continuer le combat normalement
        await _firestore.collection('battles').doc(widget.challengeId).update({
          'player1HP': widget.isChallenger ? newPlayerHP : newOpponentHP,
          'player2HP': widget.isChallenger ? newOpponentHP : newPlayerHP,
          'currentTurn': widget.isChallenger ? 'player2' : 'player1',
          'lastAction': lastAction,
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
          'type': 'shield',
          'player': widget.isChallenger ? 'player1' : 'player2',
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
      // Si je suis le challenger (player1) et j'ai gagné -> winner = player1
      // Si je suis le challenger (player1) et j'ai perdu -> winner = player2
      // Si je ne suis pas le challenger (player2) et j'ai gagné -> winner = player2
      // Si je ne suis pas le challenger (player2) et j'ai perdu -> winner = player1
      final winner = playerWon
          ? (widget.isChallenger ? 'player1' : 'player2')
          : (widget.isChallenger ? 'player2' : 'player1');
      print(
          "Fin du combat - playerWon: $playerWon, isChallenger: ${widget.isChallenger}, winner: $winner");

      await _firestore.collection('battles').doc(widget.challengeId).update({
        'status': 'finished',
        'winner': winner,
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
                  'HP final:',
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
                          '${_playerHP.toInt()}',
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
                          '${_opponentHP.toInt()}',
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
    // Vérifier si c'est le tour du joueur
    if (!_isPlayerTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce n\'est pas votre tour !'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier si la technique est en cooldown
    final currentCooldown = _cooldowns[technique.id] ?? 0;
    if (currentCooldown > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cette technique est en recharge pour encore $currentCooldown tours !'),
          backgroundColor: Colors.orange,
        ),
      );

      // Vérifier si on peut utiliser une autre technique
      if (!_canUseAnyTechnique()) {
        print(
            "Toutes les techniques sont en cooldown - Attaque automatique après délai");
        _performAutoAttack();
      }
      return;
    }

    // Vérifier si le joueur a assez de Kai
    if (_playerKai < technique.cost_kai) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Pas assez de Kai ! (${_playerKai.toInt()}/${technique.cost_kai} requis)'),
          backgroundColor: Colors.red,
        ),
      );

      // Si on ne peut utiliser aucune technique, faire une attaque automatique
      if (!_canUseAnyTechnique()) {
        print(
            "Pas assez de Kai pour utiliser des techniques - Attaque automatique après délai");
        _performAutoAttack();
      }
      return;
    }

    // Annuler le timer car le joueur a fait une action
    _turnTimer?.cancel();

    final isPlayer1 = widget.isChallenger;

    try {
      // Créer une copie des cooldowns actuels
      Map<String, int> newCooldowns = Map<String, int>.from(_cooldowns);
      // Mettre à jour le cooldown de la technique utilisée
      newCooldowns[technique.id] = technique.cooldown;

      // Calcul des dégâts en prenant en compte le niveau de la technique
      final baseDamage = technique.damage;
      final levelBonus = technique.level * 10;
      final totalDamage = baseDamage + levelBonus;

      // Jouer l'animation et le son appropriés
      if (technique.conditionGenerated == 'shield') {
        await _shieldPlayer
            .play(AssetSource('sounds/shield.mp3'))
            .catchError((e) => print('Erreur audio: $e'));
        await _shieldController.forward();
        await Future.delayed(Duration(milliseconds: 500));
        await _shieldController.reverse();

        setState(() {
          _combatMessage = "Vous activez ${technique.name} !";
        });
      } else {
        await _attackPlayer
            .play(AssetSource('sounds/attack.mp3'))
            .catchError((e) => print('Erreur audio: $e'));
        await _playerAttackController.forward();
        await _playerAttackController.reverse();

        setState(() {
          _combatMessage = "Vous utilisez ${technique.name} !";
        });
      }

      // Calculer les nouveaux points de vie en prenant en compte le bouclier
      double effectiveDamage = totalDamage.toDouble();
      if (_opponentShieldTurns > 0) {
        effectiveDamage *= 0.5; // Le bouclier réduit les dégâts de 50%
      }

      // Calculer les nouvelles valeurs
      final newOpponentHP = technique.conditionGenerated == 'shield'
          ? _opponentHP
          : max(0.0, _opponentHP - effectiveDamage);
      final newPlayerKai = max(0.0, _playerKai - technique.cost_kai);

      // Vérifier si la technique va terminer le combat
      final willEndBattle =
          newOpponentHP <= 0 && technique.conditionGenerated != 'shield';

      if (willEndBattle) {
        // Mettre à jour les points de vie et terminer le combat immédiatement
        final Map<String, dynamic> updateData = {
          'status': 'finished',
          'winner': isPlayer1 ? 'player1' : 'player2',
          'lastAction': {
            'type': 'technique',
            'technique': technique.toFirestore(),
            'damage': effectiveDamage,
            'timestamp': FieldValue.serverTimestamp(),
          }
        };

        // Mettre à jour les HP et le Kai
        updateData[isPlayer1 ? 'player2HP' : 'player1HP'] = newOpponentHP;
        updateData[isPlayer1 ? 'player1Kai' : 'player2Kai'] = newPlayerKai;

        // Mettre à jour le cooldown
        if (isPlayer1) {
          updateData['player1Cooldowns'] = newCooldowns;
        } else {
          updateData['player2Cooldowns'] = newCooldowns;
        }

        await _firestore
            .collection('battles')
            .doc(widget.challengeId)
            .update(updateData);

        // Afficher le résultat immédiatement
        await _endBattle(true);
      } else {
        // Préparer les données de mise à jour pour continuer le combat
        final Map<String, dynamic> updateData = {
          'currentTurn': isPlayer1 ? 'player2' : 'player1',
          'lastAction': {
            'type': technique.conditionGenerated == 'shield'
                ? 'shield'
                : 'technique',
            'technique': technique.toFirestore(),
            'damage': effectiveDamage,
            'timestamp': FieldValue.serverTimestamp(),
          }
        };

        // Ajouter les mises à jour spécifiques selon le type de technique
        if (technique.conditionGenerated == 'shield') {
          updateData[isPlayer1 ? 'player1Shield' : 'player2Shield'] = 2;
        } else {
          updateData[isPlayer1 ? 'player2HP' : 'player1HP'] = newOpponentHP;
        }

        // Mettre à jour le Kai
        updateData[isPlayer1 ? 'player1Kai' : 'player2Kai'] = newPlayerKai;

        // Mettre à jour le cooldown
        if (isPlayer1) {
          updateData['player1Cooldowns'] = newCooldowns;
        } else {
          updateData['player2Cooldowns'] = newCooldowns;
        }

        // Mettre à jour l'état du combat
        await _firestore
            .collection('battles')
            .doc(widget.challengeId)
            .update(updateData);
      }

      // Mettre à jour l'état local
      setState(() {
        if (technique.conditionGenerated == 'shield') {
          _playerShieldTurns = 2;
        } else {
          _opponentHP = newOpponentHP;
        }
        _playerKai = newPlayerKai;
        _cooldowns = newCooldowns; // Utiliser la nouvelle copie des cooldowns
      });
    } catch (e) {
      print('Erreur lors de l\'utilisation de la technique: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'utilisation de la technique: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _battleSubscription.cancel();
    _turnTimer?.cancel(); // Annuler le timer à la fermeture
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

  // Fonction pour vérifier si le joueur peut utiliser au moins une technique
  bool _canUseAnyTechnique() {
    if (_playerTechniques.isEmpty) return false;

    bool hasEnoughKaiForAny = false;
    bool hasNoCooldownForAny = false;
    bool hasUsableTechnique = false;

    // Parcourir toutes les techniques pour vérifier les conditions
    for (var technique in _playerTechniques) {
      final hasKai = _playerKai >= technique.cost_kai.toDouble();
      final noCooldown = (_cooldowns[technique.id] ?? 0) == 0;

      // Mettre à jour les flags
      if (hasKai) hasEnoughKaiForAny = true;
      if (noCooldown) hasNoCooldownForAny = true;

      // Vérifier si la technique est complètement utilisable (Kai + pas de cooldown)
      if (hasKai && noCooldown) {
        hasUsableTechnique = true;
        break;
      }
    }

    // Afficher des logs pour le debug
    print("État des techniques :");
    print("- A assez de Kai pour au moins une technique : $hasEnoughKaiForAny");
    print("- A au moins une technique sans cooldown : $hasNoCooldownForAny");
    print(
        "- A au moins une technique utilisable (Kai + pas de cooldown) : $hasUsableTechnique");

    return hasUsableTechnique; // Vrai uniquement si au moins une technique a assez de Kai ET pas de cooldown
  }

  // Fonction pour démarrer le timer du tour
  void _startTurnTimer() {
    _turnTimer?.cancel();
    if (_isPlayerTurn && _battleStatus == 'active') {
      _turnTimer = Timer(const Duration(seconds: 20), () {
        if (_isPlayerTurn && mounted) {
          print("Timer expiré - Attaque automatique");
          _performAutoAttack();
        }
      });
    }
  }

  // Fonction pour effectuer une attaque automatique avec délai si nécessaire
  void _performAutoAttack() async {
    if (!_canUseAnyTechnique()) {
      // Si aucune technique n'est utilisable, attendre 3 secondes
      print(
          "Aucune technique utilisable - Attente de 3 secondes avant l'attaque simple");
      await Future.delayed(const Duration(seconds: 3));
    }

    if (_isPlayerTurn && mounted) {
      _performAttack();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
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
              const Text(
                'Combat en ligne',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            if (_playerKaijin != null)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      _playerKaijin!.power.toString(),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barres de vie
              Row(
                children: [
                  Expanded(
                    child: BattleHealthBar(
                      name: _playerKaijin?.name ?? "Joueur",
                      health: _playerHP,
                      maxHealth: _playerMaxHP,
                      color: Colors.blue,
                      hasShield: _playerShieldTurns > 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BattleHealthBar(
                      name: _opponentKaijin?.name ?? "Adversaire",
                      health: _opponentHP,
                      maxHealth: _opponentMaxHP,
                      color: Colors.red,
                      hasShield: _opponentShieldTurns > 0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Barres de Kai
              Row(
                children: [
                  Expanded(
                    child: BattleKaiBar(
                      name: _playerKaijin?.name ?? "Joueur",
                      kai: _playerKai,
                      maxKai: _playerMaxKai,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BattleKaiBar(
                      name: _opponentKaijin?.name ?? "Adversaire",
                      kai: _opponentKai,
                      maxKai: _opponentMaxKai,
                    ),
                  ),
                ],
              ),

              // Zone de combat
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Combattants
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Joueur
                          SlideTransition(
                            position: _playerAttackAnimation,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_playerShieldTurns > 0)
                                  Container(
                                    width: 140,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.blue.withOpacity(0.2),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 120,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue.withOpacity(0.2),
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.blue,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _playerKaijin?.name ?? "Joueur",
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // VS
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: KaiColors.accent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "VS",
                                style: TextStyle(
                                  color: KaiColors.accent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Adversaire
                          SlideTransition(
                            position: _enemyAttackAnimation,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_opponentShieldTurns > 0)
                                  Container(
                                    width: 140,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.red.withOpacity(0.2),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 120,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red.withOpacity(0.2),
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _opponentKaijin?.name ?? "Adversaire",
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Message de combat
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _combatMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isPlayerTurn
                                    ? "VOTRE TOUR"
                                    : "TOUR DE L'ADVERSAIRE",
                                style: TextStyle(
                                  color:
                                      _isPlayerTurn ? Colors.green : Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Interface des techniques
              Container(
                height: 160,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // En-têtes
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "VOS TECHNIQUES",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.white24,
                        ),
                        const Expanded(
                          child: Text(
                            "TECHNIQUES DE L'ADVERSAIRE",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Techniques
                    Expanded(
                      child: Row(
                        children: [
                          // Techniques du joueur
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.0,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _playerTechniques.length,
                              itemBuilder: (context, index) {
                                final technique = _playerTechniques[index];
                                final cooldown = _cooldowns[technique.id] ?? 0;
                                final isDisabled =
                                    cooldown > 0 || !_isPlayerTurn;

                                return BattleTechniqueCard(
                                  technique: technique,
                                  isPlayer: true,
                                  isDisabled: isDisabled,
                                  cooldown: cooldown,
                                  onTap: () => _useTechnique(technique),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: Colors.white24,
                          ),
                          // Techniques de l'adversaire
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.0,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _opponentTechniques.length,
                              itemBuilder: (context, index) {
                                final technique = _opponentTechniques[index];
                                return BattleTechniqueCard(
                                  technique: technique,
                                  isPlayer: false,
                                  isDisabled: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Logs de combat
              if (_combatLog.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: KaiColors.accent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _combatLog
                        .map((log) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                log,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
