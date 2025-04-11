import 'dart:async';
import 'package:flutter/material.dart';

class ChakraButton extends StatefulWidget {
  final VoidCallback onTap;
  final int puissance; // Ajouter la puissance actuelle en paramètre

  const ChakraButton({
    super.key,
    required this.onTap,
    required this.puissance, // Rendre ce paramètre obligatoire
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
    super.dispose();
  }

  void _handleTap() {
    _animationController.reset();
    _animationController.forward();

    setState(() {
      _isChakraMode = true;
      _comboClicks++;

      // Augmenter la taille du cercle d'énergie et changer sa couleur
      if (_comboClicks > 1) {
        _chakraCircleSize =
            (_chakraCircleSize + 10).clamp(220, _maxChakraCircleSize);

        // Transition de couleur d'orange à bleu basée sur _comboClicks
        double blueIntensity = (_comboClicks / 10).clamp(0.0, 1.0);
        _chakraCircleColor = Color.lerp(Colors.orange.withOpacity(0.4),
            Colors.blue.withOpacity(0.6), blueIntensity)!;
      }
    });

    // Appeler le callback
    widget.onTap();

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
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
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
                  duration: const Duration(milliseconds: 100),
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
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _isChakraMode
                            ? Transform.scale(
                                scale: 1.5,
                                child: Image.asset(
                                  _chakraAnimationImages[_chakraAnimationStep],
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
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.puissance}',
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
    );
  }
}
