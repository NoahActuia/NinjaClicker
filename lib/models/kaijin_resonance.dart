import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant la relation entre un Kaijin et une Résonance
class KaijinResonance {
  final String id; // ID unique de la relation
  final String kaijinId; // ID du kaijin
  final String resonanceId; // ID de la résonance
  final int linkLevel; // Niveau de lien avec cette résonance
  final bool isUnlocked; // Si la résonance est débloquée
  final DateTime? unlockedAt; // Date de déblocage

  KaijinResonance({
    required this.id,
    required this.kaijinId,
    required this.resonanceId,
    this.linkLevel = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  // Construction à partir de Firestore
  factory KaijinResonance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return KaijinResonance(
      id: doc.id,
      kaijinId: data['kaijinId'] ?? '',
      resonanceId: data['resonanceId'] ?? '',
      linkLevel: data['linkLevel'] ?? 0,
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'kaijinId': kaijinId,
      'resonanceId': resonanceId,
      'linkLevel': linkLevel,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }
}
