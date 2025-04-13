import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../styles/kai_colors.dart';

class ChakraButton extends StatefulWidget {
  final Function(int bonusXp, double multiplier) onTap;
  final int puissance; // Valeur d'XP à afficher

  const ChakraButton({
    super.key,
    required this.onTap,
    required this.puissance,
  });

  @override
  State<ChakraButton> createState() => _ChakraButtonState();
}

class _ChakraButtonState extends State<ChakraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isChakraMode = false;
  Timer? _chakraTimer;
  int _comboClicks = 0; // Compteur de clics consécutifs

  // Animation pour afficher le nombre de clics
  List<ClickAnimation> _clickAnimations = [];

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
  Color _chakraCircleColor = KaiColors.accent
      .withOpacity(0.4); // Changé à la couleur d'accent pour l'XP

  // Position du dernier clic
  Offset? _lastTapPosition;

  // Méthode pour ajouter un timer qui remet à zéro le combo après un délai
  Timer? _comboResetTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chakraTimer?.cancel();
    _animationTimer?.cancel();
    _comboResetTimer?.cancel();

    // Nettoyer toutes les animations de clic
    for (var anim in _clickAnimations) {
      anim.timer?.cancel();
    }

    super.dispose();
  }

  void _handleTap() {
    _animationController.reset();
    _animationController.forward();

    // Annuler le timer de reset du combo s'il existe
    _comboResetTimer?.cancel();

    // On considère que c'est la fin du combo si on est au dernier clic avant expiration
    bool isEndOfCombo = false;

    // Créer un nouveau timer pour réinitialiser le combo après 1.5 secondes d'inactivité
    _comboResetTimer = Timer(const Duration(milliseconds: 1500), () {
      // Ajouter une animation finale qui montre les gains totaux
      if (_comboClicks >= 5 && mounted) {
        setState(() {
          // Position du dernier clic
          double offsetX = 0;
          double offsetY = -30;

          if (_lastTapPosition != null) {
            offsetX = _lastTapPosition!.dx - 100;
            offsetY = _lastTapPosition!.dy - 100 - 30;
          }

          // Calculer les gains finaux
          int bonusXp = (_comboClicks / 5).floor();
          double multiplier = 1.0 + (min(_comboClicks, 50) / 50);
          int gainTotal = (1 * multiplier).floor() + bonusXp;

          // Annuler les animations précédentes
          for (var anim in _clickAnimations) {
            anim.timer?.cancel();
          }
          _clickAnimations.clear();

          // Ajouter l'animation de fin de combo
          _clickAnimations.add(ClickAnimation(
            value: gainTotal,
            bonusXp: bonusXp,
            multiplier: multiplier,
            combo: _comboClicks,
            offsetX: offsetX,
            offsetY: offsetY,
            isEndOfCombo: true,
            onComplete: () {
              setState(() {
                _clickAnimations.removeWhere((anim) => anim.isCompleted);
                // Réinitialiser le compteur de combo
                _comboClicks = 0;
              });
            },
          ));
        });
      } else if (mounted) {
        // Réinitialiser simplement le compteur si pas de gains significatifs
        setState(() {
          _comboClicks = 0;
        });
      }
    });

    setState(() {
      _isChakraMode = true;
      _comboClicks++;

      // Augmenter la taille du cercle d'énergie et changer sa couleur
      if (_comboClicks > 1) {
        _chakraCircleSize =
            (_chakraCircleSize + 10).clamp(220, _maxChakraCircleSize);

        // Transition de couleur basée sur _comboClicks
        double intensityFactor = (_comboClicks / 10).clamp(0.0, 1.0);
        _chakraCircleColor = Color.lerp(KaiColors.primaryDark.withOpacity(0.4),
            KaiColors.accent.withOpacity(0.6), intensityFactor)!;
      }

      // Annuler toutes les animations précédentes sauf en fin de combo
      for (var anim in _clickAnimations) {
        anim.timer?.cancel();
      }
      _clickAnimations.clear();

      // Position du clic par rapport au centre (100, 100)
      double offsetX = 0;
      double offsetY = -30; // Par défaut un peu au-dessus du centre

      // Si on a une position de clic valide, calculer l'offset par rapport au centre
      if (_lastTapPosition != null) {
        offsetX = _lastTapPosition!.dx - 100; // Centre horizontal à 100
        offsetY = _lastTapPosition!.dy - 100; // Centre vertical à 100
        // Ajuster légèrement vers le haut pour que le texte ne soit pas caché par le doigt
        offsetY -= 30;
      }

      // Calculer le bonus et le multiplicateur en fonction du combo
      int bonusXp = 0;
      double multiplier = 1.0;

      // À partir de 5 clics, commencer à attribuer des bonus
      if (_comboClicks >= 5) {
        // 5 clics = +1 XP, 10 clics = +5 XP, etc.
        bonusXp = (_comboClicks / 5).floor();

        // Multiplicateur qui augmente de 0.1 tous les 5 clics (max 2.0)
        multiplier = 1.0 + (min(_comboClicks, 50) / 50);
      }

      // Gain total = base(1) * multiplicateur + bonus
      int gainTotal = (1 * multiplier).floor() + bonusXp;

      // Ajouter une nouvelle animation de clic
      _clickAnimations.add(ClickAnimation(
        value: gainTotal,
        bonusXp: bonusXp,
        multiplier: multiplier,
        combo: _comboClicks,
        offsetX: offsetX,
        offsetY: offsetY,
        isEndOfCombo: isEndOfCombo,
        onComplete: () {
          // Supprimer l'animation à la fin
          if (mounted) {
            setState(() {
              _clickAnimations.removeWhere((anim) => anim.isCompleted);
            });
          }
        },
      ));
    });

    // Calculer le bonus et le multiplicateur pour le callback
    int bonusXp = 0;
    double multiplier = 1.0;

    if (_comboClicks >= 5) {
      bonusXp = (_comboClicks / 5).floor();
      multiplier = 1.0 + (min(_comboClicks, 50) / 50);
    }

    // Appeler le callback avec les valeurs de bonus et de multiplicateur
    widget.onTap(bonusXp, multiplier);

    // Démarrer ou réinitialiser l'animation de chakra
    _startChakraAnimation();

    // Annuler le timer précédent s'il existe
    _chakraTimer?.cancel();

    // Créer un nouveau timer pour la durée d'affichage
    _chakraTimer = Timer(const Duration(milliseconds: 200), () {
      _startReverseAnimation();
    });
  }

  // Démarrer l'animation du chakra vers l'avant
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

  // Démarrer le processus d'animation inverse
  void _startReverseAnimation() {
    // Commencer l'animation inverse
    _animationTimer?.cancel();
    _isAnimatingForward = false;

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
          _chakraCircleSize =
              (_chakraCircleSize - 10).clamp(220.0, _maxChakraCircleSize);

          // Revenir progressivement à la couleur de base
          double reverseFactor = 1 - (_chakraAnimationStep / 4).clamp(0.0, 1.0);
          _chakraCircleColor = Color.lerp(KaiColors.accent.withOpacity(0.6),
              KaiColors.primaryDark.withOpacity(0.4), reverseFactor)!;
        } else {
          // Animation terminée, on arrête le timer
          timer.cancel();

          // Maintenant on peut désactiver complètement le mode chakra
          _isChakraMode = false;

          // Ne pas réinitialiser le compteur de combo ici, c'est maintenant géré par le comboResetTimer
          // _comboClicks = 0;

          // Réinitialiser le cercle
          _chakraCircleSize = 220;
          _chakraCircleColor = KaiColors.primaryDark.withOpacity(0.4);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        // Stocker la position du clic pour afficher l'animation d'XP
        setState(() {
          _lastTapPosition = details.localPosition;
        });
      },
      onTap: () {
        _handleTap();
      },
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cercle d'énergie (chakra/XP)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _chakraCircleSize,
              height: _chakraCircleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _chakraCircleColor,
                boxShadow: [
                  BoxShadow(
                    color: KaiColors.accent.withOpacity(
                        0.3), // Changé à la couleur d'accent pour l'XP
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),

            // Image de Naruto avec animation de pulsation
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                _isChakraMode
                    ? _chakraAnimationImages[_chakraAnimationStep]
                    : 'assets/images/naruto_normal.png',
                width: 200,
                height: 200,
              ),
            ),

            // Texte d'XP actuelle
            Positioned(
              bottom: 30,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700, // Couleur bleue pour l'XP
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.whatshot, // Icône d'XP
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatNumber(widget.puissance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          'XP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Affichage des animations de clic
            ..._clickAnimations.map((animation) => animation.buildWidget()),
          ],
        ),
      ),
    );
  }
}

