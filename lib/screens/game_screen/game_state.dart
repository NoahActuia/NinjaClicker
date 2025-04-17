import 'dart:async';
import 'dart:math' show max, min;
import 'package:flutter/material.dart';
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
  List<Sensei> senseis = [];
  List<Technique> playerTechniques = [];
  List<Sensei> playerSenseis = [];
  Map<String, int> techniqueLevels = {};
  Map<String, int> senseiLevels = {};
  Map<String, int> senseiQuantities = {};

  // Système de Résonance
  List<Resonance> allResonances = [];
  List<Resonance> playerResonances = [];
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
      print('Erreur lors de l\'initialisation des résonances: $e');
    }
  }

  // Méthodes pour les résonances
  Future<void> unlockResonance(Resonance resonance) async {
    if (currentKaijin == null) return;

    final success = await resonanceService.unlockResonanceWithXp(
        currentKaijin!, resonance, totalXP, (int amount) {
      totalXP += amount;
      updateState();
    });

    if (success) {
      // Mettre à jour localement la résonance sans attendre le rechargement
      resonance.isUnlocked = true;
      resonance.linkLevel = 1;

      // Rafraîchir les listes de résonances
      await loadPlayerResonances();
      updateState();
    }
  }

  Future<void> upgradeResonance(Resonance resonance) async {
    if (currentKaijin == null) return;

    final success = await resonanceService.upgradeResonanceWithXp(
        currentKaijin!, resonance, totalXP, (int amount) {
      totalXP += amount;
      updateState();
    });

    if (success) {
      // Mettre à jour localement la résonance sans attendre le rechargement
      resonance.linkLevel += 1;

      // Rafraîchir les listes de résonances
      await loadPlayerResonances();
      updateState();
    }
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
    // Ajouter à l'XP dépensable (monnaie du jeu)
    totalXP += amount;

    // Toujours incrémenter l'XP totale accumulée dans le kaijin
    if (currentKaijin != null) {
      currentKaijin!.totalLifetimeXp += amount;
    }

    updateState();
    updatePlayerLevel();
    calculatePower();
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
    print('Initialisation du jeu...');
    resetGameState();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Utilisateur non connecté');
      return;
    }

    await loadCurrentKaijin();
    await loadPlayerData();
    startTimers();

    print('Jeu initialisé avec succès');
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
    senseis.clear();
    playerTechniques = [];
    playerSenseis = [];
    techniqueLevels = {};
    senseiLevels = {};
    senseiQuantities = {};

    allResonances = [];
    playerResonances = [];
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

          print(
              'Kaijin chargé: ${currentKaijin!.name} (Niveau ${currentKaijin!.level}, XP: ${currentKaijin!.xp}, XP totale accumulée: ${currentKaijin!.totalLifetimeXp})');
        } else {
          print('Aucun kaijin trouvé pour l\'utilisateur');
        }
      } catch (e) {
        print('Erreur lors du chargement du kaijin: $e');
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

        print("Techniques du joueur chargées: ${playerTechniques.length}");
      }
    } catch (e) {
      print("Erreur lors du chargement des techniques du joueur: $e");
    }
  }

  // Charger les senseis du joueur
  Future<void> loadPlayerSenseis() async {
    if (currentKaijin == null) return;

    try {
      senseis = await senseiService.loadSenseis(currentKaijin!.id);

      if (senseis.isNotEmpty && currentKaijin!.senseis.isNotEmpty) {
        playerSenseis = senseiService.getPlayerSenseis(senseis, currentKaijin!);
        senseiLevels = Map<String, int>.from(currentKaijin!.senseiLevels);
        senseiQuantities =
            Map<String, int>.from(currentKaijin!.senseiQuantities);

        updateState();
        calculatePower();

        print("Senseis du joueur chargés: ${playerSenseis.length}");
      }
    } catch (e) {
      print("Erreur lors du chargement des senseis du joueur: $e");
    }
  }

  // Méthode pour démarrer les timers
  void startTimers() {
    // Timer principal du jeu - génère de l'XP passive
    timerService.startGameLoop(() {
      final xpGained = passiveXpService.generatePassiveXp();
      if (xpGained > 0) {
        totalXP += xpGained;
        updatePlayerLevel();
        updateState();
      }
    });

    // Timer pour la sauvegarde automatique
    timerService.startAutoSave(() async {
      await saveGame(updateConnections: false);
      print('Sauvegarde automatique effectuée');
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
        print(
            'Kaijin sauvegardé: ${currentKaijin!.name} (XP: ${currentKaijin!.xp}, Niveau: ${currentKaijin!.level}, XP totale accumulée: ${currentKaijin!.totalLifetimeXp})');
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  // Vérifier s'il y a de l'XP accumulée hors-ligne
  Future<void> checkOfflineXp() async {
    if (currentKaijin == null) return;

    final DateTime referenceTime =
        currentKaijin!.previousLastConnected ?? currentKaijin!.lastConnected;

    final offlineXp = await resonanceService.calculateOfflineXp(
        currentKaijin!.id, referenceTime);

    if (offlineXp > 0) {
      offlineXpGained = offlineXp;
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

      print("Résonances du joueur chargées: ${playerResonances.length}");
      print("Total des résonances disponibles: ${allResonances.length}");

      await updatePassiveXpRate();
    } catch (e) {
      print("Erreur lors du chargement des résonances du joueur: $e");
    }
  }

  // Mettre à jour le taux d'XP passive par heure
  Future<void> updatePassiveXpRate() async {
    if (currentKaijin == null) return;

    try {
      final xpPerSecond = await resonanceService
          .calculateTotalPassiveXpPerSecond(currentKaijin!.id);
      passiveXpService.xpPerSecond = xpPerSecond;
      updateState();

      print(
          "Taux d'XP passive mis à jour: ${passiveXpService.xpPerSecond} XP/s, ${passiveXpService.passiveXpPerHour} XP/h");
    } catch (e) {
      print("Erreur lors de la mise à jour du taux d'XP passive: $e");
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

    totalXP += xpGain;
    updatePlayerLevel();
    updateState();

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
      print('Erreur lors du rafraîchissement des données du Kaijin: $e');
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
