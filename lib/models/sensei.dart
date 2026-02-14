import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class Sensei {
  final String id;
  final String name;
  final String description;
  final String
      affinity; // Affinité du Kai (Flux, Fracture, Sceau, Dérive, Frappe)
  final String image;
  final double xpPerSecond;
  final int xpCostToUnlock;
  final int xpCostToUpgradeLink;
  final int maxLinkLevel;
  int linkLevel;
  bool isUnlocked;

  Sensei({
    required this.id,
    required this.name,
    required this.description,
    required this.affinity,
    required this.image,
    required this.xpPerSecond,
    required this.xpCostToUnlock,
    required this.xpCostToUpgradeLink,
    required this.maxLinkLevel,
    this.linkLevel = 0,
    this.isUnlocked = false,
  });

  // Pour l'affichage
  String getXpPerSecondFormatted() {
    double xps = getXpPerSecond();
    return xps.toStringAsFixed(3);
  }

  // Calcul du revenu d'XP par seconde actuel
  double getXpPerSecond() {
    if (!isUnlocked) return 0;

    int effectiveLinkLevel = isUnlocked ? math.max(linkLevel, 1) : 0;
    double bonusMultiplier = _getBonusMultiplier();
    double totalMultiplier = 1 + (bonusMultiplier * (effectiveLinkLevel - 1));

    return xpPerSecond * totalMultiplier;
  }

  // Calcule la valeur potentielle de XP/sec (pour l'affichage des senseis non débloqués)
  double getPotentialXpPerSecond() {
    return xpPerSecond;
  }

  // Formatage pour l'affichage potentiel
  String getPotentialXpPerSecondFormatted() {
    double xps = getPotentialXpPerSecond();
    return xps.toStringAsFixed(3);
  }

  // Multiplicateur de bonus basé sur le niveau max du sensei
  double _getBonusMultiplier() {
    switch (maxLinkLevel) {
      case 3: // Sensei Légendaire
        return 0.40; // +40% par niveau
      case 4: // Maître Sensei
        return 0.35; // +35% par niveau
      case 5: // Sensei Élite
        return 0.30; // +30% par niveau
      case 6: // Sensei Expert
        return 0.25; // +25% par niveau
      case 7: // Sensei Confirmé
        return 0.20; // +20% par niveau
      case 8: // Sensei Expérimenté
        return 0.18; // +18% par niveau
      default:
        return 0.20; // +20% par niveau
    }
  }

  // Calcul du coût pour améliorer au niveau suivant
  int getUpgradeCost() {
    double growthFactor =
        1.9; // Facteur légèrement plus élevé que les résonances
    double levelMultiplier = math.pow(growthFactor, linkLevel).toDouble();
    return (xpCostToUpgradeLink * levelMultiplier * (linkLevel + 1)).ceil();
  }

  // Vérifier si un lien peut être amélioré
  bool canUpgradeLink() {
    return isUnlocked && linkLevel < maxLinkLevel;
  }

  // Calculer la puissance apportée par ce sensei
  int calculatePower() {
    if (!isUnlocked) return 0;
    return (linkLevel * 30) + (getXpPerSecond() * 12).ceil();
  }

  // Depuis Firestore
  factory Sensei.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sensei(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      affinity: data['affinity'] ?? 'Neutre',
      image: data['image'] ?? '',
      xpPerSecond: (data['xpPerSecond'] ?? 0).toDouble(),
      xpCostToUnlock: data['xpCostToUnlock'] ?? 0,
      xpCostToUpgradeLink: data['xpCostToUpgradeLink'] ?? 0,
      maxLinkLevel: data['maxLinkLevel'] ?? 1,
      linkLevel: data['linkLevel'] ?? 0,
      isUnlocked: data['isUnlocked'] ?? false,
    );
  }

  // Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'affinity': affinity,
      'image': image,
      'xpPerSecond': xpPerSecond,
      'xpCostToUnlock': xpCostToUnlock,
      'xpCostToUpgradeLink': xpCostToUpgradeLink,
      'maxLinkLevel': maxLinkLevel,
      'linkLevel': linkLevel,
      'isUnlocked': isUnlocked,
    };
  }

  // Pour la sérialisation JSON
  Map<String, dynamic> toJson() {
    return toFirestore();
  }

  // Depuis JSON
  factory Sensei.fromJson(Map<String, dynamic> json) {
    return Sensei(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      affinity: json['affinity'] ?? 'Neutre',
      image: json['image'] ?? '',
      xpPerSecond: (json['xpPerSecond'] ?? 0).toDouble(),
      xpCostToUnlock: json['xpCostToUnlock'] ?? 0,
      xpCostToUpgradeLink: json['xpCostToUpgradeLink'] ?? 0,
      maxLinkLevel: json['maxLinkLevel'] ?? 1,
      linkLevel: json['linkLevel'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}
