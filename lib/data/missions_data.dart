import '../models/mission.dart';
import '../models/technique.dart';

class MissionsData {
  static List<Mission> getMissions() {
    return [
      // MONDE 1 — Village d'Han (Entraînement)
      Mission(
        id: 'monde1_combat1',
        titre: 'Le premier test',
        description: 'Le dojo est silencieux.\nLe Sensei m\'observe, impassible.\nC\'est l\'heure de prouver ma valeur.',
        image: 'assets/images/academy.webp',
        puissanceRequise: 10,
        recompensePuissance: 5,
        recompenses: [
          Recompense(type: 'technique', technique: Technique(
            id: 'technique_base',
            name: 'Frappe du Débutant',
            description: 'Une technique simple mais efficace.',
            cout: 5,
            niveau: 1,
          )),
        ],
        difficulte: 1,
      ),
      Mission(
        id: 'monde1_combat2',
        titre: 'Confronter ses limites',
        description: 'Mon bras tremble encore du dernier exercice.\nJe me suis juré de ne jamais abandonner.\nAujourd\'hui, je vais tenir.',
        image: 'assets/images/academy.webp',
        puissanceRequise: 20,
        recompensePuissance: 10,
        recompenses: [
          Recompense(type: 'clone', quantite: 1),
        ],
        difficulte: 1,
      ),
      Mission(
        id: 'monde1_combat3',
        titre: 'Le rival',
        description: 'Il est là, toujours devant moi.\nPlus rapide, plus fort… pour l\'instant.\nJe veux dépasser ce rival.',
        image: 'assets/images/academy.webp',
        puissanceRequise: 35,
        recompensePuissance: 15,
        recompenses: [
          Recompense(type: 'technique', technique: Technique(
            id: 'technique_rival',
            name: 'Frappe du Rival',
            description: 'Une technique inspirée de votre rival.',
            cout: 10,
            niveau: 1,
          )),
        ],
        difficulte: 2,
      ),
      Mission(
        id: 'monde1_combat4',
        titre: 'L\'épreuve du feu',
        description: 'Une rumeur court : seuls les plus dignes\nont survécu à cette épreuve.\nMon tour est venu.',
        image: 'assets/images/academy.webp',
        puissanceRequise: 50,
        recompensePuissance: 20,
        recompenses: [
          Recompense(type: 'technique', technique: Technique(
            id: 'technique_feu',
            name: 'Souffle du Feu',
            description: 'Votre première technique de feu.',
            cout: 15,
            niveau: 1,
          )),
        ],
        difficulte: 2,
      ),
      Mission(
        id: 'monde1_combat5',
        titre: 'Le Sensei',
        description: 'Ce regard... il n\'est plus mon maître.\nIl est mon obstacle final.\nSi je flanche, je recule.',
        image: 'assets/images/academy.webp',
        puissanceRequise: 75,
        recompensePuissance: 30,
        recompenses: [
          Recompense(type: 'technique', technique: Technique(
            id: 'technique_sensei',
            name: 'Sagesse du Sensei',
            description: 'Une technique transmise par votre maître.',
            cout: 20,
            niveau: 1,
          )),
        ],
        difficulte: 3,
      ),

      // MONDE 2 — Forêt d'Okawa
      Mission(
        id: 'monde2_combat1',
        titre: 'L\'exil',
        description: 'Le village a été attaqué.\nRien de grave, mais trop d\'inconnus.\nLe Sensei m\'a dit : "Pars. Observe. Grandis."',
        image: 'assets/images/jiraiya_training.webp',
        puissanceRequise: 100,
        recompensePuissance: 40,
        recompenses: [
          Recompense(type: 'technique', technique: Technique(
            id: 'technique_foret',
            name: 'Camouflage Sylvestre',
            description: 'Une technique pour se fondre dans la forêt.',
            cout: 25,
            niveau: 1,
          )),
        ],
        difficulte: 3,
      ),
      // ... Ajoutez les autres missions du monde 2 de manière similaire

      // MONDE 3 — Monts Nagi
      Mission(
        id: 'monde3_combat1',
        titre: 'L\'ascension',
        description: 'Le froid coupe ma respiration.\nMais je dois atteindre ce sommet.\nLa relique du feu m\'attend.',
        image: 'assets/images/chunin_exam.webp',
        puissanceRequise: 200,
        recompensePuissance: 60,
        recompenses: [
          Recompense(type: 'technique', technique: Technique(
            id: 'technique_montagne',
            name: 'Souffle des Cimes',
            description: 'Une technique adaptée aux hautes altitudes.',
            cout: 35,
            niveau: 1,
          )),
        ],
        difficulte: 4,
      ),
      // ... Ajoutez les autres missions du monde 3 de manière similaire

      // Continuez avec les mondes 4 et 5 de la même manière
    ];
  }
} 