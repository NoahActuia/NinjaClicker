import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../styles/kai_colors.dart';

class KaiButton extends StatefulWidget {
  final Function(int gainXp) onTap;
  final int puissance; // Valeur du combo à afficher
  final int totalXP; // Quantité d'XP totale à afficher

  const KaiButton({
    super.key,
    required this.onTap,
    required this.puissance,
    required this.totalXP,
  });

  @override
  State<KaiButton> createState() => _KaiButtonState();
}

class _KaiButtonState extends State<KaiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _iskaiMode = false;
  Timer? _kaiTimer;
  int _comboClicks = 0; // Compteur de clics consécutifs

  // Animation pour afficher le nombre de clics
  List<ClickAnimation> _clickAnimations = [];

  // Gestion de l'animation de kai
  int _kaiAnimationStep = 0;
  final List<String> _kaiAnimationImages = [
    'assets/images/naruto_chakra.png',
    'assets/images/naruto_chakra1.png',
    'assets/images/naruto_chakra2.png',
    'assets/images/naruto_chakra3.png',
    'assets/images/naruto_chakra4.png',
  ];
  Timer? _animationTimer;
  bool _isAnimatingForward = true; // Contrôle la direction de l'animation

  // Gestion du cercle d'énergie
  double _kaiCircleSize = 220;
  double _maxkaiCircleSize = 600;
  Color _kaiCircleColor = KaiColors.accent
      .withOpacity(0.4); // Changé à la couleur d'accent pour l'XP

  // Variables pour l'effet de pulsation
  bool _isPulsating = false;
  Timer? _pulsationTimer;
  bool _isPulsatingUp = true;
  double _pulsationAmount = 20.0; // Amplitude de la pulsation
  double _basePulsationSize = 0.0; // Taille de base pour la pulsation

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
    _kaiTimer?.cancel();
    _animationTimer?.cancel();
    _comboResetTimer?.cancel();
    _pulsationTimer?.cancel();

    // Nettoyer toutes les animations de clic
    for (var anim in _clickAnimations) {
      anim.timer?.cancel();
    }

    super.dispose();
  }

  void _handleTap() {
    _animationController.reset();
    _animationController.forward();

    // Utiliser directement le compteur externe (widget.puissance) au lieu du compteur interne
    // Cela garantit que l'affichage du combo et le compteur interne sont synchronisés
    _comboClicks = widget.puissance;

    // On considère que c'est la fin du combo si on est au dernier clic avant expiration
    bool isEndOfCombo = false;

    setState(() {
      _iskaiMode = true;
      // Ne pas incrémenter _comboClicks ici, c'est fait par le GameScreen

      // Augmenter la taille du cercle d'énergie et changer sa couleur en fonction du compteur de combo
      if (_comboClicks > 1) {
        _kaiCircleSize = (_kaiCircleSize + 10).clamp(220.0, _maxkaiCircleSize);

        // Transition de couleur basée sur _comboClicks
        double intensityFactor = (_comboClicks / 10).clamp(0.0, 1.0);
        _kaiCircleColor = Color.lerp(KaiColors.primaryDark.withOpacity(0.4),
            KaiColors.accent.withOpacity(0.6), intensityFactor)!;

        // Commencer l'effet de pulsation si la taille max est atteinte ou presque
        if (_kaiCircleSize >= _maxkaiCircleSize - 10 && !_isPulsating) {
          _startPulsation();
        }
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

      // Gain XP fixe de 1 par clic
      int gainXp = 1;

      // Ajouter une nouvelle animation de clic avec le compteur de combo actuel
      _clickAnimations.add(ClickAnimation(
        value: gainXp,
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

    // Appeler le callback avec la valeur de gain (1 XP)
    widget.onTap(1);

    // Démarrer ou réinitialiser l'animation de kai
    _startkaiAnimation();

    // Annuler le timer précédent s'il existe
    _kaiTimer?.cancel();

    // Créer un nouveau timer pour la durée d'affichage
    _kaiTimer = Timer(const Duration(milliseconds: 200), () {
      _startReverseAnimation();
    });
  }

  // Démarrer l'animation du kai vers l'avant
  void _startkaiAnimation() {
    // Annuler le timer d'animation précédent s'il existe
    _animationTimer?.cancel();

    // Configurer la direction de l'animation vers l'avant
    _isAnimatingForward = true;

    // Si nous commençons une nouvelle animation, réinitialiser à la première étape
    if (!_iskaiMode) {
      _kaiAnimationStep = 0;
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
            _kaiAnimationStep < _kaiAnimationImages.length - 1) {
          _kaiAnimationStep++;
        }
        // Rester sur la dernière image une fois atteinte
      });
    });
  }

  // Démarrer l'effet de pulsation
  void _startPulsation() {
    // Annuler le timer s'il existe déjà
    _pulsationTimer?.cancel();

    setState(() {
      _isPulsating = true;
      _basePulsationSize = _kaiCircleSize;
      _isPulsatingUp = true;
    });

    // Créer un timer pour l'animation de pulsation
    _pulsationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !_isPulsating) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_isPulsatingUp) {
          // Augmenter la taille
          _kaiCircleSize += 1.5;
          if (_kaiCircleSize >= _basePulsationSize + _pulsationAmount) {
            _isPulsatingUp = false;
          }
        } else {
          // Diminuer la taille
          _kaiCircleSize -= 1.5;
          if (_kaiCircleSize <= _basePulsationSize - _pulsationAmount / 2) {
            _isPulsatingUp = true;
          }
        }
      });
    });
  }

  // Arrêter l'effet de pulsation
  void _stopPulsation() {
    _pulsationTimer?.cancel();
    setState(() {
      _isPulsating = false;
      _kaiCircleSize =
          _basePulsationSize > 0 ? _basePulsationSize : _kaiCircleSize;
    });
  }

  // Démarrer le processus d'animation inverse
  void _startReverseAnimation() {
    // Commencer l'animation inverse
    _animationTimer?.cancel();
    _isAnimatingForward = false;

    // Arrêter la pulsation si elle est active
    if (_isPulsating) {
      _stopPulsation();
    }

    // Créer un timer pour l'animation inverse
    _animationTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Reculer à l'étape précédente
        if (_kaiAnimationStep > 0) {
          _kaiAnimationStep--;

          // Diminuer progressivement la taille du cercle
          _kaiCircleSize =
              (_kaiCircleSize - 10).clamp(220.0, _maxkaiCircleSize);

          // Revenir progressivement à la couleur de base
          double reverseFactor = 1 - (_kaiAnimationStep / 4).clamp(0.0, 1.0);
          _kaiCircleColor = Color.lerp(KaiColors.accent.withOpacity(0.6),
              KaiColors.primaryDark.withOpacity(0.4), reverseFactor)!;
        } else {
          // Animation terminée, on arrête le timer
          timer.cancel();

          // Maintenant on peut désactiver complètement le mode kai
          _iskaiMode = false;

          // Ne pas réinitialiser le compteur de combo ici, c'est maintenant géré par le comboResetTimer
          // _comboClicks = 0;

          // Réinitialiser le cercle
          _kaiCircleSize = 220;
          _kaiCircleColor = KaiColors.primaryDark.withOpacity(0.4);
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
            // Cercle d'énergie (kai/XP)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _kaiCircleSize,
              height: _kaiCircleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kaiCircleColor,
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

            // Image du kai
            if (_iskaiMode)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(_kaiAnimationImages[_kaiAnimationStep]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Image du bouton - maintenant conditionnelle
            if (!_iskaiMode)
              ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/naruto_chakra.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            // Affichage de l'XP total en bas au centre
            Positioned(
              bottom: 30,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KaiColors.primaryDark.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
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
                      Icons.whatshot, // Icône d'XP (flamme)
                      color: KaiColors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatXpForDisplay(widget.totalXP) +
                          ' XP', // Formater l'XP avec max 4 chiffres
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  // Méthode pour formater l'XP avec un maximum de 4 chiffres
  String _formatXpForDisplay(int xp) {
    if (xp >= 1000000) {
      // Pour les millions (M) - Exemple: 1.156M au lieu de 1.1M
      double value = xp / 1000000;
      if (value >= 10) {
        // Pour 10M et plus, afficher deux chiffres significatifs
        return '${value.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '')}M';
      } else {
        // Pour 1M à 9.999M, afficher trois décimales
        return '${value.toStringAsFixed(3).replaceAll(RegExp(r'\.0+$'), '')}M';
      }
    } else if (xp >= 1000) {
      // Pour les milliers (K) - Exemple: 1.156K au lieu de 1.1K
      double value = xp / 1000;
      if (value >= 10) {
        // Pour 10K et plus, afficher deux chiffres significatifs
        return '${value.toStringAsFixed(2).replaceAll(RegExp(r'\.0+$'), '')}K';
      } else {
        // Pour 1K à 9.999K, afficher trois décimales
        return '${value.toStringAsFixed(3).replaceAll(RegExp(r'\.0+$'), '')}K';
      }
    } else {
      // Valeurs inférieures à 1000 - Exemple: 1, 42, 999
      return xp.toString();
    }
  }
}

// Classe pour gérer les animations de clic "+n"
class ClickAnimation {
  final int value;
  final int combo;
  final double offsetX;
  final double offsetY;
  final VoidCallback onComplete;
  final bool isEndOfCombo;

  double progress = 0.0;
  double opacity = 1.0;
  bool isCompleted = false;
  Timer? timer;

  ClickAnimation({
    required this.value,
    this.combo = 1,
    required this.offsetX,
    required this.offsetY,
    required this.onComplete,
    this.isEndOfCombo = false,
  }) {
    // Démarrer l'animation
    timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      progress +=
          0.048; // Doublé par rapport à 0.024 pour une animation 2x plus rapide

      // Commencer à disparaître plus tôt (à 35% au lieu de 40%)
      if (progress > 0.35) {
        opacity = max(0, 1 - ((progress - 0.35) / 0.3));
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
        duration: const Duration(
            milliseconds: 15), // Réduit à 15ms pour être deux fois plus rapide
        child: AnimatedContainer(
          duration: const Duration(
              milliseconds: 75), // Réduit à 75ms au lieu de 150ms
          transform: Matrix4.translationValues(0, -progress * 50,
              0), // Augmenté à 50 pour un mouvement plus rapide
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Afficher le nombre de combo actuel
              Text(
                '+$combo',
                style: TextStyle(
                  fontSize:
                      40, // Légèrement plus grand pour compenser la vitesse
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: KaiColors.primaryDark,
                      blurRadius: 2,
                      offset: const Offset(1.5, 1.5),
                    ),
                    Shadow(
                      color: KaiColors.primaryDark,
                      blurRadius: 2,
                      offset: const Offset(-1.5, -1.5),
                    ),
                    Shadow(
                      color: KaiColors.primaryDark,
                      blurRadius: 2,
                      offset: const Offset(1.5, -1.5),
                    ),
                    Shadow(
                      color: KaiColors.primaryDark,
                      blurRadius: 2,
                      offset: const Offset(-1.5, 1.5),
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
