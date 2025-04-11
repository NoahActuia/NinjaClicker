import 'dart:convert';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_game.dart';
import '../models/mission.dart';

class SaveService {
  static final SaveService _instance = SaveService._internal();
  factory SaveService() => _instance;

  SaveService._internal() {
    // On initialise le service dès sa création
    _init();
  }

  Future<void> _init() async {
    try {
      print('Initialisation du SaveService...');

      // Vérifier SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedGames = prefs.getStringList('saved_games');
      print('SharedPreferences sauvegardes: ${savedGames?.length ?? 0}');

      if (savedGames != null && savedGames.isNotEmpty) {
        print('Exemple de sauvegarde: ${savedGames.first}');
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du SaveService: $e');
    }
  }

  // Sauvegarder la partie actuelle
  Future<void> saveGame(SavedGame savedGame) async {
    try {
      print(
          'Début sauvegarde pour ${savedGame.nom} avec ${savedGame.puissance} puissance');

      final prefs = await SharedPreferences.getInstance();
      List<String> savedGamesJson = prefs.getStringList('saved_games') ?? [];
      print('Sauvegardes existantes chargées: ${savedGamesJson.length}');

      // Convertir la sauvegarde en JSON
      final savedGameJson = json.encode(savedGame.toJson());
      print('Sauvegarde convertie en JSON - Taille: ${savedGameJson.length}');

      // Vérifier si une sauvegarde avec le même nom existe déjà
      final index = savedGamesJson.indexWhere((gameJson) {
        try {
          final game = SavedGame.fromJson(json.decode(gameJson));
          return game.nom == savedGame.nom;
        } catch (e) {
          print('Erreur lors du parsing JSON: $e');
          return false;
        }
      });

      if (index != -1) {
        // Remplacer la sauvegarde existante
        print('Remplacement de la sauvegarde existante à l\'index $index');
        savedGamesJson[index] = savedGameJson;
      } else {
        // Ajouter une nouvelle sauvegarde
        print('Ajout d\'une nouvelle sauvegarde');
        savedGamesJson.add(savedGameJson);
      }

      // Limiter le nombre de sauvegardes à 10
      if (savedGamesJson.length > 10) {
        print('Limitation du nombre de sauvegardes à 10');
        savedGamesJson.removeAt(0);
      }

      // IMPORTANT: Utiliser commit sync pour s'assurer que les données sont bien écrites
      print('Sauvegarde de la liste (${savedGamesJson.length} éléments)');
      await prefs.setStringList('saved_games', savedGamesJson);
      await prefs.reload(); // Force refresh des données

      // Vérifier que la sauvegarde a bien été effectuée
      final savedGamesCheck = prefs.getStringList('saved_games');
      print(
          'Vérification post-sauvegarde: ${savedGamesCheck?.length ?? 0} sauvegardes');

      // NOUVEAU: Exporter les sauvegardes dans un fichier qui sera stocké automatiquement
      await exportAllSavesToAutoStoredFile();

      print('Partie sauvegardée avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      throw e;
    }
  }

  // Charger les sauvegardes existantes
  Future<List<SavedGame>> loadSavedGames() async {
    try {
      print('Chargement des sauvegardes...');

      // D'abord, vérifions les SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force refresh des données
      final List<String>? savedGamesJson = prefs.getStringList('saved_games');

      print('Nombre de sauvegardes trouvées: ${savedGamesJson?.length ?? 0}');

      if (savedGamesJson != null && savedGamesJson.isNotEmpty) {
        final List<SavedGame> games = [];

        for (final jsonStr in savedGamesJson) {
          try {
            final game = SavedGame.fromJson(json.decode(jsonStr));
            games.add(game);
          } catch (e) {
            print('Erreur lors du décodage d\'une sauvegarde: $e');
            // Continuer avec la sauvegarde suivante
          }
        }

        print('Sauvegardes converties en objets: ${games.length}');

        // Trier par date décroissante
        games.sort((a, b) => b.date.compareTo(a.date));

        return games;
      }

      // Si aucune sauvegarde trouvée, essayer de charger depuis le localStorage (sauvegardes exportées)
      try {
        final exportedData = html.window.localStorage['ninja_clicker_saves'];
        if (exportedData != null && exportedData.isNotEmpty) {
          print(
              'Données trouvées dans localStorage, tentative de chargement...');
          await importSavesFromString(exportedData);
          return await loadSavedGames(); // Rappeler cette fonction après import
        }
      } catch (e) {
        print('Erreur lors de la récupération depuis localStorage: $e');
      }

      print('Aucune sauvegarde trouvée');
      return [];
    } catch (e) {
      print('Erreur lors du chargement des sauvegardes: $e');
      return [];
    }
  }

  // Supprimer une sauvegarde
  Future<bool> deleteSavedGame(String playerName) async {
    try {
      print('Suppression de la sauvegarde pour $playerName');

      final prefs = await SharedPreferences.getInstance();
      List<String> savedGamesJson = prefs.getStringList('saved_games') ?? [];
      print(
          'Nombre de sauvegardes avant suppression: ${savedGamesJson.length}');

      final initialLength = savedGamesJson.length;

      savedGamesJson.removeWhere((gameJson) {
        try {
          final game = SavedGame.fromJson(json.decode(gameJson));
          return game.nom == playerName;
        } catch (e) {
          print('Erreur lors du parsing JSON: $e');
          return false;
        }
      });

      print(
          'Nombre de sauvegardes après suppression: ${savedGamesJson.length}');

      if (savedGamesJson.length < initialLength) {
        await prefs.setStringList('saved_games', savedGamesJson);
        await prefs.reload(); // Force refresh des données

        // NOUVEAU: Mettre à jour l'export automatique
        await exportAllSavesToAutoStoredFile();

        print('Suppression effectuée avec succès');
        return true;
      }

      print('Aucune sauvegarde supprimée');
      return false;
    } catch (e) {
      print('Erreur lors de la suppression de la sauvegarde: $e');
      return false;
    }
  }

  // Sauvegarder l'état des missions
  Future<void> saveMissions(List<Mission> missions) async {
    try {
      print('Sauvegarde de ${missions.length} missions');

      final prefs = await SharedPreferences.getInstance();

      // Convertir la liste de missions en JSON
      final missionsJson =
          missions.map((mission) => json.encode(mission.toJson())).toList();
      print('Missions converties en JSON: ${missionsJson.length}');

      // Sauvegarder la liste
      await prefs.setStringList('missions', missionsJson);
      await prefs.reload(); // Force refresh des données

      // Vérifier que la sauvegarde a bien été effectuée
      final missionsCheck = prefs.getStringList('missions');
      print(
          'Vérification post-sauvegarde: ${missionsCheck?.length ?? 0} missions');

      // NOUVEAU: Exporter les missions dans un fichier
      await exportAllMissionsToAutoStoredFile();

      print('Missions sauvegardées avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde des missions: $e');
      throw e;
    }
  }

  // Charger l'état des missions
  Future<List<Mission>> loadMissions() async {
    try {
      print('Chargement des missions...');

      // D'abord, vérifions les SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force refresh des données
      final List<String>? missionsJson = prefs.getStringList('missions');

      print('Nombre de missions trouvées: ${missionsJson?.length ?? 0}');

      if (missionsJson != null && missionsJson.isNotEmpty) {
        final List<Mission> missions = [];

        for (final jsonStr in missionsJson) {
          try {
            final mission = Mission.fromJson(json.decode(jsonStr));
            missions.add(mission);
          } catch (e) {
            print('Erreur lors du décodage d\'une mission: $e');
            // Continuer avec la mission suivante
          }
        }

        print('Missions converties en objets: ${missions.length}');
        return missions;
      }

      // Si aucune mission trouvée, essayer de charger depuis le localStorage
      try {
        final exportedData = html.window.localStorage['ninja_clicker_missions'];
        if (exportedData != null && exportedData.isNotEmpty) {
          print(
              'Données missions trouvées dans localStorage, tentative de chargement...');
          await importMissionsFromString(exportedData);
          return await loadMissions(); // Rappeler cette fonction après import
        }
      } catch (e) {
        print(
            'Erreur lors de la récupération des missions depuis localStorage: $e');
      }

      print('Aucune mission trouvée');
      return [];
    } catch (e) {
      print('Erreur lors du chargement des missions: $e');
      return [];
    }
  }

  // Méthode pour effacer toutes les données (utile pour le débogage)
  Future<void> clearAllData() async {
    try {
      print('Suppression de toutes les données...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Aussi nettoyer localStorage
      try {
        html.window.localStorage.remove('ninja_clicker_saves');
        html.window.localStorage.remove('ninja_clicker_missions');
      } catch (e) {
        print('Erreur lors du nettoyage du localStorage: $e');
      }

      print('Toutes les données ont été effacées');
    } catch (e) {
      print('Erreur lors de la suppression des données: $e');
    }
  }

  // NOUVELLES MÉTHODES POUR L'EXPORT/IMPORT AUTOMATIQUE

  // Exporter toutes les sauvegardes vers le localStorage
  Future<void> exportAllSavesToAutoStoredFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGamesJson = prefs.getStringList('saved_games');

      if (savedGamesJson != null && savedGamesJson.isNotEmpty) {
        // Stocker dans localStorage
        html.window.localStorage['ninja_clicker_saves'] =
            json.encode(savedGamesJson);
        print('Sauvegardes exportées avec succès vers localStorage');
      }
    } catch (e) {
      print('Erreur lors de l\'export auto des sauvegardes: $e');
    }
  }

  // Exporter toutes les missions vers le localStorage
  Future<void> exportAllMissionsToAutoStoredFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final missionsJson = prefs.getStringList('missions');

      if (missionsJson != null && missionsJson.isNotEmpty) {
        // Stocker dans localStorage
        html.window.localStorage['ninja_clicker_missions'] =
            json.encode(missionsJson);
        print('Missions exportées avec succès vers localStorage');
      }
    } catch (e) {
      print('Erreur lors de l\'export auto des missions: $e');
    }
  }

  // Importer des sauvegardes depuis une chaîne JSON
  Future<bool> importSavesFromString(String jsonData) async {
    try {
      final List<dynamic> savedGamesJson = json.decode(jsonData);
      final List<String> savedGamesStringList =
          savedGamesJson.map((e) => e.toString()).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_games', savedGamesStringList);
      print('Sauvegardes importées avec succès depuis la chaîne');
      return true;
    } catch (e) {
      print('Erreur lors de l\'import des sauvegardes: $e');
      return false;
    }
  }

  // Importer des missions depuis une chaîne JSON
  Future<bool> importMissionsFromString(String jsonData) async {
    try {
      final List<dynamic> missionsJson = json.decode(jsonData);
      final List<String> missionsStringList =
          missionsJson.map((e) => e.toString()).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('missions', missionsStringList);
      print('Missions importées avec succès depuis la chaîne');
      return true;
    } catch (e) {
      print('Erreur lors de l\'import des missions: $e');
      return false;
    }
  }

  // NOUVELLES MÉTHODES POUR DOWNLOAD/UPLOAD MANUEL

  // Exporter toutes les sauvegardes dans un fichier à télécharger
  void exportAllSavesToFile() {
    try {
      final prefs = SharedPreferences.getInstance();
      prefs.then((prefs) {
        final savedGamesJson = prefs.getStringList('saved_games');
        if (savedGamesJson != null && savedGamesJson.isNotEmpty) {
          final content = json.encode(savedGamesJson);
          final blob = html.Blob([content], 'text/plain', 'native');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download',
                'ninja_clicker_saves_${DateTime.now().millisecondsSinceEpoch}.json')
            ..click();
          html.Url.revokeObjectUrl(url);
          print('Sauvegardes exportées avec succès');
        } else {
          print('Aucune sauvegarde à exporter');
        }
      });
    } catch (e) {
      print('Erreur lors de l\'export des sauvegardes: $e');
    }
  }

  // Importer des sauvegardes depuis un fichier uploadé
  Future<bool> importSavesFromFile(String content) async {
    return importSavesFromString(content);
  }
}
