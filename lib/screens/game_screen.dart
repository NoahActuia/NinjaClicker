import 'dart:async';
import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import '../models/saved_game.dart';
import '../models/technique.dart';
import '../models/ninja.dart';
import '../models/sensei.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import 'welcome_screen.dart';
import 'story/story_screen.dart';
import 'intro_video_screen.dart'; // Pour accéder à KaiColors
import '../widgets/chakra_button.dart';
import '../widgets/technique_list.dart';
import '../widgets/sensei_list.dart';
import '../widgets/settings_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ninja_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show pow;
import 'ranking_screen.dart';

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

  // Variables pour le suivi du gain d'XP
  double _xpPerSecondPassive = 0; // XP gagnée passivement par seconde
  double _xpFromClicks = 0; // XP gagnée par les clics récents
  double _totalXpPerSecond = 0; // XP totale par seconde (passive + clics)
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
  int _passiveXp = 0;
  List<Technique> _playerTechniques = [];
  List<Sensei> _playerSenseis = [];
  Map<String, int> _techniqueLevels = {};
  Map<String, int> _senseiLevels = {};
  Map<String, int> _senseiQuantities = {};

  // Services
  final AudioService _audioService = AudioService();
  final SaveService _saveService = SaveService();
  final NinjaService _ninjaService = NinjaService();

  // Techniques
  late List<Technique> _techniques = [];

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
  }

  @override
  void dispose() {
    // Arrêter tous les timers
    _timer.cancel();
    _autoSaveTimer?.cancel();
    _chakraSoundTimer?.cancel();
    _xpRateTimer?.cancel();

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
          toolbarHeight: 80,
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
                  KaiColors.kaiNeutral.withOpacity(0.6),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 42,
                  width: 42,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          KaiColors.background,
                          KaiColors.background.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.playerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: KaiColors.kaiNeutral.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: KaiColors.kaiNeutral,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Niveau $_playerLevel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    KaiColors.kaiNeutral
                        .withOpacity(0.7), // Couleur pour la puissance
                    KaiColors.background.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
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
                    Icons.bolt, // Icône de puissance
                    color: Colors.white,
                    size: 22,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatNumber(_power), // Afficher la puissance
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildActionButton(
              icon: Icons.emoji_events,
              tooltip: 'Classement',
              onPressed: _openRankingScreen,
            ),
            _buildActionButton(
              icon: Icons.book,
              tooltip: 'Mode Histoire',
              onPressed: _goToStoryMode,
            ),
            _buildActionButton(
              icon: Icons.settings,
              tooltip: 'Paramètres',
              onPressed: _showSettingsDialog,
            ),
            _buildActionButton(
              icon: Icons.exit_to_app,
              tooltip: 'Quitter',
              onPressed: _returnToMainMenu,
              rightMargin: 12,
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
                  KaiColors.kaiNeutral.withOpacity(0.6),
                  KaiColors.kaiNeutral.withOpacity(0.3),
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
                icon: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bolt, size: 20),
                      SizedBox(width: 8),
                      Text('Techniques'),
                    ],
                  ),
                ),
              ),
              Tab(
                icon: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.people, size: 20),
                      SizedBox(width: 8),
                      Text('Senseis'),
                    ],
                  ),
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
                // Partie supérieure avec Naruto et les statistiques
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Zone cliquable principale avec l'image de Naruto
                        Expanded(
                          child: Center(
                            child: ChakraButton(
                              onTap: _incrementerPuissance,
                              puissance: _totalXP,
                            ),
                          ),
                        ),

                        // Statistiques
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: KaiColors.background.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue
                                              .shade600, // Couleur bleue pour l'XP
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons
                                              .whatshot, // Nouvelle icône pour l'XP
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'XP',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            _formatNumber(_totalXP),
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue
                                                  .shade800, // Couleur bleue pour l'XP
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.speed,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'XP/seconde',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                _formatNumber(
                                                    _totalXpPerSecond),
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade800,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              if (_xpFromClicks > 0)
                                                Text(
                                                  '(+${_formatNumber(_xpFromClicks)} clics)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.purple.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Section des techniques et senseis avec TabBarView
                Expanded(
                  child: TabBarView(
                    children: [
                      // Onglet des techniques
                      _buildTechniquesList(),

                      // Onglet des senseis
                      _buildSenseisList(),
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

  // Helper pour créer un bouton d'action stylisé
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    double rightMargin = 4,
  }) {
    return Container(
      margin: EdgeInsets.only(right: rightMargin),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24,
          shadows: const [
            Shadow(
              color: Colors.black45,
              blurRadius: 2,
              offset: Offset(1, 1),
            ),
          ],
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
        padding: const EdgeInsets.all(8),
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

  // Formater le temps écoulé depuis la dernière connexion
  String _formatTimeSinceLastConnection(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} heure${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return '${duration.inSeconds} seconde${duration.inSeconds > 1 ? 's' : ''}';
    }
  }

  // Afficher une boîte de dialogue pour les gains obtenus hors ligne
  void _showOfflineGainDialog(int xpGained, Duration timeSinceLastConnection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Gains pendant votre absence',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: KaiColors.background,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Pendant votre absence de ${_formatTimeSinceLastConnection(timeSinceLastConnection)}, vos senseis ont généré:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: KaiColors.kaiNeutral, size: 28),
                const SizedBox(width: 8),
                Text(
                  '+${_formatNumber(xpGained)} XP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: KaiColors.background,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Continuez à recruter des senseis pour gagner plus de puissance même lorsque vous êtes absent !',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KaiColors.background,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child:
                const Text('Genial !', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Affichage amélioré de la liste des techniques
  Widget _buildTechniquesList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: KaiColors.background),
                    const SizedBox(width: 8),
                    const Text(
                      'Techniques Ninja',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Total: ${_techniques.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _techniques.length,
              itemBuilder: (context, index) {
                final technique = _techniques[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: technique.niveau > 0
                          ? KaiColors.background.withOpacity(0.2)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar de la technique
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: KaiColors.background.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _getTechniqueIcon(technique),
                              color: KaiColors.background,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Zone centrale: nom, niveau, description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Nom de la technique
                              Text(
                                technique.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Description
                              Text(
                                technique.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Badge de niveau
                              if (technique.niveau > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KaiColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Niv. ${technique.niveau}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Bouton d'achat
                        SizedBox(
                          height: 24,
                          child: ElevatedButton(
                            onPressed: _totalXP >= technique.cost
                                ? () => _acheterTechnique(technique)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .blue.shade600, // Couleur bleue pour l'XP
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.whatshot,
                                    size: 10, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  _formatNumber(technique.cost),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  "XP",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // Affichage amélioré de la liste des senseis
  Widget _buildSenseisList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.indigo.shade800),
                    const SizedBox(width: 8),
                    const Text(
                      'Senseis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Total: ${_senseis.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: _senseis.length,
              itemBuilder: (context, index) {
                final sensei = _senseis[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: sensei.quantity > 0
                          ? Colors.indigo.shade200
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Première ligne: Avatar, Nom et Badges
                        Row(
                          children: [
                            // Avatar du sensei
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.indigo.shade800,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nom et badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          sensei.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (sensei.quantity > 0)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(right: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade800,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'x${sensei.quantity}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (sensei.level > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Niv. ${sensei.level}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Production par seconde
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_formatNumber(sensei.getTotalXpPerSecond())}/s',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Description du sensei
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 4, bottom: 4, left: 48),
                          child: Text(
                            sensei.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Boutons d'action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Bouton d'achat (uniquement si quantity = 0)
                            if (sensei.quantity == 0)
                              SizedBox(
                                height: 24,
                                child: ElevatedButton(
                                  onPressed: _totalXP >= sensei.getCurrentCost()
                                      ? () => _acheterSensei(sensei)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue
                                        .shade600, // Couleur bleue pour l'XP
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.whatshot,
                                          size: 10, color: Colors.white),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatNumber(sensei.getCurrentCost()),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        "XP",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Bouton d'amélioration (toujours visible si quantity > 0)
                            if (sensei.quantity > 0)
                              SizedBox(
                                height: 24,
                                child: ElevatedButton(
                                  onPressed:
                                      _totalXP >= sensei.getCurrentCost() * 2
                                          ? () => _ameliorerSensei(sensei)
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.whatshot,
                                          size: 10, color: Colors.white),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatNumber(
                                            sensei.getCurrentCost() * 2),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        "XP",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.upgrade,
                                        size: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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

  // Obtenir l'icône appropriée pour une technique
  IconData _getTechniqueIcon(Technique technique) {
    switch (technique.effect) {
      case 'damage':
        return Icons.flash_on;
      case 'clone':
        return Icons.people;
      case 'boost':
        return Icons.trending_up;
      case 'warp':
        return Icons.sync;
      case 'summon':
        return Icons.pets;
      case 'area_damage':
        return Icons.radar;
      case 'copy':
        return Icons.remove_red_eye;
      default:
        return Icons.extension;
    }
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

    // Démarrer le calcul du taux d'XP par seconde
    _startXpRateCalculation();
  }

  // Méthode pour démarrer le calcul du taux d'XP par seconde
  void _startXpRateCalculation() {
    // Calcul initial
    _updateXpPerSecond();

    // Mettre à jour toutes les secondes
    _xpRateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateXpPerSecond();
    });
  }

  // Mettre à jour le taux d'XP par seconde
  void _updateXpPerSecond() {
    // Calculer l'XP passive (des senseis)
    final int passiveXp =
        _senseis.fold(0, (sum, s) => sum + s.getTotalXpPerSecond());

    // Filtrer les clics des 5 dernières secondes
    final now = DateTime.now();
    _clicksInLastSecond = _clicksInLastSecond.where((timestamp) {
      return now.difference(timestamp).inSeconds < 5;
    }).toList();

    // Calculer l'XP moyenne des clics récents par seconde
    final int clickXpPerSecond = _clicksInLastSecond.isEmpty
        ? 0
        : (_clicksInLastSecond.length ~/ 5) * _xpPerClick;

    setState(() {
      _xpPerSecondPassive = passiveXp.toDouble();
      _xpFromClicks = clickXpPerSecond.toDouble();
      _totalXpPerSecond = (passiveXp + clickXpPerSecond).toDouble();
    });
  }

  // Générer de la puissance automatiquement (à chaque tick du timer)
  void _genererPuissanceAutomatique() {
    if (_senseis.isEmpty) return;

    double puissanceGeneree = 0;
    for (var sensei in _senseis) {
      puissanceGeneree += sensei.getTotalXpPerSecond();
    }

    if (puissanceGeneree > 0) {
      setState(() {
        _totalXP += puissanceGeneree.round();
        _updateXP();
      });
    }
  }

  // Méthode appelée lors du clic sur le chakra button
  void _incrementerPuissance(int bonusXp, double multiplier) {
    final int xpGain = (_xpPerClick * multiplier).round() + bonusXp;
    setState(() {
      _totalXP += xpGain;
      _updateXP();
      _clicksInLastSecond.add(DateTime.now());
    });
  }

  void _updateXP() {
    // Mettre à jour le ninja en base de données
    if (_currentNinja != null) {
      _currentNinja!.xp = _totalXP;
      _ninjaService.updateNinja(_currentNinja!);
    }

    // Recalculer la puissance basée sur les techniques plutôt que sur l'XP
    _calculatePower();
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

  // Méthode pour acheter une technique
  void _acheterTechnique(Technique technique) {
    if (_totalXP >= technique.cost) {
      // Utiliser l'XP au lieu de la puissance
      // Sauvegarder l'état précédent pour pouvoir annuler en cas d'erreur
      final previousLevel = technique.niveau;

      // Mettre à jour l'état localement
      setState(() {
        _totalXP -= technique.cost; // Déduire de l'XP
        technique.level =
            technique.level + 1; // Modifier directement level au lieu de niveau
      });

      // Recalculer la puissance après l'achat
      _calculatePower();

      // Sauvegarder l'achat de la technique dans Firebase
      if (_currentNinja != null) {
        try {
          print('==================== ACHAT DE TECHNIQUE ====================');
          print('ID de la technique à acheter: ${technique.id}');
          print('Niveau avant achat: ${previousLevel}');
          print('Nouveau niveau: ${technique.niveau}');

          // Utiliser addTechniqueToNinja qui gère l'ajout ou mise à jour
          _ninjaService
              .addTechniqueToNinja(_currentNinja!.id, technique.id)
              .then((_) {
            print('✅ Technique sauvegardée en DB: ${technique.name}');

            // Vérifier que la technique apparaît bien comme apprise
            print('Level final: ${technique.level}');
            print('Niveau final: ${technique.niveau}');

            // Jouer le son de la technique
            _audioService.playTechniqueSound(technique.son);

            // Force la mise à jour de l'interface
            setState(() {});

            // Sauvegarde complète
            _saveGame();
          }).catchError((error) {
            // En cas d'erreur, restaurer l'état précédent
            setState(() {
              _totalXP += technique.cost;
              technique.level = previousLevel;
            });

            print('⚠️ Erreur lors de l\'achat de la technique: $error');
          });
        } catch (e) {
          // En cas d'erreur, restaurer l'état précédent
          setState(() {
            _totalXP += technique.cost;
            technique.level = previousLevel;
          });

          print('⚠️ Erreur lors de l\'achat de la technique: $e');
        }
      }
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
        _currentNinja!.passiveXp =
            _senseis.fold(0, (sum, s) => sum + s.getTotalXpPerSecond()).toInt();

        // Mettre à jour la date de dernière connexion
        _currentNinja!.lastConnected = DateTime.now();

        // Mettre à jour le ninja dans Firebase
        await _ninjaService.updateNinja(_currentNinja!);
        print(
            'Ninja sauvegardé: ${_currentNinja!.name} (${_currentNinja!.xp} XP, niveau ${_currentNinja!.level})');

        // Mettre à jour les techniques et senseis si nécessaire
        // (code de sauvegarde supplémentaire si besoin)
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
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
                backgroundColor: KaiColors.background,
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
