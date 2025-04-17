import 'package:flutter/material.dart';
import '../../../../models/resonance.dart';
import '../../../../styles/kai_colors.dart';
import '../../../../styles/kai_text_styles.dart';
import '../../../../widgets/kai_unlock_button.dart';
import '../../../../widgets/kai_upgrade_button.dart';
import '../../game_state.dart';
import 'resonance_icon.dart';
import 'resonance_xp_indicator.dart';

/// Carte de résonance individuelle
class ResonanceCard extends StatelessWidget {
  final Resonance resonance;
  final int totalXP;
  final GameState gameState;
  final Function(Resonance) onUnlockResonance;
  final Function(Resonance) onUpgradeResonance;

  const ResonanceCard({
    Key? key,
    required this.resonance,
    required this.totalXP,
    required this.gameState,
    required this.onUnlockResonance,
    required this.onUpgradeResonance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canUnlock =
        !resonance.isUnlocked && totalXP >= resonance.xpCostToUnlock;
    final bool canUpgrade = resonance.isUnlocked &&
        resonance.linkLevel < resonance.maxLinkLevel &&
        totalXP >= resonance.getUpgradeCost();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KaiColors.background,
              KaiColors.background.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KaiColors.accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(),
              const SizedBox(height: 16),
              Text(
                resonance.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              _buildCardActions(canUnlock, canUpgrade),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      children: [
        ResonanceIcon(
          icon: Icons.auto_fix_high,
          size: 60,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resonance.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (resonance.isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: KaiColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "Active",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    resonance.isUnlocked
                        ? 'Niveau ${resonance.linkLevel}/${resonance.maxLinkLevel}'
                        : 'Non débloquée',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildXpIndicator(),
      ],
    );
  }

  Widget _buildXpIndicator() {
    if (resonance.isUnlocked) {
      // Pour les résonances débloquées, afficher la production actuelle
      return ResonanceXpIndicator(
        xpPerSecond: resonance.getXpPerSecondFormatted(),
      );
    } else {
      // Pour les résonances non débloquées, afficher la production de base au niveau 1
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
        child: Text(
          gameState.formatNumber(resonance.xpPerSecond) + "XP/s",
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildCardActions(bool canUnlock, bool canUpgrade) {
    if (resonance.isUnlocked) {
      final bool isMaxLevel = resonance.linkLevel >= resonance.maxLinkLevel;

      return KaiUpgradeButton(
        onPressed: () => onUpgradeResonance(resonance),
        canUpgrade: canUpgrade,
        costText: gameState.formatNumber(resonance.getUpgradeCost()) + ' XP',
        isMaxLevel: isMaxLevel,
      );
    } else {
      return KaiUnlockButton(
        onPressed: () => onUnlockResonance(resonance),
        canUnlock: canUnlock,
        costText: gameState.formatNumber(resonance.xpCostToUnlock) + ' XP',
        label: 'Débloquer',
      );
    }
  }
}
