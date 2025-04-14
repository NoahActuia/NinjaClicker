import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant la relation entre un Ninja et une Technique (table pivot)
class NinjaTechnique {
  final String id; // ID unique de la relation
  final String ninjaId; // ID du ninja
  final String techniqueId; // ID de la technique
  final int level; // Niveau de maîtrise de la technique par ce ninja
  final bool isActive; // Si la technique est active/disponible pour ce ninja
  final DateTime? acquiredAt; // Date d'acquisition de la technique

  NinjaTechnique({
    required this.id,
    required this.ninjaId,
    required this.techniqueId,
    this.level = 1,
    this.isActive = true,
    this.acquiredAt,
  });

  // Construction à partir de Firestore
  factory NinjaTechnique.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NinjaTechnique(
      id: doc.id,
      ninjaId: data['ninjaId'] ?? '',
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
      'ninjaId': ninjaId,
      'techniqueId': techniqueId,
      'level': level,
      'isActive': isActive,
      'acquiredAt': acquiredAt != null ? Timestamp.fromDate(acquiredAt!) : null,
    };
  }
}
