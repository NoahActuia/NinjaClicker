import 'package:cloud_firestore/cloud_firestore.dart';

class Technique {
  final String id;
  final String name;
  final String description;
  final String type; // 'active', 'auto', 'passive', 'simple'
  final String? affinity; // 'Flux', 'Fracture', 'Sceau', 'Dérive', 'Frappe'
  final int cost_kai;
  final int cooldown; // En tours (pas en secondes)
  final int damage; // Valeur de base des dégâts
  final String? condition_generated; // Condition appliquée à la cible
  final String? trigger_condition; // Déclencheur nécessaire (pour les autos)
  final String? unlock_type; // 'naturelle', 'affinité', 'héritage', etc.
  final Map<String, dynamic>?
      scaling_json; // Progression des effets selon le niveau
  final int xp_unlock_cost; // Coût en XP pour le premier déblocage
  final int base_upgrade_cost; // Coût XP de montée au niveau 1
  final int max_level; // Niveau maximum de cette technique
  int level = 0;

  // Propriété privée pour le son
  final String _sound;

  // Propriétés de rétrocompatibilité
  String get nom => name;
  int get cout => cost_kai;
  int get puissanceParSeconde => damage;
  int get powerPerSecond => damage;
  int get cost => cost_kai;
  int get kaiCost => cost_kai;
  String get sound => _sound; // Utilise la propriété privée maintenant
  String get effect => condition_generated ?? "damage";
  String? get trigger => trigger_condition;
  String? get conditionGenerated => condition_generated;
  Map<String, dynamic>? get effectDetails => scaling_json;
  int get niveau => level;
  set niveau(int value) => level = value;
  bool get isDefault => true; // Par défaut pour la rétrocompatibilité

  Technique({
    required this.id,
    required this.name,
    required this.description,
<<<<<<< HEAD
    this.cost = 0,
    this.powerPerSecond = 0,
    this.sound = '',
=======
>>>>>>> 60c4a95a071637747a4098e65ba3a7e233cd603a
    required this.type,
    this.affinity,
    required this.cost_kai,
    required this.cooldown,
    required this.damage,
    this.condition_generated,
    this.trigger_condition,
    this.unlock_type = "naturelle",
    this.scaling_json,
    this.xp_unlock_cost = 500,
    this.base_upgrade_cost = 200,
    this.max_level = 10,
    this.level = 0,
    String? sound,
  }) : _sound = sound ?? "technique_sound.mp3";

  // Constructeur de compatibilité pour l'ancien code
  factory Technique.compat({
    String id = '',
    required String nom,
    required String description,
<<<<<<< HEAD
    int cout = 0,
    int puissanceParSeconde = 0,
    String son = '',
=======
>>>>>>> 60c4a95a071637747a4098e65ba3a7e233cd603a
    String type = 'active',
    String? affinity,
    int cout = 50,
    int cooldown = 3,
    int damage = 100,
    String? condition_generated,
    String? trigger_condition,
    String? unlock_type = "naturelle",
    Map<String, dynamic>? scaling_json,
    int xp_unlock_cost = 500,
    int base_upgrade_cost = 200,
    int max_level = 10,
    int niveau = 0,
    String? sound,
  }) {
    return Technique(
      id: id,
      name: nom,
      description: description,
      type: type,
      affinity: affinity,
      cost_kai: cout,
      cooldown: cooldown,
      damage: damage,
      condition_generated: condition_generated,
      trigger_condition: trigger_condition,
      unlock_type: unlock_type,
      scaling_json: scaling_json,
      xp_unlock_cost: xp_unlock_cost,
      base_upgrade_cost: base_upgrade_cost,
      max_level: max_level,
      level: niveau,
      sound: sound,
    );
  }

