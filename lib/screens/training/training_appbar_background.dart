import 'package:flutter/material.dart';
import '../../styles/kai_colors.dart';

class TrainingAppBarBackground extends StatelessWidget {
  const TrainingAppBarBackground({Key? key}) : super(key: key);

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
                color: KaiColors.accent.withOpacity(0.1),
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
                color: KaiColors.accent.withOpacity(0.05),
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
              color: KaiColors.accent.withOpacity(0.2),
            ),
          ),
          // Effet de particules (points lumineux)
          ...List.generate(8, (index) {
            final random = index * 40.0;
            return Positioned(
              top: (index % 3) * 20.0 + 10,
              right: random,
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KaiColors.accent.withOpacity(0.4),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
