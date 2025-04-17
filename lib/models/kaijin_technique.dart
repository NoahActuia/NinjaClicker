import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant la relation entre un Kaijin et une Technique (table pivot)
class KaijinTechnique {
  final String id; // ID unique de la relation
  final String kaijinId; // ID du kaijin
  final String techniqueId; // ID de la technique
  final int level; // Niveau de maîtrise de la technique par ce kaijin
  final bool isActive; // Si la technique est active/disponible pour ce kaijin
  final DateTime? acquiredAt; // Date d'acquisition de la technique

  KaijinTechnique({
    required this.id,
    required this.kaijinId,
    required this.techniqueId,
    this.level = 1,
    this.isActive = true,
    this.acquiredAt,
  });

  // Construction à partir de Firestore
  factory KaijinTechnique.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return KaijinTechnique(
      id: doc.id,
      kaijinId: data['kaijinId'] ?? '',
      techniqueId: data['techniqueId'] ?? '',
      level: data['level'] ?? 1,
      isActive: data['isActive'] ?? true,
      acquiredAt: data['acquiredAt'] != null
          ? (data['acquiredAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'kaijinId': kaijinId,
      'techniqueId': techniqueId,
      'level': level,
      'isActive': isActive,
      'acquiredAt': acquiredAt != null ? Timestamp.fromDate(acquiredAt!) : null,
    };
  }
}
