import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technique.dart';
import '../models/ninja_technique.dart';

class TechniqueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer toutes les techniques disponibles
  Future<List<Technique>> getAllTechniques() async {
    final snapshot = await _firestore.collection('techniques').get();
    return snapshot.docs.map((doc) => Technique.fromFirestore(doc)).toList();
  }

  // Récupérer les techniques débloquées par un utilisateur
  Future<Set<String>> getUnlockedTechniqueIds(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('techniques')
        .where('unlocked', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  // Récupérer les techniques associées à un ninja spécifique
  Future<List<NinjaTechnique>> getNinjaTechniques(String ninjaId) async {
    final snapshot = await _firestore
        .collection('ninjaTechniques')
        .where('ninjaId', isEqualTo: ninjaId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => NinjaTechnique.fromFirestore(doc))
        .toList();
  }

  // Récupérer les détails complets des techniques d'un ninja
  Future<List<Technique>> getTechniquesForNinja(String ninjaId) async {
    // Récupérer les relations ninja-techniques
    final ninjaTechniques = await getNinjaTechniques(ninjaId);

    // Si aucune technique n'est associée, retourner une liste vide
    if (ninjaTechniques.isEmpty) {
      return [];
    }

    // Extraire les IDs des techniques
    final techniqueIds = ninjaTechniques.map((nt) => nt.techniqueId).toList();

    // Récupérer les détails des techniques
    final snapshot = await _firestore
        .collection('techniques')
        .where(FieldPath.documentId, whereIn: techniqueIds)
        .get();

    return snapshot.docs.map((doc) => Technique.fromFirestore(doc)).toList();
  }

  // Ajouter une technique à un ninja
  Future<void> addTechniqueToNinja(String ninjaId, String techniqueId) async {
    // Vérifier si la relation existe déjà
    final existingQuery = await _firestore
        .collection('ninjaTechniques')
        .where('ninjaId', isEqualTo: ninjaId)
        .where('techniqueId', isEqualTo: techniqueId)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      // La relation existe déjà, mise à jour
      final doc = existingQuery.docs.first;
      await _firestore.collection('ninjaTechniques').doc(doc.id).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Nouvelle relation
      final newNinjaTechnique = NinjaTechnique(
        id: '', // Firestore générera l'ID
        ninjaId: ninjaId,
        techniqueId: techniqueId,
        level: 1,
        isActive: true,
        acquiredAt: DateTime.now(),
      );

      await _firestore
          .collection('ninjaTechniques')
          .add(newNinjaTechnique.toFirestore());
    }
  }

  // Supprimer une technique d'un ninja (désactiver)
  Future<void> removeTechniqueFromNinja(
      String ninjaId, String techniqueId) async {
    final existingQuery = await _firestore
        .collection('ninjaTechniques')
        .where('ninjaId', isEqualTo: ninjaId)
        .where('techniqueId', isEqualTo: techniqueId)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      final doc = existingQuery.docs.first;
      await _firestore.collection('ninjaTechniques').doc(doc.id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Récupérer les techniques par défaut
  Future<List<Technique>> getDefaultTechniques() async {
    final snapshot = await _firestore
        .collection('techniques')
        .where('isDefault', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => Technique.fromFirestore(doc)).toList();
  }

  // Récupérer les techniques associées à un ninja et à une technique spécifique
  Future<List<NinjaTechnique>> getNinjaTechniquesForTechnique(
      String ninjaId, String techniqueId) async {
    final snapshot = await _firestore
        .collection('ninjaTechniques')
        .where('ninjaId', isEqualTo: ninjaId)
        .where('techniqueId', isEqualTo: techniqueId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => NinjaTechnique.fromFirestore(doc))
        .toList();
  }

  // Formater la puissance d'une technique avec unités K ou M
  String getFormattedPower(Technique technique) {
    int power = technique.powerPerSecond;
    if (power >= 1000000) {
      double formattedValue = power / 1000000;
      return '${formattedValue.toStringAsFixed(1)}M Kai/s';
    } else if (power >= 1000) {
      double formattedValue = power / 1000;
      return '${formattedValue.toStringAsFixed(1)}k Kai/s';
    } else {
      return '$power Kai/s';
    }
  }

  // Formater le coût d'une technique avec unités K ou M
  String getFormattedCost(Technique technique) {
    int cost = technique.cost;
    if (cost >= 1000000) {
      double formattedValue = cost / 1000000;
      return 'Coût: ${formattedValue.toStringAsFixed(1)}M Kai';
    } else if (cost >= 1000) {
      double formattedValue = cost / 1000;
      return 'Coût: ${formattedValue.toStringAsFixed(1)}k Kai';
    } else {
      return 'Coût: $cost Kai';
    }
  }

  // Formater le niveau d'une technique avec un affichage élégant
  String getFormattedLevel(Technique technique) {
    return 'Niveau ${technique.level}';
  }

  // Améliorer le niveau d'une technique pour un ninja
  Future<void> upgradeTechnique(
      String ninjaId, String techniqueId, int newLevel) async {
    try {
      // Récupérer la relation existante
      final relations =
          await getNinjaTechniquesForTechnique(ninjaId, techniqueId);

      if (relations.isEmpty) {
        throw Exception('Technique non trouvée pour ce ninja');
      }

      final relation = relations.first;

      // Mettre à jour le niveau
      await _firestore.collection('ninjaTechniques').doc(relation.id).update({
        'level': newLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          'Technique $techniqueId améliorée au niveau $newLevel pour le ninja $ninjaId');
    } catch (e) {
      print('Erreur lors de l\'amélioration de la technique: $e');
      throw e;
    }
  }
}
