import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/technique.dart';
import '../../models/kaijin_technique.dart';
import '../../models/kaijin.dart';
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

      print(
          'Kaijin sélectionné: ${currentKaijin.name} (dernière connexion: ${currentKaijin.lastConnected})');

      setState(() {
        _kaijinId = currentKaijin.id;
        _kaijinName = currentKaijin.name;
        _playerXp = currentKaijin.xp;
      });
    } catch (e) {
      print('Erreur lors de la récupération du kaijin: $e');
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
        print(
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
      print('Erreur lors du chargement des techniques: $e');

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
      print('Erreur lors du chargement des techniques par défaut: $e');
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
      print('Erreur lors de la mise à jour des techniques: $e');
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
        throw Exception('Aucun kaijin actif trouvé');
      }

      // 1. Déduire l'XP du kaijin en utilisant kaijinId correctement
      await _firestore.collection('kaijins').doc(_kaijinId).update({
        'xp': FieldValue.increment(-technique.xp_unlock_cost),
      });

      // 2. Créer la relation dans la table pivot kaijinTechniques
      await _techniqueService.addTechniqueToKaijin(_kaijinId, technique.id);

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
      print('Erreur lors du débloquage de la technique: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du débloquage de la technique'),
          backgroundColor: KaiColors.error,
        ),
      );
    }
  }

  // Méthode pour améliorer une technique
  Future<void> upgradeTechnique(BuildContext context, Technique technique,
      int currentLevel, int upgradeCost) async {
    try {
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
        throw Exception('Aucun kaijin actif trouvé');
      }

      final newLevel = currentLevel + 1;

      // 1. Améliorer la technique via le service
      await _techniqueService.upgradeTechnique(
          _kaijinId, technique.id, newLevel);

      // 2. Déduire l'XP du kaijin
      await _firestore.collection('kaijins').doc(_kaijinId).update({
        'xp': FieldValue.increment(-upgradeCost),
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
      print('Erreur lors de l\'amélioration de la technique: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'amélioration de la technique'),
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
}
