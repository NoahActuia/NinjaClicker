import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as Math;

class Resonance {
  final String id;
  final String name;
  final String description;
  final double xpPerSecond;
  final int xpCostToUnlock;
  final int xpCostToUpgradeLink;
  final int maxLinkLevel;
  int linkLevel;
  bool isUnlocked;

  Resonance({
    required this.id,
    required this.name,
    required this.description,
    required this.xpPerSecond,
    required this.xpCostToUnlock,
    required this.xpCostToUpgradeLink,
    required this.maxLinkLevel,
    this.linkLevel = 0,
    this.isUnlocked = false,
  });

  // Pour l'affichage
  String getXpPerSecondFormatted() {
    // Utiliser getXpPerSecond() au lieu de xpPerSecond pour avoir la valeur réelle
    double xps = getXpPerSecond();
    // Afficher la valeur exacte avec 3 décimales pour plus de précision
    return xps.toStringAsFixed(3);
  }

  // Format spécial pour l'affichage (conservé pour référence)
  String getLegacyXpPerSecondFormatted() {
    double xps = getXpPerSecond();
    return xps < 1
        ? '${(xps * 10).toStringAsFixed(1)}' // Format décimal pour petites valeurs (multiplié par 10)
        : '${xps.ceil()}'; // Arrondi pour valeurs plus grandes
  }

  // Calcul du revenu d'XP par heure actuel (maintenu pour compatibilité)
  int getCurrentXpPerHour() {
    // Retourner 0 si la résonance n'est pas débloquée
    if (!isUnlocked) return 0;

    // Utiliser un niveau minimum de 1 pour les résonances débloquées
    int effectiveLinkLevel = isUnlocked ? Math.max(linkLevel, 1) : 0;

    // Nouvelles formules de bonus par niveau, en fonction du type de résonance
    double bonusMultiplier;

    // Déterminer le multiplicateur selon le niveau max (pour identifier le type de résonance)
    switch (maxLinkLevel) {
      case 3: // Éclat Résonant
        bonusMultiplier = 0.35; // +35% par niveau
        break;
      case 4: // Pierre d'Éveil
        bonusMultiplier = 0.30; // +30% par niveau
        break;
      case 5: // Totem Harmonié
        bonusMultiplier = 0.25; // +25% par niveau
        break;
      case 6: // Sceau Symbiotique
        bonusMultiplier = 0.20; // +20% par niveau
        break;
      case 7: // Nexus Personnel
        bonusMultiplier = 0.15; // +15% par niveau
        break;
      default: // Cas par défaut
        bonusMultiplier = 0.20; // +20% par niveau
    }

    // Appliquer le bonus seulement si le niveau est > 0
    double totalMultiplier = 1 + (bonusMultiplier * (effectiveLinkLevel - 1));
    return (xpPerSecond * 3600 * totalMultiplier).ceil();
  }

  double getXpPerSecond() {
    // Retourner 0 si la résonance n'est pas débloquée
    if (!isUnlocked) return 0;

    // Utiliser un niveau minimum de 1 pour les résonances débloquées
    int effectiveLinkLevel = isUnlocked ? Math.max(linkLevel, 1) : 0;

    // Même logique que getCurrentXpPerHour mais pour XP/sec
    double bonusMultiplier;

    switch (maxLinkLevel) {
      case 3: // Éclat Résonant
        bonusMultiplier = 0.35; // +35% par niveau
        break;
      case 4: // Pierre d'Éveil
        bonusMultiplier = 0.30; // +30% par niveau
        break;
      case 5: // Totem Harmonié
        bonusMultiplier = 0.25; // +25% par niveau
        break;
      case 6: // Sceau Symbiotique
        bonusMultiplier = 0.20; // +20% par niveau
        break;
      case 7: // Nexus Personnel
        bonusMultiplier = 0.15; // +15% par niveau
        break;
      default:
        bonusMultiplier = 0.20;
    }

    // Appliquer le bonus seulement si le niveau est > 0
    double totalMultiplier = 1 + (bonusMultiplier * (effectiveLinkLevel - 1));
    return xpPerSecond * totalMultiplier;
  }

  // Calcule la valeur potentielle de XP/sec (utilisé pour l'affichage des résonances non débloquées)
  double getPotentialXpPerSecond() {
    // Cette méthode retourne la valeur de base sans tenir compte du déverrouillage
    return xpPerSecond;
  }

  // Formatage pour l'affichage potentiel
  String getPotentialXpPerSecondFormatted() {
    double xps = getPotentialXpPerSecond();
    // Afficher la valeur exacte avec 3 décimales pour plus de précision
    return xps.toStringAsFixed(3);
  }

  // Calcul du coût pour améliorer au niveau suivant
  int getUpgradeCost() {
    // Nouvelle formule exponentielle beaucoup plus agressive:
    // coût de base × 1.8^niveau × (niveau+1)
    // Cette formule fait augmenter drastiquement le coût à chaque niveau

    // Facteur de croissance (plus il est élevé, plus la progression est difficile)
    double growthFactor = 1.8;

    // Facteur multiplicatif basé sur le niveau actuel et le facteur de croissance
    double levelMultiplier = Math.pow(growthFactor, linkLevel).toDouble();

    // Coût final arrondi à l'entier supérieur
    return (xpCostToUpgradeLink * levelMultiplier * (linkLevel + 1)).ceil();
  }

  // Vérifier si un lien peut être amélioré
  bool canUpgradeLink() {
    return isUnlocked && linkLevel < maxLinkLevel;
  }

  // Depuis Firestore
  factory Resonance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Resonance(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      xpPerSecond: data['xpPerSecond'] ?? 0,
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
  factory Resonance.fromJson(Map<String, dynamic> json) {
    return Resonance(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      xpPerSecond: json['xpPerSecond'] ?? 0,
      xpCostToUnlock: json['xpCostToUnlock'] ?? 0,
      xpCostToUpgradeLink: json['xpCostToUpgradeLink'] ?? 0,
      maxLinkLevel: json['maxLinkLevel'] ?? 1,
      linkLevel: json['linkLevel'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}
