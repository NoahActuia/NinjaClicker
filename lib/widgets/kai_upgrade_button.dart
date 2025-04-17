import 'package:flutter/material.dart';
import '../styles/kai_colors.dart';
import '../styles/kai_text_styles.dart';

/// Bouton standard pour améliorer des éléments dans l'application
/// Peut être utilisé pour les résonances, techniques, senseis, etc.
class KaiUpgradeButton extends StatelessWidget {
  /// Fonction callback appelée quand le bouton est pressé
  final VoidCallback? onPressed;

  /// Si l'amélioration peut être effectuée (affecte le style et l'état actif/inactif)
  final bool canUpgrade;

  /// Texte à afficher sur le bouton (ex: "200 Kai")
  final String costText;

  /// Icône à afficher (par défaut une flèche vers le haut)
  final IconData icon;

  /// Texte principal du bouton (par défaut "Améliorer")
  final String label;

  /// Couleurs personnalisées pour l'état actif
  final Color? activeColor;

  /// Couleurs personnalisées pour l'état inactif
  final Color? inactiveColor;

  /// Message pour niveau maximum atteint
  final String maxLevelText;

  /// Si l'élément est au niveau maximum
  final bool isMaxLevel;

  const KaiUpgradeButton({
    Key? key,
    required this.onPressed,
    required this.canUpgrade,
    required this.costText,
    this.icon = Icons.upgrade,
    this.label = 'Améliorer',
    this.activeColor,
    this.inactiveColor,
    this.maxLevelText = 'Niveau Maximum Atteint',
    this.isMaxLevel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMaxLevel) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: KaiColors.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          maxLevelText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: canUpgrade ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canUpgrade
            ? activeColor ?? KaiColors.primaryDark
            : inactiveColor ?? Colors.grey.shade800,
        disabledBackgroundColor: inactiveColor ?? Colors.grey.shade800,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label ($costText)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
