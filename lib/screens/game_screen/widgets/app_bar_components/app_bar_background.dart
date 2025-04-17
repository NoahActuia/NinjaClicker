import 'package:flutter/material.dart';
import '../../../../styles/kai_colors.dart';

/// Widget pour l'arrière-plan dégradé de l'AppBar
class AppBarBackground extends StatelessWidget {
  const AppBarBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KaiColors.background,
            KaiColors.background.withOpacity(0.7),
            KaiColors.accent.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
