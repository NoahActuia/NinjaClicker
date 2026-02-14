import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/technique.dart';
import '../../models/kaijin_technique.dart';
import '../../services/app_logger.dart';
import '../../services/kaijin_service.dart';
import '../../services/technique_service.dart';
import '../../styles/kai_colors.dart';

/// Classe qui gère l'état et la logique métier de l'écran d'arbre des techniques
class TechniqueTreeState {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TechniqueService _techniqueService = TechniqueService();
  final KaijinService _kaijinService = KaijinService();

  // Filtres des techniques par affinité
  String _selectedAffinity = 'Tous';
  final List<String> _affinities = [
    'Tous',
    'Flux',
    'Fracture',
    'Sceau',
    'Dérive',
    'Frappe'
  ];

  // Techniques regroupées par niveau
  Map<int, List<Technique>> _techniquesByLevel = {};
  // Map pour suivre les techniques débloquées
  Map<String, bool> _unlockedTechniques = {};
  // Map pour suivre la hiérarchie des techniques
  Map<String, String> _techniqueParents = {}; // ID technique -> ID parent
  // Map pour suivre le niveau technique dans l'arbre
  Map<String, int> _techniqueLevels = {}; // ID technique -> niveau

  bool _isLoading = true;
  int _playerXp = 0;
  String _kaijinId = '';
  String _kaijinName = '';

  // Getters pour accéder aux propriétés privées
  String get selectedAffinity => _selectedAffinity;
  List<String> get affinities => _affinities;
  Map<int, List<Technique>> get techniquesByLevel => _techniquesByLevel;
  Map<String, bool> get unlockedTechniques => _unlockedTechniques;
  Map<String, String> get techniqueParents => _techniqueParents;
  Map<String, int> get techniqueLevels => _techniqueLevels;
  bool get isLoading => _isLoading;
  int get playerXp => _playerXp;
  String get kaijinId => _kaijinId;
  String get kaijinName => _kaijinName;

  // Fonction pour mettre à jour l'état
  final Function(Function()) setState;

  TechniqueTreeState({required this.setState});

  // Initialisation des données
  Future<void> initialize() async {
    await getCurrentKaijin();
    await loadTechniques();
    await addNewTechniques();
  }

  // Mettre à jour l'affinité sélectionnée
  void updateSelectedAffinity(String affinity) {
    setState(() {
      _selectedAffinity = affinity;
    });
  }

  // Récupérer le kaijin actuel
  Future<void> getCurrentKaijin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Utiliser la nouvelle méthode getCurrentKaijin du service
      final currentKaijin = await _kaijinService.getCurrentKaijin(user.uid);

      if (currentKaijin == null) {
        throw Exception('Aucun personnage trouvé pour l\'utilisateur');
      }

      AppLogger.info(
          'Kaijin sélectionné: ${currentKaijin.name} (dernière connexion: ${currentKaijin.lastConnected})');

