import 'package:flutter/material.dart';
import '../../styles/kai_colors.dart';

class CombatAppBarBackground extends StatelessWidget {
  final String? missionName;

  const CombatAppBarBackground({
    Key? key,
    this.missionName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KaiColors.primaryDark,
            KaiColors.primaryDark.withOpacity(0.8),
            KaiColors.primaryDark.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Éléments décoratifs en arrière-plan
          Positioned(
            top: -5,
            right: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 20,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.05),
              ),
            ),
          ),
          // Lignes d'énergie horizontales
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: Colors.red.withOpacity(0.2),
            ),
          ),
          // Effet de particules (points lumineux pour simuler l'énergie du combat)
          ...List.generate(12, (index) {
            final random = index * 35.0;
            return Positioned(
              top: (index % 4) * 20.0 + 10,
              right: random,
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index % 2 == 0
                      ? Colors.red.withOpacity(0.4)
                      : KaiColors.accent.withOpacity(0.4),
                ),
              ),
            );
          }),
          // Affichage du nom de la mission avec un style élégant
          if (missionName != null)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  missionName!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Icônes de combat stylisées
          Positioned(
            top: 20,
            left: 20,
            child: Icon(
              Icons.flash_on,
              color: Colors.red.withOpacity(0.3),
              size: 12,
            ),
          ),
          Positioned(
            top: 15,
            right: 40,
            child: Icon(
              Icons.sports_kabaddi,
              color: Colors.red.withOpacity(0.3),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
