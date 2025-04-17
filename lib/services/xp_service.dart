import 'dart:math' show pow, min;

/// Service qui gère tous les calculs liés à l'XP, aux niveaux, et au formatage
class XpService {
  static final XpService _instance = XpService._internal();
  factory XpService() => _instance;

  // Constantes pour le calcul du niveau
  final int baseXPForLevel = 100;
  final double levelScalingFactor = 1.5;

  XpService._internal();

  // Calculer l'XP nécessaire pour le niveau suivant
  int calculateXPForNextLevel(int currentLevel) {
    return (baseXPForLevel * pow(currentLevel, levelScalingFactor)).toInt();
  }

  // Calculer le niveau en fonction de l'XP totale accumulée depuis le début
  int calculatePlayerLevel(int totalLifetimeXp) {
    if (totalLifetimeXp <= 0) return 1;

    int level = 1;
    int xpForCurrentLevel = 0;

    while (true) {
      int xpForThisLevel = calculateXPForNextLevel(level);
      if (xpForCurrentLevel + xpForThisLevel > totalLifetimeXp) {
        break;
      }
      xpForCurrentLevel += xpForThisLevel;
      level++;
    }

    return level;
  }

  // Calculer l'XP restante pour le niveau suivant
  int getXPForNextLevel(int currentLevel) {
    return calculateXPForNextLevel(currentLevel);
  }

  // Calculer le pourcentage de progression vers le niveau suivant
  double calculateLevelProgress(int totalLifetimeXp) {
    final int currentLevel = calculatePlayerLevel(totalLifetimeXp);
    final int xpForCurrentLevel = calculateTotalXpForLevel(currentLevel - 1);
    final int xpForNextLevel = calculateXPForNextLevel(currentLevel);

    final int xpInCurrentLevel = totalLifetimeXp - xpForCurrentLevel;

    return (xpInCurrentLevel / xpForNextLevel) * 100;
  }

  // Calculer l'XP totale nécessaire pour atteindre un niveau donné
  int calculateTotalXpForLevel(int level) {
    if (level <= 1) return 0;

    int totalXp = 0;
    for (int i = 1; i < level; i++) {
      totalXp += calculateXPForNextLevel(i);
    }

    return totalXp;
  }

  // Méthode pour formater les grands nombres
  String formatNumber(num number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // Calcul de l'XP accumulée pendant une période de temps
  int calculateOfflineXpGain(double xpPerSecond, int secondsElapsed) {
    return (xpPerSecond * secondsElapsed).ceil();
  }

  // Calcul de l'XP hors-ligne (capped à 24 heures)
  int calculateOfflineXp(double xpPerSecond, DateTime lastConnected) {
    if (xpPerSecond <= 0) return 0;

    final now = DateTime.now();
    final difference = now.difference(lastConnected);

    // Limiter à 24 heures maximum
    final seconds = min(difference.inSeconds, 24 * 60 * 60);

    return (xpPerSecond * seconds).toInt();
  }
}
