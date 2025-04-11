import 'package:cloud_firestore/cloud_firestore.dart';

class Technique {
  final String id;
  final String name;
  final String description;
  final int cost;
  final int powerPerSecond;
  final String sound;
  final String type; // 'special' ou 'auto'
  final String? trigger; // condition pour techniques auto
  final String effect; // 'damage', 'push', 'stun', etc.
  final int chakraCost;
  final int cooldown;
  final String? animation;
  final bool isDefault;
  int level = 0;

  // Propriétés de compatibilité
  String get nom => name;
  int get cout => cost;
  int get puissanceParSeconde => powerPerSecond;
  String get son => sound;
  int get niveau => level;
  set niveau(int value) => level = value;

  Technique({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.powerPerSecond,
    required this.sound,
    required this.type,
    this.trigger,
    required this.effect,
    required this.chakraCost,
    required this.cooldown,
    this.animation,
    this.isDefault = false,
    this.level = 0,
  });

  // Constructeur de compatibilité pour l'ancien code
  factory Technique.compat({
    String id = '',
    required String nom,
    required String description,
    required int cout,
    required int puissanceParSeconde,
    required String son,
    String type = 'special',
    String? trigger,
    String effect = 'damage',
    int chakraCost = 50,
    int cooldown = 1,
    String? animation,
    bool isDefault = false,
    int niveau = 0,
  }) {
    return Technique(
      id: id,
      name: nom,
      description: description,
      cost: cout,
      powerPerSecond: puissanceParSeconde,
      sound: son,
      type: type,
      trigger: trigger,
      effect: effect,
      chakraCost: chakraCost,
      cooldown: cooldown,
      animation: animation,
      isDefault: isDefault,
      level: niveau,
    );
  }

  // Depuis Firestore
  factory Technique.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Technique(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      cost: data['cost'] ?? 0,
      powerPerSecond: data['powerPerSecond'] ?? 0,
      sound: data['sound'] ?? '',
      type: data['type'] ?? 'auto',
      trigger: data['trigger'],
      effect: data['effect'] ?? 'damage',
      chakraCost: data['chakraCost'] ?? 0,
      cooldown: data['cooldown'] ?? 0,
      animation: data['animation'],
      isDefault: data['isDefault'] ?? false,
      level: data['level'] ?? 0,
    );
  }

  // Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'cost': cost,
      'powerPerSecond': powerPerSecond,
      'sound': sound,
      'type': type,
      'trigger': trigger,
      'effect': effect,
      'chakraCost': chakraCost,
      'cooldown': cooldown,
      'animation': animation,
      'isDefault': isDefault,
      'level': level,
    };
  }

  // Rétrocompatibilité avec l'ancien modèle
  Map<String, dynamic> toJson() {
    return {
      ...toFirestore(),
      'nom': name,
      'cout': cost,
      'puissanceParSeconde': powerPerSecond,
      'son': sound,
      'niveau': level,
    };
  }

  // Rétrocompatibilité avec l'ancien modèle
  factory Technique.fromJson(Map<String, dynamic> json) {
    return Technique(
      id: json['id'] ?? '',
      name: json['nom'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      cost: json['cout'] ?? json['cost'] ?? 0,
      powerPerSecond:
          json['puissanceParSeconde'] ?? json['powerPerSecond'] ?? 0,
      sound: json['son'] ?? json['sound'] ?? '',
      type: json['type'] ?? 'auto',
      trigger: json['trigger'],
      effect: json['effect'] ?? 'damage',
      chakraCost: json['chakraCost'] ?? 50,
      cooldown: json['cooldown'] ?? 1,
      animation: json['animation'],
      isDefault: json['isDefault'] ?? false,
      level: json['niveau'] ?? json['level'] ?? 0,
    );
  }
}