  // Depuis Firestore
  factory Technique.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Technique(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
<<<<<<< HEAD
      cost: data['cost'] as int? ?? 0,
      powerPerSecond: data['powerPerSecond'] as int? ?? 0,
      sound: data['sound'] as String? ?? '',
      type: data['type'] ?? 'auto',
      trigger: data['trigger'],
      effect: data['effect'] ?? 'damage',
      chakraCost: data['chakraCost'] ?? 0,
      cooldown: data['cooldown'] ?? 0,
      animation: data['animation'],
      isDefault: data['isDefault'] ?? false,
      level: data['level'] ?? 0,
=======
      type: data['type'] ?? 'active',
>>>>>>> 60c4a95a071637747a4098e65ba3a7e233cd603a
      affinity: data['affinity'],
      cost_kai: data['cost_kai'] ?? data['cost'] ?? data['kaiCost'] ?? 50,
      cooldown: data['cooldown'] ?? 3,
      damage: data['damage'] ?? data['powerPerSecond'] ?? 100,
      condition_generated:
          data['condition_generated'] ?? data['conditionGenerated'],
      trigger_condition: data['trigger_condition'] ?? data['trigger'],
      unlock_type: data['unlock_type'] ?? 'naturelle',
      scaling_json: data['scaling_json'] ??
          data['effectDetails'] as Map<String, dynamic>?,
      xp_unlock_cost: data['xp_unlock_cost'] ?? 500,
      base_upgrade_cost: data['base_upgrade_cost'] ?? 200,
      max_level: data['max_level'] ?? 10,
      level: data['level'] ?? 0,
      sound: data['sound'],
    );
  }

  // Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'affinity': affinity,
      'cost_kai': cost_kai,
      'cooldown': cooldown,
      'damage': damage,
      'condition_generated': condition_generated,
      'trigger_condition': trigger_condition,
      'unlock_type': unlock_type,
      'scaling_json': scaling_json,
      'xp_unlock_cost': xp_unlock_cost,
      'base_upgrade_cost': base_upgrade_cost,
      'max_level': max_level,
      'level': level,
      'isDefault': isDefault,
      'sound': _sound,
    };
  }

  // Rétrocompatibilité avec l'ancien modèle
  Map<String, dynamic> toJson() {
    return {
      ...toFirestore(),
      'id': id,
      'nom': name,
      'cout': cost_kai,
      'puissanceParSeconde': damage,
      'powerPerSecond': damage,
      'cost': cost_kai,
      'son': sound,
      'niveau': level,
      'effect': effect,
      'kaiCost': kaiCost,
      'trigger': trigger_condition,
      'conditionGenerated': condition_generated,
      'effectDetails': scaling_json,
    };
  }

  // Rétrocompatibilité avec l'ancien modèle
  factory Technique.fromJson(Map<String, dynamic> json) {
    return Technique(
      id: json['id'] ?? '',
      name: json['nom'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
<<<<<<< HEAD
      cost: json['cout'] as int? ?? 0,
      powerPerSecond: json['puissanceParSeconde'] as int? ?? 0,
      sound: json['son'] as String? ?? '',
      type: json['type'] ?? 'auto',
      trigger: json['trigger'],
      effect: json['effect'] ?? 'damage',
      chakraCost: json['chakraCost'] ?? 50,
      cooldown: json['cooldown'] ?? 1,
      animation: json['animation'],
      isDefault: json['isDefault'] ?? false,
      level: json['niveau'] ?? json['level'] ?? 0,
=======
      type: json['type'] ?? 'active',
>>>>>>> 60c4a95a071637747a4098e65ba3a7e233cd603a
      affinity: json['affinity'],
      cost_kai: json['cout'] ??
          json['cost'] ??
          json['cost_kai'] ??
          json['kaiCost'] ??
          50,
      cooldown: json['cooldown'] ?? 3,
      damage: json['puissanceParSeconde'] ??
          json['damage'] ??
          json['powerPerSecond'] ??
          100,
      condition_generated:
          json['condition_generated'] ?? json['conditionGenerated'],
      trigger_condition: json['trigger_condition'] ?? json['trigger'],
      unlock_type: json['unlock_type'] ?? 'naturelle',
      scaling_json: json['scaling_json'] ??
          json['effectDetails'] as Map<String, dynamic>?,
      xp_unlock_cost: json['xp_unlock_cost'] ?? 500,
      base_upgrade_cost: json['base_upgrade_cost'] ?? 200,
      max_level: json['max_level'] ?? 10,
      level: json['niveau'] ?? json['level'] ?? 0,
      sound: json['son'] ?? json['sound'],
    );
  }

  // Calcul du coût d'amélioration en fonction du niveau actuel
  int getUpgradeCost() {
    if (level >= max_level) return 0; // Coût 0 si niveau max atteint

    // Formule de calcul : coût de base + (coût de base * niveau actuel * 0.5)
    return base_upgrade_cost + (base_upgrade_cost * level * 0.5).round();
  }
}
