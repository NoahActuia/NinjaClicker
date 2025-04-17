import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeDatabase() async {
    await _createInitialTechniques();
    await _createInitialSenseis();
  }

  Future<void> _createInitialTechniques() async {
    final snapshot = await _firestore.collection('techniques').limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Déjà initialisé

    final techniques = [
      // Techniques actives
      {
        'name': 'Entaille du Vent',
        'description': 'Frappe rapide et aérienne, repousse l\'ennemi.',
        'cost': 50,
        'powerPerSecond': 12,
        'sound': 'sounds/technique_vent.mp3',
        'type': 'active',
        'effect': 'damage',
        'kaiCost': 2,
        'cooldown': 1,
        'affinity': 'Flux',
        'conditionGenerated': 'repoussé',
        'effectDetails': {
          'damage': 12,
        },
        'isDefault': true,
        'unlocked': true,
        'techLevel': 1,
      },
      {
        'name': 'Frappe du Vide',
        'description': 'Projette l\'adversaire dans les airs.',
        'cost': 200,
        'powerPerSecond': 15,
        'sound': 'sounds/technique_vide.mp3',
        'type': 'auto',
        'trigger': 'repoussé',
        'effect': 'damage',
        'kaiCost': 3,
        'cooldown': 2,
        'affinity': 'Flux',
        'conditionGenerated': 'projeté',
        'effectDetails': {
          'damage': 18,
        },
        'isDefault': true,
        'unlocked': true,
        'techLevel': 1,
      },
      {
        'name': 'Éclair Ascendant',
        'description': 'Combo aérien puissant sur un ennemi projeté.',
        'cost': 800,
        'powerPerSecond': 25,
        'sound': 'sounds/technique_eclair.mp3',
        'type': 'auto',
        'trigger': 'projeté',
        'effect': 'damage',
        'kaiCost': 4,
        'cooldown': 3,
        'affinity': 'Frappe',
        'conditionGenerated': null,
        'effectDetails': {
          'damage': 30,
          'combo_bonus': true,
        },
        'isDefault': true,
        'unlocked': true,
        'techLevel': 1,
      },
      {
        'name': 'Vague Fracturante',
        'description':
            'Déchire la réalité pour créer une onde d\'énergie dévastatrice.',
        'cost': 1000,
        'powerPerSecond': 40,
        'sound': 'sounds/technique_fracture.mp3',
        'type': 'active',
        'effect': 'area_damage',
        'kaiCost': 8,
        'cooldown': 4,
        'affinity': 'Fracture',
        'conditionGenerated': 'marqué',
        'effectDetails': {
          'damage': 25,
          'area': true,
        },
        'isDefault': true,
        'unlocked': true,
        'techLevel': 1,
      },
      {
        'name': 'Uppercut',
        'description': 'Coup de base qui projette légèrement l\'adversaire.',
        'cost': 0,
        'powerPerSecond': 5,
        'sound': 'sounds/technique_coup.mp3',
        'type': 'simple',
        'effect': 'damage',
        'kaiCost': 0,
        'cooldown': 0,
        'affinity': 'Frappe',
        'conditionGenerated': 'projeté',
        'effectDetails': {
          'damage': 8,
        },
        'isDefault': true,
        'unlocked': true,
        'techLevel': 1,
      },
      {
        'name': 'Détonation Ciblée',
        'description': 'Attaque bonus sur un ennemi marqué.',
        'cost': 500,
        'powerPerSecond': 30,
        'sound': 'sounds/technique_detonation.mp3',
        'type': 'auto',
        'trigger': 'marqué',
        'effect': 'damage',
        'kaiCost': 5,
        'cooldown': 2,
        'affinity': 'Fracture',
        'conditionGenerated': null,
        'effectDetails': {
          'damage': 35,
        },
        'isDefault': true,
        'unlocked': true,
        'techLevel': 1,
      },
      // Techniques niveau 2 (débloquables)
      {
        'name': 'Poing du Sceau',
        'description':
            'Scelle temporairement une partie du Kai de l\'adversaire.',
        'cost': 1500,
        'powerPerSecond': 35,
        'sound': 'sounds/technique_sceau.mp3',
        'type': 'active',
        'effect': 'seal',
        'kaiCost': 10,
        'cooldown': 5,
        'affinity': 'Sceau',
        'conditionGenerated': 'scellé',
        'effectDetails': {
          'damage': 15,
          'kai_reduction': 5,
        },
        'isDefault': true,
        'unlocked': false,
        'techLevel': 2,
        'parentTechId': null, // Sera associé à une technique de niveau 1
      },
      {
        'name': 'Lames de Dérive',
        'description': 'Crée des lames d\'énergie qui suivent l\'adversaire.',
        'cost': 2000,
        'powerPerSecond': 45,
        'sound': 'sounds/technique_derive.mp3',
        'type': 'active',
        'effect': 'damage_over_time',
        'kaiCost': 12,
        'cooldown': 6,
        'affinity': 'Dérive',
        'conditionGenerated': 'corrompu',
        'effectDetails': {
          'damage': 10,
          'duration': 3,
        },
        'isDefault': true,
        'unlocked': false,
        'techLevel': 2,
        'parentTechId': null,
      },
      {
        'name': 'Parasitage',
        'description':
            'Inverse les effets d\'une technique sur un ennemi corrompu.',
        'cost': 1800,
        'powerPerSecond': 40,
        'sound': 'sounds/technique_parasitage.mp3',
        'type': 'auto',
        'trigger': 'corrompu',
        'effect': 'inversion',
        'kaiCost': 15,
        'cooldown': 8,
        'affinity': 'Dérive',
        'conditionGenerated': null,
        'effectDetails': {
          'duration': 2,
        },
        'isDefault': true,
        'unlocked': false,
        'techLevel': 2,
        'parentTechId': null,
      },
      // Technique passive de base
      {
        'name': 'Affinité du Flux',
        'description': 'Augmente légèrement les dégâts des techniques de Flux.',
        'cost': 300,
        'powerPerSecond': 0,
        'sound': 'sounds/technique_passive.mp3',
        'type': 'passive',
        'effect': 'boost',
        'kaiCost': 0,
        'cooldown': 0,
        'affinity': 'Flux',
        'conditionGenerated': null,
        'effectDetails': {
          'flux_damage_bonus': 10,
        },
        'isDefault': true,
        'unlocked': true,
        'techLevel': 1,
      },
    ];

    for (final technique in techniques) {
      await _firestore.collection('techniques').add(technique);
    }
  }

  Future<void> _createInitialSenseis() async {
    final snapshot = await _firestore.collection('senseis').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final senseis = [
      {
        'name': 'Iruka',
        'description': 'Professeur à l\'académie',
        'image': 'assets/images/academy.webp',
        'baseCost': 100,
        'xpPerSecond': 1,
        'costMultiplier': 1.5,
        'isDefault': true,
      },
      {
        'name': 'Kakashi',
        'description': 'Maître du Sharingan',
        'image': 'assets/images/chunin_exam.webp',
        'baseCost': 500,
        'xpPerSecond': 5,
        'costMultiplier': 1.8,
        'isDefault': true,
      },
      {
        'name': 'Jiraiya',
        'description': 'L\'un des trois légendaires Sannin',
        'image': 'assets/images/academy.webp',
        'baseCost': 2000,
        'xpPerSecond': 20,
        'costMultiplier': 2.0,
        'isDefault': true,
      },
      {
        'name': 'Tsunade',
        'description': 'Expert en ninjutsu médical',
        'image': 'assets/images/chunin_exam.webp',
        'baseCost': 3000,
        'xpPerSecond': 30,
        'costMultiplier': 2.2,
        'isDefault': true,
      },
      {
        'name': 'Orochimaru',
        'description': 'Maître des techniques interdites',
        'image': 'assets/images/academy.webp',
        'baseCost': 4000,
        'xpPerSecond': 40,
        'costMultiplier': 2.5,
        'isDefault': true,
      },
    ];

    for (final sensei in senseis) {
      await _firestore.collection('senseis').add(sensei);
    }
  }
}
