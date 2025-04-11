import '../models/mission.dart';
import '../models/technique.dart';

class MissionService {
  static final MissionService _instance = MissionService._internal();
  factory MissionService() => _instance;

  MissionService._internal();

  // Liste des missions disponibles dans le mode histoire
  List<Mission> getMissions() {
    return [
      Mission(
        id: 'mission1',
        titre: 'L\'Académie Ninja',
        description: 'Commence ton apprentissage à l\'Académie Ninja de Konoha',
        image: 'assets/images/academy.webp',
        puissanceRequise: 0,
        recompensePuissance: 50,
        histoire:
            'Tu es maintenant inscrit à l\'Académie Ninja de Konoha. Ton objectif est de maîtriser les techniques de base et de devenir un Genin. Iruka-sensei t\'enseigne comment concentrer ton chakra pour réaliser des techniques simples.',
        recompenses: [
          Recompense(
            type: 'clone',
            quantite: 2,
          ),
        ],
      ),
      Mission(
        id: 'mission2',
        titre: 'L\'Examen Chunin',
        description: 'Prouve ta valeur lors de l\'examen pour devenir Chunin',
        image: 'assets/images/chunin_exam.webp',
        puissanceRequise: 100,
        recompensePuissance: 200,
        histoire:
            'L\'examen Chunin a commencé et tu dois affronter des ninjas d\'autres villages cachés. La première épreuve est un test écrit difficile, la seconde est une épreuve de survie dans la Forêt de la Mort, et la troisième consiste en des combats individuels.',
        recompenses: [
          Recompense(
            type: 'technique',
            quantite: 1,
            technique: Technique(
              nom: 'Substitution',
              description:
                  'Technique permettant de remplacer ton corps par un objet',
              cout: 150,
              puissanceParSeconde: 5,
              son: 'sounds/technique_substitution.mp3',
            ),
          ),
        ],
      ),
      Mission(
        id: 'mission3',
        titre: 'La Recherche de Sasuke',
        description:
            'Retrouve Sasuke qui a quitté le village pour rejoindre Orochimaru',
        image: 'assets/images/sasuke_retrieval.webp',
        puissanceRequise: 500,
        recompensePuissance: 500,
        histoire:
            'Sasuke a quitté le village pour rejoindre Orochimaru afin d\'obtenir plus de pouvoir. Tu dois former une équipe avec Shikamaru, Choji, Neji et Kiba pour le ramener avant qu\'il ne soit trop tard. Le combat sera difficile car les sbires d\'Orochimaru, les ninjas du Son, protègent Sasuke.',
        recompenses: [
          Recompense(
            type: 'puissance',
            quantite: 300,
          ),
          Recompense(
            type: 'clone',
            quantite: 5,
          ),
        ],
      ),
      Mission(
        id: 'mission4',
        titre: 'L\'Entraînement avec Jiraiya',
        description:
            'Quitte le village pour t\'entraîner avec l\'un des Sannins légendaires',
        image: 'assets/images/jiraiya_training.webp',
        puissanceRequise: 1000,
        recompensePuissance: 1000,
        histoire:
            'Pour devenir plus fort et te préparer à affronter l\'Akatsuki, tu pars en voyage d\'entraînement avec Jiraiya pendant deux ans et demi. Tu apprends à mieux contrôler le chakra du Renard à Neuf Queues et à perfectionner ton Rasengan.',
        recompenses: [
          Recompense(
            type: 'technique',
            quantite: 1,
            technique: Technique(
              nom: 'Rasengan Géant',
              description:
                  'Version améliorée du Rasengan, beaucoup plus puissante',
              cout: 2000,
              puissanceParSeconde: 100,
              son: 'sounds/technique_rasengan_geant.mp3',
            ),
          ),
        ],
      ),
      Mission(
        id: 'mission5',
        titre: 'Combat contre Pain',
        description: 'Affronte le chef de l\'Akatsuki qui a détruit Konoha',
        image: 'assets/images/pain_battle.webp',
        puissanceRequise: 3000,
        recompensePuissance: 2000,
        histoire:
            'Pain, le chef de l\'Akatsuki, a attaqué et détruit le village de Konoha. Après avoir maîtrisé le Mode Sage, tu dois l\'affronter pour sauver le village et venger ton maître Jiraiya. Ce combat sera l\'un des plus difficiles que tu aies jamais connu.',
        recompenses: [
          Recompense(
            type: 'technique',
            quantite: 1,
            technique: Technique(
              nom: 'Mode Sage Parfait',
              description:
                  'Utilisation parfaite de l\'énergie naturelle, augmentant considérablement ta puissance',
              cout: 5000,
              puissanceParSeconde: 300,
              son: 'sounds/technique_mode_sage_parfait.mp3',
            ),
          ),
          Recompense(
            type: 'puissance',
            quantite: 1000,
          ),
        ],
      ),
    ];
  }

  // Obtenir une mission par son ID
  Mission? getMissionById(String id) {
    final missions = getMissions();
    try {
      return missions.firstWhere((mission) => mission.id == id);
    } catch (e) {
      return null;
    }
  }

  // Vérifier si une mission est disponible (si la puissance est suffisante)
  bool isMissionAvailable(Mission mission, int currentPuissance) {
    return currentPuissance >= mission.puissanceRequise;
  }
}
