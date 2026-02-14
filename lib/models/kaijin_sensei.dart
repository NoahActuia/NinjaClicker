import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant la relation entre un Kaijin et un Sensei
class KaijinSensei {
  final String id; // ID unique de la relation
  final String kaijinId; // ID du kaijin
  final String senseiId; // ID du sensei
  final int linkLevel; // Niveau de lien avec ce sensei
  final bool isUnlocked; // Si le sensei est débloqué
  final DateTime? unlockedAt; // Date de déblocage

  KaijinSensei({
    required this.id,
    required this.kaijinId,
    required this.senseiId,
    this.linkLevel = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  // Construction à partir de Firestore
  factory KaijinSensei.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return KaijinSensei(
      id: doc.id,
      kaijinId: data['kaijinId'] ?? '',
      senseiId: data['senseiId'] ?? '',
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
      'senseiId': senseiId,
      'linkLevel': linkLevel,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }
}
