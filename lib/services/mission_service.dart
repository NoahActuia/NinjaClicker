import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mission.dart';
import '../models/technique.dart';

class MissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Liste des missions par défaut
  List<Mission> getMissions() {
    return [
      Mission(
        id: 'm1',
        titre: 'Académie des Ninjas',
        description:
            'Réussir l\'examen de l\'académie en apprenant à maîtriser le kai',
        image: 'assets/images/academy.webp',
        difficulte: 1,
        puissanceRequise: 0,
        recompensePuissance: 50,
        recompenses: [
          Recompense(
              type: 'technique',
              quantite: 1,
              technique: Technique.compat(
                nom: 'Substitution',
                description: 'Remplacer son corps par un objet',
                cout: 100,
                sound: 'sounds/technique_substitution.mp3',
              )),
        ],
        completed: false,
      ),
      Mission(
        id: 'm2',
        titre: 'Examen Chunin',
        description: 'Affronter les meilleurs ninjas de votre génération',
        image: 'assets/images/chunin_exam.webp',
        difficulte: 2,
        puissanceRequise: 200,
        recompensePuissance: 150,
        recompenses: [
          Recompense(type: 'clone', quantite: 2),
        ],
        completed: false,
      ),
      Mission(
        id: 'm3',
        titre: 'Récupération de Sasuke',
        description: 'Retrouver Sasuke et le ramener au village',
        image: 'assets/images/sasuke_retrieval.webp',
        difficulte: 3,
        puissanceRequise: 500,
        recompensePuissance: 300,
        recompenses: [
          Recompense(
              type: 'technique',
              quantite: 1,
              technique: Technique.compat(
                nom: 'Rasengan Géant',
                description: 'Version améliorée du Rasengan',
                cout: 2000,
                sound: 'sounds/technique_rasengan_geant.mp3',
              )),
        ],
        completed: false,
      ),
      Mission(
        id: 'm4',
        titre: 'Entraînement avec Jiraiya',
        description: 'Partir en voyage avec l\'un des légendaires Sannin',
        image: 'assets/images/jiraiya_training.webp',
        difficulte: 4,
        puissanceRequise: 1000,
        recompensePuissance: 500,
        recompenses: [
          Recompense(type: 'clone', quantite: 3),
          Recompense(type: 'puissance', quantite: 500),
        ],
        completed: false,
      ),
      Mission(
        id: 'm5',
        titre: 'Combat contre Pain',
        description: 'Affronter le chef de l\'Akatsuki pour sauver le village',
        image: 'assets/images/pain_battle.webp',
        difficulte: 5,
        puissanceRequise: 2000,
        recompensePuissance: 1000,
        recompenses: [
          Recompense(
              type: 'technique',
              quantite: 1,
              technique: Technique.compat(
                nom: 'Mode Sage Parfait',
                description: 'Maîtrise parfaite de l\'énergie naturelle',
                cout: 10000,
                sound: 'sounds/technique_mode_sage_parfait.mp3',
              )),
        ],
        completed: false,
      ),
    ];
  }

  // Vérifier si une mission est disponible
  bool isMissionAvailable(Mission mission, int currentPuissance) {
    return currentPuissance >= mission.puissanceRequise;
  }

  // Sauvegarder les missions dans Firebase
  Future<void> saveMissions(List<Mission> missions) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print(
            'Impossible de sauvegarder les missions: aucun utilisateur connecté');
        return;
      }

      // Convertir les missions en données JSON
      final missionData = missions.map((mission) => mission.toJson()).toList();

      // Sauvegarder dans la collection userMissions avec l'ID de l'utilisateur
      await _firestore.collection('userMissions').doc(user.uid).set({
        'missions': missionData,
        'updatedAt': Timestamp.now(),
      });

      print('Missions sauvegardées avec succès');
    } catch (e) {
      print('Erreur lors de la sauvegarde des missions: $e');
      throw e;
    }
  }

  // Charger les missions depuis Firebase
  Future<List<Mission>> loadMissions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Impossible de charger les missions: aucun utilisateur connecté');
        return getMissions(); // Retourner les missions par défaut
      }

      // Récupérer le document des missions de l'utilisateur
      final doc =
          await _firestore.collection('userMissions').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('missions')) {
          // Convertir les données en liste de missions
          final missionList = List<Map<String, dynamic>>.from(data['missions']);
          final missions = missionList.map((m) => Mission.fromJson(m)).toList();

          print('${missions.length} missions chargées depuis Firebase');
          return missions;
        }
      }

      // Si aucune mission n'est trouvée, retourner les missions par défaut
      print(
          'Aucune mission trouvée dans Firebase, utilisation des missions par défaut');
      return getMissions();
    } catch (e) {
      print('Erreur lors du chargement des missions: $e');
      return getMissions(); // En cas d'erreur, retourner les missions par défaut
    }
  }

  // Mettre à jour une mission spécifique
  Future<void> updateMission(Mission mission) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print(
            'Impossible de mettre à jour la mission: aucun utilisateur connecté');
        return;
      }

      // Récupérer les missions existantes
      final missions = await loadMissions();

      // Trouver et mettre à jour la mission
      final index = missions.indexWhere((m) => m.id == mission.id);
      if (index != -1) {
        missions[index] = mission;

        // Sauvegarder toutes les missions
        await saveMissions(missions);
        print('Mission ${mission.id} mise à jour avec succès');
      } else {
        print('Mission non trouvée: ${mission.id}');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la mission: $e');
      throw e;
    }
  }
}
