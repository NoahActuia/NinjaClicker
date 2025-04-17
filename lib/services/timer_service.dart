import 'dart:async';

/// Service qui centralise tous les timers du jeu
class TimerService {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;

  // Timers
  Timer? _gameLoopTimer;
  Timer? _autoSaveTimer;
  Timer? _xpRateCalculationTimer;
  Timer? _comboResetTimer;
  Timer? _pulsationTimer;

  // Callbacks
  Function? _onGameLoopTick;
  Function? _onAutoSaveTick;
  Function? _onXpRateCalculationTick;

  TimerService._internal();

  // Démarrer le timer principal du jeu
  void startGameLoop(Function callback) {
    _onGameLoopTick = callback;
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_onGameLoopTick != null) {
        _onGameLoopTick!();
      }
    });
  }

  // Démarrer le timer d'auto-sauvegarde
  void startAutoSave(Function callback, {int minutes = 2}) {
    _onAutoSaveTick = callback;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(Duration(minutes: minutes), (_) {
      if (_onAutoSaveTick != null) {
        _onAutoSaveTick!();
      }
    });
  }

  // Démarrer le timer de calcul du taux d'XP
  void startXpRateCalculation(Function callback) {
    _onXpRateCalculationTick = callback;
    _xpRateCalculationTimer?.cancel();
    _xpRateCalculationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_onXpRateCalculationTick != null) {
        _onXpRateCalculationTick!();
      }
    });
  }

  // Démarrer un timer pour réinitialiser le combo
  void startComboResetTimer(Function callback, {int milliseconds = 250}) {
    _comboResetTimer?.cancel();
    _comboResetTimer = Timer(Duration(milliseconds: milliseconds), () {
      callback();
    });
  }

  // Démarrer un timer de pulsation
  void startPulsationTimer(Function callback, {int milliseconds = 50}) {
    _pulsationTimer?.cancel();
    _pulsationTimer = Timer.periodic(Duration(milliseconds: milliseconds), (_) {
      callback();
    });
  }

  // Arrêter tous les timers
  void stopAllTimers() {
    _gameLoopTimer?.cancel();
    _autoSaveTimer?.cancel();
    _xpRateCalculationTimer?.cancel();
    _comboResetTimer?.cancel();
    _pulsationTimer?.cancel();
  }

  // Disposer proprement des ressources
  void dispose() {
    stopAllTimers();
    _onGameLoopTick = null;
    _onAutoSaveTick = null;
    _onXpRateCalculationTick = null;
  }
}