// Classe pour gérer les animations de clic "+n"
class ClickAnimation {
  final int value;
  final int bonusXp;
  final double multiplier;
  final int combo;
  final double offsetX;
  final double offsetY;
  final VoidCallback onComplete;
  final bool isEndOfCombo;

  double progress = 0.0;
  double opacity = 1.0;
  bool isCompleted = false;
  Timer? timer;

  // Calculer le gain provenant du multiplicateur
  int get gainFromMultiplier =>
      (multiplier > 1.0) ? ((1 * multiplier).floor() - 1) : 0;

  ClickAnimation({
    required this.value,
    this.bonusXp = 0,
    this.multiplier = 1.0,
    this.combo = 1,
    required this.offsetX,
    required this.offsetY,
    required this.onComplete,
    this.isEndOfCombo = false,
  }) {
    // Démarrer l'animation
    timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      progress += 0.016; // Environ 60 FPS

      // Commencer à disparaître à 70% de l'animation
      if (progress > 0.7) {
        opacity = max(0, 1 - ((progress - 0.7) / 0.3));
      }

      // Animation terminée
      if (progress >= 1.0) {
        timer.cancel();
        isCompleted = true;
        onComplete();
      }
    });
  }

  Widget buildWidget() {
    return Positioned(
      left: 100 + offsetX,
      top: 100 + offsetY,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, -progress * 40, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Afficher le nombre de clics en grand
              Text(
                '$combo',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.blue.shade800,
                      blurRadius: 2,
                      offset: const Offset(1.5, 1.5),
                    ),
                    Shadow(
                      color: Colors.blue.shade800,
                      blurRadius: 2,
                      offset: const Offset(-1.5, -1.5),
                    ),
                    Shadow(
                      color: Colors.blue.shade800,
                      blurRadius: 2,
                      offset: const Offset(1.5, -1.5),
                    ),
                    Shadow(
                      color: Colors.blue.shade800,
                      blurRadius: 2,
                      offset: const Offset(-1.5, 1.5),
                    ),
                  ],
                ),
              ),

              // Montrer le multiplicateur si combo >= 5
              if (combo >= 5)
                Text(
                  'x${multiplier.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade300,
                    shadows: [
                      Shadow(
                        color: Colors.blue.shade900,
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),

              // Si on est en fin d'animation et qu'il y a des bonus, les afficher
              if (isEndOfCombo && combo >= 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gain lié au multiplicateur
                      Text(
                        '+${gainFromMultiplier}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade300,
                          shadows: [
                            Shadow(
                              color: Colors.blue.shade900,
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),

                      // Bonus lié au combo si présent
                      if (bonusXp > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 10),
                            Text(
                              '+${bonusXp}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade300,
                                shadows: [
                                  Shadow(
                                    color: Colors.blue.shade900,
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
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
    );
  }
}

String _formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(2)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(2)}K';
  } else {
    return number.toString();
  }
}
