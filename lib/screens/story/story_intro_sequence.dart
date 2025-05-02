import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_colors.dart';

class StoryIntroSequence extends StatefulWidget {
  final VoidCallback onComplete;

  const StoryIntroSequence({
    super.key,
    required this.onComplete,
  });

  @override
  State<StoryIntroSequence> createState() => _StoryIntroSequenceState();
}

class _StoryIntroSequenceState extends State<StoryIntroSequence> {
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  bool _isAnimating = false;
  final Duration _transitionDuration = const Duration(milliseconds: 1000);
  final Duration _pageDuration = const Duration(seconds: 10);

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/images_histoire/introo/introo1.png',
      'text': 'Han. Mon village. Ma famille.\nJe n\'ai pas de parents.'
    },
    {
      'image': 'assets/images_histoire/introo/introo2.png',
      'text': 'Mais j\'ai grandi sous le regard du Sensei.\nIl m\'a formé, élevé... testé.'
    },
    {
      'image': 'assets/images_histoire/introo/introo3.png',
      'text': 'Il dit que je porte un feu ancien.\nPas celui qui détruit...'
    },
    {
      'image': 'assets/images_histoire/introo/introo4.png',
      'text': 'Celui qui appelle quelque chose de plus grand.\nMais parfois, je sens qu\'il me cache quelque chose.'
    },
    {
      'image': 'assets/images_histoire/introo/introo5.png',
      'text': 'Depuis quelque temps, des symboles inconnus apparaissent près du village.\nDes éclaireurs ennemis ont été repoussés, mais Han est en danger.'
    },
    {
      'image': 'assets/images_histoire/introo/introo6.png',
      'text': 'Alors je dois partir… m\'entraîner… découvrir la vérité.\nCe que je vais affronter dépasse tout ce qu\'on m\'a enseigné.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_pageDuration, (_) {
      if (_currentPage < _pages.length - 1) {
        _goToNextPage();
      } else {
        _autoScrollTimer?.cancel();
        widget.onComplete();
      }
    });
  }

  void _goToNextPage() {
    if (!mounted || _isAnimating) return;
    
    setState(() {
      _isAnimating = true;
      _currentPage++;
    });
    
    Future.delayed(_transitionDuration, () {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void _skipIntro() {
    _autoScrollTimer?.cancel();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image de fond avec animation de fondu
          AnimatedSwitcher(
            duration: _transitionDuration,
            child: Container(
              key: ValueKey<int>(_currentPage),
              width: screen.width,
              height: screen.height,
              color: Colors.black, // Couleur de fond par défaut
              child: Image(
                image: AssetImage(_pages[_currentPage]['image']),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child; // Image est chargée
                  }
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.kaiEnergy,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  // Au lieu d'afficher une erreur, on montre simplement un fond stylisé
                  return Container(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        // Effet artistique pour remplacer l'image manquante
                        Center(
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.kaiEnergy.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                                radius: 0.8,
                              ),
                            ),
                          ),
                        ),
                        // Symbole décoratif
                        Center(
                          child: Icon(
                            Icons.extension,
                            size: 100,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Overlay sombre pour améliorer la lisibilité du texte (plus léger)
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          
          // Texte avec animation de fondu
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: AnimatedSwitcher(
              duration: _transitionDuration,
              child: Container(
                key: ValueKey<int>(_currentPage),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pages[_currentPage]['text'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          // Indicateur de progression
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.kaiEnergy
                        : Colors.grey.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
          
          // Bouton passer
          Positioned(
            top: 50,
            right: 20,
            child: ElevatedButton(
              onPressed: _skipIntro,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kaiEnergy.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Passer'),
            ),
          ),
          
          // Zone tactile pour navigation
          GestureDetector(
            onTap: () {
              if (_currentPage < _pages.length - 1) {
                _autoScrollTimer?.cancel();
                _goToNextPage();
                _startAutoScroll();
              } else {
                _skipIntro();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: screen.width,
              height: screen.height,
            ),
          ),
        ],
      ),
    );
  }
} 