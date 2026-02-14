import 'dart:async';
import 'dart:math' show max;
import '../../models/kaijin.dart';
import '../../models/technique.dart';
import '../../models/sensei.dart';
import '../../models/resonance.dart';
import '../../services/audio_service.dart';
import '../../services/save_service.dart';
import '../../services/resonance_service.dart';
import '../../services/kaijin_service.dart';
import '../../services/xp_service.dart';
import '../../services/passive_xp_service.dart';
import '../../services/combo_service.dart';
import '../../services/timer_service.dart';
import '../../services/power_service.dart';
import '../../services/sensei_service.dart';
import '../../services/technique_service.dart';
import '../../services/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Classe qui gère l'état du jeu et les interactions avec les services
class GameState {
  // Variables d'état
  int totalXP = 0;
  int playerLevel = 1;
  int xpForNextLevel = 100;
  int power = 0;

  // Kaijin actuel
  Kaijin? currentKaijin;

  // Stats du joueur
  int playerStrength = 10;
  int playerAgility = 10;
  int playerKai = 10;
  int playerSpeed = 10;
  int playerDefense = 10;

  // Collections
  List<Technique> techniques = [];
  List<Technique> playerTechniques = [];
  Map<String, int> techniqueLevels = {};

  // Système de Résonance
  List<Resonance> allResonances = [];
  List<Resonance> playerResonances = [];

  // Système de Senseis (nouveau)
  List<Sensei> allSenseis = [];
  List<Sensei> playerSenseis = [];

  // XP hors-ligne
  int offlineXpGained = 0;
  bool offlineXpClaimed = false;

  // Services
  final AudioService audioService = AudioService();
  final SaveService saveService = SaveService();
  final KaijinService kaijinService = KaijinService();
  final ResonanceService resonanceService = ResonanceService();
  final XpService xpService = XpService();
  final PassiveXpService passiveXpService = PassiveXpService();
  final ComboService comboService = ComboService();
  final TimerService timerService = TimerService();
  final PowerService powerService = PowerService();
  final SenseiService senseiService = SenseiService();
  final TechniqueService techniqueService = TechniqueService();

  // Propriétés déléguées aux services (pour compatibilité)
  double get xpPerSecondPassive => passiveXpService.xpPerSecond;
  int get currentCombo => comboService.currentCombo;
  int get xpPerClick => comboService.xpPerClick;

  // Fonction de rappel pour mettre à jour l'état
  final Function() updateState;

  GameState({required this.updateState});

  // Méthodes déléguées aux services (pour compatibilité)
  Future<void> initDefaultResonances() async {
    try {
      await resonanceService.initDefaultResonances();
      await loadPlayerResonances();
    } catch (e) {
      AppLogger.error('Erreur lors de l\'initialisation des résonances', e);
    }
  }

  Future<void> initDefaultSenseis() async {
    try {
      await senseiService.initDefaultSenseis();
      await loadPlayerSenseis();
    } catch (e) {
      AppLogger.error('Erreur lors de l\'initialisation des senseis', e);
    }
  }

  // Méthodes pour les résonances
  Future<String?> unlockResonance(Resonance resonance) async {
    if (currentKaijin == null) return 'ERR_KAIJIN_NOT_FOUND';

    final errorCode = await resonanceService.unlockResonanceWithXp(
        currentKaijin!, resonance, totalXP, adjustSpendableXp);

    if (errorCode == null) {
      // Mettre à jour localement la résonance sans attendre le rechargement
      resonance.isUnlocked = true;
      resonance.linkLevel = 1;

      // Rafraîchir les listes de résonances
      await loadPlayerResonances();
      updateState();
    }
    return errorCode;
  }

  Future<String?> upgradeResonance(Resonance resonance) async {
    if (currentKaijin == null) return 'ERR_KAIJIN_NOT_FOUND';

    final errorCode = await resonanceService.upgradeResonanceWithXp(
        currentKaijin!, resonance, totalXP, adjustSpendableXp);

    if (errorCode == null) {
      // Rafraîchir les listes de résonances
      await loadPlayerResonances();
      updateState();
    }
    return errorCode;
  }

  // Méthodes pour les senseis
  Future<String?> unlockSensei(Sensei sensei) async {
    if (currentKaijin == null) return 'ERR_KAIJIN_NOT_FOUND';

    final errorCode = await senseiService
        .unlockSenseiWithXp(currentKaijin!, sensei, totalXP, adjustSpendableXp);

    if (errorCode == null) {
      // Mettre à jour localement le sensei sans attendre le rechargement
      sensei.isUnlocked = true;
      sensei.linkLevel = 1;

      // Rafraîchir les listes de senseis
      await loadPlayerSenseis();
      updateState();
    }
    return errorCode;
  }

