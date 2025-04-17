import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resonance.dart';
import '../models/kaijin.dart';
import '../models/kaijin_resonance.dart';
import 'audio_service.dart';

class ResonanceService {
  // Singleton pattern
  static final ResonanceService _instance = ResonanceService._internal();
  factory ResonanceService() => _instance;
  ResonanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioService _audioService = AudioService();

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

  // Récupérer les Résonances d'un kaijin spécifique
  Future<List<Resonance>> getKaijinResonances(String kaijinId) async {
    try {
      // Récupérer la relation kaijin-résonance
      final relationSnapshot = await _firestore
          .collection('kaijinResonances')
          .where('kaijinId', isEqualTo: kaijinId)
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
      print('Erreur lors du chargement des Résonances du kaijin: $e');
      return [];
    }
  }

  // Débloquer une Résonance avec gestion d'XP
  Future<bool> unlockResonanceWithXp(Kaijin kaijin, Resonance resonance,
      int totalXP, Function(int) updateXP) async {
    if (totalXP < resonance.xpCostToUnlock) return false;

    updateXP(-resonance.xpCostToUnlock);

    try {
      final success = await unlockResonance(kaijin.id, resonance);

      if (success) {
        _audioService.playSound('unlock.mp3');
        return true;
      } else {
        // En cas d'échec, rembourser l'XP dépensé
        updateXP(resonance.xpCostToUnlock);
        return false;
      }
    } catch (e) {
      print('Erreur lors du déblocage de la résonance: $e');
      // Rembourser l'XP en cas d'erreur
      updateXP(resonance.xpCostToUnlock);
      return false;
    }
  }

  // Améliorer une Résonance avec gestion d'XP
  Future<bool> upgradeResonanceWithXp(Kaijin kaijin, Resonance resonance,
      int totalXP, Function(int) updateXP) async {
    if (!resonance.isUnlocked) return false;

    if (resonance.linkLevel >= resonance.maxLinkLevel) {
      print(
          'Cette résonance a déjà atteint son niveau maximum (${resonance.maxLinkLevel})');
      return false;
    }

    final upgradeCost = resonance.getUpgradeCost();
    if (totalXP < upgradeCost) return false;

    updateXP(-upgradeCost);
    int originalLevel = resonance.linkLevel;
    resonance.linkLevel++;

    try {
      final success = await upgradeResonanceLink(kaijin.id, resonance);

      if (success) {
        _audioService.playSound('upgrade.mp3');
        return true;
      } else {
        // En cas d'échec, rembourser l'XP dépensé et restaurer le niveau
        updateXP(upgradeCost);
        resonance.linkLevel = originalLevel;
        return false;
      }
    } catch (e) {
      print('Erreur lors de l\'amélioration de la résonance: $e');
      // Rembourser l'XP et restaurer le niveau en cas d'erreur
      updateXP(upgradeCost);
      resonance.linkLevel = originalLevel;
      return false;
    }
  }

  // Débloquer une nouvelle Résonance pour un ninja
  Future<bool> unlockResonance(String kaijinId, Resonance resonance) async {
    try {
      // Vérifier si la relation existe déjà
      final relationQuery = await _firestore
          .collection('kaijinResonances')
          .where('kaijinId', isEqualTo: kaijinId)
          .where('resonanceId', isEqualTo: resonance.id)
          .get();

      if (relationQuery.docs.isNotEmpty) {
        // Mettre à jour la relation existante
        await _firestore
            .collection('kaijinResonances')
            .doc(relationQuery.docs.first.id)
            .update({
          'isUnlocked': true,
          'linkLevel': 1,
        });
      } else {
        // Créer une nouvelle relation
        await _firestore.collection('kaijinResonances').add({
          'kaijinId': kaijinId,
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
  Future<bool> upgradeResonanceLink(
      String kaijinId, Resonance resonance) async {
    try {
      // Trouver la relation
      final relationQuery = await _firestore
          .collection('kaijinResonances')
          .where('kaijinId', isEqualTo: kaijinId)
          .where('resonanceId', isEqualTo: resonance.id)
          .get();

      if (relationQuery.docs.isEmpty) {
        print('Relation kaijin-résonance non trouvée');
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
          .collection('kaijinResonances')
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

  // Calculer l'XP passive totale par seconde pour un kaijin
  Future<double> calculateTotalPassiveXpPerSecond(String kaijinId) async {
    try {
      final resonances = await getKaijinResonances(kaijinId);
      double totalXpPerSecond = 0.0;

      for (var resonance in resonances) {
        if (resonance.isUnlocked && resonance.linkLevel > 0) {
          totalXpPerSecond += resonance.getXpPerSecond();
        }
      }

      return totalXpPerSecond;
    } catch (e) {
      print('Erreur lors du calcul de l\'XP passive totale: $e');
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
      print('Erreur lors du calcul de l\'XP hors-ligne: $e');
      return 0;
    }
  }

  // Initialiser les résonances par défaut
  Future<void> initDefaultResonances() async {
    try {
      // Vérifier si les résonances existent déjà
      final existingResonances = await getAllResonances();
      if (existingResonances.isNotEmpty) {
        print('Les résonances existent déjà, pas besoin de les initialiser');
        return;
      }

      // Liste des résonances par défaut
      final defaultResonances = [
        {
          'name': 'Résonance du Flux',
          'description':
              'Établit une connexion avec le Flux du Kai, générant un faible flux d\'XP passive.',
          'xpPerSecond': 0.5,
          'xpCostToUnlock': 100,
          'baseUpgradeCost': 50,
          'maxLinkLevel': 10,
          'affinity': 'Flux',
        },
        {
          'name': 'Écho de la Fracture',
          'description':
              'Crée un lien avec les fissures du Kai, augmentant légèrement la génération d\'XP par clic.',
          'xpPerSecond': 0.3,
          'xpCostToUnlock': 250,
          'baseUpgradeCost': 100,
          'maxLinkLevel': 8,
          'affinity': 'Fracture',
        },
        {
          'name': 'Cognition du Sceau',
          'description':
              'Forme un lien mental avec les Sceaux anciens, permettant une meilleure compréhension du Kai.',
          'xpPerSecond': 0.7,
          'xpCostToUnlock': 500,
          'baseUpgradeCost': 150,
          'maxLinkLevel': 6,
          'affinity': 'Sceau',
        },
        {
          'name': 'Pulsation de la Dérive',
          'description':
              'S\'accorde à la Dérive du Kai pour générer une quantité modérée d\'XP au fil du temps.',
          'xpPerSecond': 1.2,
          'xpCostToUnlock': 1000,
          'baseUpgradeCost': 300,
          'maxLinkLevel': 5,
          'affinity': 'Dérive',
        },
        {
          'name': 'Impact de la Frappe',
          'description':
              'Renforce la connexion avec l\'aspect Frappe du Kai, augmentant l\'efficacité des clics.',
          'xpPerSecond': 0.2,
          'xpCostToUnlock': 750,
          'baseUpgradeCost': 250,
          'maxLinkLevel': 7,
          'affinity': 'Frappe',
        },
      ];

      // Ajouter les résonances à Firestore
      for (var resonance in defaultResonances) {
        await _firestore.collection('resonances').add(resonance);
      }

      print(
          '${defaultResonances.length} résonances par défaut ont été initialisées');
    } catch (e) {
      print('Erreur lors de l\'initialisation des résonances par défaut: $e');
    }
  }
}

// Fonction utilitaire min
int min(int a, int b) {
  return a < b ? a : b;
}
