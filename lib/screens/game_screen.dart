import 'dart:async';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import '../models/saved_game.dart';
import '../models/technique.dart';
import '../models/ninja.dart';
import '../models/sensei.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import 'welcome_screen.dart';
import 'story/story_screen.dart';
import '../widgets/chakra_button.dart';
import '../widgets/technique_list.dart';
import '../widgets/sensei_list.dart';
import '../widgets/settings_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ninja_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Ajout de la variable _currentNinja
  Ninja? _currentNinja;

  // Liste des senseis
  List<Sensei> _senseis = [];

  // Services
  final AudioService _audioService = AudioService();
  final SaveService _saveService = SaveService();
  final NinjaService _ninjaService = NinjaService();

  // Techniques
  late List<Technique> _techniques = [];

  // Initialisation des techniques
  Future<void> _initTechniques() async {
    try {
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

      setState(() {
        _techniques = availableTechniques;
      });

      print('${_techniques.length} techniques chargées depuis Firebase');
    } catch (e) {
      print('Erreur lors du chargement initial des techniques: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialiser les techniques directement
    _initTechniques();

    // Charger la sauvegarde si elle existe
    if (widget.savedGame != null) {
      _loadGameData(widget.savedGame!);
    }

    // Initialiser l'audio
    _initAudio();

    // Charger le ninja de l'utilisateur courant
    _loadCurrentNinja();

    // Démarrer la génération automatique de puissance
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _genererPuissanceAutomatique();
    });

    // Configurer la sauvegarde automatique toutes les 2 minutes
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _saveGame();

      // Afficher une notification discrète de sauvegarde automatique
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.save, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('Sauvegarde automatique effectuée'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }

      print('Sauvegarde automatique effectuée');
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

      // Puissance générée par les senseis
      for (var sensei in _senseis) {
        _puissance += sensei.getTotalXpPerSecond();
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

  // Méthode pour acheter une technique
  void _acheterTechnique(Technique technique) {
    if (_puissance >= technique.cost) {
      setState(() {
        _puissance -= technique.cost;
        technique.niveau++;
      });

      // Sauvegarder l'achat de la technique dans Firebase
      if (_currentNinja != null) {
        _ninjaService.addTechniqueToNinja(_currentNinja!.id, technique.id);
        print(
            'Technique ${technique.name} ajoutée au ninja ${_currentNinja!.name}');
      }

      // Jouer le son de la technique
      _audioService.playTechniqueSound(technique.son);

      // Sauvegarde automatique après l'achat d'une technique
      _saveGame();
    }
  }

  // Méthode pour acheter un sensei
  void _acheterSensei(Sensei sensei) {
    final cout = sensei.getCurrentCost();
    if (_puissance >= cout) {
      setState(() {
        _puissance -= cout;
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
    if (_puissance >= cout && sensei.quantity > 0) {
      setState(() {
        _puissance -= cout;
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

  // Charger les senseis depuis Firebase
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

  // Sauvegarder la partie actuelle
  Future<void> _saveGame() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && _currentNinja != null) {
        // Mettre à jour le ninja avec les valeurs actuelles
        _currentNinja!.xp = _puissance;

        // Mettre à jour les autres attributs du ninja selon les besoins
        _currentNinja!.passiveXp = (_techniques.fold(
                    0, (sum, t) => sum + (t.niveau * t.puissanceParSeconde)) +
                _senseis.fold(0, (sum, s) => sum + s.getTotalXpPerSecond()) +
                _nombreDeClones)
            .toInt();

        // Mettre à jour le ninja dans Firebase
        await _ninjaService.updateNinja(_currentNinja!);
        print(
            'Ninja sauvegardé: ${_currentNinja!.name} (${_currentNinja!.xp} XP)');

        // Mettre à jour les techniques du ninja
        for (var technique in _techniques) {
          if (technique.niveau > 0) {
            await _ninjaService.updateNinjaTechnique(
                _currentNinja!.id, technique.id, technique.niveau);
          }
        }
        print('Techniques sauvegardées: ${_techniques.length}');

        // Mettre à jour les senseis
        for (var sensei in _senseis) {
          if (sensei.quantity > 0) {
            // Vérifier si le sensei existe déjà pour le ninja
            final querySnapshot = await FirebaseFirestore.instance
                .collection('ninjaSenseis')
                .where('ninjaId', isEqualTo: _currentNinja!.id)
                .where('senseiId', isEqualTo: sensei.id)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              // Mettre à jour le sensei existant
              final docId = querySnapshot.docs.first.id;
              await FirebaseFirestore.instance
                  .collection('ninjaSenseis')
                  .doc(docId)
                  .update({
                'quantity': sensei.quantity,
                'level': sensei.level,
              });
            } else {
              // Ajouter un nouveau sensei
              await _ninjaService.addSenseiToNinja(
                  _currentNinja!.id, sensei.id);
            }
          }
        }
        print('Senseis sauvegardés: ${_senseis.length}');
      } else {
        print(
            'Impossible de sauvegarder: pas de ninja ou d\'utilisateur connecté');
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  // Méthode pour afficher la boîte de dialogue de sauvegarde
  void _showSaveDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partie sauvegardée !'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    _saveGame();
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
                backgroundColor: Colors.red.shade600,
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
                  (t) => t.name == technique.name,
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

  // Méthode pour charger le ninja de l'utilisateur courant
  Future<void> _loadCurrentNinja() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ninjas = await _ninjaService.getNinjasByUser(user.uid);
        if (ninjas.isNotEmpty) {
          setState(() {
            _currentNinja = ninjas.first;
            _puissance = _currentNinja!
                .xp; // Synchroniser la puissance avec l'XP du ninja
          });

          print(
              'Ninja chargé: ${_currentNinja!.name} (${_currentNinja!.xp} XP)');

          // Charger les techniques du ninja
          await _loadTechniques();

          // Charger les senseis du ninja
          await _loadSenseis();
        } else {
          print('Aucun ninja trouvé pour l\'utilisateur ${user.uid}');
        }
      } else {
        print('Aucun utilisateur connecté');
      }
    } catch (e) {
      print('Erreur lors du chargement du ninja: $e');
    }
  }

  // Méthode pour charger les techniques depuis Firebase
  Future<void> _loadTechniques() async {
    try {
      if (_currentNinja == null) {
        print('Pas de ninja actif, impossible de charger ses techniques');
        return;
      }

      // Charger les techniques du ninja actif pour obtenir leurs niveaux
      final ninjaTechniques =
          await _ninjaService.getNinjaTechniques(_currentNinja!.id);

      if (ninjaTechniques.isEmpty) {
        print('Le ninja ${_currentNinja!.name} n\'a pas de techniques');
        return;
      }

      // Mise à jour des niveaux pour les techniques déjà chargées
      setState(() {
        for (var ninjaTechnique in ninjaTechniques) {
          final index =
              _techniques.indexWhere((t) => t.id == ninjaTechnique.id);
          if (index >= 0) {
            // Mettre à jour le niveau de la technique existante
            _techniques[index].level = ninjaTechnique.level;
          } else {
            // Ajouter la technique si elle n'existe pas déjà dans la liste
            _techniques.add(ninjaTechnique);
          }
        }
      });

      print(
          'Niveaux des techniques mis à jour: ${ninjaTechniques.length} techniques du ninja');
    } catch (e) {
      print('Erreur lors de la mise à jour des niveaux des techniques: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: Colors.deepOrange.shade900,
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
                  Colors.deepOrange.shade800,
                  Colors.orange.shade700,
                  Colors.amber.shade600,
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
                  errorBuilder: (context, error, stackTrace) {
                    // Utiliser une icône par défaut si l'image n'est pas trouvée
                    return Icon(
                      Icons.person,
                      size: 38,
                      color: Colors.white,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange.shade900,
                      Colors.deepOrange.shade700,
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
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade700,
                    Colors.orange.shade600,
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
                    Icons.bolt,
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
                    '$_puissance',
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
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade600,
                  Colors.amber.shade300,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Production:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_nombreDeClones + _techniques.fold(0, (sum, t) => sum + (t.niveau * t.puissanceParSeconde)) + _senseis.fold(0, (sum, s) => sum + s.getTotalXpPerSecond())}/sec',
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

                // Section des techniques et senseis avec TabBarView
                Expanded(
                  child: TabBarView(
                    children: [
                      // Onglet des techniques
                      TechniqueList(
                        techniques: _techniques,
                        puissance: _puissance,
                        onAcheterTechnique: _acheterTechnique,
                      ),

                      // Onglet des senseis
                      SenseiList(
                        senseis: _senseis,
                        puissance: _puissance,
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
}
