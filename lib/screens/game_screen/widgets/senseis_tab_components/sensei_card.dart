import 'package:flutter/material.dart';
import '../../../../models/sensei.dart';
import '../../../../styles/kai_colors.dart';
import '../../../../styles/kai_text_styles.dart';
import '../../../../widgets/kai_unlock_button.dart';
import '../../../../widgets/kai_upgrade_button.dart';
import '../../game_state.dart';
import 'sensei_icon.dart';
import 'sensei_xp_indicator.dart';

/// Carte de sensei individuelle
class SenseiCard extends StatelessWidget {
  final Sensei sensei;
  final int totalXP;
  final GameState gameState;
  final Function(Sensei) onUnlockSensei;
  final Function(Sensei) onUpgradeSensei;

  const SenseiCard({
    Key? key,
    required this.sensei,
    required this.totalXP,
    required this.gameState,
    required this.onUnlockSensei,
    required this.onUpgradeSensei,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canUnlock =
        !sensei.isUnlocked && totalXP >= sensei.xpCostToUnlock;
    final bool canUpgrade = sensei.isUnlocked &&
        sensei.linkLevel < sensei.maxLinkLevel &&
        totalXP >= sensei.getUpgradeCost();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sensei.isUnlocked
              ? [
                  KaiColors.primaryDark.withOpacity(0.9),
                  KaiColors.primaryDark.withOpacity(0.7),
                ]
              : [
                  Colors.grey.shade800.withOpacity(0.6),
                  Colors.grey.shade700.withOpacity(0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sensei.isUnlocked
              ? KaiColors.accent.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SenseiIcon(
                  affinity: sensei.affinity,
                  isUnlocked: sensei.isUnlocked,
                  size: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            sensei.name,
                            style: TextStyle(
                              color: sensei.isUnlocked
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getAffinityColor(sensei.affinity),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sensei.affinity,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (sensei.isUnlocked) ...[
                        Text(
                          'Lien: ${sensei.linkLevel}/${sensei.maxLinkLevel}',
                          style: TextStyle(
                            color: KaiColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        sensei.description,
                        style: TextStyle(
                          color: sensei.isUnlocked
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[500],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildXpIndicator(),
                _buildCardActions(canUnlock, canUpgrade),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAffinityColor(String affinity) {
    switch (affinity.toLowerCase()) {
      case 'flux':
        return Colors.cyan;
      case 'fracture':
        return Colors.red;
      case 'sceau':
        return Colors.purple;
      case 'dérive':
        return Colors.indigo;
      case 'frappe':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildXpIndicator() {
    if (sensei.isUnlocked) {
      // Pour les senseis débloqués, afficher la production actuelle
      return SenseiXpIndicator(
        xpPerSecond: sensei.getXpPerSecondFormatted(),
      );
    } else {
      // Pour les senseis non débloqués, afficher la production de base
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: KaiColors.background.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: KaiColors.accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school,
              color: Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              gameState.formatNumber(sensei.xpPerSecond) + "XP/s",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCardActions(bool canUnlock, bool canUpgrade) {
    if (sensei.isUnlocked) {
      final bool isMaxLevel = sensei.linkLevel >= sensei.maxLinkLevel;

      return KaiUpgradeButton(
        onPressed: () => onUpgradeSensei(sensei),
        canUpgrade: canUpgrade,
        costText: gameState.formatNumber(sensei.getUpgradeCost()) + ' XP',
        isMaxLevel: isMaxLevel,
      );
    } else {
      return KaiUnlockButton(
        onPressed: () => onUnlockSensei(sensei),
        canUnlock: canUnlock,
        costText: gameState.formatNumber(sensei.xpCostToUnlock) + ' XP',
        label: 'Étudier',
      );
    }
  }
}
