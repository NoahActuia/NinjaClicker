import 'package:flutter/material.dart';
import 'dart:async';

class StoryIntro extends StatefulWidget {
  final VoidCallback onComplete;

  const StoryIntro({
    super.key,
    required this.onComplete,
  });

  @override
  State<StoryIntro> createState() => _StoryIntroState();
}

class _StoryIntroState extends State<StoryIntro> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _autoScrollTimer;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images_histoire/intro1.png',
      'text': 'Le dojo est silencieux.\nLe Sensei m\'observe, impassible.\nC\'est l\'heure de prouver ma valeur.',
    },
    {
      'image': 'assets/images_histoire/intro2.png',
      'text': 'Mon bras tremble encore du dernier exercice.\nJe me suis juré de ne jamais abandonner.\nAujourd\'hui, je vais tenir.',
    },
    {
      'image': 'assets/images_histoire/intro3.png',
      'text': 'Il est là, toujours devant moi.\nPlus rapide, plus fort… pour l\'instant.\nJe veux dépasser ce rival.',
    },
    {
      'image': 'assets/images_histoire/intro1.png',
      'text': 'Une rumeur court : seuls les plus dignes\nont survécu à cette épreuve.\nMon tour est venu.',
    },
    {
      'image': 'assets/images_histoire/intro2.png',
      'text': 'Ce regard... il n\'est plus mon maître.\nIl est mon obstacle final.\nSi je flanche, je recule.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _pages.length - 1) {
        _nextPage();
      } else {
        timer.cancel();
        widget.onComplete();
      }
    });
  }

  void _skipIntro() {
    _autoScrollTimer?.cancel();
    widget.onComplete();
  }

  void _nextPage() {
    _fadeController.reverse().then((_) {
      setState(() {
        _currentPage++;
      });
      _fadeController.forward();
    });
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
            child: Image.asset(
              _pages[_currentPage]['image']!,
              fit: BoxFit.cover,
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
                stops: const [0.5, 1.0],
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
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
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
        ],
      ),
    );
  }
} 