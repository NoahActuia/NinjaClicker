import 'package:flutter/material.dart';
import '../styles/kai_colors.dart';
import '../styles/kai_text_styles.dart';

/// Bouton standard pour débloquer des éléments dans l'application
/// Peut être utilisé pour les résonances, techniques, senseis, etc.
class KaiUnlockButton extends StatelessWidget {
  /// Fonction callback appelée quand le bouton est pressé
  final VoidCallback? onPressed;

  /// Si le déblocage peut être effectué (affecte le style et l'état actif/inactif)
  final bool canUnlock;

  /// Texte à afficher sur le bouton (ex: "100 Kai")
  final String costText;

  /// Icône à afficher (par défaut un cadenas ouvert)
  final IconData icon;

  /// Texte principal du bouton (par défaut "Débloquer")
  final String label;

  /// Couleurs personnalisées pour l'état actif
  final Color? activeColor;

  /// Couleurs personnalisées pour l'état inactif
  final Color? inactiveColor;

  const KaiUnlockButton({
    Key? key,
    required this.onPressed,
    required this.canUnlock,
    required this.costText,
    this.icon = Icons.lock_open,
    this.label = 'Débloquer',
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: canUnlock ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canUnlock
            ? activeColor ?? KaiColors.accent
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
