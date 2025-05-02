// lib/screens/story/story_path_screen.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/mission.dart';
import '../../constants/story_missions.dart';
import '../combat/combat_screen.dart';
import 'story_intro_sequence.dart';
import 'mission_intro_sequence.dart';
import 'mission_intro_sequence_b.dart';
import 'mission_victory_sequence.dart';
import 'mission_defeat_sequence.dart';

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
  int currentLevel = 0; // Niveau actuellement sélectionné
  final List<Offset> pathPoints = [];
  late double screenWidth;
  late double screenHeight;
  final int totalPoints = 5;
  bool _hasSeenIntro = false;
  bool isAnimating = false;
  int? lastCompletedLevel;
  bool canStartMission = true; // Variable pour contrôler si on peut lancer une mission
  
  // Ensemble des niveaux complétés
  final Set<int> completedLevels = {};

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
    
    // Calculer les positions Y pour une meilleure répartition verticale
    double startY = screenHeight - 140; // Point A légèrement plus haut
    double endY = 170; // Point E
    double totalHeight = startY - endY;
    double stepY = totalHeight / (totalPoints - 1);
    
    // Définir les positions X pour un zigzag plus marqué
    double centerX = screenWidth / 2;
    
    // Ajouter chaque point avec des positions personnalisées
    // Point A - Centré, légèrement monté
    pathPoints.add(Offset(centerX, startY));
    
    // Point B - Décalé à gauche
    pathPoints.add(Offset(centerX - 100, startY - stepY));
    
    // Point C - Décalé à droite
    pathPoints.add(Offset(centerX + 110, startY - 2 * stepY));
    
    // Point D - Décalé à gauche
    pathPoints.add(Offset(centerX - 105, startY - 3 * stepY));
    
    // Point E - Décalé à droite
    pathPoints.add(Offset(centerX + 90, endY));
    
    setState(() {});
  }

  void _startMission(int level) {
    print("Démarrage de la mission niveau ${level}");
    
    // Pour le niveau A (index 0), afficher l'intro spéciale
    if (level == 0) {
      print("Niveau A - Affichage de l'intro");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MissionIntroSequence(
            onComplete: () {
              print("Intro terminée - Lancement du combat");
              // Après l'intro, lancer le combat sans remplacer l'écran d'intro
              Navigator.of(context).pop(); // Revenir au chemin
              
              // Puis lancer le combat
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CombatScreen(
                    mission: storyMissions[level % storyMissions.length],
                    playerPuissance: widget.puissance,
                    onVictory: (gains) {
                      print("Combat terminé - Affichage de la conclusion");
                      
                      // Revenir au chemin
                      Navigator.of(context).pop();
                      
                      // Vérifier si nous devons animer le ninja
                      bool animateNinja = gains['animate_ninja'] ?? false;
                      
                      // Marquer le niveau comme complété et animer si nécessaire
                      _completeLevel(level, animateNinja);
                      
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
            },
          ),
        ),
      );
    } else if (level == 1) {
      // Pour le niveau B (index 1), afficher son intro spécifique
      print("Niveau B - Affichage de l'intro spécifique");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MissionIntroBSequence(
            onComplete: () {
              print("Intro terminée - Lancement du combat");
              // Après l'intro, lancer le combat sans remplacer l'écran d'intro
              Navigator.of(context).pop(); // Revenir au chemin
              
              // Puis lancer le combat
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CombatScreen(
                    mission: storyMissions[level % storyMissions.length],
                    playerPuissance: widget.puissance,
                    onVictory: (gains) {
                      print("Combat terminé - Affichage de la conclusion");
                      
                      // Revenir au chemin
                      Navigator.of(context).pop();
                      
                      // Vérifier si nous devons animer le ninja
                      bool animateNinja = gains['animate_ninja'] ?? false;
                      
                      // Marquer le niveau comme complété et animer si nécessaire
                      _completeLevel(level, animateNinja);
                      
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
            },
          ),
        ),
      );
    } else {
      // Pour les autres niveaux, comportement standard
      print("Niveau ${String.fromCharCode(65 + level)} - Combat standard");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CombatScreen(
            mission: storyMissions[level % storyMissions.length],
            playerPuissance: widget.puissance,
            onVictory: (gains) {
              Navigator.of(context).pop(); // Revenir au chemin
              
              // Vérifier si nous devons animer le ninja
              bool animateNinja = gains['animate_ninja'] ?? false;
              
              // Marquer le niveau comme complété et animer si nécessaire
              _completeLevel(level, animateNinja);
              
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
  }
  
  void _completeLevel(int level, [bool animateNinja = true]) {
     setState(() {
      // Ajouter le niveau aux niveaux complétés
      completedLevels.add(level);
      
      // Si c'est une victoire et qu'il y a un niveau suivant, animer vers ce niveau
      if (animateNinja && level < totalPoints - 1) {
        // Mémoriser le niveau actuel comme point de départ
        lastCompletedLevel = level;
        
        // Définir le niveau suivant comme cible
        currentLevel = level + 1;
        
        // Activer l'animation
        isAnimating = true;
        canStartMission = false;
      } else {
        // Si c'est une défaite ou le dernier niveau, rester sur le niveau actuel
        currentLevel = level;
        isAnimating = false;
        canStartMission = true;
      }
    });
  }
  
  void _moveNinjaToPoint(int targetLevel) {
    // Vérifier si le niveau est accessible
    // On peut accéder uniquement aux niveaux qu'on a déjà complétés 
    // OU au prochain niveau après le dernier niveau complété
    bool canAccessLevel = completedLevels.contains(targetLevel) || 
                          (targetLevel <= completedLevels.length);
    
    // Si le niveau n'est pas accessible, ne rien faire
    if (!canAccessLevel) {
      // Optionnel: afficher un message indiquant que le niveau est verrouillé
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terminez d\'abord le niveau ${String.fromCharCode(65 + completedLevels.length)} pour débloquer ce niveau!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Si on est déjà sur ce point et qu'il est accessible, on peut lancer la mission
    if (currentLevel == targetLevel) {
      _startMission(targetLevel);
      return;
    }
    
    setState(() {
      // Enregistrer le niveau actuel comme point de départ
      lastCompletedLevel = currentLevel;
      
      // Définir le niveau cible
      int oldLevel = currentLevel;
      currentLevel = targetLevel;
      
      // Activer l'animation et désactiver la possibilité de lancer une mission
      isAnimating = true;
      canStartMission = false;
      
      // Si l'animation est interrompue, on remet correctement les variables
      if (pathPoints.isEmpty) {
        isAnimating = false;
        canStartMission = true;
        lastCompletedLevel = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Afficher d'abord la séquence d'introduction si elle n'a pas été vue
    if (!_hasSeenIntro) {
      return StoryIntroSequence(
        onComplete: () {
          setState(() {
            _hasSeenIntro = true;
          });
        },
      );
    }
    
    // Afficher un indicateur de chargement si les points ne sont pas encore générés
    if (pathPoints.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Afficher le chemin une fois l'intro terminée et les points générés
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
              completedLevels: completedLevels,
                    ),
                  ),
          
          // Ajouter les points/nœuds
          ...List.generate(totalPoints, (index) {
                    final point = pathPoints[index];
            final bool isCurrentLevel = index == currentLevel;
            final bool isCompleted = completedLevels.contains(index);
            final bool isAccessible = isCompleted || index <= completedLevels.length;
            
                    return Positioned(
                      left: point.dx - 40,
                      top: point.dy - 40,
              child: StoryNode(
                label: String.fromCharCode(65 + index), // A, B, C, D, E
                isCurrentLevel: isCurrentLevel,
                isCompleted: isCompleted,
                isAccessible: isAccessible,
                onTap: () {
                  // Si le ninja est déjà sur ce point et qu'on peut lancer une mission
                  if (isCurrentLevel && canStartMission && !isAnimating) {
                    _startMission(index);
                  } else if (!isAnimating) {
                    // Sinon, déplacer d'abord le ninja vers ce point
                    _moveNinjaToPoint(index);
                  }
                },
                imagePath: (isCurrentLevel && !isAnimating) ? 'assets/images/ninja1.png' : null,
                      ),
                    );
                  }),
          
          // Animation du ninja qui monte
          if (isAnimating && lastCompletedLevel != null)
            NinjaAnimation(
                      startPoint: pathPoints[lastCompletedLevel!],
                      endPoint: pathPoints[currentLevel],
                      onAnimationComplete: () {
                        setState(() {
                  isAnimating = false;
                          lastCompletedLevel = null;
                  canStartMission = true; // On peut maintenant lancer la mission
                        });
                      },
                    ),
                ],
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> points;
  final int currentLevel;
  final Set<int> completedLevels;

  PathPainter({
    required this.points, 
    required this.currentLevel,
    required this.completedLevels,
  });

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
      
      // Couleur active (bleue) pour les segments qui relient des niveaux complétés
      // Couleur grise pour les segments non complétés
      bool segmentCompleted = completedLevels.contains(i) && completedLevels.contains(i+1);
      canvas.drawPath(path, segmentCompleted ? activePaint : greyPaint);
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.currentLevel != currentLevel ||
           oldDelegate.points.length != points.length ||
           oldDelegate.completedLevels.length != completedLevels.length;
  }
}

class StoryNode extends StatelessWidget {
  final String label;
  final bool isCurrentLevel;
  final bool isCompleted;
  final bool isAccessible;
  final VoidCallback onTap;
  final String? imagePath;

  const StoryNode({
    super.key,
    required this.label,
    required this.isCurrentLevel,
    required this.isCompleted,
    required this.isAccessible,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Toujours cliquable
      child: Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
              ? AppColors.kaiEnergy // Niveau complété (bleu)
              : isCurrentLevel
                  ? AppColors.kaiEnergy.withOpacity(0.7) // Niveau actuel sélectionné (bleu plus clair)
                  : isAccessible
                      ? Colors.grey.withOpacity(0.8) // Niveau accessible mais non complété (gris)
                      : Colors.grey.withOpacity(0.3), // Niveau verrouillé (gris très clair)
        boxShadow: [
          BoxShadow(
              color: isCurrentLevel
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
            // Afficher l'image uniquement sur le niveau actuel et non complété
            if (imagePath != null && isCurrentLevel)
            Image.asset(
                imagePath!,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            
            // Cadenas pour les niveaux verrouillés
            if (!isAccessible)
              Icon(
                Icons.lock,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
            
            // Lettre du niveau
          Text(
            label,
            style: TextStyle(
                color: isAccessible ? Colors.white : Colors.white.withOpacity(0.5),
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

class NinjaAnimation extends StatefulWidget {
  final Offset startPoint;
  final Offset endPoint;
  final VoidCallback onAnimationComplete;

  const NinjaAnimation({
    Key? key,
    required this.startPoint,
    required this.endPoint,
    required this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<NinjaAnimation> createState() => _NinjaAnimationState();
}

class _NinjaAnimationState extends State<NinjaAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;
  bool isMovingUp = false;

  @override
  void initState() {
    super.initState();
    
    // Déterminer si le ninja monte ou descend
    isMovingUp = widget.endPoint.dy < widget.startPoint.dy;
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Animation de déplacement
    _moveAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Utiliser ninja2.png uniquement quand on monte (niveau inférieur vers supérieur)
        // Utiliser ninja1.png quand on descend (niveau supérieur vers inférieur)
        String ninjaImage = isMovingUp ? 'assets/images/ninja2.png' : 'assets/images/ninja1.png';
        
        // Calculer la position actuelle pour le mouvement
        final currentPosition = Offset.lerp(
          widget.startPoint,
          widget.endPoint,
          _moveAnimation.value,
        )!;
        
        return Positioned(
          left: currentPosition.dx - 40,
          top: currentPosition.dy - 40,
          child: Image.asset(
            ninjaImage,
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}
