import 'dart:math';
import '../../models/technique.dart';

/// Classe pour générer des ennemis d'entraînement
class TrainingEnemyGenerator {
  final Random _random = Random();

  /// Génère une liste de techniques pour l'ennemi en fonction du niveau de difficulté
  List<Technique> generateEnemyTechniques(String difficultyLevel) {
    int techniqueCount = _getTechniqueCount(difficultyLevel);
    List<Technique> techniques = [];

    // Liste des affinités disponibles
    final affinities = ['Flux', 'Fracture', 'Sceau', 'Dérive', 'Frappe'];

    // Générer les techniques
    for (int i = 0; i < techniqueCount; i++) {
      // Choisir une affinité aléatoire
      String affinity = affinities[_random.nextInt(affinities.length)];

      // Génération de technique basée sur l'affinité et le niveau
      techniques.add(_generateTechnique(
        id: 'enemy_technique_${i + 1}',
        affinity: affinity,
        difficultyLevel: difficultyLevel,
      ));
    }

    // Ajouter toujours une technique défensive et une offensive de base
    techniques.add(_generateDefensiveTechnique(difficultyLevel));
    techniques.add(_generateOffensiveTechnique(difficultyLevel));

    return techniques;
  }

  /// Obtient le nombre de techniques en fonction du niveau de difficulté
  int _getTechniqueCount(String difficultyLevel) {
    switch (difficultyLevel) {
      case 'Novice':
        return 1;
      case 'Adepte':
        return 2;
      case 'Maître':
        return 3;
      case 'Légendaire':
        return 4;
      default:
        return 1;
    }
  }

  /// Génère une technique spécifique en fonction de l'affinité et du niveau
  Technique _generateTechnique({
    required String id,
    required String affinity,
    required String difficultyLevel,
  }) {
    // Facteurs d'échelle basés sur la difficulté
    double damageFactor = _getDifficultyFactor(difficultyLevel);
    int cooldownBase = _getDifficultyCooldown(difficultyLevel);

    // Noms de techniques selon l'affinité
    String name = _getRandomTechniqueName(affinity);
    String description = _getRandomTechniqueDescription(affinity);

    // Valeurs de base de la technique
    int damage = (15 * damageFactor).round();
    int costKai = (10 * damageFactor).round();
    int cooldown = cooldownBase;

    // Déterminer si la technique génère une condition
    String? conditionGenerated;
    if (_random.nextDouble() < 0.3) {
      conditionGenerated = _getRandomCondition(affinity);
    }

    return Technique(
      id: id,
      name: name,
      description: description,
      type: 'active',
      affinity: affinity,
      cost_kai: costKai,
      cooldown: cooldown,
      damage: damage,
      condition_generated: conditionGenerated,
      unlock_type: 'naturelle',
    );
  }

  /// Génère une technique défensive
  Technique _generateDefensiveTechnique(String difficultyLevel) {
    double factor = _getDifficultyFactor(difficultyLevel);

    return Technique(
      id: 'enemy_defensive_technique',
      name: 'Bouclier du Kai',
      description: 'Crée une barrière protectrice qui réduit les dégâts reçus.',
      type: 'active',
      affinity: 'Sceau',
      cost_kai: (15 * factor).round(),
      cooldown: _getDifficultyCooldown(difficultyLevel) + 1,
      damage: 0,
      condition_generated: 'shield',
      unlock_type: 'naturelle',
    );
  }

  /// Génère une technique offensive
  Technique _generateOffensiveTechnique(String difficultyLevel) {
    double factor = _getDifficultyFactor(difficultyLevel);

    return Technique(
      id: 'enemy_offensive_technique',
      name: 'Frappe du Kai Concentré',
      description:
          'Une puissante attaque qui concentre le Kai pour maximiser les dégâts.',
      type: 'active',
      affinity: 'Frappe',
      cost_kai: (20 * factor).round(),
      cooldown: _getDifficultyCooldown(difficultyLevel),
      damage: (30 * factor).round(),
      unlock_type: 'naturelle',
    );
  }

  /// Obtient un facteur d'échelle basé sur la difficulté
  double _getDifficultyFactor(String difficultyLevel) {
    switch (difficultyLevel) {
      case 'Novice':
        return 0.8;
      case 'Adepte':
        return 1.0;
      case 'Maître':
        return 1.3;
      case 'Légendaire':
        return 1.8;
      default:
        return 1.0;
    }
  }

