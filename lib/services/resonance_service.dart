import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resonance.dart';
import '../models/ninja.dart';

class ResonanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer toutes les Résonances disponibles
  Future<List<Resonance>> getAllResonances() async {
    try {
      final snapshot = await _firestore.collection('resonances').get();
      return snapshot.docs.map((doc) => Resonance.fromFirestore(doc)).toList();
    } catch (e) {
      print('Erreur lors du chargement des Résonances: $e');
      return [];
    }
  }

  // Récupérer les Résonances d'un ninja spécifique
  Future<List<Resonance>> getNinjaResonances(String ninjaId) async {
    try {
      // Récupérer la relation ninja-résonance
      final relationSnapshot = await _firestore
          .collection('ninjaResonances')
          .where('ninjaId', isEqualTo: ninjaId)
          .get();

      if (relationSnapshot.docs.isEmpty) {
        return [];
      }

      // Extraire les IDs de Résonance et leurs niveaux
      final resonanceIds = <String>[];
      final resonanceLevels = <String, int>{};
      final unlockedResonances = <String, bool>{};

      for (var doc in relationSnapshot.docs) {
        final data = doc.data();
        final resonanceId = data['resonanceId'] as String;
        final linkLevel = data['linkLevel'] as int? ?? 0;
        final isUnlocked = data['isUnlocked'] as bool? ?? false;

        resonanceIds.add(resonanceId);
        resonanceLevels[resonanceId] = linkLevel;
        unlockedResonances[resonanceId] = isUnlocked;
      }

      // Récupérer les détails des Résonances
      final resonanceSnapshot = await _firestore
          .collection('resonances')
          .where(FieldPath.documentId, whereIn: resonanceIds)
          .get();

      return resonanceSnapshot.docs.map((doc) {
        final resonance = Resonance.fromFirestore(doc);
        resonance.linkLevel = resonanceLevels[resonance.id] ?? 0;
        resonance.isUnlocked = unlockedResonances[resonance.id] ?? false;
        return resonance;
      }).toList();
    } catch (e) {
      print('Erreur lors du chargement des Résonances du ninja: $e');
      return [];
    }
  }

  // Débloquer une nouvelle Résonance pour un ninja
  Future<bool> unlockResonance(String ninjaId, Resonance resonance) async {
    try {
      // Vérifier si la relation existe déjà
      final relationQuery = await _firestore
          .collection('ninjaResonances')
          .where('ninjaId', isEqualTo: ninjaId)
          .where('resonanceId', isEqualTo: resonance.id)
          .get();

      if (relationQuery.docs.isNotEmpty) {
        // Mettre à jour la relation existante
        await _firestore
            .collection('ninjaResonances')
            .doc(relationQuery.docs.first.id)
            .update({
          'isUnlocked': true,
          'linkLevel': 1,
        });
      } else {
        // Créer une nouvelle relation
        await _firestore.collection('ninjaResonances').add({
          'ninjaId': ninjaId,
          'resonanceId': resonance.id,
          'linkLevel': 1,
          'isUnlocked': true,
        });
      }

      return true;
    } catch (e) {
      print('Erreur lors du déblocage de la Résonance: $e');
      return false;
    }
  }

  // Améliorer le niveau de lien d'une Résonance
  Future<bool> upgradeResonanceLink(String ninjaId, Resonance resonance) async {
    try {
      // Trouver la relation
      final relationQuery = await _firestore
          .collection('ninjaResonances')
          .where('ninjaId', isEqualTo: ninjaId)
          .where('resonanceId', isEqualTo: resonance.id)
          .get();

      if (relationQuery.docs.isEmpty) {
        print('Relation ninja-résonance non trouvée');
        return false;
      }

      // Récupérer les données de la résonance directement depuis Firestore pour avoir les valeurs à jour
      final resonanceDoc =
          await _firestore.collection('resonances').doc(resonance.id).get();
      if (!resonanceDoc.exists) {
        print('Résonance non trouvée dans Firestore');
        return false;
      }

      final resonanceData = resonanceDoc.data();
      if (resonanceData == null) {
        print('Données de résonance invalides');
        return false;
      }

      // Récupérer le niveau maximal de la résonance
      final maxLinkLevel = resonanceData['maxLinkLevel'] as int? ?? 1;

      // Récupérer le niveau actuel de la relation
      final currentLinkLevel =
          relationQuery.docs.first.data()['linkLevel'] as int? ?? 0;

      // Vérifier que le niveau futur ne dépasse pas le maximum
      if (currentLinkLevel >= maxLinkLevel) {
        print(
            'Niveau maximum déjà atteint pour cette résonance: $currentLinkLevel / $maxLinkLevel');
        return false;
      }

      // S'assurer que le niveau n'est jamais supérieur au maximum
      final newLevel = (currentLinkLevel + 1) > maxLinkLevel
          ? maxLinkLevel
          : (currentLinkLevel + 1);

      // Mettre à jour le niveau de lien
      await _firestore
          .collection('ninjaResonances')
          .doc(relationQuery.docs.first.id)
          .update({
        'linkLevel': newLevel,
      });

      return true;
    } catch (e) {
      print('Erreur lors de l\'amélioration du lien de Résonance: $e');
      return false;
    }
  }

  // Calculer l'XP passive totale par seconde pour un ninja
  Future<double> calculateTotalPassiveXpPerSecond(String ninjaId) async {
    try {
      final resonances = await getNinjaResonances(ninjaId);
      double totalXpPerSecond = 0;

      for (var resonance in resonances) {
        if (resonance.isUnlocked) {
          totalXpPerSecond += resonance.getXpPerSecond();
        }
      }

      return totalXpPerSecond;
    } catch (e) {
      print('Erreur lors du calcul de l\'XP passive: $e');
      return 0;
    }
  }

  // Méthode maintenue pour compatibilité
  Future<int> calculateTotalPassiveXpPerHour(String ninjaId) async {
    try {
      double xpPerSecond = await calculateTotalPassiveXpPerSecond(ninjaId);
      return (xpPerSecond * 3600).ceil(); // Convertir en XP/heure
    } catch (e) {
      print('Erreur lors du calcul de l\'XP passive par heure: $e');
      return 0;
    }
  }

  // Calculer l'XP gagnée depuis la dernière connexion
  Future<int> calculateOfflineXp(String ninjaId, DateTime lastConnected) async {
    try {
      final resonances = await getNinjaResonances(ninjaId);
      if (resonances.isEmpty) return 0;

      // Calculer le temps écoulé en secondes depuis la dernière connexion
      final now = DateTime.now();
      final duration = now.difference(lastConnected);
      final secondsElapsed = duration.inSeconds;

      // Calculer l'XP totale par seconde
      double totalXpPerSecond = 0;
      for (var resonance in resonances) {
        if (resonance.isUnlocked) {
          totalXpPerSecond += resonance.getXpPerSecond();
        }
      }

      // Calculer l'XP gagnée pendant l'absence
      return (totalXpPerSecond * secondsElapsed).ceil();
    } catch (e) {
      print('Erreur lors du calcul de l\'XP hors-ligne: $e');
      return 0;
    }
  }

  // Initialiser les Résonances par défaut dans la base de données
  Future<void> initDefaultResonances() async {
    try {
      // Vérifier si des Résonances existent déjà
      final existing = await _firestore.collection('resonances').get();
      if (existing.docs.isNotEmpty) {
        print(
            'Les Résonances sont déjà initialisées (${existing.docs.length} trouvées)');
        return;
      }

      // Les Résonances par défaut à créer avec un équilibrage beaucoup plus difficile
      final defaultResonances = [
        {
          'name': 'Éclat Résonant',
          'description':
              'Premier fragment détecté. Flux d\'énergie très faible mais persistant. Cœur du système de Résonance Kai.',
          'xpPerSecond': 0.125, // Réduit à 0.125 XP/s (0.45 XP/h)
          'xpCostToUnlock': 500, // Augmenté de 250 à 500
          'xpCostToUpgradeLink': 600, // Augmenté de 150 à 600
          'maxLinkLevel': 3
        },
        {
          'name': 'Pierre d\'Éveil',
          'description':
              'Cristal fissuré captant le Kai environnant. Nécessite une focalisation constante pour maintenir sa stabilité.',
          'xpPerSecond': 0.25, // Réduit de 1.2 à 0.25 XP/s (0.9 XP/h)
          'xpCostToUnlock': 2500, // Augmenté de 600 à 2500
          'xpCostToUpgradeLink': 1500, // Augmenté de 300 à 1500
          'maxLinkLevel': 4
        },
        {
          'name': 'Totem Harmonié',
          'description':
              'Structure de méditation ancienne qui amplifie la résonance. Le Kai ambiant est canalisé à travers ses gravures.',
          'xpPerSecond': 0.5, // Réduit de 2.5 à 0.5 XP/s (1.8 XP/h)
          'xpCostToUnlock': 7500, // Augmenté de 1500 à 7500
          'xpCostToUpgradeLink': 3500, // Augmenté de 750 à 3500
          'maxLinkLevel': 5
        },
        {
          'name': 'Sceau Symbiotique',
          'description':
              'Lien stable et permanent avec une source puissante du Kai. Fusion partielle entre le Kaijin et l\'énergie primordiale.',
          'xpPerSecond': 1.0, // Réduit de 5.0 à 1.0 XP/s (3.6 XP/h)
          'xpCostToUnlock': 20000, // Augmenté de 3500 à 20000
          'xpCostToUpgradeLink': 10000, // Augmenté de 1500 à 10000
          'maxLinkLevel': 6
        },
        {
          'name': 'Nexus Personnel',
          'description':
              'Le Kaijin devient lui-même une source de Kai passive, générant un flux continu d\'énergie. Transcendance des limites physiques.',
          'xpPerSecond': 2.0, // Réduit de 10.0 à 2.0 XP/s (7.2 XP/h)
          'xpCostToUnlock': 50000, // Augmenté de 8000 à 50000
          'xpCostToUpgradeLink': 25000, // Augmenté de 3000 à 25000
          'maxLinkLevel': 7
        },
        // Nouvelles résonances de très haut niveau
        {
          'name': 'Cristal de Convergence',
          'description':
              'Artefact rarissime catalysant les courants du Kai dans un vortex de puissance. Requiert une maîtrise exceptionnelle pour stabiliser son flux.',
          'xpPerSecond': 4.0, // 14.4 XP/h
          'xpCostToUnlock': 125000,
          'xpCostToUpgradeLink': 60000,
          'maxLinkLevel': 8
        },
        {
          'name': 'Matrice d\'Ascension',
          'description':
              'Réseau complexe de liaisons Kai permettant d\'atteindre un état d\'harmonie parfaite. Les fluctuations dimensionnelles sont domptées et canalisées.',
          'xpPerSecond': 8.0, // 28.8 XP/h
          'xpCostToUnlock': 300000,
          'xpCostToUpgradeLink': 150000,
          'maxLinkLevel': 9
        },
        {
          'name': 'Cœur du Kairos',
          'description':
              'Le point de convergence ultime entre l\'âme du Kaijin et l\'essence même du temps fractionné. Seuls les plus grands maîtres peuvent l\'atteindre.',
          'xpPerSecond': 16.0, // 57.6 XP/h
          'xpCostToUnlock': 750000,
          'xpCostToUpgradeLink': 350000,
          'maxLinkLevel': 10
        }
      ];

      // Ajouter les Résonances à Firestore
      for (var resonance in defaultResonances) {
        await _firestore.collection('resonances').add(resonance);
      }

      print('Résonances par défaut initialisées avec succès');
    } catch (e) {
      print('Erreur lors de l\'initialisation des Résonances par défaut: $e');
    }
  }

  // Mettre à jour le Ninja avec l'XP passive calculée
  Future<void> updateNinjaWithPassiveXp(Ninja ninja) async {
    try {
      final totalXpPerSecond = await calculateTotalPassiveXpPerSecond(ninja.id);

      // Convertir en entier avec ceil() pour Firebase puisque passiveXp est un int dans le modèle Ninja
      final passiveXpInt = totalXpPerSecond;

      await _firestore.collection('ninjas').doc(ninja.id).update({
        'passiveXp': passiveXpInt,
        'lastConnected': DateTime.now().millisecondsSinceEpoch
      });

      // Mettre à jour l'objet ninja local également
      ninja.passiveXp = passiveXpInt;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'XP passive du ninja: $e');
    }
  }
}
