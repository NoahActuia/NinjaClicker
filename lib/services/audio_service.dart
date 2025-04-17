import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  final AudioPlayer ambiancePlayer = AudioPlayer();
  final AudioPlayer effectPlayer = AudioPlayer();
  final AudioPlayer techniquePlayer = AudioPlayer();
  final AudioPlayer effectsPlayer = AudioPlayer();

  bool isAmbiancePlaying = false;
  bool isEffectsSoundPlaying = false;

  bool ambianceSoundEnabled = false;
  bool effectsSoundEnabled = true;

  double effectsVolume = 0.5;
  double ambianceVolume = 0.0;

  AudioService._internal();

  Future<void> init() async {
    try {
      await ambiancePlayer.setReleaseMode(ReleaseMode.loop);
      await effectPlayer.setReleaseMode(ReleaseMode.loop);
      await techniquePlayer.setReleaseMode(ReleaseMode.release);

      print("Services audio initialisés avec succès");
    } catch (e) {
      print('Erreur lors de l\'initialisation audio: $e');
    }
  }

  Future<void> startAmbiance() async {
    if (!ambianceSoundEnabled) return;

    try {
      await ambiancePlayer.stop();
      isAmbiancePlaying = false;

      await ambiancePlayer.play(AssetSource('sounds/ambiance.mp3'),
          volume: ambianceVolume);
      isAmbiancePlaying = true;

      print("Musique d'ambiance lancée avec succès");
    } catch (e) {
      print('Erreur lors du démarrage de la musique d\'ambiance: $e');
    }
  }

  Future<void> playkaiSound() async {
    if (!effectsSoundEnabled) return;

    try {
      await effectPlayer.play(AssetSource('sounds/chakra_charge.mp3'),
          volume: effectsVolume);
      isEffectsSoundPlaying = true;
    } catch (e) {
      print('Erreur lors de la lecture du son kai: $e');
    }
  }

  Future<void> playTechniqueSound(String soundPath) async {
    if (!effectsSoundEnabled) return;

    try {
      await techniquePlayer.stop();
      await techniquePlayer.play(AssetSource(soundPath), volume: effectsVolume);
    } catch (e) {
      print('Erreur lors de la lecture du son technique: $e');
    }
  }

  Future<void> stopkaiSound() async {
    try {
      await effectPlayer.stop();
      isEffectsSoundPlaying = false;
    } catch (e) {
      print('Erreur lors de l\'arrêt du son kai: $e');
    }
  }

  Future<void> setAmbianceVolume(double volume) async {
    ambianceVolume = volume;
    if (isAmbiancePlaying) {
      await ambiancePlayer.setVolume(volume);
    }
  }

  Future<void> fadeOutkaiSound() async {
    if (!isEffectsSoundPlaying || !effectsSoundEnabled) return;

    double volume = effectsVolume;
    while (volume > 0.05) {
      volume -= 0.05;
      await effectPlayer.setVolume(volume);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await stopkaiSound();
  }

  void toggleAmbianceSound(bool enabled) {
    ambianceSoundEnabled = enabled;
    if (isAmbiancePlaying) {
      if (enabled) {
        ambiancePlayer.setVolume(ambianceVolume);
      } else {
        ambiancePlayer.setVolume(0);
      }
    } else if (enabled) {
      startAmbiance();
    }
  }

  void toggleEffectsSound(bool enabled) {
    effectsSoundEnabled = enabled;
    if (!enabled) {
      effectPlayer.stop();
      techniquePlayer.stop();
      isEffectsSoundPlaying = false;
    }
  }

  Future<void> stopAmbiance() async {
    try {
      await ambiancePlayer.stop();
      isAmbiancePlaying = false;
      print("Musique d'ambiance arrêtée");
    } catch (e) {
      print('Erreur lors de l\'arrêt de la musique d\'ambiance: $e');
    }
  }

  void dispose() {
    stopAmbiance();
    stopkaiSound();

    ambiancePlayer.dispose();
    effectPlayer.dispose();
    techniquePlayer.dispose();
    effectsPlayer.dispose();

    isAmbiancePlaying = false;
    isEffectsSoundPlaying = false;
  }

  // Jouer un son spécifique
  Future<void> playSound(String soundName) async {
    try {
      // Le chemin doit être sans "assets/" car AssetSource l'ajoute automatiquement
      String soundPath;
      if (soundName.startsWith('assets/sounds/')) {
        // Si le chemin complet est fourni, retirer le préfixe "assets/"
        soundPath = soundName.replaceAll('assets/', '');
      } else if (soundName.startsWith('sounds/')) {
        // Si le chemin commence par "sounds/", le laisser tel quel
        soundPath = soundName;
      } else {
        // Sinon, ajouter "sounds/" devant le nom du son
        soundPath = 'sounds/$soundName';
      }

      await effectsPlayer.play(AssetSource(soundPath));
      print('Lecture du son: $soundPath');
    } catch (e) {
      print('Erreur lors de la lecture du son $soundName: $e');
    }
  }

  // Arrêter tous les sons en même temps
  Future<void> stopAll() async {
    try {
      await stopAmbiance();
      await stopkaiSound();

      // Arrêter également les autres lecteurs
      await techniquePlayer.stop();
      await effectsPlayer.stop();

      print("Tous les sons ont été arrêtés");
    } catch (e) {
      print('Erreur lors de l\'arrêt de tous les sons: $e');
    }
  }
}
