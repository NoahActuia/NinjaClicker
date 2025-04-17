import 'package:flutter/material.dart';
import '../../../../styles/kai_colors.dart';

/// Indicateur d'XP/sec pour les résonances
class ResonanceXpIndicator extends StatelessWidget {
  final String xpPerSecond;

  const ResonanceXpIndicator({
    Key? key,
    required this.xpPerSecond,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: KaiColors.primaryDark.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt,
            color: KaiColors.accent,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '+$xpPerSecond / sec',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
