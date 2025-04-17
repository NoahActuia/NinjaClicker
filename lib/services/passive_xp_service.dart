import 'dart:async';

/// Service qui gère le système d'XP passive du jeu
class PassiveXpService {
  static final PassiveXpService _instance = PassiveXpService._internal();
  factory PassiveXpService() => _instance;

  double _accumulatedXp = 0.0;
  double _xpPerSecond = 0.0;
  double _passiveXpPerHour = 0.0;

  // Getters
  double get xpPerSecond => _xpPerSecond;
  double get passiveXpPerHour => _passiveXpPerHour;
  double get accumulatedXp => _accumulatedXp;

  // Setter pour mettre à jour le taux d'XP passive
  set xpPerSecond(double value) {
    _xpPerSecond = value;
    _passiveXpPerHour = _xpPerSecond * 3600;
  }

  PassiveXpService._internal();

  // Générer de l'XP automatiquement à chaque tick
  int generatePassiveXp() {
    if (_xpPerSecond <= 0) return 0;

    _accumulatedXp += _xpPerSecond;
    int xpToAdd = _accumulatedXp.floor();

    if (xpToAdd > 0) {
      _accumulatedXp -= xpToAdd;
    }

    return xpToAdd;
  }

  // Calculer l'XP généré pendant une période hors ligne
  int calculateOfflineXp(DateTime lastConnected) {
    if (_xpPerSecond <= 0) return 0;

    final now = DateTime.now();
    final secondsElapsed = now.difference(lastConnected).inSeconds;

    // Plafonner à 24 heures (86400 secondes) pour éviter une accumulation excessive
    final cappedSeconds = secondsElapsed < 86400 ? secondsElapsed : 86400;

    return (_xpPerSecond * cappedSeconds).floor();
  }

  // Réinitialiser l'accumulateur
  void resetAccumulator() {
    _accumulatedXp = 0.0;
  }

  // Formater le taux d'XP par heure
  String formatXpPerHour() {
    if (_passiveXpPerHour >= 1000000) {
      return '${(_passiveXpPerHour / 1000000).toStringAsFixed(1)}M/h';
    } else if (_passiveXpPerHour >= 1000) {
      return '${(_passiveXpPerHour / 1000).toStringAsFixed(1)}K/h';
    } else {
      return '${_passiveXpPerHour.toStringAsFixed(1)}/h';
    }
  }

  // Formater le taux d'XP par seconde
  String formatXpPerSecond() {
    if (_xpPerSecond >= 100) {
      return '${_xpPerSecond.toStringAsFixed(0)}/s';
    } else if (_xpPerSecond >= 10) {
      return '${_xpPerSecond.toStringAsFixed(1)}/s';
    } else {
      return '${_xpPerSecond.toStringAsFixed(2)}/s';
    }
  }
}
