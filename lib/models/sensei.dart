import 'package:cloud_firestore/cloud_firestore.dart';

class Sensei {
  final String id;
  final String name;
  final String description;
  final String image;
  final int baseCost;
  final int xpPerSecond;
  final double costMultiplier;
  final bool isDefault;
  int level;
  int quantity;

  Sensei({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.baseCost,
    required this.xpPerSecond,
    this.costMultiplier = 1.5,
    this.isDefault = false,
    this.level = 1,
    this.quantity = 0,
  });

  // Calculer le coût actuel basé sur la quantité déjà achetée
  int getCurrentCost() {
    return (baseCost * (costMultiplier * quantity)).toInt();
  }

  // Calculer l'XP générée par seconde
  int getTotalXpPerSecond() {
    return xpPerSecond * level * quantity;
  }

  // Depuis Firestore
  factory Sensei.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sensei(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      baseCost: data['baseCost'] ?? 0,
      xpPerSecond: data['xpPerSecond'] ?? 0,
      costMultiplier: data['costMultiplier'] ?? 1.5,
      isDefault: data['isDefault'] ?? false,
      level: data['level'] ?? 1,
      quantity: data['quantity'] ?? 0,
    );
  }

  // Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'baseCost': baseCost,
      'xpPerSecond': xpPerSecond,
      'costMultiplier': costMultiplier,
      'isDefault': isDefault,
      'level': level,
      'quantity': quantity,
    };
  }

  // Pour la compatibilité
  Map<String, dynamic> toJson() {
    return toFirestore();
  }

  // Pour la compatibilité
  factory Sensei.fromJson(Map<String, dynamic> json) {
    return Sensei(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      baseCost: json['baseCost'] ?? 0,
      xpPerSecond: json['xpPerSecond'] ?? 0,
      costMultiplier: json['costMultiplier'] ?? 1.5,
      isDefault: json['isDefault'] ?? false,
      level: json['level'] ?? 1,
      quantity: json['quantity'] ?? 0,
    );
  }
}
