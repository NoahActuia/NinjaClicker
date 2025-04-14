import 'package:flutter/material.dart';
import '../models/resonance.dart';
import '../styles/kai_colors.dart';

class ResonanceList extends StatelessWidget {
  final List<Resonance> resonances;
  final int xp;
  final Function(Resonance) onUnlockResonance;
  final Function(Resonance) onUpgradeResonance;
  final Function() onRefresh;

  const ResonanceList({
    super.key,
    required this.resonances,
    required this.xp,
    required this.onUnlockResonance,
    required this.onUpgradeResonance,
    required this.onRefresh,
  });

  // Calcul de l'XP totale par seconde
  double getTotalXpPerSecond() {
    double total = 0;
    for (var resonance in resonances) {
      total += resonance.getXpPerSecond();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalXpPerSecond = getTotalXpPerSecond();
    final roundedTotalXpPerSecond = totalXpPerSecond.ceil();

    // Trier les résonances de la moins chère à la plus chère
    final sortedResonances = List<Resonance>.from(resonances);
    sortedResonances
        .sort((a, b) => a.xpCostToUnlock.compareTo(b.xpCostToUnlock));

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 4, vertical: 2), // Padding minimal
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Liste de résonances (occupe tout l'espace restant)
          Flexible(
            child: sortedResonances.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune résonance disponible',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemExtent: 120, // Hauteur fixe pour chaque élément
                    itemCount: sortedResonances.length,
                    itemBuilder: (context, index) {
                      final resonance = sortedResonances[index];
                      return ResonanceCardCompact(
                        // Utiliser une version compacte
                        resonance: resonance,
                        xp: xp,
                        onUnlockResonance: onUnlockResonance,
                        onUpgradeResonance: onUpgradeResonance,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Version compacte de la carte de résonance
class ResonanceCardCompact extends StatelessWidget {
  final Resonance resonance;
  final int xp;
  final Function(Resonance) onUnlockResonance;
  final Function(Resonance) onUpgradeResonance;

  const ResonanceCardCompact({
    super.key,
    required this.resonance,
    required this.xp,
    required this.onUnlockResonance,
    required this.onUpgradeResonance,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = resonance.isUnlocked;
    final bool canUnlock = !isUnlocked && xp >= resonance.xpCostToUnlock;
    final bool canUpgrade = isUnlocked &&
        resonance.linkLevel < resonance.maxLinkLevel &&
        xp >= resonance.getUpgradeCost();

    // Calculer l'XP par seconde de cette résonance
    final double xpPerSecond = resonance.getXpPerSecond();
    final String xpPerSecondText = xpPerSecond < 1
        ? '${(xpPerSecond * 10).toStringAsFixed(3)}'
        : '${xpPerSecond.ceil()}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      elevation: 1, // Moins d'ombre
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isUnlocked ? KaiColors.accent : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Pour s'assurer que la colonne est aussi petite que possible
          children: [
            // Première ligne: Icône et Nom
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône plus petite
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? KaiColors.accent.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.auto_fix_high,
                    color: isUnlocked ? KaiColors.accent : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 6),

                // Nom et info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resonance.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isUnlocked
                              ? KaiColors.primaryDark
                              : Colors.grey.shade700,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          isUnlocked
                              ? Text(
                                  'Niv: ${resonance.linkLevel}/${resonance.maxLinkLevel}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                )
                              : Text(
                                  'Base: ${resonance.getPotentialXpPerSecondFormatted()} XP/s',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                          isUnlocked
                              ? Text(
                                  '+${resonance.getXpPerSecondFormatted()} XP/s',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.green[700],
                                  ),
                                )
                              : Text(
                                  '${resonance.xpCostToUnlock} XP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: canUnlock
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Description très courte
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: SizedBox(
                height: 22,
                child: Text(
                  resonance.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Barre de progression si débloqué
            if (isUnlocked) ...[
              LinearProgressIndicator(
                value: resonance.linkLevel / resonance.maxLinkLevel,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
                minHeight: 3,
              ),
            ],

            const SizedBox(height: 3),

            // Bouton d'action
            if (isUnlocked) ...[
              // Bouton d'amélioration ou texte "niveau maximal"
              if (resonance.linkLevel < resonance.maxLinkLevel) ...[
                SizedBox(
                  width: double.infinity,
                  height: 28, // Hauteur réduite
                  child: ElevatedButton.icon(
                    onPressed:
                        canUpgrade ? () => onUpgradeResonance(resonance) : null,
                    icon: const Icon(Icons.upgrade, size: 14),
                    label: Text(
                      'Améliorer (${resonance.getUpgradeCost()} XP)',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KaiColors.primaryDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  height: 28,
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  decoration: BoxDecoration(
                    color: KaiColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: KaiColors.accent, width: 0.5),
                  ),
                  child: const Center(
                    child: Text(
                      'Niveau maximal atteint',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: KaiColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Bouton de déblocage
              SizedBox(
                width: double.infinity,
                height: 28,
                child: ElevatedButton.icon(
                  onPressed:
                      canUnlock ? () => onUnlockResonance(resonance) : null,
                  icon: const Icon(Icons.lock_open, size: 14),
                  label: Text(
                    'Débloquer (${resonance.xpCostToUnlock} XP)',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KaiColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
