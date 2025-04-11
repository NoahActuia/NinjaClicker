import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' show max;

// Classe pour représenter une technique ninja
class Technique {
  final String nom;
  final String description;
  final int cout;
  final int puissanceParSeconde;
  final String son;
  int niveau = 0;

  Technique({
    required this.nom,
    required this.description,
    required this.cout,
    required this.puissanceParSeconde,
    required this.son,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ninja Clicker',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          secondary: Colors.blue,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ),
      home: const MyHomePage(title: 'Ninja Clicker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _puissance = 0;
  int _nombreDeClones = 0;
  final int _coutClone = 25;
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isChakraMode = false;
  Timer? _chakraTimer;
  int _comboClicks = 0; // Compteur de clics consécutifs

  // Gestion des sons
  final AudioPlayer _ambiancePlayer = AudioPlayer();
  final AudioPlayer _chakraPlayer = AudioPlayer();
  final AudioPlayer _techniquePlayer = AudioPlayer();
  bool _isChakraSoundPlaying = false;
  bool _isAmbiancePlaying =
      false; // Nouvelle variable pour suivre l'état de la musique d'ambiance
  double _chakraVolume = 0.3; // Volume de base du chakra
  double _maxChakraVolume = 0.8; // Volume maximum du chakra

  // Options de son
  bool _ambianceSoundEnabled = true;
  bool _effectsSoundEnabled = true;

  // Gestion de l'animation de chakra
  int _chakraAnimationStep = 0;
  final List<String> _chakraAnimationImages = [
    'assets/images/naruto_chakra.png',
    'assets/images/naruto_chakra1.png',
    'assets/images/naruto_chakra2.png',
    'assets/images/naruto_chakra3.png',
    'assets/images/naruto_chakra4.png',
  ];
  Timer? _animationTimer;
  bool _isAnimatingForward = true; // Contrôle la direction de l'animation

  // Gestion du cercle d'énergie
  double _chakraCircleSize = 220;
  double _maxChakraCircleSize = 300;
  Color _chakraCircleColor = Colors.orange.withOpacity(0.4);

  // Liste des techniques disponibles
  final List<Technique> _techniques = [
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

  @override
  void initState() {
    super.initState();
    _initAudio();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _genererPuissanceAutomatique();
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Démarrer la musique d'ambiance après un court délai
    Future.delayed(const Duration(milliseconds: 500), () {
      _startAmbiance();
    });
  }

  Future<void> _initAudio() async {
    try {
      print("Initialisation des ressources audio...");
      // Configurer le mode de lecture en boucle et le volume
      await _ambiancePlayer.setReleaseMode(ReleaseMode.loop);

      // Préparer le son du chakra
      await _chakraPlayer.setSource(AssetSource('sounds/chakra_charge.mp3'));
      await _chakraPlayer.setReleaseMode(ReleaseMode.loop);

      // Configurer le joueur de techniques pour ne jouer qu'une seule fois
      await _techniquePlayer.setReleaseMode(ReleaseMode.release);

      print("Ressources audio initialisées avec succès");
    } catch (e) {
      print('Erreur lors de l\'initialisation audio: $e');
    }
  }

  // Nouvelle méthode pour démarrer la musique d'ambiance
  void _startAmbiance() {
    try {
      print("Tentative de démarrage de la musique d'ambiance...");
      _ambiancePlayer.play(AssetSource('sounds/ambiance.mp3'),
          volume: _ambianceSoundEnabled ? 0.15 : 0.0);
      _isAmbiancePlaying = true;
      print("Musique d'ambiance lancée avec succès");
    } catch (e) {
      print('Erreur lors du démarrage de la musique d\'ambiance: $e');
    }
  }

  // Méthode pour gérer l'activation/désactivation de la musique d'ambiance
  void _toggleAmbianceSound(bool value) {
    setState(() {
      _ambianceSoundEnabled = value;
    });

    try {
      if (_isAmbiancePlaying) {
        _ambiancePlayer.setVolume(_ambianceSoundEnabled ? 0.15 : 0.0);
        print(
            "Volume de la musique d'ambiance réglé à: ${_ambianceSoundEnabled ? 0.15 : 0.0}");
      } else {
        // Au cas où la musique n'est pas encore en cours
        _startAmbiance();
      }
    } catch (e) {
      print('Erreur lors de la modification du volume: $e');
    }
  }

  // Méthode pour gérer l'activation/désactivation des effets sonores
  void _toggleEffectsSound(bool value) {
    setState(() {
      _effectsSoundEnabled = value;
    });

    if (!_effectsSoundEnabled) {
      _chakraPlayer.stop();
      _techniquePlayer.stop();
      _isChakraSoundPlaying = false;
    }
  }

  // Affiche le dialogue des paramètres
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Paramètres',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Musique d\'ambiance'),
                  trailing: Switch(
                    value: _ambianceSoundEnabled,
                    onChanged: (value) {
                      _toggleAmbianceSound(value);
                      setState(() {}); // Mettre à jour l'état du dialogue
                    },
                    activeColor: Colors.orange,
                  ),
                ),
                ListTile(
                  title: const Text('Effets sonores'),
                  trailing: Switch(
                    value: _effectsSoundEnabled,
                    onChanged: (value) {
                      _toggleEffectsSound(value);
                      setState(() {}); // Mettre à jour l'état du dialogue
                    },
                    activeColor: Colors.orange,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fermer',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    _chakraTimer?.cancel();
    _animationTimer?.cancel();
    _ambiancePlayer.dispose();
    _chakraPlayer.dispose();
    _techniquePlayer.dispose();
    _isAmbiancePlaying = false; // Réinitialiser l'état
    super.dispose();
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
    _animationController.reset();
    _animationController.forward();

    // Annuler le timer précédent s'il existe
    _chakraTimer?.cancel();

    setState(() {
      _isChakraMode = true;
      _puissance++;
      _comboClicks++;

      // Augmenter le volume du son chakra avec les clics, mais limitez à _maxChakraVolume
      if (_comboClicks > 1) {
        _chakraVolume = (_chakraVolume + 0.05).clamp(0.3, _maxChakraVolume);
        if (_isChakraSoundPlaying && _effectsSoundEnabled) {
          _chakraPlayer.setVolume(_chakraVolume);
        }

        // Augmenter la taille du cercle d'énergie et changer sa couleur
        _chakraCircleSize =
            (_chakraCircleSize + 10).clamp(220, _maxChakraCircleSize);

        // Transition de couleur d'orange à bleu basée sur _comboClicks
        double blueIntensity = (_comboClicks / 10).clamp(0.0, 1.0);
        _chakraCircleColor = Color.lerp(Colors.orange.withOpacity(0.4),
            Colors.blue.withOpacity(0.6), blueIntensity)!;
      }
    });

    // Gérer le son du chakra
    if (!_isChakraSoundPlaying && _effectsSoundEnabled) {
      _isChakraSoundPlaying = true;
      try {
        _chakraPlayer.play(AssetSource('sounds/chakra_charge.mp3'),
            volume: _chakraVolume);
      } catch (e) {
        print('Erreur lors de la lecture du son chakra: $e');
      }
    }

    // Démarrer ou réinitialiser l'animation de chakra
    _startChakraAnimation();

    // Créer un nouveau timer pour 1 seconde
    _chakraTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        // Ne pas désactiver immédiatement le mode chakra
        // On laisse l'animation inverse se terminer d'abord
        _startReverseAnimation();
      }
    });
  }

