import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer un nouveau défi
  Future<String> createChallenge({
    required String challengerId,
    required String challengerName,
    required int challengerPower,
    required String targetId,
    required String targetName,
    required int targetPower,
    required String challengerKaijinId,
    required String targetKaijinId,
  }) async {
    try {
      print('Création d\'un nouveau défi:');
      print(
          '- Challenger: $challengerName ($challengerId) - Power: $challengerPower');
      print('- Target: $targetName ($targetId) - Power: $targetPower');

      // Vérifier s'il existe déjà un défi en attente entre ces deux joueurs
      final existingChallenges = await _firestore
          .collection('challenges')
          .where('challengerId', isEqualTo: challengerId)
          .where('targetId', isEqualTo: targetId)
          .where('status', isEqualTo: 'pending')
          .get();

      print('Défis existants trouvés: ${existingChallenges.docs.length}');

      if (existingChallenges.docs.isNotEmpty) {
        print('Un défi est déjà en attente entre ces joueurs');
        throw Exception('Un défi est déjà en attente entre ces joueurs');
      }

      final challenge = {
        'challengerId': challengerId,
        'challengerName': challengerName,
        'challengerPower': challengerPower,
        'targetId': targetId,
        'targetName': targetName,
        'targetPower': targetPower,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'challengerKaijinId': challengerKaijinId,
        'targetKaijinId': targetKaijinId,
      };

      print('Création du document de défi avec les données: $challenge');
      final docRef = await _firestore.collection('challenges').add(challenge);
      print('Défi créé avec l\'ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du défi: $e');
      throw e;
    }
  }

  // Obtenir les défis en attente pour un joueur
  Stream<QuerySnapshot> getPendingChallenges(String userId) {
    print('Écoute des défis pour l\'utilisateur: $userId');
    return _firestore
        .collection('challenges')
        .where('targetId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Accepter un défi
  Future<void> acceptChallenge(String challengeId) async {
    try {
      print('Début de l\'acceptation du défi: $challengeId');

      // Vérifier si le défi existe et est toujours en attente
      final challengeDoc =
          await _firestore.collection('challenges').doc(challengeId).get();
      print('Document du défi récupéré: ${challengeDoc.exists}');

      if (!challengeDoc.exists) {
        print('Le défi n\'existe pas');
        throw Exception('Le défi n\'existe pas');
      }

      final data = challengeDoc.data() as Map<String, dynamic>;
      print('Données du défi: $data');

      if (data['status'] != 'pending') {
        print('Le défi n\'est plus en attente (status: ${data['status']})');
        throw Exception('Le défi n\'est plus en attente');
      }

      print('Mise à jour du statut du défi vers "accepted"');
      // Mettre à jour le statut du défi
      await _firestore.collection('challenges').doc(challengeId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Défi accepté avec succès');
    } catch (e) {
      print('Erreur lors de l\'acceptation du défi: $e');
      throw e;
    }
  }

  // Refuser un défi
  Future<void> rejectChallenge(String challengeId) async {
    try {
      print('Refus du défi: $challengeId');
      await _firestore.collection('challenges').doc(challengeId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Défi refusé avec succès');
    } catch (e) {
      print('Erreur lors du refus du défi: $e');
      throw e;
    }
  }

  // Nettoyer les anciens défis
  Future<void> cleanupOldChallenges() async {
    try {
      print('Nettoyage des anciens défis');
      // Supprimer les défis en attente de plus de 24 heures
      final oldChallenges = await _firestore
          .collection('challenges')
          .where('status', isEqualTo: 'pending')
          .where('timestamp',
              isLessThan: Timestamp.fromDate(
                  DateTime.now().subtract(Duration(hours: 24))))
          .get();

      for (var doc in oldChallenges.docs) {
        await doc.reference.delete();
      }
      print('Nettoyage terminé: ${oldChallenges.docs.length} défis supprimés');
    } catch (e) {
      print('Erreur lors du nettoyage des anciens défis: $e');
    }
  }
}
