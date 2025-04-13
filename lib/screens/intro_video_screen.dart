import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_screen.dart';
import '../services/audio_service.dart';

// Palette de couleurs Terre du Kai Fracturé
class KaiColors {
  static const Color background = Color(0xFF0B0F1A); // Noir bleuté
  static const Color textLight = Color(0xFFE4E4E4); // Gris perle
  static const Color kaiNeutral = Color(0xFF4AE3E2); // Cyan spectral
  static const Color kaiCorrupted = Color(0xFF6E4E9E); // Violet sombre (Dérive)
  static const Color kaiRitual = Color(0xFFBBAA66); // Or terni (Sceau)
  static const Color kaiFractured =
      Color(0xFFD84F40); // Rouge ardent (Fracture)
  static const Color kaiFlux = Color(0xFF29C1B8); // Turquoise vif (Flux)
  static const Color kaiStrike = Color(0xFF8E2B2B); // Rouge sang (Frappe)
  static const Color uiElements = Color(0xFF4C5A70); // Gris bleuté
  static const Color highlight = Color(0xFF3CDFFF); // Éclat azur
}

class IntroVideoScreen extends StatefulWidget {
  final String playerName;

  const IntroVideoScreen({
    Key? key,
    required this.playerName,
  }) : super(key: key);

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen>
    with TickerProviderStateMixin {
  bool _isTransitioning = false;

  // Service audio
  final AudioService _audioService = AudioService();

  // Index de l'image actuelle
  int _currentImageIndex = 0;

  // Index du sous-titre actuel
  int _currentSubtitleIndex = -1;

  // Timer pour les sous-titres
  Timer? _subtitleTimer;

  // Timer pour l'effet glitch
  Timer? _glitchTimer;
  bool _showGlitch = false;

  // Liste des images à afficher en séquence
  final List<String> _introImages = [
    'assets/images/intro/intro1.png',
    'assets/images/intro/intro2.jpg',
    'assets/images/intro/intro3.png',
    'assets/images/intro/intro4.png',
    'assets/images/intro/intro5.png',
    'assets/images/intro/intro6.png',
    'assets/images/intro/intro7.png',
    'assets/images/intro/intro8.png',
  ];

  // Structure pour les sous-titres avec leurs timings
  final List<Map<String, dynamic>> _subtitles = [
    {'time': 0, 'text': "Il y a bien longtemps… le monde était uni."},
    {
      'time': 4000,
      'text':
          "Sous l'Empire de Ryoma, une force primordiale reposait au centre du monde…"
    },
    {'time': 8000, 'text': "Le Sceau de l'Équilibre. Gardien du Kai."},
    {'time': 12000, 'text': "Une énergie invisible… et vivante."},
    {'time': 16000, 'text': "Nul ne sait ce qui a causé sa chute."},
    {'time': 20000, 'text': "Une trahison ? Ou un éveil… ?"},
    {'time': 22000, 'text': "Ce jour-là, le Kai se déchaîna."},
    {
      'time': 26000,
      'text':
          "Il coula à travers les êtres. Brisa les frontières. Transforma les âmes."
    },
    {'time': 28000, 'text': "Ce fut… la Fracture."},
    {'time': 30000, 'text': "Le monde éclata."},
    {
      'time': 33000,
      'text':
          "Cinq grands clans se dressèrent. Chacun affirmant détenir la vraie voie du Kai."
    },
    {
      'time': 38000,
      'text': "Chacun prêt à dominer… ou purifier ce qu'il reste."
    },
    {'time': 42000, 'text': "Mais toi… Tu n'es d'aucun clan."},
    {'time': 48000, 'text': "Tu n'as reçu… ni rite, ni nom, ni bénédiction."},
    {'time': 52000, 'text': "Tu es Fracturé. Libre. Instable. Incontrôlable."},
    {
      'time': 58000,
      'text':
          "On dit que les Fracturés vivent moins longtemps... Qu'ils brûlent vite… mais brillent fort."
    },
    {
      'time': 62000,
      'text':
          "Pourtant, un murmure court encore sur les ruines du Sceau. Un nom oublié. Une légende."
    },
    {'time': 66000, 'text': "Le Kairos."},
    {
      'time': 70000,
      'text':
          "Le seul Kaijin capable d'unir les fragments du Kai… Sans se perdre."
    },
    {
      'time': 76000,
      'text': "Et si ce chemin… dangereux et solitaire… était le tien ?"
    },
    {'time': 80000, 'text': ""}, // Sous-titre vide pour effacer le dernier
  ];

  // Durées d'affichage pour chaque image (en millisecondes)
  final List<int> _imageDurations = [
    17000,
    7000,
    9000,
    12000,
    19000,
    5000,
    10000,
    5000,
  ];

  // Effets pour chaque image
  late final List<Map<String, dynamic>> _imageEffects = [
    {
      'transition': 'fade', // fondu
      'scale': {'start': 1.0, 'end': 1.1}, // légère zoom avant
      'alignment': Alignment.center,
      'color': KaiColors.kaiRitual.withOpacity(0.1), // Teinte de Sceau
    },
    {
      'transition': 'slide_right',
      'scale': {'start': 1.05, 'end': 1.0}, // léger zoom arrière
      'alignment': Alignment.centerLeft,
      'color': KaiColors.kaiFlux.withOpacity(0.15), // Teinte de Flux
    },
    {
      'transition': 'fade',
      'scale': {'start': 1.0, 'end': 1.2}, // zoom avant plus prononcé
      'alignment': Alignment.topCenter,
      'color': KaiColors.kaiCorrupted.withOpacity(0.2), // Teinte de Dérive
    },
    {
      'transition': 'slide_left',
      'scale': {'start': 1.0, 'end': 1.1},
      'alignment': Alignment.bottomCenter,
      'color': KaiColors.kaiFractured.withOpacity(0.15), // Teinte de Fracture
    },
    {
      'transition': 'fade',
      'scale': {'start': 1.15, 'end': 1.0}, // zoom arrière
      'alignment': Alignment.center,
      'color': KaiColors.kaiStrike.withOpacity(0.2), // Teinte de Frappe
    },
    {
      'transition': 'slide_up',
      'scale': {'start': 1.0, 'end': 1.15},
      'alignment': Alignment.centerRight,
      'color': KaiColors.kaiNeutral.withOpacity(0.1), // Teinte de Kai neutre
    },
    {
      'transition': 'fade',
      'scale': {'start': 1.1, 'end': 1.05},
      'alignment': Alignment.bottomRight,
      'color': KaiColors.kaiCorrupted.withOpacity(0.25), // Teinte de Dérive
    },
    {
      'transition': 'fade',
      'scale': {'start': 1.0, 'end': 1.2},
      'alignment': Alignment.center,
      'color': KaiColors.kaiNeutral.withOpacity(0.3), // Teinte de Kai neutre
    },
  ];

  // Timer pour gérer le changement d'images
  Timer? _imageTimer;

  // Contrôleurs d'animation
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;
  late AnimationController _positionController;
  late Animation<Offset> _positionAnimation;

  // Animation pour l'effet pulsation du Kai
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Animation pour les sous-titres
  late AnimationController _subtitleOpacityController;
  late Animation<double> _subtitleOpacityAnimation;

  // Gestionnaire de transition pour l'image suivante
  bool _isTransitioningToNextImage = false;

  // Durée totale de l'intro en millisecondes
  final int _totalIntroDuration = 82000; // 1 minute 22 secondes

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs d'animation avec des durées temporaires
    // (seront ajustées par image)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _opacityController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _positionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Contrôleur pour l'animation des sous-titres
    _subtitleOpacityController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _subtitleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitleOpacityController,
      curve: Curves.easeIn,
    ));

    // Contrôleur pour l'effet de pulsation du Kai
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Répéter l'animation de pulsation
    _pulseController.repeat(reverse: true);

    // Démarrer l'effet glitch périodique
    _startGlitchEffect();

    // Mettre à jour les sous-titres pour inclure le nom du joueur
    _updateSubtitlesWithPlayerName();

    // Configurer les animations initiales
    _setupAnimations(_currentImageIndex);

    // Initialiser l'audio
    _initAudio();

    // Démarrer la séquence d'images
    _startImageSequence();

    // Démarrer les sous-titres
    _startSubtitles();
  }

  // Démarrer l'effet glitch périodique
  void _startGlitchEffect() {
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 5000), (_) {
      // Créer un effet glitch aléatoire
      setState(() {
        _showGlitch = true;
      });

      // Désactiver l'effet après un court délai
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _showGlitch = false;
          });
        }
      });
    });
  }

  // Mettre à jour les sous-titres avec le nom du joueur
  void _updateSubtitlesWithPlayerName() {
    for (var i = 0; i < _subtitles.length; i++) {
      _subtitles[i]['text'] = _subtitles[i]['text']
          .replaceAll(String.fromCharCodes([0]), widget.playerName);
    }
  }

  // Configuration des animations pour chaque image
  void _setupAnimations(int index) {
    final effect = _imageEffects[index];
    final int imageDuration = _imageDurations[index];

    // Mise à jour des durées pour que l'animation d'échelle dure pendant tout l'affichage
    _scaleController.duration = Duration(milliseconds: imageDuration);
    _opacityController.duration =
        const Duration(milliseconds: 1500); // Transition d'opacité plus rapide
    _positionController.duration = const Duration(
        milliseconds: 2000); // Transition de position plus rapide

    // Animation d'échelle (zoom) qui dure pendant toute la durée d'affichage
    _scaleAnimation = Tween<double>(
      begin: effect['scale']['start'],
      end: effect['scale']['end'],
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Animation d'opacité (fondu)
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _opacityController,
      curve: Curves.easeIn,
    ));

    // Animation de position (slide)
    Offset beginOffset;

    switch (effect['transition']) {
      case 'slide_left':
        beginOffset = const Offset(1.0, 0.0); // droite vers gauche
        break;
      case 'slide_right':
        beginOffset = const Offset(-1.0, 0.0); // gauche vers droite
        break;
      case 'slide_up':
        beginOffset = const Offset(0.0, 1.0); // bas vers haut
        break;
      case 'slide_down':
        beginOffset = const Offset(0.0, -1.0); // haut vers bas
        break;
      default:
        beginOffset = const Offset(0.0, 0.0); // pas de slide
    }

    _positionAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _positionController,
      curve: Curves.easeOutCubic,
    ));

    // Réinitialiser les contrôleurs
    _scaleController.reset();
    _opacityController.reset();
    _positionController.reset();

    // Démarrer les animations
    if (effect['transition'] == 'fade') {
      _positionController.value = 1.0; // Pas de mouvement pour le fondu
    } else {
      _positionController.forward();
    }

    _opacityController.forward();
    _scaleController
        .forward(); // Cette animation durera pendant toute la durée d'affichage
  }

  // Initialiser l'audio
  Future<void> _initAudio() async {
    await _audioService.init();

    // Jouer le son d'introduction
    try {
      await _audioService.playSound('intro.mp3');
    } catch (e) {
      print('Erreur lors de la lecture du son d\'introduction: $e');
    }
  }

  // Démarrer la séquence de sous-titres
  void _startSubtitles() {
    _showNextSubtitle(0);
  }

  // Afficher le sous-titre suivant
  void _showNextSubtitle(int index) {
    if (index >= _subtitles.length) {
      return;
    }

    // Calculer le délai jusqu'au prochain sous-titre
    int currentTime = _subtitles[index]['time'];
    int nextDelay;

    if (index < _subtitles.length - 1) {
      nextDelay = _subtitles[index + 1]['time'] - currentTime;
    } else {
      nextDelay = _totalIntroDuration - currentTime;
    }

    // Faire disparaître le sous-titre actuel
    _subtitleOpacityController.reverse().then((_) {
      // Changer le sous-titre
      setState(() {
        _currentSubtitleIndex = index;
      });

      // Faire apparaître le nouveau sous-titre
      if (_subtitles[index]['text'].isNotEmpty) {
        _subtitleOpacityController.forward();
      }
    });

    // Planifier l'affichage du prochain sous-titre
    if (index < _subtitles.length - 1) {
      _subtitleTimer = Timer(Duration(milliseconds: nextDelay), () {
        _showNextSubtitle(index + 1);
      });
    }
  }

  // Démarrer la séquence d'images
  void _startImageSequence() {
    _showNextImage(0);
  }

  void _showNextImage(int index) {
    if (index >= _introImages.length) {
      // Toutes les images ont été affichées, passer au jeu
      _goToGameScreen();
      return;
    }

    // Indiquer qu'une transition est en cours
    _isTransitioningToNextImage = true;

    setState(() {
      _currentImageIndex = index;
    });

    // Reconfigurer les animations pour cette image
    _setupAnimations(index);

    // Marquer la fin de la transition d'entrée
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isTransitioningToNextImage = false;
        });
      }
    });

    // Planifier l'affichage de la prochaine image
    _imageTimer = Timer(Duration(milliseconds: _imageDurations[index]), () {
      _showNextImage(index + 1);
    });
  }

  void _goToGameScreen() {
    if (mounted && !_isTransitioning) {
      _isTransitioning = true;

      // Arrêter l'audio de l'introduction
      _audioService.stopAmbiance();

      // Annuler les timers
      _subtitleTimer?.cancel();
      _glitchTimer?.cancel();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => GameScreen(
            playerName: widget.playerName,
            savedGame: null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Effet de transition avec éclat de Kai
            return FadeTransition(
              opacity: animation,
              child: Stack(
                children: [
                  child,
                  // Éclat de Kai qui disparaît
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.8, end: 0.0)
                        .animate(CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                    )),
                    child: Container(
                      color: KaiColors.kaiNeutral.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  void _skipIntro() {
    if (_imageTimer != null) {
      _imageTimer!.cancel();
    }
    if (_subtitleTimer != null) {
      _subtitleTimer!.cancel();
    }
    if (_glitchTimer != null) {
      _glitchTimer!.cancel();
    }
    _goToGameScreen();
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _subtitleTimer?.cancel();
    _glitchTimer?.cancel();
    _scaleController.dispose();
    _opacityController.dispose();
    _positionController.dispose();
    _subtitleOpacityController.dispose();
    _pulseController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaiColors.background,
      body: Stack(
        children: [
          // Image d'introduction animée avec effets de Kai
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _scaleController,
                  _opacityController,
                  _positionController,
                  _pulseController,
                ]),
                key: ValueKey<int>(_currentImageIndex),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _opacityAnimation,
                    child: SlideTransition(
                      position: _positionAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value *
                            (_showGlitch ? 1.03 : 1.0) *
                            _pulseAnimation.value,
                        alignment: _imageEffects[_currentImageIndex]
                            ['alignment'],
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image de base
                            child!,
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  _introImages[_currentImageIndex],
                  fit: BoxFit.cover,
                  key: ValueKey<String>(_introImages[_currentImageIndex]),
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: KaiColors.background,
                      child: const Center(
                        child: Text(
                          "Chargement...",
                          style: TextStyle(color: KaiColors.textLight),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Zone des sous-titres avec style Terre du Kai
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _subtitleOpacityController,
              builder: (context, child) {
                return Opacity(
                  opacity: _subtitleOpacityAnimation.value,
                  child: child,
                );
              },
              child: _currentSubtitleIndex >= 0 &&
                      _currentSubtitleIndex < _subtitles.length
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: KaiColors.background.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: KaiColors.kaiNeutral.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: KaiColors.kaiNeutral.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        _subtitles[_currentSubtitleIndex]['text'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spectral(
                          textStyle: const TextStyle(
                            color: KaiColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            height: 1.3,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),

          // Bouton pour passer l'introduction avec style Terre du Kai
          Positioned(
            bottom: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _isTransitioningToNextImage ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 500),
              child: ElevatedButton(
                onPressed: _skipIntro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaiColors.uiElements.withOpacity(0.8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: KaiColors.kaiNeutral.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "PASSER",
                  style: GoogleFonts.rajdhani(
                    textStyle: const TextStyle(
                      color: KaiColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Symbole du Kai en haut de l'écran
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Opacity(
                  opacity: 0.25,
                  child: Image.asset(
                    'images/kai_symbol.png',
                    width: 60,
                    height: 60,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
