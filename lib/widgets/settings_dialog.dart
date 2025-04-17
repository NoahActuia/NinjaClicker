import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../styles/kai_colors.dart';

// Fonction pour afficher le dialogue des paramètres
void showSettingsDialog({
  required BuildContext context,
  required AudioService audioService,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: KaiColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: KaiColors.accent.withOpacity(0.5), width: 1.5),
            ),
            title: const Text(
              'Paramètres',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: KaiColors.accent,
                fontSize: 22,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text(
                    'Musique d\'ambiance',
                    style: TextStyle(
                      color: KaiColors.textPrimary,
                    ),
                  ),
                  trailing: Switch(
                    value: audioService.ambianceSoundEnabled,
                    onChanged: (value) {
                      audioService.toggleAmbianceSound(value);
                      setState(() {}); // Mettre à jour l'état du dialogue
                    },
                    activeColor: KaiColors.accent,
                    activeTrackColor: KaiColors.accent.withOpacity(0.3),
                  ),
                ),
                if (audioService.ambianceSoundEnabled)
                  Slider(
                    value: audioService.ambianceVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label:
                        'Volume: ${(audioService.ambianceVolume * 100).round()}%',
                    onChanged: (value) {
                      audioService.setAmbianceVolume(value);
                      setState(() {}); // Mettre à jour l'état du dialogue
                    },
                    activeColor: KaiColors.accent,
                    inactiveColor: KaiColors.accent.withOpacity(0.2),
                  ),
                ListTile(
                  title: const Text(
                    'Effets sonores',
                    style: TextStyle(
                      color: KaiColors.textPrimary,
                    ),
                  ),
                  trailing: Switch(
                    value: audioService.effectsSoundEnabled,
                    onChanged: (value) {
                      audioService.toggleEffectsSound(value);
                      setState(() {}); // Mettre à jour l'état du dialogue
                    },
                    activeColor: KaiColors.accent,
                    activeTrackColor: KaiColors.accent.withOpacity(0.3),
                  ),
                ),
                if (audioService.effectsSoundEnabled)
                  Slider(
                    value: audioService.effectsVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label:
                        'Volume: ${(audioService.effectsVolume * 100).round()}%',
                    onChanged: (value) {
                      setState(() {
                        audioService.effectsVolume = value;
                      });
                    },
                    activeColor: KaiColors.accent,
                    inactiveColor: KaiColors.accent.withOpacity(0.2),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: KaiColors.accent,
                  backgroundColor: KaiColors.primaryDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Fermer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
