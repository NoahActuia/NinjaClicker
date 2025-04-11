import 'package:cloud_firestore/cloud_firestore.dart';

class NinjaSimple {
  final String id;
  final String userId;
  final String name;
  int xp;
  int level;

  NinjaSimple({
    required this.id,
    required this.userId,
    required this.name,
    this.xp = 0,
    this.level = 1,
  });

  // Depuis Firestore
  factory NinjaSimple.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NinjaSimple(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      xp: data['xp'] ?? 0,
      level: data['level'] ?? 1,
    );
  }

  // Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'xp': xp,
      'level': level,
    };
  }
}
