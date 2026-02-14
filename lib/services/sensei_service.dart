import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensei.dart';
import '../models/kaijin.dart';
import 'audio_service.dart';
import 'app_logger.dart';

class SenseiService {
  // Singleton pattern
  static final SenseiService _instance = SenseiService._internal();
  factory SenseiService() => _instance;
  SenseiService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioService _audioService = AudioService();

  // Récupérer tous les Senseis disponibles
  Future<List<Sensei>> getAllSenseis() async {
    try {
      final snapshot = await _firestore.collection('senseis').get();
      return snapshot.docs.map((doc) => Sensei.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Erreur lors du chargement des Senseis', e);
      return [];
    }
  }

  // Récupérer les Senseis d'un kaijin spécifique
  Future<List<Sensei>> getKaijinSenseis(String kaijinId) async {
    try {
      // Récupérer la relation kaijin-sensei
      final relationSnapshot = await _firestore
          .collection('kaijinSenseis')
          .where('kaijinId', isEqualTo: kaijinId)
          .get();

      if (relationSnapshot.docs.isEmpty) {
        return [];
      }

      // Extraire les IDs de Sensei et leurs niveaux
      final senseiIds = <String>[];
      final senseiLevels = <String, int>{};
      final unlockedSenseis = <String, bool>{};

      for (var doc in relationSnapshot.docs) {
        final data = doc.data();
        final senseiId = data['senseiId'] as String;
        final linkLevel = data['linkLevel'] as int? ?? 0;
        final isUnlocked = data['isUnlocked'] as bool? ?? false;

        senseiIds.add(senseiId);
        senseiLevels[senseiId] = linkLevel;
        unlockedSenseis[senseiId] = isUnlocked;
      }

      // Récupérer les détails des Senseis
      final senseiSnapshot = await _firestore
          .collection('senseis')
          .where(FieldPath.documentId, whereIn: senseiIds)
          .get();

      return senseiSnapshot.docs.map((doc) {
        final sensei = Sensei.fromFirestore(doc);
        sensei.linkLevel = senseiLevels[sensei.id] ?? 0;
        sensei.isUnlocked = unlockedSenseis[sensei.id] ?? false;
        return sensei;
      }).toList();
    } catch (e) {
      AppLogger.error('Erreur lors du chargement des Senseis du kaijin', e);
      return [];
    }
  }

  // Débloquer un Sensei avec gestion d'XP
  Future<String?> unlockSenseiWithXp(
      Kaijin kaijin, Sensei sensei, int totalXP, Function(int) updateXP) async {
    if (sensei.xpCostToUnlock <= 0) {
      AppLogger.warning('Coût de déblocage invalide pour le sensei ${sensei.id}');
      return 'ERR_INVALID_UNLOCK_COST';
    }
    if (totalXP < sensei.xpCostToUnlock) return 'ERR_NOT_ENOUGH_XP';

    updateXP(-sensei.xpCostToUnlock);

    try {
      final success = await unlockSensei(kaijin.id, sensei);

      if (success) {
        _audioService.playSound('unlock.mp3');
        return null;
      } else {
        // En cas d'échec, rembourser l'XP dépensé
        updateXP(sensei.xpCostToUnlock);
        return 'ERR_UNLOCK_FAILED';
      }
    } catch (e) {
      AppLogger.error('Erreur lors du déblocage du sensei', e);
      // Rembourser l'XP en cas d'erreur
      updateXP(sensei.xpCostToUnlock);
      return 'ERR_UNLOCK_EXCEPTION';
    }
  }

  // Améliorer un Sensei avec gestion d'XP
  Future<String?> upgradeSenseiWithXp(
      Kaijin kaijin, Sensei sensei, int totalXP, Function(int) updateXP) async {
    if (!sensei.isUnlocked) return 'ERR_NOT_UNLOCKED';

    if (sensei.linkLevel >= sensei.maxLinkLevel) {
      AppLogger.warning(
          'Ce sensei a déjà atteint son niveau maximum (${sensei.maxLinkLevel})');
      return 'ERR_MAX_LEVEL_REACHED';
    }

    final upgradeCost = sensei.getUpgradeCost();
    if (upgradeCost <= 0) {
      AppLogger.warning('Coût d\'amélioration invalide pour le sensei ${sensei.id}');
      return 'ERR_INVALID_UPGRADE_COST';
    }
    if (totalXP < upgradeCost) return 'ERR_NOT_ENOUGH_XP';

    updateXP(-upgradeCost);
    int originalLevel = sensei.linkLevel;
    sensei.linkLevel++;

    try {
      final success = await upgradeSenseiLink(kaijin.id, sensei);

      if (success) {
        _audioService.playSound('upgrade.mp3');
        return null;
      } else {
        // En cas d'échec, rembourser l'XP dépensé et restaurer le niveau
        updateXP(upgradeCost);
        sensei.linkLevel = originalLevel;
        return 'ERR_UPGRADE_FAILED';
      }
    } catch (e) {
      AppLogger.error('Erreur lors de l\'amélioration du sensei', e);
      // Rembourser l'XP et restaurer le niveau en cas d'erreur
      updateXP(upgradeCost);
      sensei.linkLevel = originalLevel;
      return 'ERR_UPGRADE_EXCEPTION';
    }
  }

  // Débloquer un nouveau Sensei pour un kaijin
  Future<bool> unlockSensei(String kaijinId, Sensei sensei) async {
    try {
      // Vérifier si la relation existe déjà
      final relationQuery = await _firestore
          .collection('kaijinSenseis')
          .where('kaijinId', isEqualTo: kaijinId)
          .where('senseiId', isEqualTo: sensei.id)
          .get();

      if (relationQuery.docs.isNotEmpty) {
        // Mettre à jour la relation existante
        await _firestore
            .collection('kaijinSenseis')
            .doc(relationQuery.docs.first.id)
            .update({
          'isUnlocked': true,
          'linkLevel': 1,
        });
      } else {
        // Créer une nouvelle relation
        await _firestore.collection('kaijinSenseis').add({
          'kaijinId': kaijinId,
          'senseiId': sensei.id,
          'linkLevel': 1,
          'isUnlocked': true,
        });
      }

      return true;
    } catch (e) {
      AppLogger.error('Erreur lors du déblocage du Sensei', e);
      return false;
    }
  }

  // Améliorer le niveau de lien d'un Sensei
  Future<bool> upgradeSenseiLink(String kaijinId, Sensei sensei) async {
    try {
      // Trouver la relation
      final relationQuery = await _firestore
          .collection('kaijinSenseis')
          .where('kaijinId', isEqualTo: kaijinId)
          .where('senseiId', isEqualTo: sensei.id)
          .get();

      if (relationQuery.docs.isEmpty) {
        AppLogger.warning('Relation kaijin-sensei non trouvée');
        return false;
      }

      // Récupérer les données du sensei directement depuis Firestore
      final senseiDoc =
          await _firestore.collection('senseis').doc(sensei.id).get();
      if (!senseiDoc.exists) {
        AppLogger.warning('Sensei non trouvé dans Firestore');
        return false;
      }

      final senseiData = senseiDoc.data();
      if (senseiData == null) {
        AppLogger.warning('Données de sensei invalides');
        return false;
      }

      // Récupérer le niveau maximal du sensei
      final maxLinkLevel = senseiData['maxLinkLevel'] as int? ?? 1;

      // Récupérer le niveau actuel de la relation
      final currentLinkLevel =
          relationQuery.docs.first.data()['linkLevel'] as int? ?? 0;

      // Vérifier que le niveau futur ne dépasse pas le maximum
      if (currentLinkLevel >= maxLinkLevel) {
        AppLogger.warning(
            'Niveau maximum déjà atteint pour ce sensei: $currentLinkLevel / $maxLinkLevel');
        return false;
      }

      // S'assurer que le niveau n'est jamais supérieur au maximum
      final newLevel = (currentLinkLevel + 1) > maxLinkLevel
          ? maxLinkLevel
          : (currentLinkLevel + 1);

      // Mettre à jour le niveau de lien
      await _firestore
          .collection('kaijinSenseis')
          .doc(relationQuery.docs.first.id)
          .update({
        'linkLevel': newLevel,
      });

      return true;
    } catch (e) {
      AppLogger.error('Erreur lors de l\'amélioration du lien de Sensei', e);
      return false;
    }
  }

  // Calculer l'XP passive totale par seconde pour un kaijin
  Future<double> calculateTotalPassiveXpPerSecond(String kaijinId) async {
    try {
      final senseis = await getKaijinSenseis(kaijinId);
      double totalXpPerSecond = 0.0;

      for (var sensei in senseis) {
        if (sensei.isUnlocked && sensei.linkLevel > 0) {
          totalXpPerSecond += sensei.getXpPerSecond();
        }
      }

      return totalXpPerSecond;
    } catch (e) {
      AppLogger.error('Erreur lors du calcul de l\'XP passive totale', e);
      return 0.0;
    }
  }

  // Calculer l'XP hors-ligne pour un kaijin
  Future<int> calculateOfflineXp(
      String kaijinId, DateTime lastConnected) async {
    try {
      final xpPerSecond = await calculateTotalPassiveXpPerSecond(kaijinId);

      if (xpPerSecond <= 0) return 0;

      final now = DateTime.now();
      final difference = now.difference(lastConnected);

      // Limiter à 24 heures maximum
      final seconds = min(difference.inSeconds, 24 * 60 * 60);

      return (xpPerSecond * seconds).toInt();
    } catch (e) {
      AppLogger.error('Erreur lors du calcul de l\'XP hors-ligne', e);
      return 0;
    }
  }

  // Initialiser les senseis par défaut
  Future<void> initDefaultSenseis() async {
    try {
      // Vérifier si les senseis existent déjà
      final existingSenseis = await getAllSenseis();
      if (existingSenseis.isNotEmpty) {
        AppLogger.info('Les senseis existent déjà, pas besoin de les initialiser');
        return;
      }

      // Liste des senseis par défaut
      final defaultSenseis = [
        {
          'name': 'Maître du Flux',
          'description':
              'Un sage ermite qui maîtrise parfaitement les courants du Kai Flux, enseignant la fluidité et l\'adaptation.',
          'affinity': 'Flux',
          'image': 'assets/images/senseis/maitre_flux.png',
          'xpPerSecond': 0.8,
          'xpCostToUnlock': 150,
          'xpCostToUpgradeLink': 75,
          'maxLinkLevel': 6,
        },
        {
          'name': 'Sage de la Fracture',
          'description':
              'Un maître mystérieux qui canalise le chaos de la Fracture, révélant les secrets de l\'instabilité du Kai.',
          'affinity': 'Fracture',
          'image': 'assets/images/senseis/sage_fracture.png',
          'xpPerSecond': 0.6,
          'xpCostToUnlock': 300,
          'xpCostToUpgradeLink': 120,
          'maxLinkLevel': 5,
        },
        {
          'name': 'Gardien du Sceau',
          'description':
              'Un ancien protecteur des Sceaux brisés qui enseigne l\'art du contrôle et de la stabilisation du Kai.',
          'affinity': 'Sceau',
          'image': 'assets/images/senseis/gardien_sceau.png',
          'xpPerSecond': 1.0,
          'xpCostToUnlock': 600,
          'xpCostToUpgradeLink': 200,
          'maxLinkLevel': 4,
        },
        {
          'name': 'Oracle de la Dérive',
          'description':
              'Une figure énigmatique qui navigue dans les méandres de la Dérive, maîtrisant l\'art de l\'illusion et de la manipulation.',
          'affinity': 'Dérive',
          'image': 'assets/images/senseis/oracle_derive.png',
          'xpPerSecond': 1.5,
          'xpCostToUnlock': 1200,
          'xpCostToUpgradeLink': 350,
          'maxLinkLevel': 3,
        },
        {
          'name': 'Champion de la Frappe',
          'description':
              'Un guerrier légendaire qui incarne la pure force du Kai Frappe, enseignant la voie de la puissance brute.',
          'affinity': 'Frappe',
          'image': 'assets/images/senseis/champion_frappe.png',
          'xpPerSecond': 0.4,
          'xpCostToUnlock': 800,
          'xpCostToUpgradeLink': 280,
          'maxLinkLevel': 7,
        },
      ];

      // Ajouter les senseis à Firestore
      for (var sensei in defaultSenseis) {
        await _firestore.collection('senseis').add(sensei);
      }

      AppLogger.info('${defaultSenseis.length} senseis par défaut ont été initialisés');
    } catch (e) {
      AppLogger.error(
          'Erreur lors de l\'initialisation des senseis par défaut', e);
    }
  }
}

// Fonction utilitaire min
int min(int a, int b) {
  return a < b ? a : b;
}
