import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/technique.dart';
import '../models/sensei.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;

  FirebaseService._internal();

  bool get isInitialized => _isInitialized;

  // Vérifier si Firebase est correctement initialisé
  Future<bool> checkConnection() async {
    try {
      // Vérifier Firebase Core
      if (Firebase.apps.isEmpty) {
        return false;
      }

      // Vérifier Firestore
      try {
        await _firestore
            .collection('connection_test')
            .doc('test')
            .set({'timestamp': FieldValue.serverTimestamp()});
      } catch (e) {
        print('Erreur de connexion Firestore: $e');
        return false;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Erreur lors de la vérification de la connexion: $e');
      return false;
    }
  }

  // Initialiser les données de base dans Firestore
  Future<void> initializeData() async {
    if (!await checkConnection()) {
      throw Exception('Firebase n\'est pas correctement initialisé');
    }

    await _initializeTechniques();
    await _initializeSenseis();
  }

  // Initialiser les techniques de base
  Future<void> _initializeTechniques() async {
    // Vérifier si les techniques existent déjà
    final techniques = await _firestore
        .collection('techniques')
        .where('isDefault', isEqualTo: true)
        .get();

    if (techniques.docs.isNotEmpty) {
      print('Les techniques par défaut existent déjà.');
      return;
    }

    // Liste des techniques de base
    final defaultTechniques = [
      {
        'name': 'Boule de Feu',
        'description': 'Technique de base du clan Uchiwa',
        'cost': 50,
        'powerPerSecond': 2,
        'sound': 'sounds/technique_boule_feu.mp3',
        'type': 'special',
        'effect': 'damage',
        'chakraCost': 30,
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
        'chakraCost': 60,
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
        'chakraCost': 100,
        'cooldown': 4,
        'isDefault': true,
      },
      {
        'name': 'Mode Sage',
        'description': 'Utiliser l\'énergie naturelle',
        'cost': 5000,
        'powerPerSecond': 250,
        'sound': 'sounds/technique_mode_sage.mp3',
        'type': 'auto',
        'effect': 'boost',
        'chakraCost': 200,
        'cooldown': 10,
        'isDefault': true,
      },
      {
        'name': 'Rasengan Géant',
        'description': 'Version améliorée du Rasengan, beaucoup plus puissante',
        'cost': 2000,
        'powerPerSecond': 100,
        'sound': 'sounds/technique_rasengan_geant.mp3',
        'type': 'special',
        'effect': 'damage',
        'chakraCost': 150,
        'cooldown': 5,
        'isDefault': true,
      },
      {
        'name': 'Mode Sage Parfait',
        'description': 'Utilisation parfaite de l\'énergie naturelle',
        'cost': 5000,
        'powerPerSecond': 300,
        'sound': 'sounds/technique_mode_sage_parfait.mp3',
        'type': 'auto',
        'effect': 'boost',
        'chakraCost': 250,
        'cooldown': 15,
        'isDefault': true,
      },
    ];

    // Ajouter les techniques à Firestore
    final batch = _firestore.batch();
    for (final technique in defaultTechniques) {
      final docRef = _firestore.collection('techniques').doc();
      batch.set(docRef, technique);
    }
    await batch.commit();
    print('Techniques par défaut ajoutées avec succès.');
  }

  // Initialiser les senseis de base
  Future<void> _initializeSenseis() async {
    // Vérifier si les senseis existent déjà
    final senseis = await _firestore
        .collection('senseis')
        .where('isDefault', isEqualTo: true)
        .get();

    if (senseis.docs.isNotEmpty) {
      print('Les senseis par défaut existent déjà.');
      return;
    }

    // Liste des senseis de base
    final defaultSenseis = [
      {
        'name': 'Iruka Sensei',
        'description': 'Enseignant à l\'Académie des Ninjas',
        'image': 'assets/images/senseis/iruka.png',
        'baseCost': 50,
        'xpPerSecond': 1,
        'costMultiplier': 1.2,
        'isDefault': true,
      },
      {
        'name': 'Kakashi Sensei',
        'description': 'Ninja copieur, maître de mille techniques',
        'image': 'assets/images/senseis/kakashi.png',
        'baseCost': 200,
        'xpPerSecond': 5,
        'costMultiplier': 1.3,
        'isDefault': true,
      },
      {
        'name': 'Jiraiya Sensei',
        'description': 'L\'un des trois Sannins légendaires',
        'image': 'assets/images/senseis/jiraiya.png',
        'baseCost': 1000,
        'xpPerSecond': 25,
        'costMultiplier': 1.4,
        'isDefault': true,
      },
    ];

    // Ajouter les senseis à Firestore
    final batch = _firestore.batch();
    for (final sensei in defaultSenseis) {
      final docRef = _firestore.collection('senseis').doc();
      batch.set(docRef, sensei);
    }
    await batch.commit();
    print('Senseis par défaut ajoutés avec succès.');
  }

  // Tester si toutes les collections sont accessibles
  Future<Map<String, bool>> testCollections() async {
    final results = <String, bool>{};

    try {
      // Liste des collections à tester
      final collections = [
        'users',
        'ninjas',
        'techniques',
        'senseis',
        'ninjaTechniques',
        'ninjaSenseis'
      ];

      for (final collection in collections) {
        try {
          await _firestore.collection(collection).limit(1).get();
          results[collection] = true;
        } catch (e) {
          results[collection] = false;
          print('Erreur lors du test de $collection: $e');
        }
      }
    } catch (e) {
      print('Erreur globale lors du test des collections: $e');
    }

    return results;
  }

  // Exportation des données de techniques et senseis pour migration
  Future<void> exportTechniquesAndSenseis() async {
    try {
      // Récupérer toutes les techniques existantes
      final techniques = await _firestore.collection('techniques').get();

      // Sauvegarder dans Firestore
      if (techniques.docs.isNotEmpty) {
        final batch = _firestore.batch();
        final exportDoc = _firestore.collection('exports').doc('techniques');

        batch.set(exportDoc, {
          'data': techniques.docs.map((doc) => doc.data()).toList(),
          'exportedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        print('Techniques exportées avec succès.');
      }

      // Même chose pour les senseis
      final senseis = await _firestore.collection('senseis').get();

      if (senseis.docs.isNotEmpty) {
        final batch = _firestore.batch();
        final exportDoc = _firestore.collection('exports').doc('senseis');

        batch.set(exportDoc, {
          'data': senseis.docs.map((doc) => doc.data()).toList(),
          'exportedAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        print('Senseis exportés avec succès.');
      }
    } catch (e) {
      print('Erreur lors de l\'exportation: $e');
      throw e;
    }
  }
}
