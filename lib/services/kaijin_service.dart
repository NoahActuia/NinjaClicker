import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kaijin.dart';
import '../models/technique.dart';
import '../models/sensei.dart';

class KaijinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer un nouveau kaijin
  Future<Kaijin> createKaijin({
    required String userId,
    required String name,
  }) async {
    try {
      // Créer les données du kaijin
      final kaijinData = {
        'userId': userId,
        'name': name,
        'xp': 0,
        'level': 1,
        'strength': 10,
        'agility': 10,
        'kai': 10,
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

      // Ajouter le kaijin à Firestore
      final kaijinRef = await _firestore.collection('kaijins').add(kaijinData);

      // Récupérer le document créé
      final kaijinDoc = await kaijinRef.get();

      // Retourner le kaijin
      return Kaijin.fromFirestore(kaijinDoc);
    } catch (e) {
      print('Erreur lors de la création du kaijin: $e');
      throw e;
    }
  }

  // Récupérer le kaijin actuellement connecté pour un utilisateur
  Future<Kaijin?> getCurrentKaijin(String userId) async {
    try {
      // Récupérer tous les kaijins de l'utilisateur
      final kaijins = await getKaijinsByUser(userId);

      if (kaijins.isEmpty) {
        return null;
      }

      // Trier les kaijins par date de dernière connexion (du plus récent au plus ancien)
      kaijins.sort((a, b) => b.lastConnected.compareTo(a.lastConnected));

      // Retourner le kaijin le plus récemment connecté
      return kaijins.first;
    } catch (e) {
      print('Erreur lors de la récupération du kaijin actuel: $e');
      return null;
    }
  }

  // Récupérer tous les kaijins d'un utilisateur
  Future<List<Kaijin>> getKaijinsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('kaijins')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Kaijin.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des kaijins: $e');
      return [];
    }
  }

  // Récupérer un kaijin par son ID
  Future<Kaijin?> getKaijinById(String kaijinId) async {
    try {
      final kaijinDoc =
          await _firestore.collection('kaijins').doc(kaijinId).get();

      if (kaijinDoc.exists) {
        return Kaijin.fromFirestore(kaijinDoc);
      }
    } catch (e) {
      print('Erreur lors de la récupération du kaijin: $e');
    }
    return null;
  }

  // Récupérer tous les kaijins classés par niveau
  Future<List<Kaijin>> getAllKaijinsRankedByLevel({int limit = 20}) async {
    try {
      // Récupérer tous les kaijins triés par niveau uniquement pour éviter l'erreur d'index
      final querySnapshot = await _firestore
          .collection('kaijins')
          .orderBy('level', descending: true)
          .limit(
              limit * 2) // Récupérer plus de documents pour le tri secondaire
          .get();

      // Convertir les documents en objets Kaijin
      final kaijins =
          querySnapshot.docs.map((doc) => Kaijin.fromFirestore(doc)).toList();

      // Trier localement par XP pour les kaijins de même niveau
      kaijins.sort((a, b) {
        // D'abord par niveau (descendant)
        if (a.level != b.level) {
          return b.level.compareTo(a.level);
        }
        // Ensuite par XP (descendant)
        return b.xp.compareTo(a.xp);
      });

      // Limiter le nombre de résultats après le tri
      final limitedKaijins = kaijins.take(limit).toList();

      // Ajouter un rang à chaque kaijin en fonction de sa position
      for (int i = 0; i < limitedKaijins.length; i++) {
        limitedKaijins[i].rank = (i + 1).toString(); // Le rang commence à 1
      }

      return limitedKaijins;
    } catch (e) {
      print('Erreur lors de la récupération du classement des kaijins: $e');
      return [];
    }
  }

  // Supprimer un kaijin
  Future<bool> deleteKaijin(String kaijinId) async {
    try {
      // 1. Supprimer les techniques du kaijin
      final techniqueRelations = await _firestore
          .collection('kaijinTechniques')
          .where('kaijinId', isEqualTo: kaijinId)
          .get();

      // Utiliser un batch pour les suppressions massives
      var batch = _firestore.batch();

      for (var doc in techniqueRelations.docs) {
        batch.delete(doc.reference);
      }

      // 2. Supprimer les senseis du kaijin
      final senseiRelations = await _firestore
          .collection('kaijinSenseis')
          .where('kaijinId', isEqualTo: kaijinId)
          .get();

      for (var doc in senseiRelations.docs) {
        batch.delete(doc.reference);
      }

      // Exécuter le premier batch
      await batch.commit();

      // 3. Supprimer le kaijin lui-même
      await _firestore.collection('kaijins').doc(kaijinId).delete();

      print('Kaijin et ses relations supprimés avec succès');
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du kaijin: $e');
      return false;
    }
  }

  // Mettre à jour un kaijin
  Future<void> updateKaijin(Kaijin kaijin) async {
    try {
      await _firestore
          .collection('kaijins')
          .doc(kaijin.id)
          .update(kaijin.toFirestore());
    } catch (e) {
      print('Erreur lors de la mise à jour du kaijin: $e');
      throw e;
    }
  }

  // Ajouter de l'XP
  Future<void> addXp(String kaijinId, int amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final kaijinRef = _firestore.collection('kaijins').doc(kaijinId);
        final kaijinDoc = await transaction.get(kaijinRef);

        if (kaijinDoc.exists) {
          final currentXp = kaijinDoc.data()?['xp'] as int? ?? 0;
          final newXp = currentXp + amount;

          // Mise à jour de l'XP
          transaction.update(kaijinRef, {'xp': newXp});

          // Vérifier si passage de niveau
          final currentLevel = kaijinDoc.data()?['level'] as int? ?? 1;
          final xpNeededForNextLevel = currentLevel * 100; // Formule simple

          if (newXp >= xpNeededForNextLevel) {
            // Passage de niveau
            transaction.update(kaijinRef, {
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

  // Récupérer les techniques d'un kaijin
  Future<List<Technique>> getKaijinTechniques(String kaijinId) async {
    try {
      final querySnapshot = await _firestore
          .collection('kaijinTechniques')
          .where('kaijinId', isEqualTo: kaijinId)
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

  // Ajouter une technique à un kaijin
  Future<void> addTechniqueToKaijin(String kaijinId, String techniqueId) async {
    try {
      // Vérifier si la relation existe déjà
      final querySnapshot = await _firestore
          .collection('kaijinTechniques')
          .where('kaijinId', isEqualTo: kaijinId)
          .where('techniqueId', isEqualTo: techniqueId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // La technique existe déjà, augmenter son niveau
        final docId = querySnapshot.docs.first.id;
        final currentLevel =
            querySnapshot.docs.first.data()['level'] as int? ?? 0;

        await _firestore
            .collection('kaijinTechniques')
            .doc(docId)
            .update({'level': currentLevel + 1});
      } else {
        // Ajouter la nouvelle technique
        await _firestore.collection('kaijinTechniques').add({
          'kaijinId': kaijinId,
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

  // Récupérer les senseis d'un kaijin
  Future<List<Sensei>> getKaijinSenseis(String kaijinId) async {
    try {
      final querySnapshot = await _firestore
          .collection('kaijinSenseis')
          .where('kaijinId', isEqualTo: kaijinId)
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

  // Ajouter un sensei à un kaijin
  Future<void> addSenseiToKaijin(String kaijinId, String senseiId) async {
    try {
      // Vérifier si la relation existe déjà
      final querySnapshot = await _firestore
          .collection('kaijinSenseis')
          .where('kaijinId', isEqualTo: kaijinId)
          .where('senseiId', isEqualTo: senseiId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Le sensei existe déjà, augmenter sa quantité
        final docId = querySnapshot.docs.first.id;
        final currentQuantity =
            querySnapshot.docs.first.data()['quantity'] as int? ?? 0;

        await _firestore
            .collection('kaijinSenseis')
            .doc(docId)
            .update({'quantity': currentQuantity + 1});
      } else {
        // Ajouter le nouveau sensei
        await _firestore.collection('kaijinSenseis').add({
          'kaijinId': kaijinId,
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
  Future<void> upgradeSensei(String kaijinId, String senseiId) async {
    try {
      final querySnapshot = await _firestore
          .collection('kaijinSenseis')
          .where('kaijinId', isEqualTo: kaijinId)
          .where('senseiId', isEqualTo: senseiId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        final currentLevel =
            querySnapshot.docs.first.data()['level'] as int? ?? 1;

        await _firestore
            .collection('kaijinSenseis')
            .doc(docId)
            .update({'level': currentLevel + 1});
      }
    } catch (e) {
      print('Erreur lors de l\'amélioration du sensei: $e');
      throw e;
    }
  }

  // Mettre à jour le niveau d'une technique du kaijin
  Future<void> updateKaijinTechnique(
      String kaijinId, String techniqueId, int level) async {
    try {
      // Vérifier si la relation existe déjà
      final querySnapshot = await _firestore
          .collection('kaijinTechniques')
          .where('kaijinId', isEqualTo: kaijinId)
          .where('techniqueId', isEqualTo: techniqueId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // La technique existe, mettre à jour son niveau
        final docId = querySnapshot.docs.first.id;
        await _firestore
            .collection('kaijinTechniques')
            .doc(docId)
            .update({'level': level});
      } else {
        // Créer une nouvelle relation avec le niveau spécifié
        await _firestore.collection('kaijinTechniques').add({
          'kaijinId': kaijinId,
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
}
