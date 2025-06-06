import 'package:flutter/material.dart';
import '../styles/kai_colors.dart';
import '../models/technique.dart';

class BattleHealthBar extends StatelessWidget {
  final String name;
  final double health;
  final double maxHealth;
  final Color color;
  final bool hasShield;

  const BattleHealthBar({
    Key? key,
    required this.name,
    required this.health,
    this.maxHealth = 1000.0,
    required this.color,
    this.hasShield = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          height: 25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.black26,
          ),
          child: Stack(
            children: [
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: health / maxHealth,
                  backgroundColor: Colors.black38,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 25,
                ),
              ),
              // Texte de la valeur
              Center(
                child: Text(
                  "${health.toInt()}/${maxHealth.toInt()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Effet de bouclier
              if (hasShield)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: color.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class BattleKaiBar extends StatelessWidget {
  final String name;
  final double kai;
  final double maxKai;

  const BattleKaiBar({
    Key? key,
    required this.name,
    required this.kai,
    required this.maxKai,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 2),
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.black26,
          ),
          child: Stack(
            children: [
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: kai / maxKai,
                  backgroundColor: Colors.black38,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(KaiColors.kaiEnergy),
                  minHeight: 20,
                ),
              ),
              // Texte de la valeur
              Center(
                child: Text(
                  "${kai.toInt()}/$maxKai",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BattleTechniqueCard extends StatelessWidget {
  final Technique technique;
  final bool isPlayer;
  final bool isDisabled;
  final int cooldown;
  final VoidCallback? onTap;

  const BattleTechniqueCard({
    Key? key,
    required this.technique,
    required this.isPlayer,
    this.isDisabled = false,
    this.cooldown = 0,
    this.onTap,
  }) : super(key: key);

  Color _getTechniqueColor() {
    if (isDisabled) return Colors.grey.shade800;

    switch (technique.type.toLowerCase()) {
      case 'flux':
        return Colors.blue;
      case 'fracture':
        return Colors.purple;
      case 'sceau':
        return Colors.green;
      case 'dérive':
        return Colors.orange;
      case 'frappe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTechniqueColor();
    final textColor = isPlayer ? Colors.white : Colors.white70;

    return Container(
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade800 : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDisabled ? Colors.grey : color.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  technique.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      technique.conditionGenerated == 'shield'
                          ? Icons.shield
                          : Icons.flash_on,
                      color: textColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${technique.damage} dmg",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.energy_savings_leaf,
                      color: isPlayer ? KaiColors.kaiEnergy : textColor,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "${technique.cost_kai}",
                      style: TextStyle(
                        color: isPlayer ? KaiColors.kaiEnergy : textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (cooldown > 0)
                  Text(
                    "CD: $cooldown",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
