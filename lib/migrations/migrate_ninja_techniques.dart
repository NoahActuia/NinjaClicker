import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ninja_technique.dart';

/// Classe utilitaire pour migrer les techniques des ninjas vers la nouvelle table pivot
class MigrateNinjaTechniques {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrer les techniques d'un utilisateur spécifique
  Future<void> migrateForUser(String userId) async {
    try {
      print('Début de la migration des techniques pour l\'utilisateur $userId');

      // 1. Obtenir tous les ninjas de l'utilisateur
      final ninjaSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ninjas')
          .get();

      if (ninjaSnapshot.docs.isEmpty) {
        print('Aucun ninja trouvé pour l\'utilisateur $userId');
        return;
      }

      // 2. Pour chaque ninja, migrer ses techniques
      for (final ninjaDoc in ninjaSnapshot.docs) {
        await _migrateNinjaTechniques(ninjaDoc, userId);
      }

      print('Migration terminée pour l\'utilisateur $userId');
    } catch (e) {
      print('Erreur lors de la migration: $e');
    }
  }

  /// Migrer les techniques d'un ninja spécifique
  Future<void> _migrateNinjaTechniques(
      DocumentSnapshot ninjaDoc, String userId) async {
    try {
      final ninjaId = ninjaDoc.id;
      final ninjaData = ninjaDoc.data() as Map<String, dynamic>;
      final ninjaName = ninjaData['name'] ?? 'Sans nom';

      print(
          'Migration des techniques pour le ninja: $ninjaName (ID: $ninjaId)');

      // 1. Obtenir les IDs des techniques associées au ninja
      final List<String> techniqueIds =
          List<String>.from(ninjaData['techniques'] ?? []);

      if (techniqueIds.isEmpty) {
        print('Aucune technique associée au ninja $ninjaName');
        return;
      }

      print('Nombre de techniques à migrer: ${techniqueIds.length}');

      // 2. Récupérer les techniques débloquées par l'utilisateur
      final unlockedTechsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('techniques')
          .where('unlocked', isEqualTo: true)
          .get();

      final unlockedTechniqueIds =
          unlockedTechsSnapshot.docs.map((doc) => doc.id).toSet();

      // 3. Filtrer les techniques débloquées
      final validTechniqueIds = techniqueIds
          .where((id) => unlockedTechniqueIds.contains(id))
          .toList();

      print('Techniques débloquées et valides: ${validTechniqueIds.length}');

      // 4. Vérifier si les relations existent déjà dans la table pivot
      final existingRelationsSnapshot = await _firestore
          .collection('ninjaTechniques')
          .where('ninjaId', isEqualTo: ninjaId)
          .get();

      final existingTechniqueIds = existingRelationsSnapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['techniqueId'] as String)
          .toSet();

      // 5. Créer les nouvelles relations
      final batch = _firestore.batch();
      int addedCount = 0;

      for (final techniqueId in validTechniqueIds) {
        if (!existingTechniqueIds.contains(techniqueId)) {
          // Nouvelle relation à créer
          final newRelationRef = _firestore.collection('ninjaTechniques').doc();

          final ninjaTechnique = NinjaTechnique(
            id: newRelationRef.id,
            ninjaId: ninjaId,
            techniqueId: techniqueId,
            level: ninjaData['techniqueLevels']?[techniqueId] ?? 1,
            isActive: true,
            acquiredAt: DateTime.now(),
          );

          batch.set(newRelationRef, ninjaTechnique.toFirestore());
          addedCount++;
        }
      }

      // 6. Exécuter le lot de modifications
      if (addedCount > 0) {
        await batch.commit();
        print(
            '$addedCount nouvelles relations créées pour le ninja $ninjaName');
      } else {
        print('Aucune nouvelle relation à créer pour le ninja $ninjaName');
      }
    } catch (e) {
      print('Erreur lors de la migration des techniques du ninja: $e');
    }
  }

  /// Migrer les techniques pour tous les utilisateurs
  Future<void> migrateForAllUsers() async {
    try {
      print('Début de la migration globale des techniques');

      final usersSnapshot = await _firestore.collection('users').get();

      if (usersSnapshot.docs.isEmpty) {
        print('Aucun utilisateur trouvé');
        return;
      }

      print('Nombre d\'utilisateurs: ${usersSnapshot.docs.length}');

      for (final userDoc in usersSnapshot.docs) {
        await migrateForUser(userDoc.id);
      }

      print('Migration globale terminée');
    } catch (e) {
      print('Erreur lors de la migration globale: $e');
    }
  }
}
