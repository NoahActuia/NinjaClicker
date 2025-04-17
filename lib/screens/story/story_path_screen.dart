// lib/screens/story/story_path_screen.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/mission.dart';
import '../../constants/story_missions.dart';
import '../combat/combat_screen.dart';

class StoryPathScreen extends StatefulWidget {
  final int puissance;
  final Function(int puissance, int clones, List<dynamic> techniques) onMissionComplete;

  const StoryPathScreen({
    super.key,
    required this.puissance,
    required this.onMissionComplete,
  });

  @override
  State<StoryPathScreen> createState() => _StoryPathScreenState();
}

class _StoryPathScreenState extends State<StoryPathScreen> {
  int currentLevel = 0;
  final List<Offset> pathPoints = [];
  late double screenWidth;
  late double screenHeight;
  final int totalPoints = 5;

  @override
  void initState() {
    super.initState();
    
    // Initialiser les points après le build du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenWidth = MediaQuery.of(context).size.width;
      screenHeight = MediaQuery.of(context).size.height;
      _generatePath();
    });
  }

  void _generatePath() {
    pathPoints.clear();
    
    // Calculer la hauteur utilisable
    double startY = screenHeight - 100; // Point de départ (en bas)
    double totalHeight = screenHeight - 200; // Espace vertical total disponible
    double spacing = totalHeight / (totalPoints - 1); // Espacement entre les points
    
    // Créer 5 points du bas vers le haut
    for (int i = 0; i < totalPoints; i++) {
      double y = startY - (i * spacing);
      double x = screenWidth / 2;
      
      // Léger zigzag pour les points intermédiaires
      if (i > 0 && i < totalPoints - 1) {
        x += (i % 2 == 0) ? 60 : -60;
      }
      
      pathPoints.add(Offset(x, y));
    }
    
    setState(() {});
  }

  void _startMission(int level) {
    // Vérifier si la mission est disponible
    if (level > currentLevel) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CombatScreen(
          mission: storyMissions[level % storyMissions.length],
          playerPuissance: widget.puissance,
          onVictory: (gains) {
            setState(() {
              // Débloquer le niveau suivant si ce n'est pas déjà fait
              if (currentLevel == level) {
                currentLevel = (currentLevel + 1).clamp(0, totalPoints - 1);
              }
            });
            
            // Appeler la fonction de callback avec les gains
            widget.onMissionComplete(
              gains['puissance'] ?? 0,
              gains['clones'] ?? 0,
              gains['techniques'] ?? [],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pathPoints.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Mode Histoire'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Dessiner le chemin
          CustomPaint(
            size: Size(screenWidth, screenHeight),
            painter: PathPainter(
              points: pathPoints,
              currentLevel: currentLevel,
            ),
          ),
          
          // Ajouter les points/nœuds
          ...List.generate(totalPoints, (index) {
            final point = pathPoints[index];
            return Positioned(
              left: point.dx - 40,
              top: point.dy - 40,
              child: StoryNode(
                label: String.fromCharCode(65 + index), // A, B, C, D, E
                isUnlocked: index <= currentLevel,
                onTap: () => _startMission(index),
                isCompleted: index < currentLevel,
                imagePath: index == 0 ? 'assets/images/ninja1.png' : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> points;
  final int currentLevel;

  PathPainter({required this.points, required this.currentLevel});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final greyPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = AppColors.kaiEnergy
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    // Dessiner les segments entre les points
    for (int i = 0; i < points.length - 1; i++) {
      final path = Path()
        ..moveTo(points[i].dx, points[i].dy)
        ..lineTo(points[i + 1].dx, points[i + 1].dy);
      
      // Utiliser la couleur active pour les segments débloqués
      canvas.drawPath(path, i < currentLevel ? activePaint : greyPaint);
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.currentLevel != currentLevel ||
           oldDelegate.points.length != points.length;
  }
}

class StoryNode extends StatelessWidget {
  final String label;
  final bool isUnlocked;
  final bool isCompleted;
  final VoidCallback onTap;
  final String? imagePath;

  const StoryNode({
    super.key,
    required this.label,
    required this.isUnlocked,
    required this.isCompleted,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted
              ? AppColors.kaiEnergy.withOpacity(0.5) // Complété
              : isUnlocked
                  ? AppColors.kaiEnergy // Débloqué
                  : Colors.grey.withOpacity(0.8), // Verrouillé
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? AppColors.kaiEnergy.withOpacity(0.4)
                  : Colors.transparent,
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Afficher l'image si disponible et débloqué
            if (imagePath != null && isUnlocked && !isCompleted)
              Image.asset(
                imagePath!,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            
            // Lettre du niveau
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
