import 'package:flutter/material.dart';
import '../../styles/kai_colors.dart';
import '../../services/audio_service.dart';
import 'game_state.dart';

/// Affiche une boîte de dialogue pour l'XP accumulée hors-ligne
void showOfflineXpDialog({
  required BuildContext context,
  required int xpGained,
  required Function() onClaim,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('XP Passive Accumulée'),
      content: Text(
        'Pendant votre absence, vos Résonances ont généré $xpGained XP!',
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClaim();
          },
          child: const Text('Récupérer'),
        ),
      ],
    ),
  );
}

/// Affiche une boîte de dialogue pour quitter le jeu
void showQuitGameDialog({
  required BuildContext context,
  required Function() onQuit,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Quitter la partie',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text('Voulez-vous vraiment quitter le jeu ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onQuit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KaiColors.primaryDark,
            ),
            child: const Text(
              'Quitter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

/// Affiche la boîte de dialogue de mission complétée
void showMissionCompleteDialog({
  required BuildContext context,
  required String title,
  required String description,
  required int xpGained,
  required List<String> rewards,
  required Function() onClose,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          color: KaiColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 10),
          Text(
            'XP gagnée: $xpGained',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          if (rewards.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Récompenses:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            ...rewards.map(
              (reward) => Padding(
                padding: const EdgeInsets.only(left: 10, top: 5),
                child: Text('• $reward'),
              ),
            ),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onClose();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KaiColors.accent,
          ),
          child: const Text('Continuer'),
        ),
      ],
    ),
  );
}

/// Affiche une boîte de dialogue d'information
void showInfoDialog({
  required BuildContext context,
  required String title,
  required String content,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          color: KaiColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Affiche une boîte de dialogue de confirmation avec des options
void showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmLabel,
  required String cancelLabel,
  required Function() onConfirm,
  required Function() onCancel,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          color: KaiColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel();
          },
          child: Text(
            cancelLabel,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KaiColors.accent,
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