      setState(() {
        _kaijinId = currentKaijin.id;
        _kaijinName = currentKaijin.name;
        _playerXp = currentKaijin.xp;
      });
    } catch (e) {
      AppLogger.error('Erreur lors de la récupération du kaijin', e);
      setState(() {
        _kaijinId = '';
        _kaijinName = 'Fracturé inconnu';
        _playerXp = 0;
      });
    }
  }

  Future<void> loadTechniques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier que nous avons un ID de kaijin valide
      if (_kaijinId.isEmpty) {
        AppLogger.warning(
            'Aucun kaijin actif trouvé, impossible de charger les techniques');
        // Charger les techniques par défaut à la place
        await loadDefaultTechniques();
        return;
      }

      final querySnapshot = await _firestore.collection('techniques').get();

      // Récupérer les techniques débloquées par l'utilisateur
      final userTechniquesDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('techniques')
          .get();

      // Map des IDs de techniques débloquées
      final Map<String, bool> unlockedTechniques = {};
      for (var doc in userTechniquesDoc.docs) {
        final techId = doc.id;
        final isUnlocked = doc.data()['unlocked'] ?? false;
        unlockedTechniques[techId] = isUnlocked;
      }

      // Récupérer les techniques associées au kaijin via la table pivot
      final kaijinTechniques =
          await _techniqueService.getKaijinTechniques(_kaijinId);

      // Set des IDs de techniques déjà associées au kaijin
      final Set<String> kaijinTechniqueIds =
          kaijinTechniques.map((nt) => nt.techniqueId).toSet();

      // Organisation des techniques par niveau
      final Map<int, List<Technique>> techniquesByLevel = {};

      for (var doc in querySnapshot.docs) {
        final technique = Technique.fromFirestore(doc);

        // Mise à jour du statut de débloquage basé sur la table pivot
        final bool isUnlocked = kaijinTechniqueIds.contains(technique.id);

        // Créer une copie avec le statut de débloquage mis à jour
        final updatedTechnique = Technique(
          id: technique.id,
          name: technique.name,
          description: technique.description,
          type: technique.type,
          affinity: technique.affinity,
          cost_kai: technique.cost_kai,
          cooldown: technique.cooldown,
          damage: technique.damage,
          condition_generated: technique.condition_generated,
          trigger_condition: technique.trigger_condition,
          unlock_type: technique.unlock_type,
          scaling_json: technique.scaling_json,
          xp_unlock_cost: technique.xp_unlock_cost,
          base_upgrade_cost: technique.base_upgrade_cost,
          max_level: technique.max_level,
          level: technique.level,
        );

        // Stocker le statut de débloquage dans une map séparée
        _unlockedTechniques[updatedTechnique.id] = isUnlocked;

        // Ajouter à la map par niveau (utiliser une structure à plat sans hierarchy pour l'instant)
        int techLevel = 1; // Valeur par défaut pour tous
        if (!techniquesByLevel.containsKey(techLevel)) {
          techniquesByLevel[techLevel] = [];
        }
        techniquesByLevel[techLevel]?.add(updatedTechnique);
      }

      setState(() {
        _techniquesByLevel = techniquesByLevel;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Erreur lors du chargement des techniques', e);

      // En cas d'erreur, charger les techniques par défaut
      loadDefaultTechniques();
    }
  }

  // Méthode de secours pour charger les techniques par défaut
  Future<void> loadDefaultTechniques() async {
    try {
      final defaultTechniques = await _techniqueService.getDefaultTechniques();

      final Map<int, List<Technique>> techniquesByLevel = {};

      // Assigner un niveau par défaut (1) pour toutes les techniques
      for (var technique in defaultTechniques) {
        // Niveau par défaut
        int techLevel = 1;
        _techniqueLevels[technique.id] = techLevel;

        // Initialiser comme non débloquée
        _unlockedTechniques[technique.id] = false;

        // Ajouter à la map par niveau
        if (!techniquesByLevel.containsKey(techLevel)) {
          techniquesByLevel[techLevel] = [];
        }
        techniquesByLevel[techLevel]?.add(technique);
      }

      setState(() {
        _techniquesByLevel = techniquesByLevel;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Erreur lors du chargement des techniques par défaut', e);
      setState(() {
        _techniquesByLevel = {};
        _isLoading = false;
      });
    }
  }

  Future<void> addNewTechniques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      TechniqueService techniqueService = TechniqueService();
      await techniqueService.addNewTechniquesIfNotExist();
    } catch (e) {
      AppLogger.error('Erreur lors de la mise à jour des techniques', e);
    } finally {
      setState(() {
        _isLoading = false;
      });
      await loadTechniques(); // Recharger les techniques après l'ajout
    }
  }

  Future<void> unlockTechnique(
      BuildContext context, Technique technique) async {
    try {
      if (technique.xp_unlock_cost <= 0) {
        throw Exception('ERR_INVALID_UNLOCK_COST');
      }

      // Vérifier si le joueur a assez d'XP
      if (_playerXp < technique.xp_unlock_cost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'XP insuffisante pour débloquer cette technique (${technique.xp_unlock_cost} XP nécessaires)'),
            backgroundColor: KaiColors.error,
          ),
        );
        return;
      }

      if (_kaijinId.isEmpty) {
        throw Exception('ERR_KAIJIN_NOT_FOUND');
      }

      await _firestore.runTransaction((transaction) async {
        final kaijinRef = _firestore.collection('kaijins').doc(_kaijinId);
        final kaijinSnapshot = await transaction.get(kaijinRef);
        if (!kaijinSnapshot.exists) {
          throw Exception('ERR_KAIJIN_NOT_FOUND');
        }

        final currentXp = kaijinSnapshot.data()?['xp'] as int? ?? 0;
        if (currentXp < technique.xp_unlock_cost) {
          throw Exception('ERR_NOT_ENOUGH_XP');
        }

        final relationQuery = await _firestore
            .collection('kaijinTechniques')
            .where('kaijinId', isEqualTo: _kaijinId)
            .where('techniqueId', isEqualTo: technique.id)
            .limit(1)
            .get();

        transaction.update(kaijinRef, {
          'xp': currentXp - technique.xp_unlock_cost,
        });

        if (relationQuery.docs.isNotEmpty) {
          transaction.update(relationQuery.docs.first.reference, {
            'isActive': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final newRelationRef = _firestore.collection('kaijinTechniques').doc();
          transaction.set(newRelationRef, {
            'kaijinId': _kaijinId,
            'techniqueId': technique.id,
            'level': 1,
            'isActive': true,
            'acquiredAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // 3. Mettre à jour notre map locale des techniques débloquées
      setState(() {
        _unlockedTechniques[technique.id] = true;
      });

      // 4. Rafraîchir les données
      await getCurrentKaijin();
      await loadTechniques();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Technique débloquée: ${technique.name}'),
          backgroundColor: KaiColors.success,
        ),
      );
    } catch (e) {
      AppLogger.error('Erreur lors du débloquage de la technique', e);
      final message = _mapTechniqueErrorToMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: KaiColors.error,
        ),
      );
    }
  }

  // Méthode pour améliorer une technique
  Future<void> upgradeTechnique(BuildContext context, Technique technique,
      int currentLevel, int upgradeCost) async {
    try {
      if (upgradeCost <= 0) {
        throw Exception('ERR_INVALID_UPGRADE_COST');
      }

      // Vérifier si le joueur a assez d'XP
      if (_playerXp < upgradeCost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'XP insuffisante pour améliorer cette technique (${upgradeCost} XP nécessaires)'),
            backgroundColor: KaiColors.error,
          ),
        );
        return;
      }

      if (_kaijinId.isEmpty) {
        throw Exception('ERR_KAIJIN_NOT_FOUND');
      }

      final newLevel = currentLevel + 1;

      await _firestore.runTransaction((transaction) async {
        final kaijinRef = _firestore.collection('kaijins').doc(_kaijinId);
        final kaijinSnapshot = await transaction.get(kaijinRef);
        if (!kaijinSnapshot.exists) {
          throw Exception('ERR_KAIJIN_NOT_FOUND');
        }

        final currentXp = kaijinSnapshot.data()?['xp'] as int? ?? 0;
        if (currentXp < upgradeCost) {
          throw Exception('ERR_NOT_ENOUGH_XP');
        }

        final relationQuery = await _firestore
            .collection('kaijinTechniques')
            .where('kaijinId', isEqualTo: _kaijinId)
            .where('techniqueId', isEqualTo: technique.id)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (relationQuery.docs.isEmpty) {
          throw Exception('ERR_TECHNIQUE_NOT_UNLOCKED');
        }

        final relationRef = relationQuery.docs.first.reference;
        final storedLevel = relationQuery.docs.first.data()['level'] as int? ?? 1;
        final targetLevel = storedLevel >= newLevel ? storedLevel + 1 : newLevel;

        transaction.update(kaijinRef, {
          'xp': currentXp - upgradeCost,
        });
        transaction.update(relationRef, {
          'level': targetLevel,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // 3. Jouer le son d'amélioration
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/upgrade.mp3'));

      // 4. Rafraîchir les données
      await getCurrentKaijin();
      await loadTechniques();

      // 5. Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Technique améliorée: ${technique.name} (Niveau ${newLevel})'),
          backgroundColor: KaiColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Ne pas fermer la modale, elle sera mise à jour à la prochaine ouverture
    } catch (e) {
      AppLogger.error('Erreur lors de l\'amélioration de la technique', e);
      final message = _mapTechniqueErrorToMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: KaiColors.error,
        ),
      );
    }
  }

  // Récupérer les techniques associées à un kaijin et une technique spécifique
  Future<List<KaijinTechnique>> getKaijinTechniquesForTechnique(
      String techniqueId) async {
    return await _techniqueService.getKaijinTechniquesForTechnique(
        _kaijinId, techniqueId);
  }

  String _mapTechniqueErrorToMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('ERR_NOT_ENOUGH_XP')) {
      return 'XP insuffisante pour cette action.';
    }
    if (raw.contains('ERR_KAIJIN_NOT_FOUND')) {
      return 'Kaijin introuvable. Recharge la session.';
    }
    if (raw.contains('ERR_TECHNIQUE_NOT_UNLOCKED')) {
      return 'Technique non débloquée pour ce personnage.';
    }
    if (raw.contains('ERR_INVALID_UNLOCK_COST') ||
        raw.contains('ERR_INVALID_UPGRADE_COST')) {
      return 'Coût invalide détecté. Réessaie après synchronisation.';
    }
    return 'Une erreur est survenue pendant l\'opération.';
  }
}
