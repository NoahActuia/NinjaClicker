import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_colors.dart';

class MissionDefeatSequence extends StatefulWidget {
  final VoidCallback onComplete;

  const MissionDefeatSequence({
    super.key,
    required this.onComplete,
  });

  @override
  State<MissionDefeatSequence> createState() => _MissionDefeatSequenceState();
}

class _MissionDefeatSequenceState extends State<MissionDefeatSequence>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _autoScrollTimer;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images_histoire/combat1/combat1vaincu.png',
      'text': "Ce n'est pas la fin.\nCe n'est que le début de ma vraie force.",
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
    // Au lieu de terminer complètement, passer à l'image suivante
    if (_currentPage < _pages.length - 1) {
      _autoScrollTimer?.cancel();
      _nextPage();
      _startAutoScroll(); // Redémarrer le timer pour la prochaine image
    } else {
      // Si on est à la dernière image, alors terminer
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
        print("Préchargement de l'image: ${page['image']}");
        await precacheImage(AssetImage(page['image']!), context);
        print("Préchargement réussi: ${page['image']}");
      } catch (e) {
        print("ERREUR de préchargement pour ${page['image']}: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond image
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              _pages[_currentPage]['image']!,
              fit: BoxFit.cover,
            ),
          ),
          
          // Overlay sombre pour la lisibilité
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          
          // Texte
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _pages[_currentPage]['text']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Indicateurs de progression (points)
          if (_pages.length > 1)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
          
          // Bouton "Passer"
          Positioned(
            top: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _skipIntro,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Passer'),
            ),
          ),
        ],
      ),
    );
  }
} 