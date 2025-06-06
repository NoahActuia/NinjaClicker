import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';
import '../../theme/app_colors.dart';
import '../../styles/kai_colors.dart';
import 'dart:math';
import '../story/mission_victory_sequence.dart';
import '../story/mission_defeat_sequence.dart';
import '../story/mission_victory_sequence_b.dart';
import '../story/mission_defeat_sequence_b.dart';
import '../story/mission_intro_sequence_b.dart';
import 'combat_appbar_background.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CombatScreen extends StatefulWidget {
  final Mission mission;
  final int playerPuissance;
  final Function(Map<String, dynamic>) onVictory;
  final List<Technique>? customPlayerTechniques;
  final List<Technique>? customEnemyTechniques;
  final String? customEnemyName;
  final bool isTrainingMode;

  const CombatScreen({
    super.key,
    required this.mission,
    required this.playerPuissance,
    required this.onVictory,
    this.customPlayerTechniques,
    this.customEnemyTechniques,
    this.customEnemyName,
    this.isTrainingMode = false,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  double _playerHealth = 1000;
  double _enemyHealth = 1000;
  double _playerMaxHealth = 1000;
  double _enemyMaxHealth = 1000;
  bool _isPlayerTurn = true; // Pour le tour par tour
  bool _showVictoryDialog = false; // Pour afficher le dialogue de victoire
  bool _showDefeatDialog = false; // Pour afficher le dialogue de défaite
  String _enemyName = "";

  // Variables pour le système de Kai
  double _playerKai = 100;
  double _enemyKai = 100;
  double _playerMaxKai = 100;
  double _enemyMaxKai = 100;
  double _kaiRegenerationPerTurn = 10; // Régénération du Kai à chaque tour

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

  // Techniques du joueur
  List<Technique> _playerTechniques = [];

  // Techniques pour la simulation
  List<Technique> _demoTechniques = [
    Technique(
      id: '1',
      name: 'Frappe du Kai Fluctuant',
      description:
          'Une frappe simple mais puissante qui concentre le Kai dans les poings.',
      type: 'active',
      affinity: 'Frappe',
      cost_kai: 15,
      cooldown: 1,
      damage: 25,
      unlock_type: 'naturelle',
    ),
    Technique(
      id: '2',
      name: 'Vague de Fracture',
      description: 'Crée une fissure temporelle qui blesse tous les ennemis.',
      type: 'active',
      affinity: 'Fracture',
      cost_kai: 30,
      cooldown: 3,
      damage: 40,
      condition_generated: 'fissure',
      unlock_type: 'naturelle',
    ),
    Technique(
      id: '3',
      name: 'Barrière du Sceau',
      description:
          'Crée une barrière qui absorbe les dégâts pendant plusieurs tours.',
      type: 'active',
      affinity: 'Sceau',
      cost_kai: 25,
      cooldown: 4,
      damage: 0,
      condition_generated: 'shield',
      unlock_type: 'naturelle',
    ),
  ];

  // Cooldowns des techniques
  Map<String, int> _cooldowns = {};

  // État du bouclier
  int _playerShieldTurns = 0;
  int _enemyShieldTurns = 0;

  // Techniques de l'ennemi
  List<Technique> _enemyTechniques = [];

  // Techniques anciennes de l'ennemi (pour compatibilité)
  List<Map<String, dynamic>> _oldEnemyTechniques = [
    {
      'name': 'Frappe simple',
      'damage': 10,
      'type': 'attack',
    },
    {
      'name': 'Bouclier',
      'damage': 0,
      'type': 'shield',
      'turns': 2,
    },
    {
      'name': 'Attaque puissante',
      'damage': 10,
      'type': 'attack',
    },
  ];

  // Messages de combat
  String _combatMessage = "Le combat commence!";
  List<String> _combatLog = [];

  // Déterminer si c'est le combat du niveau A
  bool get _isLevelA =>
      widget.mission.id == 1 ||
      widget.mission.id == '1' ||
      widget.mission.id == 'monde1_combat1';

  // Déterminer si c'est le combat du niveau B
  bool get _isLevelB =>
      widget.mission.id == 2 ||
      widget.mission.id == '2' ||
      widget.mission.id == 'monde1_combat2';

  // Timer pour l'auto-attaque
  Timer? _autoAttackTimer;

  // Audio players
  late AudioPlayer _attackPlayer;
  late AudioPlayer _shieldPlayer;
  late AudioPlayer _healPlayer;
  late AudioPlayer _kaiRegenPlayer;
  late AudioPlayer _victoryPlayer;
  late AudioPlayer _defeatPlayer;

  // Variables pour le combat en ligne
  String? _battleId;
  StreamSubscription? _battleSubscription;
  bool _isOnlineMode = false;

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs d'animation
    _playerAttackController = AnimationController(
      duration: const Duration(
          milliseconds: 800), // Augmenté pour une animation plus fluide
      vsync: this,
    );
    _enemyAttackController = AnimationController(
      duration: const Duration(
          milliseconds: 800), // Augmenté pour une animation plus fluide
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

    // Configurer les animations d'attaque avec aller-retour
    _playerAttackAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 30)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 30, end: -5)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -5, end: 0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_playerAttackController);

    _enemyAttackAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -30)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -30, end: 5)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 5, end: 0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_enemyAttackController);

    // Autres animations
    _playerKaiRegenAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _playerKaiRegenController,
      curve: Curves.easeInOut,
    ));

    _enemyKaiRegenAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _enemyKaiRegenController,
      curve: Curves.easeInOut,
    ));

    _playerHealAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _playerHealController,
      curve: Curves.easeInOut,
    ));

    _enemyHealAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _enemyHealController,
      curve: Curves.easeInOut,
    ));

    _shieldAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shieldController,
      curve: Curves.elasticOut,
    ));

    // Initialiser le nom de l'ennemi
    _enemyName = widget.customEnemyName ?? "Ombre du Kai";

    // Initialiser les points de vie en fonction de la difficulté
    _initializeHealthPoints();

    // Charger les techniques du joueur et de l'ennemi
    _loadTechniques();

    // Initialiser les cooldowns
    for (var technique in _playerTechniques) {
      _cooldowns[technique.id] = 0;
    }

    // Compatibilité avec les niveaux spécifiques
    if (!widget.isTrainingMode) {
      // Ajuster les dégâts de l'ennemi pour le niveau B
      if (_isLevelB) {
        _oldEnemyTechniques = [
          {
            'name': 'Frappe simple',
            'damage': 20,
            'type': 'attack',
          },
          {
            'name': 'Bouclier',
            'damage': 0,
            'type': 'shield',
            'turns': 2,
          },
          {
            'name': 'Attaque puissante',
            'damage': 20,
            'type': 'attack',
          },
        ];
      }
    }

    // Démarrer le timer pour l'auto-attaque
    _startAutoAttackTimer();

    // Initialiser les audio players
    _attackPlayer = AudioPlayer();
    _shieldPlayer = AudioPlayer();
    _healPlayer = AudioPlayer();
    _kaiRegenPlayer = AudioPlayer();
    _victoryPlayer = AudioPlayer();
    _defeatPlayer = AudioPlayer();

    // Vérifier si c'est un combat en ligne
    _isOnlineMode = !widget.isTrainingMode &&
        widget.mission.id.startsWith('online_battle_');
    if (_isOnlineMode) {
      _battleId = widget.mission.id.replaceAll('online_battle_', '');
      _listenToBattle();
    }
  }

  // Initialiser les points de vie en fonction de la difficulté
  void _initializeHealthPoints() {
    // HP de base pour le joueur: 1000
    _playerHealth = 1000;
    _playerMaxHealth = 1000;

    // HP de l'ennemi selon la difficulté
    if (widget.isTrainingMode) {
      // En mode entraînement, calculer les HP en fonction du niveau
      int difficultyLevel = widget.mission.enemyLevel;
      _enemyMaxHealth = 1000 +
          (difficultyLevel - 1) *
              250; // +250 HP par niveau (1000, 1250, 1500, 1750, etc.)
      _enemyHealth = _enemyMaxHealth;
    } else {
      // Pour les combats d'histoire, suivre la logique spécifique au scénario
      if (_isLevelB) {
        _enemyMaxHealth = 1250; // Plus dur dans le niveau B
        _enemyHealth = _enemyMaxHealth;
      } else {
        _enemyMaxHealth = 1000; // Niveau standard pour autres combats
        _enemyHealth = _enemyMaxHealth;
      }
    }
  }

  // Chargement des techniques
  void _loadTechniques() {
    // Techniques du joueur
    if (widget.customPlayerTechniques != null &&
        widget.customPlayerTechniques!.isNotEmpty) {
      // Utiliser les techniques personnalisées du joueur
      _playerTechniques = widget.customPlayerTechniques!;
    } else {
      // Utiliser les techniques de démonstration
      _playerTechniques = _demoTechniques;
    }

    // Techniques de l'ennemi
    if (widget.customEnemyTechniques != null &&
        widget.customEnemyTechniques!.isNotEmpty) {
      // Utiliser les techniques personnalisées de l'ennemi
      _enemyTechniques = widget.customEnemyTechniques!;
    } else {
      // Créer des techniques à partir de l'ancien format pour compatibilité
      _enemyTechniques = _oldEnemyTechniques.map((tech) {
        return Technique(
          id: 'enemy_${tech['name']?.toLowerCase().replaceAll(' ', '_') ?? ''}',
          name: tech['name'] ?? 'Technique inconnue',
          description: 'Technique utilisée par l\'adversaire',
          type: 'active',
          affinity: tech['type'] == 'shield' ? 'Sceau' : 'Frappe',
          cost_kai: 10,
          cooldown: 1,
          damage: (tech['damage'] ?? 10).toInt(),
          condition_generated: tech['type'] == 'shield' ? 'shield' : null,
          unlock_type: 'naturelle',
        );
      }).toList();
    }
  }

  // Fonction pour jouer les sons
  Future<void> _playSound(String soundType) async {
    try {
      switch (soundType) {
        case 'attack':
          // Utiliser un son d'attaque existant
          await _attackPlayer.play(AssetSource('sounds/attack.mp3'));
          break;
        case 'shield':
          await _shieldPlayer.play(AssetSource('sounds/shield.mp3'));
          break;
        case 'heal':
          // Utiliser le son de mode sage pour la guérison
          // await _healPlayer.play(AssetSource('sounds/technique_mode_sage.mp3'));
          break;
        case 'kai_regen':
          // Utiliser le son de charge de chakra pour la régénération de Kai
          //await _kaiRegenPlayer.play(AssetSource('sounds/chakra_charge.mp3'));
          break;
        case 'victory':
          // Utiliser le son de déblocage pour la victoire
          // await _victoryPlayer.play(AssetSource('sounds/unlock.mp3'));
          break;
        case 'defeat':
          // Utiliser un son approprié pour la défaite
          // await _defeatPlayer
          //     .play(AssetSource('sounds/technique_substitution.mp3'));
          break;
      }
    } catch (e) {
      print('Erreur lors de la lecture du son: $e');
    }
  }

  // Fonction pour utiliser une technique
  void _useTechnique(Technique technique) async {
    if (!_isPlayerTurn) return;

    // Annuler le timer d'auto-attaque car le joueur agit manuellement
    _autoAttackTimer?.cancel();

    // Vérifier si la technique est en recharge
    if (_cooldowns[technique.id]! > 0) {
      _updateCombatMessage(
          "Cette technique est en recharge (${_cooldowns[technique.id]} tours restants)");
      return;
    }

    // Vérifier si le joueur a assez de Kai
    if (_playerKai < technique.cost_kai) {
      // Pas assez de Kai, déclencher l'auto-attaque
      _executeAutoAttack();
      return;
    }

    setState(() {
      // Consommer le Kai
      _playerKai = (_playerKai - technique.cost_kai).clamp(0.0, _playerMaxKai);

      // Appliquer les effets de la technique
      switch (technique.conditionGenerated) {
        case 'shield':
        case 'barrier':
          _playerShieldTurns = 2; // 2 tours de bouclier
          _updateCombatMessage("Vous avez activé un bouclier pour 2 tours!");
          _shieldController.forward(from: 0);
          _playSound('shield');
          break;
        default: // Attaque par défaut
          double damage = technique.damage.toDouble();
          // Réduire les dégâts si l'ennemi a un bouclier
          if (_enemyShieldTurns > 0) {
            damage *= 0.5;
            _updateCombatMessage(
                "Votre ${technique.name} inflige $damage dégâts (réduits par le bouclier)!");
          } else {
            _updateCombatMessage(
                "Votre ${technique.name} inflige $damage dégâts!");
          }
          _enemyHealth = (_enemyHealth - damage).clamp(0.0, _enemyMaxHealth);
          // Animation d'attaque
          _playerAttackController.forward(from: 0);
          _playSound('attack');
          break;
      }

      // Appliquer le cooldown
      _cooldowns[technique.id] = technique.cooldown;

      // Fin du tour du joueur
      _endPlayerTurn();
    });

    // Mettre à jour l'état du combat en ligne
    if (_isOnlineMode) {
      await _updateBattleState();
    }
  }

  // Exécuter une attaque automatique simple
  void _executeAutoAttack() {
    setState(() {
      // L'auto-attaque inflige des dégâts faibles mais ne coûte pas de Kai
      double damage = 15.0; // Dégâts faibles fixes

      // Réduire les dégâts si l'ennemi a un bouclier
      if (_enemyShieldTurns > 0) {
        damage *= 0.5;
        _updateCombatMessage(
            "Vous utilisez une Frappe Simple et infligez $damage dégâts (réduits par le bouclier)!");
      } else {
        _updateCombatMessage(
            "Vous utilisez une Frappe Simple et infligez $damage dégâts!");
      }

      // Appliquer les dégâts
      _enemyHealth = (_enemyHealth - damage).clamp(0.0, _enemyMaxHealth);

      // Animation d'attaque simple
      _playerAttackController.forward(from: 0);

      // Fin du tour du joueur
      _endPlayerTurn();
    });
  }

  // Fonction pour terminer le tour du joueur
  void _endPlayerTurn() {
    _isPlayerTurn = false;

    // Vérifier si le combat est terminé
    if (_enemyHealth <= 0) {
      _finishCombat(true);
      return;
    }

    // Attendre la fin de l'animation d'attaque du joueur
    _playerAttackController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _playerAttackController.removeStatusListener((status) {});

        // Tour de l'ennemi avec un délai plus important
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _enemyTurn();
          }
        });
      }
    });
  }

  // Tour de l'ennemi
  void _enemyTurn() async {
    if (!mounted) return;

    // Réduire les cooldowns
    for (var id in _cooldowns.keys) {
      if (_cooldowns[id]! > 0) {
        _cooldowns[id] = _cooldowns[id]! - 1;
      }
    }

    // Régénérer du Kai pour le joueur
    setState(() {
      double previousKai = _playerKai;
      _playerKai =
          (_playerKai + _kaiRegenerationPerTurn).clamp(0.0, _playerMaxKai);

      // Animation de régénération du Kai si nécessaire
      if (_playerKai > previousKai) {
        _playerKaiRegenController.forward(from: 0);
        _playSound('kai_regen');
      }
    });

    // Choisir une technique aléatoire pour l'ennemi
    final rng = Random();

    if (widget.isTrainingMode && _enemyTechniques.isNotEmpty) {
      final Technique technique =
          _enemyTechniques[rng.nextInt(_enemyTechniques.length)];

      setState(() {
        if (_enemyKai < technique.cost_kai) {
          // Attaque simple si pas assez de Kai
          double damage = 15.0;
          if (_playerShieldTurns > 0) {
            damage *= 0.5;
            _updateCombatMessage(
                "$_enemyName utilise une Frappe Simple et inflige $damage dégâts (réduits par votre bouclier)!");
          } else {
            _updateCombatMessage(
                "$_enemyName utilise une Frappe Simple et inflige $damage dégâts!");
          }
          _playerHealth = (_playerHealth - damage).clamp(0.0, _playerMaxHealth);
          _enemyAttackController.forward(from: 0);
          _playSound('attack');
        } else {
          // Utiliser la technique choisie
          _enemyKai = (_enemyKai - technique.cost_kai).clamp(0.0, _enemyMaxKai);

          switch (technique.conditionGenerated) {
            case 'shield':
            case 'barrier':
              _enemyShieldTurns = 2;
              _updateCombatMessage(
                  "$_enemyName active ${technique.name} pour 2 tours!");
              _shieldController.forward(from: 0);
              _playSound('shield');
              break;
            default:
              double damage = technique.damage.toDouble();
              if (_playerShieldTurns > 0) {
                damage *= 0.5;
                _updateCombatMessage(
                    "$_enemyName utilise ${technique.name} et inflige $damage dégâts (réduits par votre bouclier)!");
              } else {
                _updateCombatMessage(
                    "$_enemyName utilise ${technique.name} et inflige $damage dégâts!");
              }
              _playerHealth =
                  (_playerHealth - damage).clamp(0.0, _playerMaxHealth);
              _enemyAttackController.forward(from: 0);
              _playSound('attack');
              break;
          }
        }

        // Régénérer du Kai pour l'ennemi
        double previousEnemyKai = _enemyKai;
        _enemyKai = (_enemyKai + 10).clamp(0.0, _enemyMaxKai);
        if (_enemyKai > previousEnemyKai) {
          _enemyKaiRegenController.forward(from: 0);
        }

        // Réduire la durée des boucliers
        if (_playerShieldTurns > 0) _playerShieldTurns--;
        if (_enemyShieldTurns > 0) _enemyShieldTurns--;

        // Fin du tour de l'ennemi
        _isPlayerTurn = true;

        // Vérifier si le combat est terminé
        if (_playerHealth <= 0) {
          _finishCombat(false);
        }

        // Démarrer le timer d'auto-attaque pour le tour du joueur
        _startAutoAttackTimer();
      });
    } else {
      // Mode histoire avec l'ancien format de techniques
      final technique =
          _oldEnemyTechniques[rng.nextInt(_oldEnemyTechniques.length)];

      setState(() {
        switch (technique['type']) {
          case 'shield':
            _enemyShieldTurns = technique['turns'];
            _updateCombatMessage(
                "L'ennemi active un bouclier pour ${technique['turns']} tours!");
            _shieldController.forward(from: 0);
            _playSound('shield');
            break;
          case 'attack':
            double damage = technique['damage'].toDouble();
            if (_playerShieldTurns > 0) {
              damage *= 0.5;
              _updateCombatMessage(
                  "L'ennemi utilise ${technique['name']} et inflige $damage dégâts (réduits par votre bouclier)!");
            } else {
              _updateCombatMessage(
                  "L'ennemi utilise ${technique['name']} et inflige $damage dégâts!");
            }
            _playerHealth =
                (_playerHealth - damage).clamp(0.0, _playerMaxHealth);
            _enemyAttackController.forward(from: 0);
            _playSound('attack');
            break;
        }

        // Réduire la durée des boucliers
        if (_playerShieldTurns > 0) _playerShieldTurns--;
        if (_enemyShieldTurns > 0) _enemyShieldTurns--;

        // Fin du tour de l'ennemi
        _isPlayerTurn = true;

        // Vérifier si le combat est terminé
        if (_playerHealth <= 0) {
          _finishCombat(false);
        }

        // Démarrer le timer d'auto-attaque pour le tour du joueur
        _startAutoAttackTimer();
      });
    }

    // Mettre à jour l'état du combat en ligne
    if (_isOnlineMode) {
      await _updateBattleState();
    }
  }

  // Mettre à jour le message de combat
  void _updateCombatMessage(String message) {
    _combatMessage = message;
    _combatLog.add(message);
    if (_combatLog.length > 5) {
      _combatLog.removeAt(0);
    }
  }

  // Terminer le combat
  void _finishCombat(bool victory) {
    if (victory) {
      _updateCombatMessage("Victoire! Vous avez vaincu l'ennemi!");
      _playSound('victory');
      setState(() {
        _showVictoryDialog = true;
      });
    } else {
      _updateCombatMessage("Défaite! Votre santé est tombée à zéro.");
      _playSound('defeat');
      setState(() {
        _showDefeatDialog = true;
      });
    }
  }

  // Afficher la séquence de victoire
  void _showVictorySequence() {
    if (_isLevelB) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MissionVictoryBSequence(
            onComplete: () {
              // Quand la séquence de victoire est terminée, retourner au chemin et donner les récompenses
              Navigator.of(context).pop(); // Fermer l'écran de combat

              // En cas de victoire, on veut animer le ninja
              Map<String, dynamic> rewards = {...widget.mission.rewards};
              rewards['animate_ninja'] =
                  true; // Indiquer qu'il faut animer le ninja
              widget.onVictory(rewards);
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MissionVictorySequence(
            onComplete: () {
              // Quand la séquence de victoire est terminée, retourner au chemin et donner les récompenses
              Navigator.of(context).pop(); // Fermer l'écran de combat

              // En cas de victoire, on veut animer le ninja
              Map<String, dynamic> rewards = {...widget.mission.rewards};
              rewards['animate_ninja'] =
                  true; // Indiquer qu'il faut animer le ninja
              widget.onVictory(rewards);
            },
          ),
        ),
      );
    }
  }

  // Afficher la séquence de défaite
  void _showDefeatSequence() {
    if (_isLevelB) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MissionDefeatBSequence(
            onComplete: () {
              // Quand la séquence de défaite est terminée, retourner directement au chemin
              // Sans animer le ninja (comportement par défaut)
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MissionDefeatSequence(
            onComplete: () {
              // Quand la séquence de défaite est terminée, retourner directement au chemin
              // Sans animer le ninja (comportement par défaut)
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  // Démarrer le timer pour l'auto-attaque
  void _startAutoAttackTimer() {
    // Annuler le timer existant s'il y en a un
    _autoAttackTimer?.cancel();

    // Vérifier d'abord si le joueur peut utiliser une technique
    bool canUseAnyTechnique = false;
    for (var technique in _playerTechniques) {
      if (_cooldowns[technique.id]! <= 0 && _playerKai >= technique.cost_kai) {
        canUseAnyTechnique = true;
        break;
      }
    }

    // Si le joueur ne peut utiliser aucune technique, déclencher immédiatement l'auto-attaque
    if (!canUseAnyTechnique && _isPlayerTurn && mounted) {
      _executeAutoAttack();
      return;
    }

    // Seulement démarrer le timer si c'est le tour du joueur
    if (_isPlayerTurn) {
      _autoAttackTimer = Timer(const Duration(seconds: 10), () {
        // Vérifier si c'est toujours le tour du joueur
        if (_isPlayerTurn && mounted) {
          // Exécuter une attaque simple automatique
          _executeAutoAttack();
        }
      });
    }
  }

  @override
  void dispose() {
    _playerAttackController.dispose();
    _enemyAttackController.dispose();
    _playerKaiRegenController.dispose();
    _enemyKaiRegenController.dispose();
    _playerHealController.dispose();
    _enemyHealController.dispose();
    _shieldController.dispose();
    _autoAttackTimer?.cancel();
    _attackPlayer.dispose();
    _shieldPlayer.dispose();
    _healPlayer.dispose();
    _kaiRegenPlayer.dispose();
    _victoryPlayer.dispose();
    _defeatPlayer.dispose();
    _battleSubscription?.cancel();
    super.dispose();
  }

  void _listenToBattle() {
    if (_battleId == null) return;

    _battleSubscription = FirebaseFirestore.instance
        .collection('battles')
        .doc(_battleId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;

      // Mettre à jour l'état du combat
      setState(() {
        _playerHealth = data['player1Health'] ?? _playerHealth;
        _enemyHealth = data['player2Health'] ?? _enemyHealth;
        _playerKai = data['player1Kai'] ?? _playerKai;
        _enemyKai = data['player2Kai'] ?? _enemyKai;
        _isPlayerTurn =
            data['currentTurn'] == FirebaseAuth.instance.currentUser?.uid;

        // Mettre à jour les cooldowns
        final cooldowns = data['cooldowns'] as Map<String, dynamic>?;
        if (cooldowns != null) {
          _cooldowns = Map<String, int>.from(cooldowns);
        }

        // Mettre à jour les effets
        _playerShieldTurns = data['player1ShieldTurns'] ?? 0;
        _enemyShieldTurns = data['player2ShieldTurns'] ?? 0;

        // Vérifier la fin du combat
        if (data['status'] == 'finished') {
          final winner = data['winner'];
          if (winner == FirebaseAuth.instance.currentUser?.uid) {
            _showVictoryDialog = true;
          } else {
            _showDefeatDialog = true;
          }
        }
      });
    });
  }

  Future<void> _updateBattleState() async {
    if (!_isOnlineMode || _battleId == null) return;

    await FirebaseFirestore.instance
        .collection('battles')
        .doc(_battleId)
        .update({
      'player1Health': _playerHealth,
      'player2Health': _enemyHealth,
      'player1Kai': _playerKai,
      'player2Kai': _enemyKai,
      'currentTurn':
          _isPlayerTurn ? FirebaseAuth.instance.currentUser?.uid : null,
      'cooldowns': _cooldowns,
      'player1ShieldTurns': _playerShieldTurns,
      'player2ShieldTurns': _enemyShieldTurns,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showVictoryDialog) {
      return _buildVictoryDialog();
    }

    if (_showDefeatDialog) {
      return _buildDefeatDialog();
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
            missionName: widget.mission.name,
          ),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Combat: ${widget.mission.name}',
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
                    widget.playerPuissance.toString(),
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
        decoration: _isLevelA
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images_histoire/environnement/environnement1.png'),
                  fit: BoxFit.cover,
                  opacity: 0.7,
                ),
              )
            : _isLevelB
                ? const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          'assets/images_histoire/environnement/environnement2.png'),
                      fit: BoxFit.cover,
                      opacity: 0.7,
                    ),
                  )
                : const BoxDecoration(
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
              // Barres de vie côte à côte
              Row(
                children: [
                  // Barre de vie du joueur (gauche)
                  Expanded(
                    child: _buildHealthBar("Joueur", _playerHealth, Colors.blue,
                        hasShield: _playerShieldTurns > 0),
                  ),

                  // Petit espacement entre les barres
                  const SizedBox(width: 12),

                  // Barre de vie de l'ennemi (droite)
                  Expanded(
                    child: _buildHealthBar(
                        _enemyName.isEmpty ? "Ombre du Kai" : _enemyName,
                        _enemyHealth,
                        Colors.red,
                        hasShield: _enemyShieldTurns > 0),
                  ),
                ],
              ),

              // Petit espacement entre les barres de vie et de Kai
              const SizedBox(height: 6),

              // Barres de Kai côte à côte
              Row(
                children: [
                  // Barre de Kai du joueur (gauche)
                  Expanded(
                    child: _buildKaiBar("Joueur", _playerKai, _playerMaxKai),
                  ),

                  // Petit espacement entre les barres
                  const SizedBox(width: 12),

                  // Barre de Kai de l'ennemi (droite)
                  Expanded(
                    child: _buildKaiBar(
                        _enemyName.isEmpty ? "Ombre du Kai" : _enemyName,
                        _enemyKai,
                        _enemyMaxKai),
                  ),
                ],
              ),

              // Zone des combattants - avec de l'espace supplémentaire
              Expanded(
                flex:
                    4, // Augmenté de 2 à 4 pour donner plus d'espace aux images agrandies
                child: _buildCombatantsView(),
              ),

              // Message de combat et tour actuel
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
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
                    const SizedBox(height: 3),
                    if (_isPlayerTurn)
                      const Text(
                        "VOTRE TOUR",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      const Text(
                        "TOUR DE L'ADVERSAIRE",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Interface de combat avec techniques du joueur et de l'adversaire
              Expanded(
                flex: 2, // Augmenté pour conserver les proportions
                child: _buildCombatInterface(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour afficher l'écran de victoire
  Widget _buildVictoryDialog() {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.kaiEnergy,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.kaiEnergy.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              const Text(
                "VICTOIRE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Icône de victoire
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 80,
                shadows: [
                  Shadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Message
              const Text(
                "Vous avez triomphé de votre adversaire!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Bouton continuer
              ElevatedButton(
                onPressed: _showVictorySequence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kaiEnergy,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "CONTINUER",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour afficher l'écran de défaite
  Widget _buildDefeatDialog() {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.shade700,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade900.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              const Text(
                "VAINCU",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Icône de défaite
              Icon(
                Icons.cancel_outlined,
                color: Colors.red.shade700,
                size: 80,
                shadows: [
                  Shadow(
                    color: Colors.red.shade700.withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Message
              const Text(
                "Vous avez été vaincu par votre adversaire!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Bouton revenez plus fort
              ElevatedButton(
                onPressed: _showDefeatSequence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "REVENEZ PLUS FORT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour afficher l'interface de combat avec techniques
  Widget _buildCombatInterface() {
    return Column(
      children: [
        // En-têtes des colonnes
        Row(
          children: [
            // Titre des techniques du joueur
            Expanded(
              child: const Text(
                "VOS TECHNIQUES",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Séparateur vertical
            Container(
              width: 1,
              height: 20,
              color: Colors.white.withOpacity(0.3),
            ),

            // Titre des techniques de l'adversaire
            Expanded(
              child: const Text(
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

        const SizedBox(height: 4),

        // Techniques du joueur et de l'adversaire en grille compacte
        // Utiliser Expanded plutôt qu'une hauteur fixe pour s'adapter
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Techniques du joueur (côté gauche)
              Expanded(
                child: _buildPlayerTechniquesCompact(),
              ),

              // Séparateur vertical
              Container(
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),

              // Techniques de l'adversaire (côté droit)
              Expanded(
                child: _buildEnemyTechniquesCompact(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget pour afficher les techniques du joueur de manière compacte
  Widget _buildPlayerTechniquesCompact() {
    // Calculer le nombre optimal de lignes en fonction du nombre de techniques
    final int columns = 2; // Toujours 2 colonnes
    final int rows = (_playerTechniques.length + columns - 1) ~/
        columns; // Arrondir au supérieur

    return GridView.builder(
      shrinkWrap: true, // Compresser la grille à sa taille minimale
      physics: const NeverScrollableScrollPhysics(), // Désactiver le défilement
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns, // 2 colonnes
        childAspectRatio: 1.8, // Rapport hauteur/largeur optimisé (plus carré)
        crossAxisSpacing: 2, // Réduit de 4 à 2
        mainAxisSpacing: 2, // Réduit de 4 à 2
        mainAxisExtent: 70, // Réduit de 75 à 70
      ),
      itemCount: _playerTechniques.length,
      itemBuilder: (context, index) {
        final technique = _playerTechniques[index];
        final onCooldown = _cooldowns[technique.id]! > 0;
        final isDisabled = !_isPlayerTurn || onCooldown;

        return GestureDetector(
          onTap: isDisabled ? null : () => _useTechnique(technique),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(4), // Padding réduit de 6 à 4
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.3)
                  : _getAffinityColor(technique.affinity).withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.5)
                    : _getAffinityColor(technique.affinity),
                width: isDisabled ? 1 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nom de la technique
                Text(
                  technique.name,
                  style: TextStyle(
                    color: isDisabled
                        ? Colors.white.withOpacity(0.7)
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Réduit de 13 à 12
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4), // Réduit de 6 à 4
                // Icône et valeur
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      technique.conditionGenerated == 'shield'
                          ? Icons.shield
                          : Icons.flash_on,
                      color: isDisabled
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white,
                      size: 12, // Réduit de 14 à 12
                    ),
                    const SizedBox(width: 4),
                    Text(
                      technique.conditionGenerated == 'shield'
                          ? "Défense"
                          : "${technique.damage} dmg",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11, // Réduit de 12 à 11
                      ),
                    ),

                    // Indique le coût en Kai
                    const SizedBox(width: 8),
                    Icon(
                      Icons.south_rounded,
                      color: KaiColors.kaiEnergy,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "${technique.cost_kai}",
                      style: TextStyle(
                        color: _playerKai < technique.cost_kai
                            ? Colors.red.withOpacity(0.9)
                            : KaiColors.kaiEnergy.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (onCooldown) ...[
                      const SizedBox(width: 4),
                      Text(
                        "CD:${_cooldowns[technique.id]}",
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget pour afficher les techniques de l'adversaire de manière compacte
  Widget _buildEnemyTechniquesCompact() {
    // Utiliser la liste de techniques de l'ennemi selon le mode
    final techniques =
        widget.isTrainingMode ? _enemyTechniques : _enemyTechniques;

    // Map des cooldowns pour l'ennemi (simulation)
    Map<String, int> _enemyCooldowns = {};

    // Initialiser les cooldowns simulés pour l'ennemi
    for (var technique in techniques) {
      if (!_enemyCooldowns.containsKey(technique.id)) {
        // Simuler un état de cooldown aléatoire pour certaines techniques
        _enemyCooldowns[technique.id] =
            Random().nextInt(3) == 0 ? Random().nextInt(3) + 1 : 0;
      }
    }

    return GridView.builder(
      shrinkWrap: true, // Compresser la grille à sa taille minimale
      physics: const NeverScrollableScrollPhysics(), // Désactiver le défilement
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 colonnes
        childAspectRatio: 1.8, // Rapport hauteur/largeur optimisé (plus carré)
        crossAxisSpacing: 2, // Réduit de 4 à 2
        mainAxisSpacing: 2, // Réduit de 4 à 2
        mainAxisExtent: 70, // Réduit de 80 à 75
      ),
      itemCount: techniques.length,
      itemBuilder: (context, index) {
        final technique = techniques[index];
        final onCooldown = _enemyCooldowns[technique.id]! > 0;

        return Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(4), // Padding réduit de 6 à 4
          decoration: BoxDecoration(
            // Couleur plus grisée pour indiquer que c'est inutilisable
            color: _getAffinityColor(technique.affinity).withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _getAffinityColor(technique.affinity).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Opacity(
            opacity:
                0.7, // Opacité réduite pour indiquer qu'elles ne sont pas utilisables
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nom de la technique
                Text(
                  technique.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Icône et valeur
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      technique.conditionGenerated == 'shield'
                          ? Icons.shield
                          : Icons.flash_on,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      technique.conditionGenerated == 'shield'
                          ? "Défense"
                          : "${technique.damage} dmg",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),

                    // Indique le coût en Kai
                    const SizedBox(width: 8),
                    Icon(
                      Icons.south_rounded,
                      color: KaiColors.kaiEnergy,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "${technique.cost_kai}",
                      style: TextStyle(
                        color: _enemyKai < technique.cost_kai
                            ? Colors.red.withOpacity(0.9)
                            : KaiColors.kaiEnergy.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Affichage du cooldown
                    if (onCooldown) ...[
                      const SizedBox(width: 4),
                      Text(
                        "CD:${_enemyCooldowns[technique.id]}",
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget pour afficher les combattants - Rendre fixe sans animation
  Widget _buildCombatantsView() {
    return Container(
      width: double.infinity,
      height: 300,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
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
                  opacity = 0.8 + (_playerKaiRegenAnimation.value * 0.2);
                }

                return Transform.translate(
                  offset: Offset(translateX, 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Stack(
                        children: [
                          // Image du joueur
                          Container(
                            width: 191, // Taille originale
                            height: 248, // Taille originale
                            child: Image.asset(
                              'assets/images_histoire/joueur/joueur1.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (_playerShieldTurns > 0)
                            AnimatedBuilder(
                              animation: _shieldAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 191,
                                  height: 248,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.kaiEnergy.withOpacity(
                                        0.3 + (_shieldAnimation.value * 0.7),
                                      ),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.kaiEnergy
                                            .withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
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

                return Transform.translate(
                  offset: Offset(translateX, 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Stack(
                        children: [
                          // Image de l'ennemi
                          Container(
                            width: 191, // Taille originale
                            height: 248, // Taille originale
                            child: Image.asset(
                              _isLevelB
                                  ? 'assets/images_histoire/joueur/joueur3.png'
                                  : 'assets/images_histoire/joueur/joueur2.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (_enemyShieldTurns > 0)
                            AnimatedBuilder(
                              animation: _shieldAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 191,
                                  height: 248,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.kaiEnergy.withOpacity(
                                        0.3 + (_shieldAnimation.value * 0.7),
                                      ),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.kaiEnergy
                                            .withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, double value, Color color,
      {bool hasShield = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // En-tête avec nom et icône de bouclier
        Row(
          mainAxisAlignment: label == "Joueur"
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (label != "Joueur" && hasShield)
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black,
                  )
                ],
              ),
            ),
            if (label == "Joueur" && hasShield)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),

        // Barre de progression avec valeur
        Stack(
          children: [
            // Barre de base
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: label == "Joueur"
                    ? value / _playerMaxHealth
                    : value / _enemyMaxHealth,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 18,
              ),
            ),
            // Valeur numérique
            Positioned.fill(
              child: Center(
                child: Text(
                  "${value.toInt()}/${label == "Joueur" ? _playerMaxHealth.toInt() : _enemyMaxHealth.toInt()}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Obtenir la couleur en fonction de l'affinité
  Color _getAffinityColor(String? affinity) {
    switch (affinity) {
      case 'Flux':
        return Colors.blue;
      case 'Fracture':
        return Colors.purple;
      case 'Sceau':
        return Colors.amber;
      case 'Dérive':
        return Colors.teal;
      case 'Frappe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Widget pour afficher une barre de Kai
  Widget _buildKaiBar(String label, double value, double maxValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barre de progression avec valeur
        Stack(
          children: [
            // Barre de base
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / maxValue,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(KaiColors.kaiEnergy),
                minHeight: 14, // Plus petit que la barre de vie
              ),
            ),
            // Valeur numérique
            Positioned.fill(
              child: Center(
                child: Text(
                  "${value.toInt()}/${maxValue.toInt()}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
