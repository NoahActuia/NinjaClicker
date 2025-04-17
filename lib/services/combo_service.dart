import 'dart:async';

/// Service qui gère le système de combo et de clics
class ComboService {
  static final ComboService _instance = ComboService._internal();
  factory ComboService() => _instance;

  int _currentCombo = 0;
  int _xpPerClick = 1;
  List<DateTime> _clicksInLastSecond = [];
  DateTime _lastClickTime = DateTime.now();
  double _xpFromClicks = 0.0;

  // Getters
  int get currentCombo => _currentCombo;
  int get xpPerClick => _xpPerClick;
  double get xpFromClicks => _xpFromClicks;
  DateTime get lastClickTime => _lastClickTime;

  // Setters
  set xpPerClick(int value) {
    _xpPerClick = value > 0 ? value : 1; // Ensure it's positive
  }

  ComboService._internal();

  // Enregistrer un clic et retourner l'XP gagnée
  int registerClick({double multiplier = 1.0}) {
    _lastClickTime = DateTime.now();
    _clicksInLastSecond.add(_lastClickTime);
    _currentCombo++;

    // Calcule l'XP gagnée, potentiellement avec un multiplicateur
    final int xpGain = (_xpPerClick * multiplier).round();

    return xpGain;
  }

  // Réinitialiser le combo
  void resetCombo() {
    _currentCombo = 0;
  }

  // Mettre à jour les statistiques pour le taux d'XP par seconde
  void updateXpRateStats() {
    final now = DateTime.now();
    // Supprimer les clics plus vieux qu'une seconde
    _clicksInLastSecond
        .removeWhere((clickTime) => now.difference(clickTime).inSeconds >= 1);
    // Calculer l'XP générée par les clics dans la dernière seconde
    _xpFromClicks = _clicksInLastSecond.length * _xpPerClick.toDouble();
  }

  // Calculer le taux total d'XP par seconde (incluant passif + clics)
  double calculateTotalXpPerSecond(double passiveXpPerSecond) {
    return _xpFromClicks + passiveXpPerSecond;
  }

  // Temps écoulé depuis le dernier clic (en millisecondes)
  int timeSinceLastClick() {
    return DateTime.now().difference(_lastClickTime).inMilliseconds;
  }

  // Vider la liste des clics (pour réinitialisation)
  void clearClicks() {
    _clicksInLastSecond.clear();
    _currentCombo = 0;
    _xpFromClicks = 0;
  }
}
