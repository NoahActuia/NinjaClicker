import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_game.dart';
import '../models/mission.dart';

class SaveService {
  static final SaveService _instance = SaveService._internal();
  factory SaveService() => _instance;

  SaveService._internal();

  // Sauvegarder la partie actuelle
  Future<void> saveGame(SavedGame savedGame) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Charger les sauvegardes existantes
      List<String> savedGamesJson = prefs.getStringList('saved_games') ?? [];

      // Convertir la sauvegarde en JSON
      final savedGameJson = json.encode(savedGame.toJson());

      // Vérifier si une sauvegarde avec le même nom existe déjà
      final index = savedGamesJson.indexWhere((gameJson) {
        final game = SavedGame.fromJson(json.decode(gameJson));
        return game.nom == savedGame.nom;
      });

      if (index != -1) {
        // Remplacer la sauvegarde existante
        savedGamesJson[index] = savedGameJson;
      } else {
        // Ajouter une nouvelle sauvegarde
        savedGamesJson.add(savedGameJson);
      }

      // Limiter le nombre de sauvegardes à 10
      if (savedGamesJson.length > 10) {
        savedGamesJson.removeAt(0);
      }

      // Sauvegarder la liste mise à jour
      await prefs.setStringList('saved_games', savedGamesJson);

      print('Partie sauvegardée avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      throw e;
    }
  }

  // Charger les sauvegardes existantes
  Future<List<SavedGame>> loadSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedGamesJson = prefs.getStringList('saved_games');

      if (savedGamesJson != null && savedGamesJson.isNotEmpty) {
        return savedGamesJson
            .map((jsonStr) => SavedGame.fromJson(json.decode(jsonStr)))
            .toList();
      }

      return [];
    } catch (e) {
      print('Erreur lors du chargement des sauvegardes: $e');
      return [];
    }
  }

  // Supprimer une sauvegarde
  Future<bool> deleteSavedGame(String playerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedGamesJson = prefs.getStringList('saved_games') ?? [];

      final initialLength = savedGamesJson.length;

      savedGamesJson.removeWhere((gameJson) {
        final game = SavedGame.fromJson(json.decode(gameJson));
        return game.nom == playerName;
      });

      if (savedGamesJson.length < initialLength) {
        await prefs.setStringList('saved_games', savedGamesJson);
        return true;
      }

      return false;
    } catch (e) {
      print('Erreur lors de la suppression de la sauvegarde: $e');
      return false;
    }
  }

  // Sauvegarder l'état des missions
  Future<void> saveMissions(List<Mission> missions) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir la liste de missions en JSON
      final missionsJson =
          missions.map((mission) => json.encode(mission.toJson())).toList();

      // Sauvegarder la liste
      await prefs.setStringList('missions', missionsJson);

      print('Missions sauvegardées avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde des missions: $e');
      throw e;
    }
  }

  // Charger l'état des missions
  Future<List<Mission>> loadMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? missionsJson = prefs.getStringList('missions');

      if (missionsJson != null && missionsJson.isNotEmpty) {
        return missionsJson
            .map((jsonStr) => Mission.fromJson(json.decode(jsonStr)))
            .toList();
      }

      return [];
    } catch (e) {
      print('Erreur lors du chargement des missions: $e');
      return [];
    }
  }
}
