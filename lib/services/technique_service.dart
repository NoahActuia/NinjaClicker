import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technique.dart';
import '../models/kaijin_technique.dart';
import '../models/kaijin.dart';
import 'kaijin_service.dart';

/// Service qui gère toutes les opérations liées aux techniques
class TechniqueService {
  static final TechniqueService _instance = TechniqueService._internal();
  factory TechniqueService() => _instance;

  final KaijinService kaijinService = KaijinService();

  TechniqueService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer toutes les techniques disponibles
  Future<List<Technique>> getAllTechniques() async {
    final snapshot = await _firestore.collection('techniques').get();
    return snapshot.docs.map((doc) => Technique.fromFirestore(doc)).toList();
  }

  // Récupérer les techniques débloquées par un utilisateur
  Future<Set<String>> getUnlockedTechniqueIds(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('techniques')
        .where('unlocked', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  // Récupérer les techniques associées à un kaijin spécifique
  Future<List<KaijinTechnique>> getKaijinTechniques(String kaijinId) async {
    final snapshot = await _firestore
        .collection('kaijinTechniques')
        .where('kaijinId', isEqualTo: kaijinId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => KaijinTechnique.fromFirestore(doc))
        .toList();
  }

  // Récupérer les détails complets des techniques d'un kaijin
  Future<List<Technique>> getTechniquesForKaijin(String kaijinId) async {
    // Récupérer les relations kaijin-techniques
    final kaijinTechniques = await getKaijinTechniques(kaijinId);

    // Si aucune technique n'est associée, retourner une liste vide
    if (kaijinTechniques.isEmpty) {
      return [];
    }

    // Extraire les IDs des techniques
    final techniqueIds = kaijinTechniques.map((nt) => nt.techniqueId).toList();

    // Récupérer les détails des techniques
    final snapshot = await _firestore
        .collection('techniques')
        .where(FieldPath.documentId, whereIn: techniqueIds)
        .get();

    return snapshot.docs.map((doc) => Technique.fromFirestore(doc)).toList();
  }

  // Ajouter une technique à un kaijin
  Future<void> addTechniqueToKaijin(String kaijinId, String techniqueId) async {
    // Vérifier si la relation existe déjà
    final existingQuery = await _firestore
        .collection('kaijinTechniques')
        .where('kaijinId', isEqualTo: kaijinId)
        .where('techniqueId', isEqualTo: techniqueId)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      // La relation existe déjà, mise à jour
      final doc = existingQuery.docs.first;
      await _firestore.collection('kaijinTechniques').doc(doc.id).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Nouvelle relation
      final newKaijinTechnique = KaijinTechnique(
        id: '', // Firestore générera l'ID
        kaijinId: kaijinId,
        techniqueId: techniqueId,
        level: 1,
        isActive: true,
        acquiredAt: DateTime.now(),
      );

      await _firestore
          .collection('kaijinTechniques')
          .add(newKaijinTechnique.toFirestore());
    }
  }

  // Supprimer une technique d'un kaijin (désactiver)
  Future<void> removeTechniqueFromKaijin(
      String kaijinId, String techniqueId) async {
    final existingQuery = await _firestore
        .collection('kaijinTechniques')
        .where('kaijinId', isEqualTo: kaijinId)
        .where('techniqueId', isEqualTo: techniqueId)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      final doc = existingQuery.docs.first;
      await _firestore.collection('kaijinTechniques').doc(doc.id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Récupérer les techniques par défaut
  Future<List<Technique>> getDefaultTechniques() async {
    final snapshot = await _firestore
        .collection('techniques')
        .where('isDefault', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => Technique.fromFirestore(doc)).toList();
  }

  // Récupérer les techniques associées à un kaijin et à une technique spécifique
  Future<List<KaijinTechnique>> getKaijinTechniquesForTechnique(
      String kaijinId, String techniqueId) async {
    final snapshot = await _firestore
        .collection('kaijinTechniques')
        .where('kaijinId', isEqualTo: kaijinId)
        .where('techniqueId', isEqualTo: techniqueId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => KaijinTechnique.fromFirestore(doc))
        .toList();
  }

  // Formater la puissance d'une technique avec unités K ou M
  String getFormattedPower(Technique technique) {
    int power = technique.damage;
    if (power >= 1000000) {
      double formattedValue = power / 1000000;
      return '${formattedValue.toStringAsFixed(1)}M Dégats';
    } else if (power >= 1000) {
      double formattedValue = power / 1000;
      return '${formattedValue.toStringAsFixed(1)}k Dégats';
    } else {
      return '$power Dégats';
    }
  }

  // Formater le coût d'une technique avec unités K ou M
  String getFormattedCost(Technique technique) {
    int cost = technique.cost_kai;
    if (cost >= 1000000) {
      double formattedValue = cost / 1000000;
      return 'Coût: ${formattedValue.toStringAsFixed(1)}M Kai';
    } else if (cost >= 1000) {
      double formattedValue = cost / 1000;
      return 'Coût: ${formattedValue.toStringAsFixed(1)}k Kai';
    } else {
      return 'Coût: $cost Kai';
    }
  }

  // Formater le niveau d'une technique avec un affichage élégant
  String getFormattedLevel(Technique technique) {
    return 'Niveau ${technique.level}';
  }

  // Améliorer le niveau d'une technique pour un kaijin
  Future<void> upgradeTechnique(
      String kaijinId, String techniqueId, int newLevel) async {
    try {
      // Récupérer la relation existante
      final relations =
          await getKaijinTechniquesForTechnique(kaijinId, techniqueId);

      if (relations.isEmpty) {
        throw Exception('Technique non trouvée pour ce kaijin');
      }

      final relation = relations.first;

      // Mettre à jour le niveau
      await _firestore.collection('kaijinTechniques').doc(relation.id).update({
        'level': newLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          'Technique $techniqueId améliorée au niveau $newLevel pour le kaijin $kaijinId');
    } catch (e) {
      print('Erreur lors de l\'amélioration de la technique: $e');
      throw e;
    }
  }

  // Supprimer toutes les techniques existantes et réinitialiser la collection
  Future<void> deleteAllTechniques() async {
    try {
      print('Suppression de toutes les techniques...');

      // Récupérer toutes les techniques
      final snapshot = await _firestore.collection('techniques').get();

      if (snapshot.docs.isEmpty) {
        print('Aucune technique à supprimer.');
        return;
      }

      // Utiliser un batch pour supprimer plusieurs documents efficacement
      final WriteBatch batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Exécuter le batch
      await batch.commit();

      print(
          '${snapshot.docs.length} techniques ont été supprimées avec succès.');
    } catch (e) {
      print('Erreur lors de la suppression des techniques: $e');
      throw e;
    }
  }

  // Créer les techniques initiales avec le nouveau format
  Future<void> createInitialTechniques() async {
    try {
      print('Création des techniques initiales...');

      // Liste des techniques initiales
      final initialTechniques = [
        // Techniques de type ACTIVE
        {
          'name': 'Lame du Flux',
          'description': 'Crée une lame de Kai qui tranche avec précision.',
          'type': 'active',
          'affinity': 'Flux',
          'cost_kai': 30,
          'cooldown': 2,
          'damage': 150,
          'condition_generated': 'saignement',
          'trigger_condition': null,
          'unlock_type': 'naturelle',
          'scaling_json': {
            'flux_damage_bonus_percent': 5,
            'bonus_per_level': 2,
            'flux_cooldown_reduction': 1
          },
          'xp_unlock_cost': 500,
          'base_upgrade_cost': 250,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Endurance Fracturée',
          'description':
              'Renforce la résistance et augmente le Kai généré passivement.',
          'type': 'passive',
          'affinity': 'Fracture',
          'cost_kai': 0,
          'cooldown': 0,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'affinité',
          'scaling_json': {
            'defense_bonus_percent': 10,
            'bonus_per_level': 3,
            'passive_kai_generation': 2
          },
          'xp_unlock_cost': 450,
          'base_upgrade_cost': 220,
          'max_level': 5,
          'isDefault': true,
        },
        // AJOUT DE 20 NOUVELLES TECHNIQUES
        // 1. Techniques de Flux
        {
          'name': 'Vague Déferlante',
          'description':
              'Crée une vague de Kai qui balaye les ennemis sur sa trajectoire.',
          'type': 'active',
          'affinity': 'Flux',
          'cost_kai': 45,
          'cooldown': 3,
          'damage': 200,
          'condition_generated': 'déséquilibre',
          'trigger_condition': null,
          'unlock_type': 'naturelle',
          'scaling_json': {
            'area_damage_bonus': 15,
            'bonus_per_level': 3,
            'knockback_distance': 2
          },
          'xp_unlock_cost': 600,
          'base_upgrade_cost': 300,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Ruissellement',
          'description': 'Technique passive qui régénère du Kai à chaque tour.',
          'type': 'passive',
          'affinity': 'Flux',
          'cost_kai': 0,
          'cooldown': 0,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'affinité',
          'scaling_json': {
            'kai_regen_per_turn': 5,
            'bonus_per_level': 2,
            'increased_max_kai': 10
          },
          'xp_unlock_cost': 550,
          'base_upgrade_cost': 275,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Torrent Vengeur',
          'description':
              'Une contre-attaque qui s\'active lorsque vous êtes touchés.',
          'type': 'auto',
          'affinity': 'Flux',
          'cost_kai': 20,
          'cooldown': 4,
          'damage': 100,
          'condition_generated': null,
          'trigger_condition': 'subir_des_degats',
          'unlock_type': 'héritage',
          'scaling_json': {
            'counter_damage_percent': 40,
            'bonus_per_level': 5,
            'chance_to_stun': 10
          },
          'xp_unlock_cost': 800,
          'base_upgrade_cost': 400,
          'max_level': 4,
          'isDefault': true,
        },
        // 2. Techniques de Fracture
        {
          'name': 'Poing Tectonique',
          'description':
              'Concentre le Kai dans le poing pour briser les défenses ennemies.',
          'type': 'active',
          'affinity': 'Fracture',
          'cost_kai': 35,
          'cooldown': 2,
          'damage': 180,
          'condition_generated': 'vulnérabilité',
          'trigger_condition': null,
          'unlock_type': 'naturelle',
          'scaling_json': {
            'armor_penetration_percent': 30,
            'bonus_per_level': 5,
            'defense_reduction_duration': 2
          },
          'xp_unlock_cost': 650,
          'base_upgrade_cost': 325,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Armure Lithique',
          'description':
              'Renforce la peau avec des fragments de Kai solidifié.',
          'type': 'passive',
          'affinity': 'Fracture',
          'cost_kai': 0,
          'cooldown': 0,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'affinité',
          'scaling_json': {
            'damage_reduction_percent': 15,
            'bonus_per_level': 3,
            'reflect_damage_percent': 5
          },
          'xp_unlock_cost': 700,
          'base_upgrade_cost': 350,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Contrecoup',
          'description':
              'Stocke l\'énergie des attaques subies pour la libérer contre l\'ennemi.',
          'type': 'auto',
          'affinity': 'Fracture',
          'cost_kai': 15,
          'cooldown': 5,
          'damage': 0,
          'condition_generated': 'étourdissement',
          'trigger_condition': 'accumulation_de_dégâts',
          'unlock_type': 'héritage',
          'scaling_json': {
            'stored_damage_percent': 75,
            'bonus_per_level': 5,
            'stun_duration': 1
          },
          'xp_unlock_cost': 850,
          'base_upgrade_cost': 425,
          'max_level': 4,
          'isDefault': true,
        },
        // 3. Techniques de Sceau
        {
          'name': 'Prison des Sceaux',
          'description':
              'Enferme l\'ennemi dans une cage de sceaux restrictifs.',
          'type': 'active',
          'affinity': 'Sceau',
          'cost_kai': 50,
          'cooldown': 4,
          'damage': 80,
          'condition_generated': 'immobilisation',
          'trigger_condition': null,
          'unlock_type': 'naturelle',
          'scaling_json': {
            'immobilize_duration': 2,
            'bonus_per_level': 1,
            'damage_over_time': 15
          },
          'xp_unlock_cost': 750,
          'base_upgrade_cost': 375,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Barrière Kaïque',
          'description':
              'Crée une barrière qui absorbe une quantité fixe de dégâts.',
          'type': 'passive',
          'affinity': 'Sceau',
          'cost_kai': 40,
          'cooldown': 6,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'affinité',
          'scaling_json': {
            'shield_amount': 120,
            'bonus_per_level': 30,
            'shield_duration': 3
          },
          'xp_unlock_cost': 700,
          'base_upgrade_cost': 350,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Sceau de Réflexion',
          'description':
              'Sceau qui renvoie une partie des attaques vers l\'attaquant.',
          'type': 'auto',
          'affinity': 'Sceau',
          'cost_kai': 35,
          'cooldown': 5,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': 'subir_une_technique',
          'unlock_type': 'héritage',
          'scaling_json': {
            'reflection_percent': 30,
            'bonus_per_level': 5,
            'duration': 2
          },
          'xp_unlock_cost': 800,
          'base_upgrade_cost': 400,
          'max_level': 4,
          'isDefault': true,
        },
        // 4. Techniques de Dérive
        {
          'name': 'Transposition',
          'description':
              'Échange instantanément sa position avec l\'ennemi, désorientant ce dernier.',
          'type': 'active',
          'affinity': 'Dérive',
          'cost_kai': 30,
          'cooldown': 3,
          'damage': 50,
          'condition_generated': 'confusion',
          'trigger_condition': null,
          'unlock_type': 'naturelle',
          'scaling_json': {
            'confusion_duration': 2,
            'bonus_per_level': 1,
            'bonus_damage_on_confused': 30
          },
          'xp_unlock_cost': 600,
          'base_upgrade_cost': 300,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Flux Temporel',
          'description':
              'Accélère le temps pour le porteur, augmentant ses chances d\'esquive.',
          'type': 'passive',
          'affinity': 'Dérive',
          'cost_kai': 0,
          'cooldown': 0,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'affinité',
          'scaling_json': {
            'dodge_chance_percent': 10,
            'bonus_per_level': 2,
            'cooldown_reduction': 1
          },
          'xp_unlock_cost': 750,
          'base_upgrade_cost': 375,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Écho du Vide',
          'description':
              'Crée une image miroir qui absorbe la prochaine attaque.',
          'type': 'auto',
          'affinity': 'Dérive',
          'cost_kai': 25,
          'cooldown': 4,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': 'être_ciblé',
          'unlock_type': 'héritage',
          'scaling_json': {
            'mirror_health_percent': 50,
            'bonus_per_level': 10,
            'counter_attack_damage': 60
          },
          'xp_unlock_cost': 800,
          'base_upgrade_cost': 400,
          'max_level': 4,
          'isDefault': true,
        },
        // 5. Techniques de Frappe
        {
          'name': 'Impact Fulgurant',
          'description':
              'Frappe éclair qui touche l\'ennemi avant qu\'il puisse réagir.',
          'type': 'active',
          'affinity': 'Frappe',
          'cost_kai': 40,
          'cooldown': 3,
          'damage': 220,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'naturelle',
          'scaling_json': {
            'critical_chance_percent': 20,
            'bonus_per_level': 5,
            'critical_damage_multiplier': 1.5
          },
          'xp_unlock_cost': 650,
          'base_upgrade_cost': 325,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Maîtrise du Combat',
          'description':
              'Améliore la précision et la puissance des attaques physiques.',
          'type': 'passive',
          'affinity': 'Frappe',
          'cost_kai': 0,
          'cooldown': 0,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'affinité',
          'scaling_json': {
            'accuracy_percent': 15,
            'bonus_per_level': 3,
            'physical_damage_percent': 10
          },
          'xp_unlock_cost': 600,
          'base_upgrade_cost': 300,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Réplique Instinctive',
          'description':
              'Contre automatiquement après avoir esquivé une attaque.',
          'type': 'auto',
          'affinity': 'Frappe',
          'cost_kai': 20,
          'cooldown': 3,
          'damage': 150,
          'condition_generated': null,
          'trigger_condition': 'esquive_réussie',
          'unlock_type': 'héritage',
          'scaling_json': {
            'counter_damage_percent': 100,
            'bonus_per_level': 10,
            'precision_bonus': 25
          },
          'xp_unlock_cost': 750,
          'base_upgrade_cost': 375,
          'max_level': 4,
          'isDefault': true,
        },
        // 6. Techniques fusionnant plusieurs affinités
        {
          'name': 'Tempête Fracturée',
          'description':
              'Combine Flux et Fracture pour créer une tempête de fragments acérés.',
          'type': 'active',
          'affinity': 'Flux',
          'cost_kai': 60,
          'cooldown': 5,
          'damage': 250,
          'condition_generated': 'saignement',
          'trigger_condition': null,
          'unlock_type': 'fusion',
          'scaling_json': {
            'area_damage_bonus': 20,
            'bonus_per_level': 5,
            'bleed_duration': 3,
            'fracture_synergy': true
          },
          'xp_unlock_cost': 1000,
          'base_upgrade_cost': 500,
          'max_level': 6,
          'isDefault': true,
        },
        {
          'name': 'Méditation du Kai Scellé',
          'description':
              'Technique qui scelle une partie du Kai pour le libérer plus tard avec une puissance décuplée.',
          'type': 'passive',
          'affinity': 'Sceau',
          'cost_kai': 50,
          'cooldown': 6,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'fusion',
          'scaling_json': {
            'kai_storage_percent': 25,
            'bonus_per_level': 5,
            'damage_multiplier_on_release': 2.5,
            'frappe_synergy': true
          },
          'xp_unlock_cost': 1200,
          'base_upgrade_cost': 600,
          'max_level': 6,
          'isDefault': true,
        },
        {
          'name': 'Nexus des Dimensions',
          'description':
              'Crée un rift qui attire les ennemis et les maintient piégés.',
          'type': 'active',
          'affinity': 'Dérive',
          'cost_kai': 70,
          'cooldown': 6,
          'damage': 120,
          'condition_generated': 'gravité_altérée',
          'trigger_condition': null,
          'unlock_type': 'fusion',
          'scaling_json': {
            'pull_strength': 3,
            'bonus_per_level': 1,
            'damage_per_turn': 40,
            'duration': 3,
            'sceau_synergy': true
          },
          'xp_unlock_cost': 1100,
          'base_upgrade_cost': 550,
          'max_level': 6,
          'isDefault': true,
        },
        {
          'name': 'Éclat de l\'Âme Fracturée',
          'description':
              'Libère toute la puissance du Fracturé, ignorant temporairement ses limites.',
          'type': 'active',
          'affinity': 'Fracture',
          'cost_kai': 100,
          'cooldown': 8,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'ultime',
          'scaling_json': {
            'all_damage_increase_percent': 50,
            'bonus_per_level': 10,
            'duration': 3,
            'hp_cost_percent': 10,
            'all_affinities_synergy': true
          },
          'xp_unlock_cost': 2000,
          'base_upgrade_cost': 1000,
          'max_level': 10,
          'isDefault': true,
        },
      ];

      // Ajouter chaque technique à Firestore
      for (var technique in initialTechniques) {
        await _firestore.collection('techniques').add(technique);
      }

      print(
          '${initialTechniques.length} techniques ont été créées avec succès.');
    } catch (e) {
      print('Erreur lors de la création des techniques initiales: $e');
      throw e;
    }
  }

  // Réinitialiser et recréer toutes les techniques
  Future<void> resetAndCreateTechniques() async {
    try {
      // Supprimer toutes les techniques existantes
      await deleteAllTechniques();

      // Créer les nouvelles techniques
      await createInitialTechniques();

      print(
          'Réinitialisation et création des techniques terminées avec succès.');
    } catch (e) {
      print('Erreur lors de la réinitialisation des techniques: $e');
      throw e;
    }
  }

  // Ajouter uniquement les nouvelles techniques qui n'existent pas déjà
  Future<void> addNewTechniquesIfNotExist() async {
    try {
      print('Vérification et ajout des nouvelles techniques...');

      // Récupérer toutes les techniques existantes
      final existingTechniques = await getAllTechniques();

      // Créer un ensemble de noms de techniques pour une recherche rapide
      final existingTechniqueNames =
          existingTechniques.map((t) => t.name).toSet();

      // Définir les nouvelles techniques à ajouter
      final initialTechniques = [
        {
          'name': 'Frappe du Kai Fluctuant',
          'description':
              'Une frappe simple mais puissante qui concentre le Kai dans les poings.',
          'type': 'active',
          'affinity': 'Frappe',
          'cost_kai': 15,
          'cooldown': 1,
          'damage': 25,
          'condition_generated': 'aucune',
          'trigger_condition': 'basique',
          'unlock_type': 'naturelle',
          'scaling_json': {
            'force_scaling': 1.2,
            'bonus_per_level': 3,
          },
          'xp_unlock_cost': 300,
          'base_upgrade_cost': 150,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Vague de Fracture',
          'description':
              'Crée une fissure temporelle qui blesse tous les ennemis.',
          'type': 'active',
          'affinity': 'Fracture',
          'cost_kai': 30,
          'cooldown': 3,
          'damage': 40,
          'condition_generated': 'fissure',
          'trigger_condition': null,
          'unlock_type': 'naturelle',
          'scaling_json': {
            'intelligence_scaling': 1.5,
            'bonus_per_level': 5,
            'fissure_duration': 2
          },
          'xp_unlock_cost': 500,
          'base_upgrade_cost': 250,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Sceau de Protection',
          'description':
              'Un sceau protecteur qui réduit les dégâts reçus pendant 2 tours.',
          'type': 'active',
          'affinity': 'Sceau',
          'cost_kai': 25,
          'cooldown': 4,
          'damage': 0,
          'condition_generated': 'protection',
          'trigger_condition': null,
          'unlock_type': 'naturelle',
          'scaling_json': {
            'endurance_scaling': 1.0,
            'bonus_per_level': 10,
            'protection_duration': 2,
            'damage_reduction': 0.3
          },
          'xp_unlock_cost': 450,
          'base_upgrade_cost': 225,
          'max_level': 5,
          'isDefault': true,
        },
        {
          'name': 'Flux Régénérant',
          'description':
              'Rétablit une partie du Kai dépensé en absorbant l\'énergie environnante.',
          'type': 'auto',
          'affinity': 'Flux',
          'cost_kai': 10,
          'cooldown': 5,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': 'kai_faible',
          'unlock_type': 'héritage',
          'scaling_json': {
            'sagesse_scaling': 1.3,
            'bonus_per_level': 10,
            'kai_restore_amount': 40
          },
          'xp_unlock_cost': 700,
          'base_upgrade_cost': 350,
          'max_level': 4,
          'isDefault': true,
        },
        {
          'name': 'Dérive Temporelle',
          'description':
              'Ralentit le temps autour de l\'ennemi, augmentant la chance d\'esquiver ses attaques.',
          'type': 'passive',
          'affinity': 'Dérive',
          'cost_kai': 0,
          'cooldown': 0,
          'damage': 0,
          'condition_generated': null,
          'trigger_condition': null,
          'unlock_type': 'affinité',
          'scaling_json': {
            'agilité_scaling': 1.4,
            'bonus_per_level': 5,
            'evasion_boost': 0.25
          },
          'xp_unlock_cost': 600,
          'base_upgrade_cost': 300,
          'max_level': 5,
          'isDefault': true,
        },
      ];

      // Liste des techniques à ajouter
      final techniquesToAdd = initialTechniques
          .where((technique) =>
              !existingTechniqueNames.contains(technique['name']))
          .toList();

      if (techniquesToAdd.isEmpty) {
        print('Aucune nouvelle technique à ajouter.');
        return;
      }

      // Ajouter uniquement les nouvelles techniques
      int addedCount = 0;
      for (var technique in techniquesToAdd) {
        await _firestore.collection('techniques').add(technique);
        addedCount++;
      }

      print('$addedCount nouvelles techniques ont été ajoutées avec succès.');
    } catch (e) {
      print('Erreur lors de l\'ajout des nouvelles techniques: $e');
      throw e;
    }
  }

  // Charger les techniques disponibles pour un kaijin
  Future<List<Technique>> loadTechniques(String kaijinId) async {
    try {
      final techniques = await kaijinService.getKaijinTechniques(kaijinId);
      print('Techniques chargées: ${techniques.length}');
      return techniques;
    } catch (e) {
      print('Erreur lors du chargement des techniques: $e');
      return [];
    }
  }

  // Filtrer les techniques pour obtenir celles du joueur
  List<Technique> getPlayerTechniques(
      List<Technique> allTechniques, Kaijin kaijin) {
    if (allTechniques.isEmpty || kaijin.techniques.isEmpty) {
      return [];
    }

    final playerTechniques = allTechniques
        .where((technique) => kaijin.techniques.contains(technique.id))
        .toList();

    // Mettre à jour les niveaux des techniques
    for (var technique in playerTechniques) {
      technique.niveau = kaijin.techniqueLevels[technique.id] ?? 0;
    }

    return playerTechniques;
  }

  // Débloquer une technique
  Future<bool> unlockTechnique(Kaijin kaijin, Technique technique, int totalXP,
      Function(int) updateXP) async {
    final cost = technique.cout;
    if (totalXP < cost) return false;

    updateXP(-cost);

    try {
      await kaijinService.addTechniqueToKaijin(kaijin.id, technique.id);
      print('Technique ${technique.nom} débloquée pour ${kaijin.name}');
      return true;
    } catch (e) {
      print('Erreur lors du déblocage de la technique: $e');
      updateXP(cost); // Rembourser l'XP
      return false;
    }
  }

  // Améliorer une technique avec gestion d'XP (renommée pour éviter le conflit)
  Future<bool> upgradeTechniqueWithXp(Kaijin kaijin, Technique technique,
      int totalXP, Function(int) updateXP) async {
    final upgradeCost = calculateUpgradeCost(technique);
    if (totalXP < upgradeCost) return false;

    updateXP(-upgradeCost);
    final originalLevel = technique.niveau;
    technique.niveau += 1;

    try {
      // Mettre à jour le niveau de la technique dans la relation kaijin-technique
      await upgradeTechnique(kaijin.id, technique.id, technique.niveau);
      print(
          'Technique ${technique.nom} améliorée au niveau ${technique.niveau}');
      return true;
    } catch (e) {
      print('Erreur lors de l\'amélioration de la technique: $e');
      technique.niveau = originalLevel;
      updateXP(upgradeCost); // Rembourser l'XP
      return false;
    }
  }

  // Calculer le coût d'amélioration d'une technique
  int calculateUpgradeCost(Technique technique) {
    // Formule de calcul du coût d'amélioration
    return (technique.cout * (1.5 * (technique.niveau + 1))).toInt();
  }

  // Calculer la puissance totale des techniques
  int calculateTotalTechniquePower(List<Technique> techniques) {
    int totalPower = 0;
    for (var technique in techniques) {
      if (technique.niveau > 0) {
        // Utiliser damage au lieu de getPuissance qui n'existe pas et convertir en int
        totalPower += technique.damage.toInt();
      }
    }
    return totalPower;
  }
}
