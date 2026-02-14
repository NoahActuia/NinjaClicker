import 'package:flutter/material.dart';

/// Widget d'icône pour les senseis avec couleurs basées sur l'affinité
class SenseiIcon extends StatelessWidget {
  final double size;
  final String affinity;
  final bool isUnlocked;

  const SenseiIcon({
    Key? key,
    this.size = 60,
    required this.affinity,
    this.isUnlocked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getAffinityColors(affinity);
    final opacity = isUnlocked ? 1.0 : 0.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors['background']!.withOpacity(0.2 * opacity),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors['border']!.withOpacity(opacity),
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: colors['border']!.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          _getAffinityIcon(affinity),
          size: size * 0.6,
          color: colors['icon']!.withOpacity(opacity),
        ),
      ),
    );
  }

  Map<String, Color> _getAffinityColors(String affinity) {
    switch (affinity.toLowerCase()) {
      case 'flux':
        return {
          'background': Colors.cyan,
          'border': Colors.cyanAccent,
          'icon': Colors.cyan.shade300,
        };
      case 'fracture':
        return {
          'background': Colors.red,
          'border': Colors.redAccent,
          'icon': Colors.red.shade300,
        };
      case 'sceau':
        return {
          'background': Colors.purple,
          'border': Colors.purpleAccent,
          'icon': Colors.purple.shade300,
        };
      case 'dérive':
        return {
          'background': Colors.indigo,
          'border': Colors.indigoAccent,
          'icon': Colors.indigo.shade300,
        };
      case 'frappe':
        return {
          'background': Colors.orange,
          'border': Colors.orangeAccent,
          'icon': Colors.orange.shade300,
        };
      default:
        return {
          'background': Colors.grey,
          'border': Colors.grey.shade400,
          'icon': Colors.grey.shade300,
        };
    }
  }

  IconData _getAffinityIcon(String affinity) {
    switch (affinity.toLowerCase()) {
      case 'flux':
        return Icons.waves;
      case 'fracture':
        return Icons.flash_on;
      case 'sceau':
        return Icons.security;
      case 'dérive':
        return Icons.blur_on;
      case 'frappe':
        return Icons.fitness_center;
      default:
        return Icons.person;
    }
  }
}
