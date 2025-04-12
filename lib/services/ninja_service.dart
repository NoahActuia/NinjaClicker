import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ninja.dart';
import '../models/technique.dart';
import '../models/sensei.dart';

class NinjaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer un nouveau ninja
  Future<Ninja> createNinja({
    required String userId,
    required String name,
  }) async {
    try {
      // Créer les données du ninja
      final ninjaData = {
        'userId': userId,
        'name': name,
        'xp': 0,
        'level': 1,
        'strength': 10,
        'agility': 10,
        'chakra': 10,
        'speed': 10,
        'defense': 10,
        'xpPerClick': 1,
        'passiveXp': 0,
        'appearance': {
          'skin': 'default',
          'headband': 'default',
          'weapon': 'default'
        },
        'rank': 'beginner',
        'eloPoints': 1000,
        'matchesPlayed': 0,
        'wins': 0,
        'losses': 0,
      };

      // Ajouter le ninja à Firestore
      final ninjaRef = await _firestore.collection('ninjas').add(ninjaData);

      // Récupérer le document créé
      final ninjaDoc = await ninjaRef.get();

      // Retourner le ninja
      return Ninja.fromFirestore(ninjaDoc);
    } catch (e) {
      print('Erreur lors de la création du ninja: $e');
      throw e;
    }
  }

  // Récupérer tous les ninjas d'un utilisateur
  Future<List<Ninja>> getNinjasByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ninjas')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) => Ninja.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des ninjas: $e');
      return [];
    }
  }

  // Récupérer un ninja par son ID
  Future<Ninja?> getNinjaById(String ninjaId) async {
    try {
      final ninjaDoc = await _firestore.collection('ninjas').doc(ninjaId).get();

      if (ninjaDoc.exists) {
        return Ninja.fromFirestore(ninjaDoc);
      }
    } catch (e) {
      print('Erreur lors de la récupération du ninja: $e');
    }
    return null;
  }

  // Récupérer tous les ninjas classés par niveau
  Future<List<Ninja>> getAllNinjasRankedByLevel({int limit = 20}) async {
    try {
      // Récupérer tous les ninjas triés par niveau uniquement pour éviter l'erreur d'index
      final querySnapshot = await _firestore
          .collection('ninjas')
          .orderBy('level', descending: true)
          .limit(
              limit * 2) // Récupérer plus de documents pour le tri secondaire
          .get();

      // Convertir les documents en objets Ninja
      final ninjas =
          querySnapshot.docs.map((doc) => Ninja.fromFirestore(doc)).toList();

      // Trier localement par XP pour les ninjas de même niveau
      ninjas.sort((a, b) {
        // D'abord par niveau (descendant)
        if (a.level != b.level) {
          return b.level.compareTo(a.level);
        }
        // Ensuite par XP (descendant)
        return b.xp.compareTo(a.xp);
      });

      // Limiter le nombre de résultats après le tri
      final limitedNinjas = ninjas.take(limit).toList();

      // Ajouter un rang à chaque ninja en fonction de sa position
      for (int i = 0; i < limitedNinjas.length; i++) {
        limitedNinjas[i].rank = (i + 1).toString(); // Le rang commence à 1
      }

      return limitedNinjas;
    } catch (e) {
      print('Erreur lors de la récupération du classement des ninjas: $e');
      return [];
    }
  }

  // Supprimer un ninja
  Future<bool> deleteNinja(String ninjaId) async {
    try {
      // 1. Supprimer les techniques du ninja
      final techniqueRelations = await _firestore
          .collection('ninjaTechniques')
          .where('ninjaId', isEqualTo: ninjaId)
          .get();

      // Utiliser un batch pour les suppressions massives
      var batch = _firestore.batch();

      for (var doc in techniqueRelations.docs) {
        batch.delete(doc.reference);
      }

      // 2. Supprimer les senseis du ninja
      final senseiRelations = await _firestore
          .collection('ninjaSenseis')
          .where('ninjaId', isEqualTo: ninjaId)
          .get();

      for (var doc in senseiRelations.docs) {
        batch.delete(doc.reference);
      }

      // Exécuter le premier batch
      await batch.commit();

      // 3. Supprimer le ninja lui-même
      await _firestore.collection('ninjas').doc(ninjaId).delete();

      print('Ninja et ses relations supprimés avec succès');
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du ninja: $e');
      return false;
    }
  }

  // Mettre à jour un ninja
  Future<void> updateNinja(Ninja ninja) async {
    try {
      await _firestore
          .collection('ninjas')
          .doc(ninja.id)
          .update(ninja.toFirestore());
    } catch (e) {
      print('Erreur lors de la mise à jour du ninja: $e');
      throw e;
    }
  }

  // Ajouter de l'XP
  Future<void> addXp(String ninjaId, int amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final ninjaRef = _firestore.collection('ninjas').doc(ninjaId);
        final ninjaDoc = await transaction.get(ninjaRef);

        if (ninjaDoc.exists) {
          final currentXp = ninjaDoc.data()?['xp'] as int? ?? 0;
          final newXp = currentXp + amount;

          // Mise à jour de l'XP
          transaction.update(ninjaRef, {'xp': newXp});

          // Vérifier si passage de niveau
          final currentLevel = ninjaDoc.data()?['level'] as int? ?? 1;
          final xpNeededForNextLevel = currentLevel * 100; // Formule simple

          if (newXp >= xpNeededForNextLevel) {
            // Passage de niveau
            transaction.update(ninjaRef, {
              'level': currentLevel + 1,
              'xp': newXp - xpNeededForNextLevel
            });
          }
        }
      });
    } catch (e) {
      print('Erreur lors de l\'ajout d\'XP: $e');
      throw e;
    }
  }

  // Récupérer les techniques d'un ninja
  Future<List<Technique>> getNinjaTechniques(String ninjaId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ninjaTechniques')
          .where('ninjaId', isEqualTo: ninjaId)
          .get();

      final techniqueIds = querySnapshot.docs
          .map((doc) => doc.data()['techniqueId'] as String)
          .toList();

      if (techniqueIds.isEmpty) return [];

      // Récupérer les techniques
      final techniques = <Technique>[];
      for (final id in techniqueIds) {
        final techniqueDoc =
            await _firestore.collection('techniques').doc(id).get();

        if (techniqueDoc.exists) {
          // Récupérer le niveau depuis la relation
          final relationDoc = querySnapshot.docs.firstWhere(
            (doc) => doc.data()['techniqueId'] == id,
          );

          final technique = Technique.fromFirestore(techniqueDoc);
          technique.level = relationDoc.data()['level'] as int? ?? 0;

          techniques.add(technique);
        }
      }

      return techniques;
    } catch (e) {
      print('Erreur lors de la récupération des techniques: $e');
      return [];
    }
  }

  // Ajouter une technique à un ninja
  Future<void> addTechniqueToNinja(String ninjaId, String techniqueId) async {
    try {
      // Vérifier si la relation existe déjà
      final querySnapshot = await _firestore
          .collection('ninjaTechniques')
          .where('ninjaId', isEqualTo: ninjaId)
          .where('techniqueId', isEqualTo: techniqueId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // La technique existe déjà, augmenter son niveau
        final docId = querySnapshot.docs.first.id;
        final currentLevel =
            querySnapshot.docs.first.data()['level'] as int? ?? 0;

        await _firestore
            .collection('ninjaTechniques')
            .doc(docId)
            .update({'level': currentLevel + 1});
      } else {
        // Ajouter la nouvelle technique
        await _firestore.collection('ninjaTechniques').add({
          'ninjaId': ninjaId,
          'techniqueId': techniqueId,
          'level': 1,
          'acquiredAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Erreur lors de l\'ajout de la technique: $e');
      throw e;
    }
  }

  // Récupérer les senseis d'un ninja
  Future<List<Sensei>> getNinjaSenseis(String ninjaId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ninjaSenseis')
          .where('ninjaId', isEqualTo: ninjaId)
          .get();

      final senseiIds = querySnapshot.docs
          .map((doc) => doc.data()['senseiId'] as String)
          .toList();

      if (senseiIds.isEmpty) return [];

      // Récupérer les senseis
      final senseis = <Sensei>[];
      for (final id in senseiIds) {
        final senseiDoc = await _firestore.collection('senseis').doc(id).get();

        if (senseiDoc.exists) {
          // Récupérer le niveau et la quantité depuis la relation
          final relationDoc = querySnapshot.docs.firstWhere(
            (doc) => doc.data()['senseiId'] == id,
          );

          final sensei = Sensei.fromFirestore(senseiDoc);
          sensei.level = relationDoc.data()['level'] as int? ?? 1;
          sensei.quantity = relationDoc.data()['quantity'] as int? ?? 0;

          senseis.add(sensei);
        }
      }

      return senseis;
    } catch (e) {
      print('Erreur lors de la récupération des senseis: $e');
      return [];
    }
  }

  // Ajouter un sensei à un ninja
  Future<void> addSenseiToNinja(String ninjaId, String senseiId) async {
    try {
      // Vérifier si la relation existe déjà
      final querySnapshot = await _firestore
          .collection('ninjaSenseis')
          .where('ninjaId', isEqualTo: ninjaId)
          .where('senseiId', isEqualTo: senseiId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Le sensei existe déjà, augmenter sa quantité
        final docId = querySnapshot.docs.first.id;
        final currentQuantity =
            querySnapshot.docs.first.data()['quantity'] as int? ?? 0;

        await _firestore
            .collection('ninjaSenseis')
            .doc(docId)
            .update({'quantity': currentQuantity + 1});
      } else {
        // Ajouter le nouveau sensei
        await _firestore.collection('ninjaSenseis').add({
          'ninjaId': ninjaId,
          'senseiId': senseiId,
          'level': 1,
          'quantity': 1,
        });
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du sensei: $e');
      throw e;
    }
  }

  // Améliorer un sensei
  Future<void> upgradeSensei(String ninjaId, String senseiId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ninjaSenseis')
          .where('ninjaId', isEqualTo: ninjaId)
          .where('senseiId', isEqualTo: senseiId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        final currentLevel =
            querySnapshot.docs.first.data()['level'] as int? ?? 1;

        await _firestore
            .collection('ninjaSenseis')
            .doc(docId)
            .update({'level': currentLevel + 1});
      }
    } catch (e) {
      print('Erreur lors de l\'amélioration du sensei: $e');
      throw e;
    }
  }

  // Mettre à jour le niveau d'une technique d'un ninja
  Future<void> updateNinjaTechnique(
      String ninjaId, String techniqueId, int level) async {
    try {
      // Vérifier si la relation existe déjà
      final querySnapshot = await _firestore
          .collection('ninjaTechniques')
          .where('ninjaId', isEqualTo: ninjaId)
          .where('techniqueId', isEqualTo: techniqueId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // La technique existe déjà, mettre à jour son niveau
        final docId = querySnapshot.docs.first.id;
        await _firestore
            .collection('ninjaTechniques')
            .doc(docId)
            .update({'level': level});
      } else {
        // Ajouter la nouvelle technique avec le niveau spécifié
        await _firestore.collection('ninjaTechniques').add({
          'ninjaId': ninjaId,
          'techniqueId': techniqueId,
          'level': level,
          'acquiredAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la technique: $e');
      throw e;
    }
  }

  Future<void> createNinjaForNewUser(String userId, String username) async {
    // Vérifier si l'utilisateur a déjà un ninja
    final existingNinjas = await getNinjasByUser(userId);

    if (existingNinjas.isEmpty) {
      // Créer un nouveau ninja par défaut
      await createNinja(
        userId: userId,
        name: username,
      );

      // Récupérer les techniques par défaut
      final defaultTechniques = await _firestore
          .collection('techniques')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (defaultTechniques.docs.isNotEmpty) {
        final techniqueId = defaultTechniques.docs[0].id;
        final ninja = await getNinjasByUser(userId);

        if (ninja.isNotEmpty) {
          // Ajouter la technique au ninja
          await addTechniqueToNinja(ninja[0].id, techniqueId);
        }
      }
    }
  }
}
