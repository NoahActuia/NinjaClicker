import 'dart:async';
import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import '../models/saved_game.dart';
import '../models/technique.dart';
import '../models/ninja.dart';
import '../models/sensei.dart';
import '../models/resonance.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import '../services/resonance_service.dart';
import '../styles/kai_colors.dart';
import 'welcome_screen.dart';
import 'story/story_screen.dart';
import 'intro_video_screen.dart' hide KaiColors;
import '../widgets/chakra_button.dart';
import '../widgets/technique_list.dart';
import '../widgets/sensei_list.dart';
import '../widgets/resonance_list.dart';
import '../widgets/settings_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ninja_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show pow;
import 'ranking_screen.dart';
import 'technique_tree_screen.dart';
import 'combat_techniques_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.playerName,
    this.savedGame,
  });

  final String playerName;
  final SavedGame? savedGame;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Timer? _autoSaveTimer;
  Timer? _chakraSoundTimer; // Timer pour le son du chakra

  // Ajout de la variable _currentNinja
  Ninja? _currentNinja;

  // Variables pour le système de niveau
  int _totalXP = 0;
  int _playerLevel = 1;
  int _xpForNextLevel = 100;
  int _power = 0; // Score de puissance basé sur les techniques

  // Ajout d'une variable pour le combo actuel
  int _currentCombo = 0;

  // Variables pour le suivi du gain d'XP
  double _xpPerSecondPassive = 0; // XP gagnée passivement par seconde
  double _xpFromClicks = 0; // XP gagnée par les clics récents
  double _totalXpPerSecond = 0; // XP totale par seconde (passive + clics)
  double _xpPerSecond = 0; // Taux d'XP par seconde provenant des résonances
  DateTime _lastClickTime = DateTime.now(); // Horodatage du dernier clic
  List<DateTime> _clicksInLastSecond = []; // Liste des gains des clics récents
  Timer? _xpRateTimer; // Timer pour calculer le taux d'XP par seconde

  // Constantes pour le calcul du niveau
  final int _baseXPForLevel = 100;
  final double _levelScalingFactor = 1.5;

  // Liste des senseis
  List<Sensei> _senseis = [];

  // Nouvelles variables pour stocker les données du joueur
  int _playerStrength = 10;
  int _playerAgility = 10;
  int _playerChakra = 10;
  int _playerSpeed = 10;
  int _playerDefense = 10;
  int _xpPerClick = 1;
  double _passiveXp = 0;
  List<Technique> _playerTechniques = [];
  List<Sensei> _playerSenseis = [];
  Map<String, int> _techniqueLevels = {};
  Map<String, int> _senseiLevels = {};
  Map<String, int> _senseiQuantities = {};

  // Services
  final AudioService _audioService = AudioService();
  final SaveService _saveService = SaveService();
  final NinjaService _ninjaService = NinjaService();
  final ResonanceService _resonanceService = ResonanceService();

  // Techniques
  late List<Technique> _techniques = [];

  // Ajout des variables pour le système de Résonance
  List<Resonance> _allResonances = [];
  List<Resonance> _playerResonances = [];
  int _offlineXpGained = 0;
  bool _offlineXpClaimed = false;

  // Timer pour réinitialiser le combo
  Timer? _comboResetTimer;

  // Variables d'état du jeu
  double _accumulatedXp = 0.0; // Accumulateur pour les fractions d'XP passive

  // Calculer l'XP nécessaire pour le niveau suivant
  int _calculateXPForNextLevel(int currentLevel) {
    return (_baseXPForLevel * pow(currentLevel, _levelScalingFactor)).toInt();
  }

  // Mettre à jour le niveau basé sur l'XP totale
  void _updatePlayerLevel() {
    int level = 1;
    int xpNeeded = _baseXPForLevel;
    int remainingXP = _totalXP;

    // Tant qu'on a assez d'XP pour monter de niveau
    while (remainingXP >= xpNeeded) {
      remainingXP -= xpNeeded;
      level++;
      xpNeeded = _calculateXPForNextLevel(level);
    }

    setState(() {
      _playerLevel = level;
      _xpForNextLevel = xpNeeded;
    });

    // Mettre à jour le niveau du ninja si besoin
    if (_currentNinja != null && _playerLevel != _currentNinja!.level) {
      _currentNinja!.level = _playerLevel;
      _ninjaService.updateNinja(_currentNinja!);
    }
  }

  // Ajouter de l'XP et mettre à jour le niveau
  void _addXP(int amount) {
    setState(() {
      _totalXP += amount;
      // Ne plus augmenter la puissance directement
    });

    _updatePlayerLevel();
    _calculatePower(); // Recalculer la puissance basée sur les techniques
  }

  // Calculer la puissance basée sur la moyenne des niveaux des techniques
  void _calculatePower() {
    int totalTechniqueLevels = 0;
    int activeTechniques = 0;

    for (var technique in _techniques) {
      if (technique.niveau > 0) {
        totalTechniqueLevels += technique.niveau;
        activeTechniques++;
      }
    }

    if (activeTechniques == 0) {
      setState(() {
        _power = 0;
      });
    } else {
      // Calculer la puissance en fonction de la moyenne des niveaux des techniques
      int avgTechniqueLevel = totalTechniqueLevels ~/ activeTechniques;
      int newPower = (avgTechniqueLevel * 15).toInt();

      // Bonus pour chaque technique active
      newPower += activeTechniques * 5;

      setState(() {
        _power = newPower;
      });
    }

    // Mettre à jour le ninja si nécessaire
    if (_currentNinja != null) {
      _currentNinja!.power = _power;
    }
  }

  // Initialisation des techniques
  Future<void> _initTechniques() async {
    try {
      print(
          '==================== INITIALISATION DES TECHNIQUES ====================');

      // Charger toutes les techniques disponibles de Firebase
      final snapshot =
          await FirebaseFirestore.instance.collection('techniques').get();

      if (snapshot.docs.isEmpty) {
        print('Aucune technique trouvée dans Firebase');
        return;
      }

      // Liste des techniques disponibles
      final availableTechniques =
          snapshot.docs.map((doc) => Technique.fromFirestore(doc)).toList();

      // Vérifier que toutes les techniques ont un ID valide
      for (int i = 0; i < availableTechniques.length; i++) {
        final technique = availableTechniques[i];
        if (technique.id.isEmpty) {
          print(
              '⚠️ Technique sans ID trouvée: ${technique.name}. Document ID: ${snapshot.docs[i].id}');

          // Recréer une technique avec l'ID correct
          final correctedTechnique = Technique.fromFirestore(snapshot.docs[i]);
          availableTechniques[i] = correctedTechnique;

          print('✅ ID corrigé: ${correctedTechnique.id}');
        }
      }

      setState(() {
        _techniques = availableTechniques;
      });

      // Loguer toutes les techniques disponibles
      for (var technique in _techniques) {
        print(
            '- Technique disponible: ${technique.name} (ID: ${technique.id})');
      }

      print('${_techniques.length} techniques chargées depuis Firebase');
      print(
          '=================================================================');
    } catch (e) {
      print('⚠️ Erreur lors du chargement initial des techniques: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialiser l'audio
    _initAudio();

    // Initialiser le jeu dans un ordre précis
    _initializeGame();

    // Démarrer le calcul du taux d'XP par seconde
    _startXpRateCalculation();

    // Initialiser les résonances par défaut si nécessaire
    _initDefaultResonances();
  }

  @override
  void dispose() {
    // Arrêter tous les timers
    _timer.cancel();
    _autoSaveTimer?.cancel();
    _chakraSoundTimer?.cancel();
    _xpRateTimer?.cancel();
    _comboResetTimer?.cancel();

    // Arrêter et libérer les ressources audio
    _audioService.dispose();

    super.dispose();
  }

  Future<void> _initAudio() async {
    // S'assurer que tout son précédent est arrêté
    await _audioService.stopAmbiance();

    // Initialiser les ressources audio
    await _audioService.init();

    // Démarrer la musique d'ambiance
    await _audioService.startAmbiance();
  }

  // Méthode pour initialiser le jeu
  Future<void> _initializeGame() async {
    print('Initialisation du jeu...');
    // Réinitialiser l'état du jeu avant de charger un nouveau ninja
    _resetGameState();

    // Vérifier si un joueur est connecté
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Utilisateur non connecté');
      return;
    }

    // Chargement du ninja actuel
    await _loadCurrentNinja();

    // Charger les techniques et senseis du joueur
    await _loadPlayerTechniques();
    await _loadPlayerSenseis();

    // Charger les résonances du joueur
    await _loadPlayerResonances();

    // Vérifier s'il y a de l'XP accumulée hors-ligne
    await _checkOfflineXp();

    // Démarrer le timer pour les calculs par seconde
    _startTimer();

    print('Jeu initialisé avec succès');
  }

  // Réinitialiser l'état du jeu
  void _resetGameState() {
    setState(() {
      _totalXP = 0;
      _power = 0;
      _playerLevel = 1;
      _playerStrength = 10;
      _playerAgility = 10;
      _playerChakra = 10;
      _playerSpeed = 10;
      _playerDefense = 10;
      _xpPerClick = 1;
      _passiveXp = 0;
      _accumulatedXp = 0.0; // Réinitialiser l'accumulateur d'XP
      _currentNinja = null;
      _techniques.clear();
      _senseis.clear();
      _playerTechniques = [];
      _playerSenseis = [];
      _techniqueLevels = {};
      _senseiLevels = {};
      _senseiQuantities = {};
      _xpPerSecondPassive = 0;
      _xpFromClicks = 0;
      _totalXpPerSecond = 0;
      _clicksInLastSecond = [];

      // Réinitialiser les résonances
      _allResonances = [];
      _playerResonances = [];
      _offlineXpGained = 0;
      _offlineXpClaimed = false;
    });
  }

  // Charger le ninja actuel
  Future<void> _loadCurrentNinja() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Récupérer les ninjas de l'utilisateur
        final ninjas = await _ninjaService.getNinjasByUser(user.uid);

        if (ninjas.isNotEmpty) {
          // Si un nom est spécifié, chercher le ninja correspondant
          if (widget.playerName != null && widget.playerName!.isNotEmpty) {
            _currentNinja = ninjas.firstWhere(
              (ninja) => ninja.name == widget.playerName,
              orElse: () => ninjas.first,
            );
          } else {
            // Sinon, prendre le premier ninja
            _currentNinja = ninjas.first;
          }

          // Mettre à jour les données du joueur
          setState(() {
            _totalXP = _currentNinja!.xp;
            _playerLevel = _currentNinja!.level;
            _playerStrength = _currentNinja!.strength;
            _playerAgility = _currentNinja!.agility;
            _playerChakra = _currentNinja!.chakra;
            _playerSpeed = _currentNinja!.speed;
            _playerDefense = _currentNinja!.defense;
            _xpPerClick = _currentNinja!.xpPerClick;
            _passiveXp = _currentNinja!.passiveXp;
            _xpForNextLevel = _playerLevel * 100;
          });

          // Charger les techniques et senseis
          await _loadPlayerTechniques();
          await _loadPlayerSenseis();
        } else {
          print("Aucun ninja trouvé pour cet utilisateur");
        }
      } catch (e) {
        print("Erreur lors du chargement du ninja: $e");
      }
    } else {
      print("Aucun utilisateur connecté");
    }
  }

  // Charger les techniques du joueur
  Future<void> _loadPlayerTechniques() async {
    if (_currentNinja == null) {
      print("Aucun ninja actif pour charger les techniques");
      return;
    }

    try {
      await _loadTechniques();

      if (_techniques.isNotEmpty && _currentNinja!.techniques.isNotEmpty) {
        setState(() {
          _playerTechniques = _techniques
              .where((technique) =>
                  _currentNinja!.techniques.contains(technique.id))
              .toList();

          _techniqueLevels =
              Map<String, int>.from(_currentNinja!.techniqueLevels);
        });
        print("Techniques du joueur chargées: ${_playerTechniques.length}");
      }
    } catch (e) {
      print("Erreur lors du chargement des techniques du joueur: $e");
    }
  }

  // Charger les senseis du joueur
  Future<void> _loadPlayerSenseis() async {
    if (_currentNinja == null) {
      print("Aucun ninja actif pour charger les senseis");
      return;
    }

    try {
      await _loadSenseis();

      if (_senseis.isNotEmpty && _currentNinja!.senseis.isNotEmpty) {
        setState(() {
          _playerSenseis = _senseis
              .where((sensei) => _currentNinja!.senseis.contains(sensei.id))
              .toList();

          _senseiLevels = Map<String, int>.from(_currentNinja!.senseiLevels);
          _senseiQuantities =
              Map<String, int>.from(_currentNinja!.senseiQuantities);
        });
        print("Senseis du joueur chargés: ${_playerSenseis.length}");
      }
    } catch (e) {
      print("Erreur lors du chargement des senseis du joueur: $e");
    }
  }

  // Méthode pour charger les techniques depuis Firebase
  Future<void> _loadTechniques() async {
    try {
      if (_currentNinja == null) {
        print('Pas de ninja actif, impossible de charger ses techniques');
        return;
      }

      // DEBUG
      print(
          '==================== CHARGEMENT DES TECHNIQUES ====================');

      // Charger toutes les techniques disponibles si pas encore fait
      if (_techniques.isEmpty) {
        await _initTechniques();
        print('Techniques disponibles initialisées: ${_techniques.length}');
      } else {
        print('Techniques déjà chargées: ${_techniques.length}');
      }

      // Charger les techniques du ninja actif pour obtenir leurs niveaux DIRECTEMENT depuis la DB
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('ninjaTechniques')
            .where('ninjaId', isEqualTo: _currentNinja!.id)
            .get();

        print(
            'Relations techniques-ninja trouvées: ${querySnapshot.docs.length}');

        if (querySnapshot.docs.isEmpty) {
          print(
              'Le ninja ${_currentNinja!.name} n\'a pas de techniques en DB (relation vide)');
          return;
        }

        // Afficher toutes les relations
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final techniqueId = data['techniqueId'] as String;
          final level = data['level'] as int? ?? 0;
          print('- Relation trouvée: techniqueId=$techniqueId, level=$level');
        }

        // Mise à jour des niveaux pour les techniques déjà chargées
        setState(() {
          for (var doc in querySnapshot.docs) {
            final data = doc.data();
            final techniqueId = data['techniqueId'] as String;
            final level = data['level'] as int? ?? 0;

            final index = _techniques.indexWhere((t) => t.id == techniqueId);

            if (index >= 0) {
              // Mettre à jour DIRECTEMENT la propriété level (qui contrôle niveau)
              _techniques[index].level = level;

              print(
                  '✅ Technique mise à jour: ${_techniques[index].name} (ID: ${_techniques[index].id})');
              print(
                  '   Level = ${_techniques[index].level}, Niveau = ${_techniques[index].niveau}');
            } else {
              print(
                  '⚠️ Technique non trouvée dans la liste: ID=$techniqueId, niveau=$level');

              // Noter les techniques manquantes pour les charger après le setState
              _loadMissingTechnique(techniqueId, level);
            }
          }
        });
      } catch (e) {
        print(
            '⚠️ Erreur lors du chargement des relations techniques-ninja: $e');
      }

      // Vérifier les résultats finaux
      int techniquesActives = 0;
      for (var technique in _techniques) {
        if (technique.niveau > 0) {
          techniquesActives++;
          print(
              '▶️ Technique active: ${technique.name} (niveau=${technique.niveau})');
        }
      }

      print('Techniques actives chargées: $techniquesActives');
      print(
          '=================================================================');
    } catch (e) {
      print('⚠️ Erreur lors de la mise à jour des niveaux des techniques: $e');
    }
  }

  // Méthode auxiliaire pour charger une technique manquante
  Future<void> _loadMissingTechnique(String techniqueId, int level) async {
    try {
      final techniqueDoc = await FirebaseFirestore.instance
          .collection('techniques')
          .doc(techniqueId)
          .get();

      if (techniqueDoc.exists) {
        final technique = Technique.fromFirestore(techniqueDoc);
        technique.level = level; // Définir directement le niveau

        setState(() {
          _techniques.add(technique);
        });
        print(
            '➕ Technique manquante ajoutée: ${technique.name} (niveau ${technique.niveau})');
      }
    } catch (e) {
      print('⚠️ Erreur lors du chargement de la technique manquante: $e');
    }
  }

  // Méthode pour ouvrir l'écran de classement
  void _openRankingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RankingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: KaiColors.background,
          elevation: 12,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  KaiColors.background,
                  KaiColors.background.withOpacity(0.7),
                  KaiColors.accent.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              // Logo et nom du joueur regroupés
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 32,
                      width: 32,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.playerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Niv. $_playerLevel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Indicateur de puissance
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KaiColors.accent.withOpacity(0.7),
                    KaiColors.primaryDark.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt, // Icône de puissance au lieu de l'éclair
                    color: KaiColors
                        .accent, // Couleur ambre pour mieux la distinguer
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatNumber(
                        _power), // Afficher la puissance au lieu de l'XP
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menu regroupant plusieurs fonctionnalités
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.white),
              offset: const Offset(0, 40),
              onSelected: (value) {
                switch (value) {
                  case 'ranking':
                    _openRankingScreen();
                    break;
                  case 'story':
                    _goToStoryMode();
                    break;
                  case 'technique_tree':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TechniqueTreeScreen(),
                      ),
                    );
                    break;
                  case 'combat_techniques':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CombatTechniquesScreen(),
                      ),
                    );
                    break;
                  case 'settings':
                    _showSettingsDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
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
              ],
            ),

            // Bouton Quitter conservé séparément
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: _returnToMainMenu,
              tooltip: 'Quitter',
            ),
          ],
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  KaiColors.accent.withOpacity(0.6),
                  KaiColors.accent.withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            tabs: [
              Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_fix_high, size: 18),
                    SizedBox(width: 4),
                    Text('Résonances'),
                  ],
                ),
              ),
              Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.people, size: 18),
                    SizedBox(width: 4),
                    Text('Senseis'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Container(
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
                // Partie supérieure avec le bouton de chakra et les stats
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Indicateur de génération XP passive
                      Container(
                        margin: const EdgeInsets.only(
                            top: 16, bottom: 16, left: 16, right: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: KaiColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: KaiColors.accent.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time,
                                    color: KaiColors.primaryDark, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Génération passive: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: KaiColors.primaryDark,
                                  ),
                                ),
                                Text(
                                  '${_xpPerSecondPassive.toStringAsFixed(3)} XP/s',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            if (_playerResonances.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Somme des résonances actives (${_playerResonances.where((r) => r.isUnlocked).length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Bouton Chakra
                      Expanded(
                        child: Center(
                          child: ChakraButton(
                            onTap: (gainXp) => _incrementerXp(gainXp),
                            puissance: _currentCombo,
                            totalXP: _totalXP,
                          ),
                        ),
                      ),

                      // Statistiques
                    ],
                  ),
                ),

                // Section des onglets avec TabBarView
                Expanded(
                  flex: 2, // Agrandir la section des Résonances/Senseis
                  child: TabBarView(
                    children: [
                      // Premier onglet: Résonances
                      ResonanceList(
                        resonances: _allResonances,
                        xp: _totalXP,
                        onUnlockResonance: _unlockResonance,
                        onUpgradeResonance: _upgradeResonance,
                        onRefresh: _loadPlayerResonances,
                      ),

                      // Deuxième onglet: Senseis
                      SenseiList(
                        senseis: _senseis,
                        puissance: _totalXP,
                        onAcheterSensei: _acheterSensei,
                        onAmeliorerSensei: _ameliorerSensei,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthode pour formater les grands nombres
  String _formatNumber(num number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // Méthode pour aller au mode histoire
  void _goToStoryMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryScreen(
          puissance: _power,
          onMissionComplete:
              (missionPuissance, missionClones, missionTechniques) {
            setState(() {
              _power += missionPuissance;

              // Ajouter les techniques gagnées
              for (var technique in missionTechniques) {
                // Vérifier si la technique existe déjà
                var existingTechnique = _techniques.firstWhere(
                  (t) => t.id == technique.id,
                  orElse: () => technique,
                );

                if (!_techniques.contains(existingTechnique)) {
                  _techniques.add(existingTechnique);
                }

                existingTechnique.niveau += 1;

                // Sauvegarder immédiatement la technique
                if (_currentNinja != null) {
                  _ninjaService.addTechniqueToNinja(
                      _currentNinja!.id, existingTechnique.id);
                }
              }

              // Sauvegarde complète après la mission
              _saveGame();
            });
          },
        ),
      ),
    );
  }

  // Méthode pour afficher la boîte de dialogue des paramètres
  void _showSettingsDialog() {
    showSettingsDialog(
      context: context,
      audioService: _audioService,
    );
  }

  // Méthode pour retourner au menu principal
  void _returnToMainMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Quitter la partie',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
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
                // S'assurer que lastConnected est mis à jour avant de quitter
                if (_currentNinja != null) {
                  _currentNinja!.lastConnected = DateTime.now();
                }

                // Sauvegarder automatiquement avant de quitter
                await _saveGame();

                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomeScreen()),
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

  // Méthode pour incrémenter l'XP en cliquant, ajustée pour le ChakraButton
  void _incrementerXp(int bonusXp, [double multiplier = 1.0]) {
    // Ne pas multiplier le xpPerClick, utiliser uniquement le bonusXp qui est envoyé par le ChakraButton
    final int xpGain = bonusXp;

    setState(() {
      _totalXP += xpGain;
      _updatePlayerLevel();
      _clicksInLastSecond.add(DateTime.now());
      // Incrémenter le compteur de combo (sera montré sur le bouton)
      _currentCombo++;
    });

    // Réinitialiser le compteur de combo après 1.5 secondes d'inactivité
    _startComboResetTimer();
  }

  // Démarrer un timer pour réinitialiser le combo
  void _startComboResetTimer() {
    // Annuler l'ancien timer s'il existe
    _comboResetTimer?.cancel();

    // Réduire le délai à 250ms pour correspondre à l'animation plus rapide
    _comboResetTimer = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        _currentCombo = 0;
      });
    });
  }

  // Méthode pour démarrer le timer
  void _startTimer() {
    // Démarrer la génération automatique de puissance
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _genererPuissanceAutomatique();
    });

    // Configurer la sauvegarde automatique toutes les 2 minutes
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _saveGame();
      print('Sauvegarde automatique effectuée');
    });
  }

  // Générer de la puissance automatiquement (à chaque tick du timer)
  void _genererPuissanceAutomatique() {
    // S'assurer que nous avons une valeur positive d'XP passive
    if (_xpPerSecondPassive <= 0) {
      // Actualiser la valeur depuis les résonances au cas où elle n'aurait pas été mise à jour
      _updatePassiveXpRate();
      return;
    }

    setState(() {
      // Ajouter l'XP passive à l'accumulateur
      _accumulatedXp += _xpPerSecondPassive;

      // Extraire la partie entière
      int xpToAdd = _accumulatedXp.floor();

      // Si nous avons au moins 1 XP entier à ajouter
      if (xpToAdd > 0) {
        _totalXP += xpToAdd;
        // Ne conserver que la partie fractionnelle pour la prochaine fois
        _accumulatedXp -= xpToAdd;
      }

      _updatePlayerLevel();
    });
  }

  // Méthode pour charger les senseis depuis Firebase
  Future<void> _loadSenseis() async {
    try {
      // D'abord charger tous les senseis disponibles
      final snapshot =
          await FirebaseFirestore.instance.collection('senseis').get();

      if (snapshot.docs.isEmpty) {
        print('Aucun sensei trouvé dans Firebase');
        return;
      }

      // Liste des senseis disponibles
      final availableSenseis =
          snapshot.docs.map((doc) => Sensei.fromFirestore(doc)).toList();

      setState(() {
        _senseis = availableSenseis;
      });

      print('${_senseis.length} senseis chargés depuis Firebase');

      // Ensuite, si un ninja est actif, charger ses senseis pour les niveaux et quantités
      if (_currentNinja != null) {
        final ninjaSenseis =
            await _ninjaService.getNinjaSenseis(_currentNinja!.id);

        if (ninjaSenseis.isNotEmpty) {
          setState(() {
            // Mettre à jour les niveaux et quantités des senseis existants
            for (var ninjaSensei in ninjaSenseis) {
              final index = _senseis.indexWhere((s) => s.id == ninjaSensei.id);
              if (index >= 0) {
                _senseis[index].level = ninjaSensei.level;
                _senseis[index].quantity = ninjaSensei.quantity;
              }
            }
          });

          print(
              'Niveaux et quantités des senseis mis à jour: ${ninjaSenseis.length} senseis du ninja');
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des senseis: $e');
    }
  }

  // Méthode pour acheter un sensei
  void _acheterSensei(Sensei sensei) {
    final cout = sensei.getCurrentCost();
    // Vérifier que le sensei n'a pas déjà été acheté
    if (_totalXP >= cout && sensei.quantity == 0) {
      // Utiliser l'XP au lieu de la puissance
      setState(() {
        _totalXP -= cout; // Déduire de l'XP
        sensei.quantity += 1;
      });

      // Sauvegarder dans Firebase
      if (_currentNinja != null) {
        _ninjaService.addSenseiToNinja(_currentNinja!.id, sensei.id);
        print(
            'Sensei ${sensei.name} ajouté au ninja ${_currentNinja!.name} (Quantité: ${sensei.quantity})');

        // Sauvegarde automatique après l'achat d'un sensei
        _saveGame();
      }
    }
  }

  // Méthode pour améliorer un sensei
  void _ameliorerSensei(Sensei sensei) {
    // Coût d'amélioration (par exemple 2x le coût d'achat)
    final cout = sensei.getCurrentCost() * 2;
    if (_totalXP >= cout && sensei.quantity > 0) {
      // Utiliser l'XP au lieu de la puissance
      setState(() {
        _totalXP -= cout; // Déduire de l'XP
        sensei.level += 1;
      });

      // Sauvegarder dans Firebase
      if (_currentNinja != null) {
        _ninjaService.upgradeSensei(_currentNinja!.id, sensei.id);
        print('Sensei ${sensei.name} amélioré au niveau ${sensei.level}');

        // Sauvegarde automatique après l'amélioration d'un sensei
        _saveGame();
      }
    }
  }

  // Sauvegarder la partie actuelle
  Future<void> _saveGame() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && _currentNinja != null) {
        // Mettre à jour le ninja avec les valeurs actuelles
        _currentNinja!.xp = _totalXP; // Sauvegarder l'XP totale
        _currentNinja!.level = _playerLevel;
        _currentNinja!.power = _power; // Sauvegarder le score de puissance

        // Mettre à jour les autres attributs du ninja selon les besoins
        _currentNinja!.passiveXp = _passiveXp;

        // Mettre à jour la date de dernière connexion
        _currentNinja!.lastConnected = DateTime.now();

        // Mettre à jour le ninja dans Firebase
        await _ninjaService.updateNinja(_currentNinja!);
        print(
            'Ninja sauvegardé: ${_currentNinja!.name} (${_currentNinja!.xp} XP, niveau ${_currentNinja!.level})');
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  // Vérifier s'il y a de l'XP accumulée hors-ligne
  Future<void> _checkOfflineXp() async {
    if (_currentNinja == null) return;

    // Calculer l'XP hors-ligne
    final offlineXp = await _resonanceService.calculateOfflineXp(
        _currentNinja!.id, _currentNinja!.lastConnected);

    if (offlineXp > 0) {
      setState(() {
        _offlineXpGained = offlineXp;
        _offlineXpClaimed = false;
      });

      // Afficher la notification d'XP hors-ligne
      _showOfflineXpDialog();
    }
  }

  // Afficher la notification d'XP hors-ligne
  void _showOfflineXpDialog() {
    if (_offlineXpGained <= 0 || _offlineXpClaimed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('XP Passive Accumulée'),
          content: Text(
            'Pendant votre absence, vos Résonances ont généré $_offlineXpGained XP!',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _claimOfflineXp();
              },
              child: const Text('Récupérer'),
            ),
          ],
        ),
      );
    });
  }

  // Récupérer l'XP hors-ligne
  void _claimOfflineXp() {
    if (_offlineXpGained <= 0 || _offlineXpClaimed) return;

    setState(() {
      _addXP(_offlineXpGained);
      _offlineXpClaimed = true;
      _offlineXpGained = 0;
    });
  }

  // Débloquer une résonance
  Future<void> _unlockResonance(Resonance resonance) async {
    if (_currentNinja == null || _totalXP < resonance.xpCostToUnlock) return;

    // Soustraire le coût
    setState(() {
      _totalXP -= resonance.xpCostToUnlock;
    });

    // Débloquer la résonance
    final success =
        await _resonanceService.unlockResonance(_currentNinja!.id, resonance);

    if (success) {
      // Mettre à jour l'affichage
      await _loadPlayerResonances();

      // Jouer un son
      _audioService.playSound('unlock.mp3');
    } else {
      // Rembourser le joueur en cas d'échec
      setState(() {
        _totalXP += resonance.xpCostToUnlock;
      });
    }
  }

  // Améliorer le niveau de lien d'une résonance
  Future<void> _upgradeResonance(Resonance resonance) async {
    if (_currentNinja == null || !resonance.isUnlocked) return;

    // Vérifier que le niveau actuel est strictement inférieur au niveau maximum
    if (resonance.linkLevel >= resonance.maxLinkLevel) {
      print(
          'Cette résonance a déjà atteint son niveau maximum (${resonance.maxLinkLevel})');
      return;
    }

    final upgradeCost = resonance.getUpgradeCost();

    if (_totalXP < upgradeCost) return;

    // Soustraire le coût
    setState(() {
      _totalXP -= upgradeCost;
    });

    // Enregistrer l'amélioration
    resonance.linkLevel++;
    final success = await _resonanceService.upgradeResonanceLink(
        _currentNinja!.id, resonance);

    if (success) {
      // Mettre à jour l'affichage
      await _loadPlayerResonances();

      // Jouer un son
      _audioService.playSound('upgrade.mp3');
    } else {
      // Rembourser le joueur en cas d'échec
      setState(() {
        _totalXP += upgradeCost;
      });
      resonance.linkLevel--;
    }
  }

  // Charger les résonances du joueur
  Future<void> _loadPlayerResonances() async {
    if (_currentNinja == null) {
      print("Aucun ninja actif pour charger les résonances");
      return;
    }

    try {
      // Charger toutes les résonances disponibles
      final allResonances = await _resonanceService.getAllResonances();

      // Charger les résonances du joueur
      final playerResonances =
          await _resonanceService.getNinjaResonances(_currentNinja!.id);

      // Si le joueur n'a pas encore de résonances, initialiser avec toutes les résonances disponibles
      if (playerResonances.isEmpty) {
        setState(() {
          _allResonances = allResonances;
          _playerResonances = [];
        });
      } else {
        // Fusionner les résonances du joueur avec toutes les résonances disponibles
        final availableResonanceIds =
            playerResonances.map((r) => r.id).toList();
        final otherResonances = allResonances
            .where((r) => !availableResonanceIds.contains(r.id))
            .toList();

        setState(() {
          _playerResonances = playerResonances;
          _allResonances = [...playerResonances, ...otherResonances];
        });
      }

      print("Résonances du joueur chargées: ${_playerResonances.length}");
      print("Total des résonances disponibles: ${_allResonances.length}");

      // Mettre à jour l'XP passive par heure
      await _updatePassiveXpRate();
    } catch (e) {
      print("Erreur lors du chargement des résonances du joueur: $e");
    }
  }

  // Mettre à jour le taux d'XP passive par heure
  Future<void> _updatePassiveXpRate() async {
    if (_currentNinja == null) return;

    try {
      // Calculer directement le taux d'XP par seconde à partir des résonances chargées
      print('========== CALCUL DU TAUX D\'XP PASSIVE ==========');
      double totalXpPerSecond = 0;

      // Afficher toutes les résonances débloquées pour le débogage
      for (var resonance in _playerResonances) {
        print('Résonance: ${resonance.name}');
        print('  isUnlocked = ${resonance.isUnlocked}');
        print('  linkLevel = ${resonance.linkLevel}');
        print('  xpPerSecond (base) = ${resonance.xpPerSecond}');

        if (resonance.isUnlocked) {
          final xpContribution = resonance.getXpPerSecond();
          totalXpPerSecond += xpContribution;
          print(
              '  --> Contribution XP/s = $xpContribution (${resonance.getXpPerSecondFormatted()})');
        } else {
          print('  --> Non débloquée, pas de contribution XP');
        }
      }

      print('Total XP/s calculé: $totalXpPerSecond');

      // Mettre à jour les valeurs locales
      setState(() {
        // Ne pas arrondir avec ceil(), utiliser la valeur exacte
        _passiveXp =
            totalXpPerSecond; // Utiliser round() au lieu de ceil() pour être plus précis
        _xpPerSecondPassive =
            totalXpPerSecond; // Garder la valeur exacte pour l'affichage
      });

      print(
          'Taux d\'XP passive mis à jour: $_passiveXp XP/s (valeur exacte: $_xpPerSecondPassive)');
      print('================================================');

      // Mettre à jour le ninja dans la base de données (en parallèle)
      if (_currentNinja != null) {
        _currentNinja!.passiveXp = _passiveXp;
        _resonanceService.updateNinjaWithPassiveXp(_currentNinja!);
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du taux d\'XP passive: $e');
    }
  }

  // Méthode pour démarrer le calcul du taux d'XP par seconde
  void _startXpRateCalculation() {
    _xpRateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Nettoyer les clics plus vieux qu'une seconde
        _clicksInLastSecond.removeWhere(
            (clickTime) => DateTime.now().difference(clickTime).inSeconds >= 1);

        // Calculer l'XP provenant des clics récents
        _xpFromClicks = _clicksInLastSecond.length * _xpPerClick.toDouble();

        // Calculer l'XP passive (basée sur les résonances et senseis)
        _xpPerSecondPassive = _passiveXp.toDouble();

        // Calculer le taux d'XP total par seconde
        _totalXpPerSecond = _xpFromClicks + _xpPerSecondPassive;
      });
    });
  }

  // Initialiser les résonances par défaut si nécessaire
  Future<void> _initDefaultResonances() async {
    try {
      // Vérifier si des résonances existent dans la base de données
      final allResonances = await _resonanceService.getAllResonances();

      if (allResonances.isEmpty) {
        // Si aucune résonance n'existe, initialiser les résonances par défaut
        await _resonanceService.initDefaultResonances();

        // Recharger les résonances
        _allResonances = await _resonanceService.getAllResonances();

        // Charger les résonances du joueur si un ninja est sélectionné
        if (_currentNinja != null) {
          await _loadPlayerResonances();
        }
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des résonances: $e');
    }
  }

  // Forcer la réinitialisation des résonances dans la base de données
  Future<void> _reinitializeResonances() async {
    try {
      // Réinitialiser les résonances par défaut
      await _resonanceService.initDefaultResonances();

      // Recharger les résonances
      await _loadPlayerResonances();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Résonances réinitialisées avec succès'),
            backgroundColor: KaiColors.accent,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la réinitialisation des résonances: $e');

      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
