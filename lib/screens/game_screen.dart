import 'dart:async';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import '../models/saved_game.dart';
import '../models/technique.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import 'welcome_screen.dart';
import 'story/story_screen.dart';
import '../widgets/chakra_button.dart';
import '../widgets/technique_list.dart';
import '../widgets/settings_dialog.dart';

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
  int _puissance = 0;
  int _nombreDeClones = 0;
  final int _coutClone = 25;
  late Timer _timer;
  late Timer? _autoSaveTimer;
  Timer? _chakraSoundTimer; // Timer pour le son du chakra

  // Services
  final AudioService _audioService = AudioService();
  final SaveService _saveService = SaveService();

  // Techniques
  late List<Technique> _techniques;

  // Initialisation des techniques
  List<Technique> _initTechniques() {
    return [
      Technique(
        nom: 'Boule de Feu',
        description: 'Technique de base du clan Uchiwa',
        cout: 50,
        puissanceParSeconde: 2,
        son: 'sounds/technique_boule_feu.mp3',
      ),
      Technique(
        nom: 'Multi-Clonage',
        description: 'Créer plusieurs clones simultanément',
        cout: 200,
        puissanceParSeconde: 10,
        son: 'sounds/technique_multi_clonage.mp3',
      ),
      Technique(
        nom: 'Rasengan',
        description: 'Boule de chakra tourbillonnante',
        cout: 1000,
        puissanceParSeconde: 50,
        son: 'sounds/technique_rasengan.mp3',
      ),
      Technique(
        nom: 'Mode Sage',
        description: 'Utiliser l\'énergie naturelle',
        cout: 5000,
        puissanceParSeconde: 250,
        son: 'sounds/technique_mode_sage.mp3',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();

    // Initialiser les techniques
    _techniques = _initTechniques();

    // Charger la sauvegarde si elle existe
    if (widget.savedGame != null) {
      _loadGameData(widget.savedGame!);
    }

    // Initialiser l'audio
    _initAudio();

    // Démarrer la génération automatique de puissance
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _genererPuissanceAutomatique();
    });

    // Configurer la sauvegarde automatique toutes les 2 minutes
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _saveGame();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _autoSaveTimer?.cancel();
    _chakraSoundTimer?.cancel(); // Annuler le timer du son de chakra
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    await _audioService.init();
    _audioService.startAmbiance();
  }

  // Charger les données d'une sauvegarde
  void _loadGameData(SavedGame savedGame) {
    setState(() {
      _puissance = savedGame.puissance;
      _nombreDeClones = savedGame.nombreDeClones;

      // Fusionner les techniques sauvegardées avec les techniques initiales
      for (int i = 0; i < _techniques.length; i++) {
        if (i < savedGame.techniques.length) {
          _techniques[i].niveau = savedGame.techniques[i].niveau;
        }
      }
    });
  }

  void _genererPuissanceAutomatique() {
    setState(() {
      // Puissance générée par les clones
      _puissance += _nombreDeClones;

      // Puissance générée par les techniques
      for (var technique in _techniques) {
        _puissance += technique.niveau * technique.puissanceParSeconde;
      }
    });
  }

  void _incrementerPuissance() {
    setState(() {
      _puissance++;
    });

    // Gérer le son du chakra
    if (!_audioService.isEffectsSoundPlaying) {
      // Si le son n'est pas en cours de lecture, le démarrer
      _audioService.playChakraSound();
    }

    // Annuler le timer précédent s'il existe
    _chakraSoundTimer?.cancel();

    // Créer un nouveau timer pour arrêter le son après un délai
    _chakraSoundTimer = Timer(const Duration(milliseconds: 1000), () {
      // Arrêter le son en fondu progressif
      _audioService.fadeOutChakraSound();
    });
  }

  void _acheterClone() {
    if (_puissance >= _coutClone) {
      setState(() {
        _puissance -= _coutClone;
        _nombreDeClones++;
      });
    }
  }

  void _acheterTechnique(Technique technique) async {
    if (_puissance >= technique.cout) {
      setState(() {
        _puissance -= technique.cout;
        technique.niveau++;
      });

      // Jouer le son de la technique
      _audioService.playTechniqueSound(technique.son);
    }
  }

  // Sauvegarder la partie actuelle
  Future<void> _saveGame() async {
    try {
      final savedGame = SavedGame(
        nom: widget.playerName,
        puissance: _puissance,
        nombreDeClones: _nombreDeClones,
        techniques: _techniques,
        date: DateTime.now(),
      );

      await _saveService.saveGame(savedGame);
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  // Méthode pour afficher la boîte de dialogue de sauvegarde
  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Sauvegarde',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('Sauvegarder la partie en cours ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveGame();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Partie sauvegardée !'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Sauvegarder',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
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
          content: const Text('Voulez-vous sauvegarder avant de quitter ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WelcomeScreen()),
                );
              },
              child: const Text(
                'Quitter sans sauvegarder',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
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
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Sauvegarder et quitter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour aller au mode histoire
  void _goToStoryMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryScreen(
          puissance: _puissance,
          onMissionComplete:
              (missionPuissance, missionClones, missionTechniques) {
            setState(() {
              _puissance += missionPuissance;
              _nombreDeClones += missionClones;

              // Ajouter les techniques gagnées
              for (var technique in missionTechniques) {
                // Vérifier si la technique existe déjà
                var existingTechnique = _techniques.firstWhere(
                  (t) => t.nom == technique.nom,
                  orElse: () => technique,
                );

                if (!_techniques.contains(existingTechnique)) {
                  _techniques.add(existingTechnique);
                }

                existingTechnique.niveau += 1;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
        title: Row(
          children: [
            const Text(
              'Ninja Clicker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '- ${widget.playerName}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.book, color: Colors.white),
            onPressed: _goToStoryMode,
            tooltip: 'Mode Histoire',
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _showSaveDialog,
            tooltip: 'Sauvegarder',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
            tooltip: 'Paramètres',
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: _returnToMainMenu,
            tooltip: 'Menu principal',
          ),
        ],
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
                Colors.orange[50]!.withOpacity(0.7),
                Colors.orange[100]!.withOpacity(0.7),
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
                            puissance: _puissance,
                          ),
                        ),
                      ),

                      // Statistiques
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Production:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_nombreDeClones + _techniques.fold(0, (sum, t) => sum + (t.niveau * t.puissanceParSeconde))}/sec',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
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

              // Section des techniques
              Expanded(
                child: TechniqueList(
                  techniques: _techniques,
                  puissance: _puissance,
                  onAcheterTechnique: _acheterTechnique,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
