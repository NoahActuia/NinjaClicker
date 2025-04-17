import 'package:flutter/material.dart';
import '../../../../styles/kai_colors.dart';

/// Widget pour l'indicateur de puissance
class PowerIndicatorWidget extends StatelessWidget {
  final int power;
  final Function formatNumber;

  const PowerIndicatorWidget({
    Key? key,
    required this.power,
    required this.formatNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KaiColors.accent.withOpacity(0.7),
            KaiColors.primaryDark.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt,
            color: KaiColors.accent,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            formatNumber(power),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
