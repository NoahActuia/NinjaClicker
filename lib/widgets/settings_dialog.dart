import 'package:flutter/material.dart';
import '../services/audio_service.dart';

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
            title: const Text(
              'Paramètres',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Musique d\'ambiance'),
                  trailing: Switch(
                    value: audioService.ambianceSoundEnabled,
                    onChanged: (value) {
                      audioService.toggleAmbianceSound(value);
                      setState(() {}); // Mettre à jour l'état du dialogue
                    },
                    activeColor: Colors.orange,
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
                    activeColor: Colors.orange,
                  ),
                ListTile(
                  title: const Text('Effets sonores'),
                  trailing: Switch(
                    value: audioService.effectsSoundEnabled,
                    onChanged: (value) {
                      audioService.toggleEffectsSound(value);
                      setState(() {}); // Mettre à jour l'état du dialogue
                    },
                    activeColor: Colors.orange,
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
                    activeColor: Colors.orange,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fermer',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