  // Nouvelle méthode pour démarrer le processus d'arrêt avec animation inverse
  void _startReverseAnimation() {
    // Commencer l'animation inverse
    _animationTimer?.cancel();
    _isAnimatingForward = false;

    // Durée estimée de l'animation inverse (nombre d'étapes * temps par étape)
    int reverseAnimationDuration = _chakraAnimationStep * 70;

    // Créer un timer pour l'animation inverse
    _animationTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Reculer à l'étape précédente
        if (_chakraAnimationStep > 0) {
          _chakraAnimationStep--;

          // Diminuer progressivement la taille du cercle
          _chakraCircleSize = max(220, _chakraCircleSize - 10);

          // Revenir progressivement à la couleur orange
          double orangeIntensity =
              1 - (_chakraAnimationStep / 4).clamp(0.0, 1.0);
          _chakraCircleColor = Color.lerp(Colors.blue.withOpacity(0.6),
              Colors.orange.withOpacity(0.4), orangeIntensity)!;
        } else {
          // Animation terminée, on arrête le timer
          timer.cancel();

          // Maintenant on peut désactiver complètement le mode chakra
          _isChakraMode = false;
          _comboClicks = 0;

          // Réinitialiser le cercle
          _chakraCircleSize = 220;
          _chakraCircleColor = Colors.orange.withOpacity(0.4);

          // Diminuer progressivement le volume
          _fadeOutChakraSound();
        }
      });
    });
  }

  // Nouvelle méthode pour démarrer l'animation du chakra
  void _startChakraAnimation() {
    // Annuler le timer d'animation précédent s'il existe
    _animationTimer?.cancel();

    // Configurer la direction de l'animation vers l'avant
    _isAnimatingForward = true;

    // Si nous commençons une nouvelle animation, réinitialiser à la première étape
    if (!_isChakraMode) {
      _chakraAnimationStep = 0;
    }

    // Créer un nouveau timer pour avancer dans les images d'animation
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isAnimatingForward) {
        timer.cancel();
        return;
      }

      setState(() {
        // Avancer à l'étape suivante uniquement si nous ne sommes pas déjà à la dernière image
        if (_isAnimatingForward &&
            _chakraAnimationStep < _chakraAnimationImages.length - 1) {
          _chakraAnimationStep++;
        }
        // Rester sur la dernière image une fois atteinte
      });
    });
  }

  // Nouvelle méthode pour arrêter l'animation du chakra (appelée lors de la destruction du widget)
  void _stopChakraAnimation() {
    _animationTimer?.cancel();
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

      // Jouer le son de la technique seulement si les effets sont activés
      if (_effectsSoundEnabled) {
        try {
          // Arrêter le son précédent s'il y en a un
          await _techniquePlayer.stop();

          // S'assurer que le son ne joue qu'une seule fois
          await _techniquePlayer.setReleaseMode(ReleaseMode.release);

          // Définir la source et jouer le son
          await _techniquePlayer.setSource(AssetSource(technique.son));
          await _techniquePlayer.play(AssetSource(technique.son), volume: 0.7);
        } catch (e) {
          print('Erreur lors de la lecture du son technique: $e');
        }
      }
    }
  }

  // Nouvelle méthode pour diminuer progressivement le son chakra
  void _fadeOutChakraSound() {
    if (!_isChakraSoundPlaying || !_effectsSoundEnabled) return;

    // Créer un timer pour diminuer progressivement le volume
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isChakraSoundPlaying || _chakraVolume <= 0.05) {
        // Arrêter le son et le timer quand le volume est très bas
        _chakraPlayer.stop();
        _isChakraSoundPlaying = false;
        _chakraVolume = 0.3; // Réinitialiser le volume pour le prochain clic
        timer.cancel();
      } else {
        // Diminuer le volume progressivement
        _chakraVolume = (_chakraVolume - 0.05).clamp(0.0, _maxChakraVolume);
        _chakraPlayer.setVolume(_chakraVolume);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Colors.orange[700],
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
            tooltip: 'Paramètres',
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
                          child: GestureDetector(
                            onTap: _incrementerPuissance,
                            child: AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Effet de cercle derrière Naruto
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 100),
                                        width: _chakraCircleSize,
                                        height: _chakraCircleSize,
                                        decoration: BoxDecoration(
                                          color: _chakraCircleColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),

                                      // Image de Naruto qui change
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Emplacement pour l'image de Naruto
                                          Container(
                                            width: 200,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: _isChakraMode
                                                  ? Transform.scale(
                                                      scale: 1.5,
                                                      child: Image.asset(
                                                        _chakraAnimationImages[
                                                            _chakraAnimationStep],
                                                        fit: BoxFit.contain,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      'assets/images/naruto_normal.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                            ),
                                          ),

                                          // Compteur de puissance
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[700],
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '$_puissance',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Section des techniques
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Techniques Ninja',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _techniques.length,
                          itemBuilder: (context, index) {
                            final technique = _techniques[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              child: ListTile(
                                title: Text(
                                  technique.nom,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(technique.description),
                                    Text(
                                      'Niveau: ${technique.niveau}',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Production: ${technique.puissanceParSeconde * technique.niveau}/sec',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: _puissance >= technique.cout
                                      ? () => _acheterTechnique(technique)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[400],
                                  ),
                                  child: Text(
                                    '${technique.cout}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
