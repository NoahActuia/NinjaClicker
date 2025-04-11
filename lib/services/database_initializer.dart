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
      {
        'name': 'Boule de Feu',
        'description': 'Technique de base du clan Uchiwa',
        'cost': 50,
        'powerPerSecond': 2,
        'sound': 'sounds/technique_boule_feu.mp3',
        'type': 'special',
        'effect': 'damage',
        'chakraCost': 20,
        'cooldown': 2,
        'isDefault': true,
      },
      {
        'name': 'Multi-Clonage',
        'description': 'Créer plusieurs clones simultanément',
        'cost': 200,
        'powerPerSecond': 10,
        'sound': 'sounds/technique_multi_clonage.mp3',
        'type': 'special',
        'effect': 'clone',
        'chakraCost': 50,
        'cooldown': 3,
        'isDefault': true,
      },
      {
        'name': 'Rasengan',
        'description': 'Boule de chakra tourbillonnante',
        'cost': 1000,
        'powerPerSecond': 50,
        'sound': 'sounds/technique_rasengan.mp3',
        'type': 'special',
        'effect': 'damage',
        'chakraCost': 80,
        'cooldown': 3,
        'isDefault': true,
      },
      {
        'name': 'Mode Sage',
        'description': 'Utiliser l\'énergie naturelle',
        'cost': 5000,
        'powerPerSecond': 250,
        'sound': 'sounds/technique_mode_sage.mp3',
        'type': 'special',
        'effect': 'boost',
        'chakraCost': 150,
        'cooldown': 8,
        'isDefault': true,
      },
      // Nouvelles techniques
      {
        'name': 'Chidori',
        'description': 'Concentration d\'électricité dans la main',
        'cost': 800,
        'powerPerSecond': 40,
        'sound': 'sounds/technique_boule_feu.mp3',
        'type': 'special',
        'effect': 'damage',
        'chakraCost': 70,
        'cooldown': 3,
        'isDefault': true,
      },
      {
        'name': 'Kamui',
        'description': 'Distorsion de l\'espace-temps',
        'cost': 3000,
        'powerPerSecond': 150,
        'sound': 'sounds/technique_rasengan.mp3',
        'type': 'special',
        'effect': 'warp',
        'chakraCost': 120,
        'cooldown': 6,
        'isDefault': true,
      },
      {
        'name': 'Invocation',
        'description': 'Invoquer un animal de combat',
        'cost': 1500,
        'powerPerSecond': 75,
        'sound': 'sounds/technique_multi_clonage.mp3',
        'type': 'special',
        'effect': 'summon',
        'chakraCost': 90,
        'cooldown': 4,
        'isDefault': true,
      },
      {
        'name': 'Sceau Maudit',
        'description': 'Libérer la puissance du sceau maudit',
        'cost': 4000,
        'powerPerSecond': 200,
        'sound': 'sounds/technique_mode_sage.mp3',
        'type': 'auto',
        'trigger': 'health<50%',
        'effect': 'boost',
        'chakraCost': 130,
        'cooldown': 15,
        'isDefault': true,
      },
      {
        'name': 'Sharingan',
        'description': 'Activer le pouvoir héréditaire des yeux',
        'cost': 2500,
        'powerPerSecond': 125,
        'sound': 'sounds/technique_boule_feu.mp3',
        'type': 'auto',
        'trigger': 'combat_start',
        'effect': 'copy',
        'chakraCost': 100,
        'cooldown': 10,
        'isDefault': true,
      },
      {
        'name': 'Senjutsu',
        'description': 'Techniques utilisant l\'énergie naturelle',
        'cost': 6000,
        'powerPerSecond': 300,
        'sound': 'sounds/technique_mode_sage.mp3',
        'type': 'special',
        'effect': 'area_damage',
        'chakraCost': 200,
        'cooldown': 12,
        'isDefault': true,
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
