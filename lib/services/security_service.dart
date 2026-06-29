import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service centralisé pour les contrôles d'autorisation côté client.
/// Complète les Firestore Security Rules (défense en profondeur).
class SecurityService {
  SecurityService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static void requireAuthenticated() {
    if (_auth.currentUser == null) {
      throw SecurityException('Utilisateur non authentifié');
    }
  }

  static void requireEmailVerified() {
    requireAuthenticated();
    if (_auth.currentUser!.emailVerified != true) {
      throw SecurityException('Email non vérifié');
    }
  }

  static void requireOwnership(String resourceUserId) {
    requireAuthenticated();
    if (_auth.currentUser!.uid != resourceUserId) {
      throw SecurityException('Accès non autorisé à cette ressource');
    }
  }

  /// Vérifie que le kaijin appartient à l'utilisateur connecté.
  static Future<void> requireKaijinOwnership(String kaijinId) async {
    requireEmailVerified();
    final doc = await _firestore.collection('kaijins').doc(kaijinId).get();
    if (!doc.exists) {
      throw SecurityException('Kaijin introuvable');
    }
    final userId = doc.data()?['userId'] as String?;
    if (userId != _auth.currentUser!.uid) {
      throw SecurityException('Ce personnage ne vous appartient pas');
    }
  }

  /// Vérifie que l'utilisateur est bien la cible d'un défi.
  static Future<void> requireChallengeTarget(
    String challengeId,
    String expectedUserId,
  ) async {
    requireEmailVerified();
    final doc =
        await _firestore.collection('challenges').doc(challengeId).get();
    if (!doc.exists) {
      throw SecurityException('Défi introuvable');
    }
    final targetId = doc.data()?['targetId'] as String?;
    if (targetId != expectedUserId) {
      throw SecurityException('Vous n\'êtes pas autorisé à répondre à ce défi');
    }
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => message;
}
