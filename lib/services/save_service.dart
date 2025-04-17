import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../models/saved_game.dart';
import '../models/mission.dart';
import 'kaijin_service.dart';

// Import conditionnel pour le web
// ignore: unused_import
import 'save_service_web.dart' if (dart.library.io) 'save_service_stub.dart';

class SaveService {
  static final SaveService _instance = SaveService._internal();
  factory SaveService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final KaijinService _kaijinService = KaijinService();

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

      // Récupérer le fracturé actuel ou créer un nouveau fracturé si nécessaire
      final currentKaijin = await _kaijinService.getCurrentKaijin(user.uid);

      if (currentKaijin == null) {
        // Créer un nouveau fracturé
        await _kaijinService.createKaijin(
          userId: user.uid,
          name: savedGame.nom,
        );
        print('Nouveau fracturé créé pour la sauvegarde');
      } else {
        // Mettre à jour le fracturé existant
        currentKaijin.xp = savedGame.puissance;
        await _kaijinService.updateKaijin(currentKaijin);
        print('Fracturé actuel mis à jour');

        // Mettre à jour les techniques du kaijin
        for (var technique in savedGame.techniques) {
          await _kaijinService.updateKaijinTechnique(
              currentKaijin.id, technique.id, technique.level);
        }
        print('Techniques du fracturé mises à jour');
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

  // Charger les sauvegardes existantes - utilise maintenant les kaijins de Firebase
  Future<List<SavedGame>> loadSavedGames() async {
    try {
      print('Chargement des sauvegardes depuis Firebase...');
      final user = _auth.currentUser;

      if (user == null) {
        print(
            'Aucun utilisateur connecté, impossible de charger les sauvegardes');
        return [];
      }

      // Ici nous avons besoin de TOUS les kaijins de l'utilisateur, donc nous utilisons getkaijinsByUser
      final kaijins = await _kaijinService.getKaijinsByUser(user.uid);
      print('${kaijins.length} kaijins trouvés pour l\'utilisateur');

      if (kaijins.isEmpty) {
        return [];
      }

      // Convertir les kaijins en SavedGame pour compatibilité
      final List<SavedGame> games = [];

      for (final kaijin in kaijins) {
        // Charger les techniques du kaijin
        final techniques = await _kaijinService.getKaijinTechniques(kaijin.id);

        // Créer une sauvegarde à partir du kaijin
        final savedGame = SavedGame(
          id: kaijin.id,
          nom: kaijin.name,
          puissance: kaijin.xp,
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

  // Supprimer une sauvegarde - maintenant supprime le kaijin de Firebase
  Future<bool> deleteSavedGame(String playerName) async {
    try {
      print('Suppression de la sauvegarde pour $playerName dans Firebase');

      final user = _auth.currentUser;
      if (user == null) {
        print(
            'Aucun utilisateur connecté, impossible de supprimer la sauvegarde');
        return false;
      }

      // Trouver le kaijin correspondant au nom du joueur
      final kaijins = await _kaijinService.getKaijinsByUser(user.uid);
      final kaijinToDelete =
          kaijins.where((kaijin) => kaijin.name == playerName).firstOrNull;

      if (kaijinToDelete != null) {
        // Suppression du kaijin de Firebase
        await _kaijinService.deleteKaijin(kaijinToDelete.id);
        print('Fracturé supprimé de Firebase');

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

      print('Aucun kaijin trouvé avec le nom $playerName');
      return false;
    } catch (e) {
      print('Erreur lors de la suppression de la sauvegarde: $e');
      return false;
    }
  }

  // Charger une sauvegarde par son nom
  Future<SavedGame?> loadGameByName(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Aucun utilisateur connecté, impossible de charger la partie');
        return null;
      }

      // Trouver le kaijin correspondant au nom
      final kaijins = await _kaijinService.getKaijinsByUser(user.uid);
      final kaijin = kaijins.where((k) => k.name == name).firstOrNull;

      if (kaijin != null) {
        // Charger les techniques du kaijin
        final techniques = await _kaijinService.getKaijinTechniques(kaijin.id);

        // Créer une sauvegarde à partir du kaijin
        return SavedGame(
          id: kaijin.id,
          nom: kaijin.name,
          puissance: kaijin.xp,
          nombreDeClones: 0, // Valeur par défaut
          techniques: techniques,
          date: DateTime.now(), // On n'a pas cette info, on utilise maintenant
        );
      }

      // Fallback: essayer de charger depuis le stockage local
      final prefs = await SharedPreferences.getInstance();
      List<String> savedGamesJson = prefs.getStringList('saved_games') ?? [];

      final gameJson = savedGamesJson.firstWhere(
        (json) {
          try {
            final game = SavedGame.fromJson(jsonDecode(json));
            return game.nom == name;
          } catch (_) {
            return false;
          }
        },
        orElse: () => '',
      );

      if (gameJson.isNotEmpty) {
        return SavedGame.fromJson(jsonDecode(gameJson));
      }

      return null;
    } catch (e) {
      print('Erreur lors du chargement de la partie par nom: $e');
      return null;
    }
  }

  // Sauvegarder la progression des missions
  Future<void> saveMissionProgress(List<Mission> missions) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Impossible de sauvegarder: aucun utilisateur connecté');
        return;
      }

      print('Sauvegarde de la progression des missions dans Firebase');

      // Récupérer le kaijin actuel
      final currentKaijin = await _kaijinService.getCurrentKaijin(user.uid);

      if (currentKaijin == null) {
        print(
            'Aucun kaijin actif trouvé, impossible de sauvegarder la progression');
        return;
      }

      // Créer la collection pour les missions si elle n'existe pas
      await FirebaseFirestore.instance
          .collection('kaijins')
          .doc(currentKaijin.id)
          .collection('missions')
          .get();

      // Sauvegarder chaque mission
      for (var mission in missions) {
        await FirebaseFirestore.instance
            .collection('kaijins')
            .doc(currentKaijin.id)
            .collection('missions')
            .doc(mission.id)
            .set({
          'completed': mission.completed,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }

      print('Progression des missions sauvegardée avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde de la progression des missions: $e');
    }
  }
}
