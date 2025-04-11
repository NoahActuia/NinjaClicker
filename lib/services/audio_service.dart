import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  final AudioPlayer ambiancePlayer = AudioPlayer();
  final AudioPlayer effectPlayer = AudioPlayer();
  final AudioPlayer techniquePlayer = AudioPlayer();

  bool isAmbiancePlaying = false;
  bool isEffectsSoundPlaying = false;

  bool ambianceSoundEnabled = true;
  bool effectsSoundEnabled = true;

  double effectsVolume = 0.5;
  double ambianceVolume = 0.15;

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
      if (isAmbiancePlaying) {
        await ambiancePlayer.setVolume(ambianceVolume);
      } else {
        await ambiancePlayer.play(AssetSource('sounds/ambiance.mp3'),
            volume: ambianceVolume);
        isAmbiancePlaying = true;
      }
      print("Musique d'ambiance lancée avec succès");
    } catch (e) {
      print('Erreur lors du démarrage de la musique d\'ambiance: $e');
    }
  }

  Future<void> playChakraSound() async {
    if (!effectsSoundEnabled) return;

    try {
      await effectPlayer.play(AssetSource('sounds/chakra_charge.mp3'),
          volume: effectsVolume);
      isEffectsSoundPlaying = true;
    } catch (e) {
      print('Erreur lors de la lecture du son chakra: $e');
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

  Future<void> stopChakraSound() async {
    try {
      await effectPlayer.stop();
      isEffectsSoundPlaying = false;
    } catch (e) {
      print('Erreur lors de l\'arrêt du son chakra: $e');
    }
  }

  Future<void> setAmbianceVolume(double volume) async {
    ambianceVolume = volume;
    if (isAmbiancePlaying) {
      await ambiancePlayer.setVolume(volume);
    }
  }

  Future<void> fadeOutChakraSound() async {
    if (!isEffectsSoundPlaying || !effectsSoundEnabled) return;

    double volume = effectsVolume;
    while (volume > 0.05) {
      volume -= 0.05;
      await effectPlayer.setVolume(volume);
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await stopChakraSound();
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

  void dispose() {
    ambiancePlayer.dispose();
    effectPlayer.dispose();
    techniquePlayer.dispose();
  }
}
