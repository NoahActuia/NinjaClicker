import 'package:flutter/material.dart';
import 'dart:async';

class MissionVictoryBSequence extends StatefulWidget {
  final VoidCallback onComplete;

  const MissionVictoryBSequence({
    super.key,
    required this.onComplete,
  });

  @override
  State<MissionVictoryBSequence> createState() => _MissionVictoryBSequenceState();
}

class _MissionVictoryBSequenceState extends State<MissionVictoryBSequence>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _autoScrollTimer;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images_histoire/combat2/combat2fin.png',
      'text': 'Je l\'ai surpris. Il ne s\'attendait pas à ça.',
    },
    {
      'image': 'assets/images_histoire/combat2/combat22fin.png',
      'text': 'Le Sensei sourit à peine.',
    },
    {
      'image': 'assets/images_histoire/combat2/combat222fin.png',
      'text': 'Mais moi, je sens que j\'avance.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
    _startAutoScroll();
    
    // Précacher les images pour éviter les problèmes de chargement
    _precacheImages();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentPage < _pages.length - 1) {
        _nextPage();
      } else {
        timer.cancel();
        widget.onComplete();
      }
    });
  }

  void _skipIntro() {
    if (_currentPage < _pages.length - 1) {
      _autoScrollTimer?.cancel();
      _nextPage();
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
      widget.onComplete();
    }
  }

  void _nextPage() {
    _fadeController.reverse().then((_) {
      setState(() {
        _currentPage++;
      });
      _fadeController.forward();
    });
  }

  void _precacheImages() async {
    for (var page in _pages) {
      // Essayer de précacher chaque image et journaliser les résultats
      try {
        print("Préchargement de l'image de victoire: ${page['image']}");
        await precacheImage(AssetImage(page['image']!), context);
        print("Préchargement réussi (victoire): ${page['image']}");
      } catch (e) {
        print("ERREUR de préchargement pour ${page['image']}: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image(
              image: AssetImage(_pages[_currentPage]['image']!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Afficher un fond de remplacement en cas d'erreur
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.green.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          radius: 0.8,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Overlay gradient pour améliorer la lisibilité du texte
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),

          // Texte
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    _pages[_currentPage]['text']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Indicateur de progression
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Bouton Passer
          Positioned(
            top: 30,
            right: 20,
            child: TextButton(
              onPressed: _skipIntro,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              child: const Text(
                'PASSER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Zone tactile pour navigation
          GestureDetector(
            onTap: () {
              if (_currentPage < _pages.length - 1) {
                _autoScrollTimer?.cancel();
                _nextPage();
                _startAutoScroll();
              } else {
                _skipIntro();
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
} 