  Future<String?> upgradeSensei(Sensei sensei) async {
    if (currentKaijin == null) return 'ERR_KAIJIN_NOT_FOUND';

    final errorCode = await senseiService.upgradeSenseiWithXp(
        currentKaijin!, sensei, totalXP, adjustSpendableXp);

    if (errorCode == null) {
      // Rafraîchir les listes de senseis
      await loadPlayerSenseis();
      updateState();
    }
    return errorCode;
  }

  // Mettre à jour le niveau basé sur l'XP totale
  void updatePlayerLevel() {
    if (currentKaijin != null) {
      // Calculer le niveau en fonction de l'XP totale accumulée
      playerLevel =
          xpService.calculatePlayerLevel(currentKaijin!.totalLifetimeXp);
      xpForNextLevel = xpService.calculateXPForNextLevel(playerLevel);

      // Mettre à jour le niveau du kaijin si besoin
      if (playerLevel != currentKaijin!.level) {
        currentKaijin!.level = playerLevel;
        kaijinService.updateKaijin(currentKaijin!);
      }
    }

    updateState();
  }

  // Ajouter de l'XP et mettre à jour le niveau
  void addXP(int amount) {
    if (amount <= 0) return;

    // Ajouter à l'XP dépensable (monnaie du jeu)
    totalXP += amount;

    // Toujours incrémenter l'XP totale accumulée dans le kaijin
    if (currentKaijin != null) {
      currentKaijin!.xp = totalXP;
      currentKaijin!.totalLifetimeXp += amount;
    }

    updateState();
    updatePlayerLevel();
    calculatePower();
  }

  // Appliquer une dépense ou un remboursement d'XP sans toucher l'XP lifetime
  void adjustSpendableXp(int amount) {
    if (amount == 0) return;
    totalXP = max(0, totalXP + amount);
    if (currentKaijin != null) {
      currentKaijin!.xp = totalXP;
    }
    updateState();
  }

  // Calculer la puissance
  void calculatePower() {
    power = powerService.calculateTotalPower(
        playerTechniques, playerSenseis, playerResonances, playerLevel);

    updateState();

    if (currentKaijin != null) {
      currentKaijin!.power = power;
    }
  }

  // Initialisation du jeu
  Future<void> initializeGame() async {
    AppLogger.info('Initialisation du jeu...');
    resetGameState();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.warning('Utilisateur non connecté');
      return;
    }

    await loadCurrentKaijin();
    await initDefaultResonances();
    await initDefaultSenseis();
    await loadPlayerData();
    startTimers();

