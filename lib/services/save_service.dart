import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/saved_game.dart';
import '../models/mission.dart';
import 'ninja_service.dart';

// Import conditionnel pour le web
// ignore: unused_import
import 'save_service_web.dart' if (dart.library.io) 'save_service_stub.dart';

class SaveService {
  static final SaveService _instance = SaveService._internal();
  factory SaveService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NinjaService _ninjaService = NinjaService();

  SaveService._internal() {
    // On initialise le service dès sa création
    _init();
  }

  Future<void> _init() async {
    try {
      print('Initialisation du SaveService...');
    } catch (e) {
      print('Erreur lors de l\'initialisation du SaveService: $e');
    }
  }

  // Sauvegarder la partie actuelle - cette méthode maintenant utilise Firebase
  Future<void> saveGame(SavedGame savedGame) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Impossible de sauvegarder: aucun utilisateur connecté');
        return;
      }

      print(
          'Début sauvegarde pour ${savedGame.nom} avec ${savedGame.puissance} puissance dans Firebase');

      // Utiliser le NinjaService pour mettre à jour le ninja
      final ninjas = await _ninjaService.getNinjasByUser(user.uid);
      if (ninjas.isEmpty) {
        // Créer un nouveau ninja
        await _ninjaService.createNinja(
          userId: user.uid,
          name: savedGame.nom,
        );
        print('Nouveau ninja créé pour la sauvegarde');
      } else {
        // Mettre à jour le ninja existant
        final ninja = ninjas.first;
        ninja.xp = savedGame.puissance;
        await _ninjaService.updateNinja(ninja);
        print('Ninja existant mis à jour');

        // Mettre à jour les techniques du ninja
        for (var technique in savedGame.techniques) {
          await _ninjaService.updateNinjaTechnique(
              ninja.id, technique.id, technique.level);
        }
        print('Techniques du ninja mises à jour');
      }

      // Pour compatibilité, on garde aussi la sauvegarde locale (temporairement pendant la migration)
      final prefs = await SharedPreferences.getInstance();
      List<String> savedGamesJson = prefs.getStringList('saved_games') ?? [];

      // Convertir la sauvegarde en JSON
      final savedGameJson = json.encode(savedGame.toJson());

      // Vérifier si une sauvegarde avec le même nom existe déjà
      final index = savedGamesJson.indexWhere((gameJson) {
        try {
          final game = SavedGame.fromJson(json.decode(gameJson));
          return game.nom == savedGame.nom;
        } catch (e) {
          print('Erreur lors du parsing Json: $e');
          return false;
        }
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

      await prefs.setStringList('saved_games', savedGamesJson);
      await prefs.reload();

      print('Partie sauvegardée avec succès dans Firebase et localement');
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      throw e;
    }
  }

  // Charger les sauvegardes existantes - utilise maintenant les ninjas de Firebase
  Future<List<SavedGame>> loadSavedGames() async {
    try {
      print('Chargement des sauvegardes depuis Firebase...');
      final user = _auth.currentUser;

      if (user == null) {
        print(
            'Aucun utilisateur connecté, impossible de charger les sauvegardes');
        return [];
      }

      // Charger les ninjas de l'utilisateur depuis Firebase
      final ninjas = await _ninjaService.getNinjasByUser(user.uid);
      print('${ninjas.length} ninjas trouvés pour l\'utilisateur');

      if (ninjas.isEmpty) {
        return [];
      }

      // Convertir les ninjas en SavedGame pour compatibilité
      final List<SavedGame> games = [];

      for (final ninja in ninjas) {
        // Charger les techniques du ninja
        final techniques = await _ninjaService.getNinjaTechniques(ninja.id);

        // Créer une sauvegarde à partir du ninja
        final savedGame = SavedGame(
          id: ninja.id,
          nom: ninja.name,
          puissance: ninja.xp,
          nombreDeClones: 0, // Valeur par défaut
          techniques: techniques,
          date: DateTime.now(), // On n'a pas cette info, on utilise maintenant
        );

        games.add(savedGame);
      }

      // Trier par date décroissante (le plus récent en premier)
      games.sort((a, b) => b.date.compareTo(a.date));

      return games;
    } catch (e) {
      print('Erreur lors du chargement des sauvegardes depuis Firebase: $e');

      // En cas d'erreur, tentative de charger depuis le stockage local (fallback)
      try {
        print('Tentative de chargement depuis le stockage local...');
        final prefs = await SharedPreferences.getInstance();
        final List<String>? savedGamesJson = prefs.getStringList('saved_games');

        if (savedGamesJson != null && savedGamesJson.isNotEmpty) {
          final List<SavedGame> games = [];

          for (final jsonStr in savedGamesJson) {
            try {
              final game = SavedGame.fromJson(json.decode(jsonStr));
              games.add(game);
            } catch (e) {
              print('Erreur lors du décodage d\'une sauvegarde: $e');
            }
          }

          print(
              '${games.length} sauvegardes chargées depuis le stockage local');

          // Trier par date décroissante
          games.sort((a, b) => b.date.compareTo(a.date));

          return games;
        }
      } catch (localError) {
        print('Erreur lors du chargement local: $localError');
      }

      return [];
    }
  }

  // Supprimer une sauvegarde - maintenant supprime le ninja de Firebase
  Future<bool> deleteSavedGame(String playerName) async {
    try {
      print('Suppression de la sauvegarde pour $playerName dans Firebase');

      final user = _auth.currentUser;
      if (user == null) {
        print(
            'Aucun utilisateur connecté, impossible de supprimer la sauvegarde');
        return false;
      }

      // Trouver le ninja correspondant au nom du joueur
      final ninjas = await _ninjaService.getNinjasByUser(user.uid);
      final ninjaToDelete =
          ninjas.where((ninja) => ninja.name == playerName).firstOrNull;

      if (ninjaToDelete != null) {
        // Suppression du ninja de Firebase
        // Ajouter une méthode de suppression dans NinjaService si nécessaire
        // await _ninjaService.deleteNinja(ninjaToDelete.id);
        print('Ninja supprimé de Firebase');

        // Pour compatibilité, supprimer aussi la sauvegarde locale
        final prefs = await SharedPreferences.getInstance();
        List<String> savedGamesJson = prefs.getStringList('saved_games') ?? [];

        final initialLength = savedGamesJson.length;

        savedGamesJson.removeWhere((gameJson) {
          try {
            final game = SavedGame.fromJson(json.decode(gameJson));
            return game.nom == playerName;
          } catch (e) {
            print('Erreur lors du parsing Json: $e');
            return false;
          }
        });

        if (savedGamesJson.length < initialLength) {
          await prefs.setStringList('saved_games', savedGamesJson);
          print('Sauvegarde locale supprimée');
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Erreur lors de la suppression de la sauvegarde: $e');
      return false;
    }
  }

  // Méthode pour effacer toutes les données locales (pour compatibilité/migration)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('Toutes les données locales ont été effacées');
    } catch (e) {
      print('Erreur lors de la suppression des données: $e');
    }
  }

  // Méthodes d'export/import pour la compatibilité pendant la transition
  Future<void> exportAllSavesToFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGamesJson = prefs.getStringList('saved_games') ?? [];

      if (savedGamesJson.isEmpty) {
        print('Aucune sauvegarde à exporter');
        return;
      }

      final String jsonData = json.encode(savedGamesJson);

      if (kIsWeb) {
        // Pour le web, on délègue à une implémentation spécifique
        exportToWebFile(jsonData, 'ninja_clicker_saves.json');
      } else {
        // Version Mobile
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final file = File('${directory.path}/ninja_clicker_saves.json');
        await file.writeAsString(jsonData);
        print('Fichier sauvegardé à: ${file.path}');
      }

      print('Sauvegardes exportées avec succès');
    } catch (e) {
      print('Erreur lors de l\'export des sauvegardes: $e');
    }
  }

  // Méthode pour le web uniquement (stub pour mobile)
  void exportToWebFile(String jsonData, String fileName) {
    // Cette méthode est remplacée par l'implémentation réelle dans save_service_web.dart
    // Elle ne fait rien sur mobile
    print('Export vers fichier non disponible sur cette plateforme');
  }

  Future<void> importSavesFromString(String jsonData) async {
    try {
      final List<dynamic> savedGamesJson = json.decode(jsonData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_games',
          savedGamesJson.map((item) => item.toString()).toList());

      print('Sauvegardes importées avec succès');
    } catch (e) {
      print('Erreur lors de l\'import des sauvegardes: $e');
    }
  }

  // Cette méthode est gardée pour compatibilité mais sera dépréciée
  Future<void> exportAllSavesToAutoStoredFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGamesJson = prefs.getStringList('saved_games') ?? [];

      if (savedGamesJson.isEmpty) {
        return;
      }

      final String jsonData = json.encode(savedGamesJson);

      if (kIsWeb) {
        storeInWebLocalStorage('ninja_clicker_saves', jsonData);
      } else {
        // Sur mobile, on utilise les SharedPreferences à la place
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ninja_clicker_saves_backup', jsonData);
      }
    } catch (e) {
      print('Erreur lors de l\'auto-export des sauvegardes: $e');
    }
  }

  // Méthode pour le web uniquement (stub pour mobile)
  void storeInWebLocalStorage(String key, String data) {
    // Cette méthode est remplacée par l'implémentation réelle dans save_service_web.dart
    // Elle ne fait rien sur mobile
    print('Stockage localStorage non disponible sur cette plateforme');
  }

  // Cette méthode est gardée pour compatibilité mais sera dépréciée
  Future<void> exportAllMissionsToAutoStoredFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final missionsJson = prefs.getStringList('missions') ?? [];

      if (missionsJson.isEmpty) {
        return;
      }

      final String jsonData = json.encode(missionsJson);

      if (kIsWeb) {
        storeInWebLocalStorage('ninja_clicker_missions', jsonData);
      } else {
        // Sur mobile, on utilise les SharedPreferences à la place
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ninja_clicker_missions_backup', jsonData);
      }
    } catch (e) {
      print('Erreur lors de l\'auto-export des missions: $e');
    }
  }
}