  /// Obtient la valeur de base du cooldown en fonction de la difficulté
  int _getDifficultyCooldown(String difficultyLevel) {
    switch (difficultyLevel) {
      case 'Novice':
        return 3;
      case 'Adepte':
        return 2;
      case 'Maître':
        return 2;
      case 'Légendaire':
        return 1;
      default:
        return 2;
    }
  }

  /// Obtient un nom aléatoire pour une technique en fonction de l'affinité
  String _getRandomTechniqueName(String affinity) {
    List<String> names = [];

    switch (affinity) {
      case 'Flux':
        names = [
          'Vague du Flux Éternel',
          'Courant du Kai Fluide',
          'Cascade de Résonance',
          'Torrent de l\'Essence',
          'Marée Temporelle',
        ];
        break;
      case 'Fracture':
        names = [
          'Fissure Dimensionnelle',
          'Éclat de Réalité Brisée',
          'Rupture du Voile',
          'Séisme du Kai Fracturé',
          'Déchirure de l\'Éther',
        ];
        break;
      case 'Sceau':
        names = [
          'Sceau des Anciens',
          'Barrière du Kai Stabilisé',
          'Prison des Âmes',
          'Domaine Protecteur',
          'Mur de Résistance',
        ];
        break;
      case 'Dérive':
        names = [
          'Dérive Fantomatique',
          'Pas de l\'Ombre Évasive',
          'Flou Temporel',
          'Danse du Mirage',
          'Distorsion de la Réalité',
        ];
        break;
      case 'Frappe':
        names = [
          'Frappe du Poing Écrasant',
          'Impact du Kai Condensé',
          'Percussion Foudroyante',
          'Assaut Dévastateur',
          'Choc de l\'Éclair Noir',
        ];
        break;
      default:
        names = ['Technique du Kai'];
    }

    return names[_random.nextInt(names.length)];
  }

  /// Obtient une description aléatoire pour une technique en fonction de l'affinité
  String _getRandomTechniqueDescription(String affinity) {
    List<String> descriptions = [];

    switch (affinity) {
      case 'Flux':
        descriptions = [
          'Manipule les courants du Kai pour créer une vague d\'énergie dévastatrice.',
          'Canalise le flux du Kai pour former un torrent qui submerge l\'adversaire.',
          'Transforme le Kai en une cascade d\'énergie pure qui érode les défenses.',
        ];
        break;
      case 'Fracture':
        descriptions = [
          'Crée une fissure dans la réalité qui déstabilise l\'adversaire.',
          'Fracture l\'espace entre les dimensions pour infliger des dégâts imprévisibles.',
          'Brise la structure du Kai environnant pour créer une onde de choc destructrice.',
        ];
        break;
      case 'Sceau':
        descriptions = [
          'Génère une barrière de Kai stabilisé qui absorbe les attaques ennemies.',
          'Scelle temporairement une partie du Kai adverse, réduisant sa puissance.',
          'Crée un domaine protecteur qui repousse les techniques adverses.',
        ];
        break;
      case 'Dérive':
        descriptions = [
          'Permet de se déplacer entre les flux du Kai, esquivant les attaques avec fluidité.',
          'Crée des illusions de Kai qui déroutent l\'adversaire.',
          'Manipule la perception du temps pour anticiper les mouvements adverses.',
        ];
        break;
      case 'Frappe':
        descriptions = [
          'Concentre le Kai dans les poings pour déchaîner une attaque dévastatrice.',
          'Frappe avec la force d\'un Kai condensé, capable de briser les défenses.',
          'Libère une explosion d\'énergie focalisée qui transperce les protections.',
        ];
        break;
      default:
        descriptions = ['Une technique qui manipule le Kai de façon unique.'];
    }

    return descriptions[_random.nextInt(descriptions.length)];
  }

  /// Obtient une condition aléatoire générée par la technique en fonction de l'affinité
  String _getRandomCondition(String affinity) {
    switch (affinity) {
      case 'Flux':
        return _random.nextBool() ? 'flood' : 'torrent';
      case 'Fracture':
        return _random.nextBool() ? 'fissure' : 'breach';
      case 'Sceau':
        return _random.nextBool() ? 'shield' : 'barrier';
      case 'Dérive':
        return _random.nextBool() ? 'dodge' : 'mirage';
      case 'Frappe':
        return _random.nextBool() ? 'stun' : 'shatter';
      default:
        return 'condition';
    }
  }
}
