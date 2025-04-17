import '../models/technique.dart';
import '../models/sensei.dart';
import '../models/resonance.dart';

/// Service qui gère tous les calculs liés à la puissance du joueur
class PowerService {
  static final PowerService _instance = PowerService._internal();
  factory PowerService() => _instance;

  PowerService._internal();

  // Calculer la puissance basée sur les techniques, senseis et résonances
  int calculateTotalPower(List<Technique> techniques, List<Sensei> senseis,
      List<Resonance> resonances, int playerLevel) {
    int techniquePower = calculateTechniquePower(techniques);
    int senseiPower = calculateSenseiPower(senseis);
    int resonancePower = calculateResonancePower(resonances);
    int levelPower = calculateLevelPower(playerLevel);

    return techniquePower + senseiPower + resonancePower + levelPower;
  }

  // Calculer la puissance basée uniquement sur les techniques
  int calculateTechniquePower(List<Technique> techniques) {
    int totalTechniqueLevels = 0;
    int activeTechniques = 0;

    for (var technique in techniques) {
      if (technique.niveau > 0) {
        totalTechniqueLevels += technique.niveau;
        activeTechniques++;
      }
    }

    if (activeTechniques == 0) {
      return 0;
    }

    int avgTechniqueLevel = totalTechniqueLevels ~/ activeTechniques;
    int techniquePower = (avgTechniqueLevel * 15).toInt();
    techniquePower += activeTechniques * 5;

    return techniquePower;
  }

  // Calculer la puissance basée sur les senseis
  int calculateSenseiPower(List<Sensei> senseis) {
    int totalPower = 0;

    for (var sensei in senseis) {
      if (sensei.quantity > 0) {
        // Formule : (niveau * 10) * (quantité)^0.5
        totalPower += (sensei.level * 10) * (sensei.quantity * 0.5).ceil();
      }
    }

    return totalPower;
  }

  // Calculer la puissance basée sur les résonances
  int calculateResonancePower(List<Resonance> resonances) {
    int totalPower = 0;

    for (var resonance in resonances) {
      if (resonance.isUnlocked) {
        // Puissance basée sur le niveau de lien et l'XP par seconde
        int resonancePower = (resonance.linkLevel * 25) +
            (resonance.getXpPerSecond() * 10).ceil();
        totalPower += resonancePower;
      }
    }

    return totalPower;
  }

  // Calculer la puissance basée sur le niveau du joueur
  int calculateLevelPower(int playerLevel) {
    // Formule simple : niveau² * 5
    return playerLevel * playerLevel * 5;
  }

  // Prédire l'augmentation de puissance après amélioration
  int predictPowerIncrease(String upgradeType, dynamic item, int currentPower) {
    switch (upgradeType) {
      case 'technique':
        Technique technique = item;
        technique.niveau++;
        int newPower = calculateTechniquePower([technique]);
        technique.niveau--;
        return newPower - currentPower;

      case 'sensei':
        Sensei sensei = item;
        sensei.level++;
        int newPower = calculateSenseiPower([sensei]);
        sensei.level--;
        return newPower - currentPower;

      case 'resonance':
        Resonance resonance = item;
        resonance.linkLevel++;
        int newPower = calculateResonancePower([resonance]);
        resonance.linkLevel--;
        return newPower - currentPower;

      default:
        return 0;
    }
  }
}