    AppLogger.info('Jeu initialisé avec succès');
  }

  // Chargement centralisé des données du joueur
  Future<void> loadPlayerData() async {
    if (currentKaijin == null) return;

    await Future.wait([
      loadPlayerTechniques(),
      loadPlayerSenseis(),
      loadPlayerResonances(),
    ]);

    await checkOfflineXp();
    startXpRateCalculation();
  }

  // Réinitialiser l'état du jeu
  void resetGameState() {
    totalXP = 0;
    power = 0;
    playerLevel = 1;
    playerStrength = 10;
    playerAgility = 10;
    playerKai = 10;
    playerSpeed = 10;
    playerDefense = 10;
    currentKaijin = null;

    techniques.clear();
    playerTechniques = [];
    techniqueLevels = {};

    allResonances = [];
    playerResonances = [];

    allSenseis = [];
    playerSenseis = [];

    offlineXpGained = 0;
    offlineXpClaimed = false;

    passiveXpService.xpPerSecond = 0;
    comboService.xpPerClick = 1;
    passiveXpService.resetAccumulator();
    comboService.clearClicks();

    updateState();
  }

  // Charger le kaijin actuel
  Future<void> loadCurrentKaijin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        currentKaijin = await kaijinService.getCurrentKaijin(user.uid);

        if (currentKaijin != null) {
          totalXP = currentKaijin!.xp;

          // Vérifier si totalLifetimeXp est initialisé correctement
          if (currentKaijin!.totalLifetimeXp <= 0) {
            // Si totalLifetimeXp n'est pas initialisé, on le définit au moins égal à l'XP actuelle
            // C'est une approche de migration des anciennes données
            currentKaijin!.totalLifetimeXp = currentKaijin!.xp;
            await kaijinService.updateKaijin(currentKaijin!);
          }

          // Calculer le niveau basé sur totalLifetimeXp
          playerLevel =
              xpService.calculatePlayerLevel(currentKaijin!.totalLifetimeXp);
          playerStrength = currentKaijin!.strength;
          playerAgility = currentKaijin!.agility;
          playerKai = currentKaijin!.kai;
          playerSpeed = currentKaijin!.speed;
          playerDefense = currentKaijin!.defense;
          comboService.xpPerClick = currentKaijin!.xpPerClick;
          xpForNextLevel = xpService.calculateXPForNextLevel(playerLevel);

          updateState();

          AppLogger.info(
              'Kaijin chargé: ${currentKaijin!.name} (Niveau ${currentKaijin!.level}, XP: ${currentKaijin!.xp}, XP totale accumulée: ${currentKaijin!.totalLifetimeXp})');
        } else {
          AppLogger.warning('Aucun kaijin trouvé pour l\'utilisateur');
        }
      } catch (e) {
        AppLogger.error('Erreur lors du chargement du kaijin', e);
      }
    }
  }

  // Charger les techniques du joueur
  Future<void> loadPlayerTechniques() async {
    if (currentKaijin == null) return;

    try {
      techniques = await techniqueService.loadTechniques(currentKaijin!.id);

      if (techniques.isNotEmpty && currentKaijin!.techniques.isNotEmpty) {
        playerTechniques =
            techniqueService.getPlayerTechniques(techniques, currentKaijin!);
        techniqueLevels = Map<String, int>.from(currentKaijin!.techniqueLevels);

        updateState();
        calculatePower();

        AppLogger.info("Techniques du joueur chargées: ${playerTechniques.length}");
      }
    } catch (e) {
      AppLogger.error("Erreur lors du chargement des techniques du joueur", e);
    }
  }

  // Charger les senseis du joueur
  Future<void> loadPlayerSenseis() async {
    if (currentKaijin == null) return;

    try {
      // Charger d'abord tous les senseis disponibles
      allSenseis = await senseiService.getAllSenseis();

      // Charger les senseis du joueur
      playerSenseis = await senseiService.getKaijinSenseis(currentKaijin!.id);

      // Mettre à jour l'état de déverrouillage et le niveau des senseis dans allSenseis
      for (var playerSensei in playerSenseis) {
        final index = allSenseis.indexWhere((s) => s.id == playerSensei.id);
        if (index != -1) {
          // Mettre à jour l'état du sensei dans la liste principale
          allSenseis[index].isUnlocked = playerSensei.isUnlocked;
          allSenseis[index].linkLevel = playerSensei.linkLevel;
        }
      }

      updateState();
      calculatePower();

      AppLogger.info("Senseis du joueur chargés: ${playerSenseis.length}");
      AppLogger.info("Total des senseis disponibles: ${allSenseis.length}");

      await updatePassiveXpRate();
    } catch (e) {
      AppLogger.error("Erreur lors du chargement des senseis du joueur", e);
    }
  }

  // Méthode pour démarrer les timers
  void startTimers() {
    // Timer principal du jeu - génère de l'XP passive
    timerService.startGameLoop(() {
      final xpGained = passiveXpService.generatePassiveXp();
      if (xpGained > 0) {
        addXP(xpGained);
      }
    });

    // Timer pour la sauvegarde automatique
    timerService.startAutoSave(() async {
      await saveGame(updateConnections: false);
      AppLogger.info('Sauvegarde automatique effectuée');
    });
  }

  // Sauvegarder la partie actuelle
  Future<void> saveGame({bool updateConnections = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && currentKaijin != null) {
        // Mise à jour des données de base
        currentKaijin!.xp = totalXP;

        // Recalculer le niveau à partir de l'XP totale accumulée
        if (currentKaijin!.totalLifetimeXp > 0) {
          playerLevel =
              xpService.calculatePlayerLevel(currentKaijin!.totalLifetimeXp);
        }

        currentKaijin!.level = playerLevel;
        currentKaijin!.power = power;
        currentKaijin!.passiveXp = passiveXpService.xpPerSecond;

        if (updateConnections) {
          currentKaijin!.previousLastConnected = currentKaijin!.lastConnected;
          currentKaijin!.lastConnected = DateTime.now();
        }

        await kaijinService.updateKaijin(currentKaijin!);
        AppLogger.info(
            'Kaijin sauvegardé: ${currentKaijin!.name} (XP: ${currentKaijin!.xp}, Niveau: ${currentKaijin!.level}, XP totale accumulée: ${currentKaijin!.totalLifetimeXp})');
      }
    } catch (e) {
      AppLogger.error('Erreur lors de la sauvegarde', e);
    }
  }

  // Vérifier s'il y a de l'XP accumulée hors-ligne
  Future<void> checkOfflineXp() async {
    if (currentKaijin == null) return;

    final DateTime referenceTime =
        currentKaijin!.previousLastConnected ?? currentKaijin!.lastConnected;

    // Calculer l'XP hors-ligne des résonances et des senseis
    final resonanceOfflineXp = await resonanceService.calculateOfflineXp(
        currentKaijin!.id, referenceTime);
    final senseiOfflineXp = await senseiService.calculateOfflineXp(
        currentKaijin!.id, referenceTime);

    final totalOfflineXp = resonanceOfflineXp + senseiOfflineXp;

    if (totalOfflineXp > 0) {
      offlineXpGained = totalOfflineXp;
      offlineXpClaimed = false;
      updateState();
    }

    currentKaijin!.previousLastConnected = currentKaijin!.lastConnected;
    currentKaijin!.lastConnected = DateTime.now();

    await kaijinService.updateKaijin(currentKaijin!);
  }

  // Récupérer l'XP hors-ligne
  void claimOfflineXp() {
    if (offlineXpGained <= 0 || offlineXpClaimed) return;

    addXP(offlineXpGained);
    offlineXpClaimed = true;
    offlineXpGained = 0;
    updateState();
  }

  // Charger les résonances du joueur
  Future<void> loadPlayerResonances() async {
    if (currentKaijin == null) return;

    try {
      // Charger d'abord toutes les résonances disponibles
      allResonances = await resonanceService.getAllResonances();

      // Charger les résonances du joueur
      playerResonances =
          await resonanceService.getKaijinResonances(currentKaijin!.id);

      // Mettre à jour l'état de déverrouillage et le niveau des résonances dans allResonances
      // Cette étape est cruciale pour que l'interface affiche correctement l'état débloqué
      for (var playerResonance in playerResonances) {
        final index =
            allResonances.indexWhere((r) => r.id == playerResonance.id);
        if (index != -1) {
          // Mettre à jour l'état de la résonance dans la liste principale
          allResonances[index].isUnlocked = playerResonance.isUnlocked;
          allResonances[index].linkLevel = playerResonance.linkLevel;
        }
      }

      updateState();

      AppLogger.info("Résonances du joueur chargées: ${playerResonances.length}");
      AppLogger.info("Total des résonances disponibles: ${allResonances.length}");

      await updatePassiveXpRate();
    } catch (e) {
      AppLogger.error("Erreur lors du chargement des résonances du joueur", e);
    }
  }

  // Mettre à jour le taux d'XP passive par heure
  Future<void> updatePassiveXpRate() async {
    if (currentKaijin == null) return;

    try {
      // Calculer l'XP passive des résonances
      final resonanceXpPerSecond = await resonanceService
          .calculateTotalPassiveXpPerSecond(currentKaijin!.id);

      // Calculer l'XP passive des senseis
      final senseiXpPerSecond = await senseiService
          .calculateTotalPassiveXpPerSecond(currentKaijin!.id);

      // Combiner les deux sources d'XP passive
      final totalXpPerSecond = resonanceXpPerSecond + senseiXpPerSecond;

      passiveXpService.xpPerSecond = totalXpPerSecond;
      updateState();

      AppLogger.info(
          "Taux d'XP passive mis à jour: ${passiveXpService.xpPerSecond} XP/s (Résonances: $resonanceXpPerSecond, Senseis: $senseiXpPerSecond), ${passiveXpService.passiveXpPerHour} XP/h");
    } catch (e) {
      AppLogger.error("Erreur lors de la mise à jour du taux d'XP passive", e);
    }
  }

  // Méthode pour démarrer le calcul du taux d'XP par seconde
  void startXpRateCalculation() {
    timerService.startXpRateCalculation(() {
      comboService.updateXpRateStats();
      updateState();
    });
  }

  // Méthode pour incrémenter l'XP en cliquant
  void incrementerXp(int bonusXp, [double multiplier = 1.0]) {
    final int xpGain = comboService.registerClick(multiplier: multiplier);
    addXP(xpGain);

    timerService.startComboResetTimer(() {
      comboService.resetCombo();
      updateState();
    });
  }

  // Rafraîchir les données du Kaijin
  Future<void> refreshKaijinData() async {
    try {
      if (currentKaijin == null || currentKaijin!.id.isEmpty) return;

      final updatedKaijin =
          await kaijinService.getKaijinById(currentKaijin!.id);

      if (updatedKaijin != null) {
        currentKaijin = updatedKaijin;
        totalXP = updatedKaijin.xp;
        updateState();
        updatePlayerLevel();
      }
    } catch (e) {
      AppLogger.error('Erreur lors du rafraîchissement des données du Kaijin', e);
    }
  }

  // Nettoyer les ressources
  void dispose() {
    timerService.dispose();
    audioService.dispose();
  }

  // Méthode pour formater les grands nombres
  String formatNumber(num number) {
    return xpService.formatNumber(number);
  }
}
