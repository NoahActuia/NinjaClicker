import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission.dart';
import '../models/technique.dart';

class MissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _missionsKey = 'missions';
  final SharedPreferences _prefs;

  MissionService(this._prefs);

  List<Mission> _missions = [
    Mission(
      id: 1,
      name: 'Académie des Ninjas',
      description: 'Commencez votre formation de ninja et apprenez les bases du Kai.',
      difficulty: 1,
      rewards: {
        'puissance': 100,
        'technique': 'Clone de Kai',
        'histoire': 'Vous avez fait vos premiers pas dans la maîtrise du Kai.',
      },
      enemyLevel: 1,
      puissanceRequise: 0,
      image: 'assets/images/academy.webp',
    ),
    Mission(
      id: 2,
      name: 'Examen Chunin',
      description: 'Prouvez votre valeur lors de l\'examen Chunin.',
      difficulty: 2,
      rewards: {
        'puissance': 200,
        'technique': 'Frappe du Kai',
        'histoire': 'Vous avez démontré votre maîtrise croissante du Kai.',
      },
      enemyLevel: 2,
      puissanceRequise: 150,
      image: 'assets/images/chunin_exam.webp',
    ),
    Mission(
      id: 3,
      name: 'Récupération de Sasuke',
      description: 'Une mission de rang S pour sauver un camarade.',
      difficulty: 3,
      rewards: {
        'puissance': 300,
        'technique': 'Rasengan',
        'histoire': 'La puissance du Kai se révèle dans les moments critiques.',
      },
      enemyLevel: 3,
      puissanceRequise: 250,
      image: 'assets/images/rescue.webp',
    ),
    Mission(
      id: 4,
      name: 'Entraînement avec Jiraiya',
      description: 'Apprenez les secrets du Kai auprès d\'un maître.',
      difficulty: 4,
      rewards: {
        'puissance': 400,
        'technique': 'Mode Ermite',
        'histoire': 'La sagesse du Kai transcende la simple puissance.',
      },
      enemyLevel: 4,
      puissanceRequise: 350,
      image: 'assets/images/training.webp',
    ),
    Mission(
      id: 5,
      name: 'Combat contre Pain',
      description: 'Affrontez le chef de l\'Akatsuki.',
      difficulty: 5,
      rewards: {
        'puissance': 500,
        'technique': 'Bombe de Kai',
        'histoire': 'Le véritable pouvoir naît de la compréhension.',
      },
      enemyLevel: 5,
      puissanceRequise: 450,
      image: 'assets/images/pain.webp',
    ),
  ];

  List<Mission> get missions => _missions;

  // Vérifier si une mission est disponible
  bool isMissionAvailable(Mission mission, int currentPuissance) {
    return currentPuissance >= mission.puissanceRequise;
  }

  // Sauvegarder les missions dans Firebase et SharedPreferences
  Future<void> saveMissions(List<Mission> missions) async {
    try {
      // Sauvegarder localement
      final missionData = missions.map((mission) => mission.toJson()).toList();
      await _prefs.setString(_missionsKey, jsonEncode(missionData));

      // Sauvegarder dans Firebase si l'utilisateur est connecté
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('userMissions').doc(user.uid).set({
          'missions': missionData,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde des missions: $e');
      throw e;
    }
  }

  // Charger les missions depuis Firebase ou SharedPreferences
  Future<List<Mission>> loadMissions() async {
    try {
      // D'abord essayer de charger depuis Firebase
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('userMissions').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('missions')) {
            final missionList = List<Map<String, dynamic>>.from(data['missions']);
            _missions = missionList.map((m) => Mission.fromJson(m)).toList();
            return _missions;
          }
        }
      }

      // Si pas de données Firebase, essayer SharedPreferences
      final String? missionsJson = _prefs.getString(_missionsKey);
      if (missionsJson != null) {
        final List<dynamic> missionList = jsonDecode(missionsJson);
        _missions = missionList.map((m) => Mission.fromJson(m as Map<String, dynamic>)).toList();
        return _missions;
      }

      // Si aucune donnée n'est trouvée, retourner les missions par défaut
      return _missions;
    } catch (e) {
      print('Erreur lors du chargement des missions: $e');
      return _missions;
    }
  }

  // Mettre à jour une mission spécifique
  Future<void> updateMission(Mission mission) async {
    final index = _missions.indexWhere((m) => m.id == mission.id);
    if (index != -1) {
      _missions[index] = mission;
      await saveMissions(_missions);
    }
  }

  bool canStartMission(Mission mission, int currentPuissance) {
    return currentPuissance >= mission.puissanceRequise;
  }

  void completeMission(int missionId) {
    final index = _missions.indexWhere((m) => m.id == missionId);
    if (index != -1) {
      _missions[index].completed = true;
      saveMissions(_missions);
    }
  }
}
