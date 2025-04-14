import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/technique.dart';
import '../models/ninja_technique.dart';
import '../models/ninja.dart';
import '../services/ninja_service.dart';
import '../services/technique_service.dart';
import '../styles/kai_colors.dart';

class TechniqueTreeScreen extends StatefulWidget {
  const TechniqueTreeScreen({Key? key}) : super(key: key);

  @override
  _TechniqueTreeScreenState createState() => _TechniqueTreeScreenState();
}

class _TechniqueTreeScreenState extends State<TechniqueTreeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TechniqueService _techniqueService = TechniqueService();
  final NinjaService _ninjaService = NinjaService();

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
  bool _isLoading = true;
  int _playerXp = 0;
  String _ninjaId = '';
  String _ninjaName = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentNinja();
    await _loadTechniques();
  }

  // Récupérer le ninja actuel
  Future<void> _getCurrentNinja() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Récupérer les ninjas de l'utilisateur avec NinjaService
      final ninjas = await _ninjaService.getNinjasByUser(user.uid);

      if (ninjas.isEmpty) {
        throw Exception('Aucun personnage trouvé pour l\'utilisateur');
      }

      // Trier les ninjas par date de dernière connexion (du plus récent au moins récent)
      ninjas.sort((a, b) => b.lastConnected.compareTo(a.lastConnected));

      // Utiliser le ninja le plus récemment connecté
      final currentNinja = ninjas.first;

      print(
          'Ninja sélectionné: ${currentNinja.name} (dernière connexion: ${currentNinja.lastConnected})');

      setState(() {
        _ninjaId = currentNinja.id;
        _ninjaName = currentNinja.name;
        _playerXp = currentNinja.xp;
      });
    } catch (e) {
      print('Erreur lors de la récupération du ninja: $e');
      setState(() {
        _ninjaId = '';
        _ninjaName = 'Fracturé inconnu';
        _playerXp = 0;
      });
    }
  }

  Future<void> _loadTechniques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier que nous avons un ID de ninja valide
      if (_ninjaId.isEmpty) {
        print('Aucun ninja actif trouvé, impossible de charger les techniques');
        // Charger les techniques par défaut à la place
        await _loadDefaultTechniques();
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

      // Récupérer les techniques associées au ninja via la table pivot
      final ninjaTechniques =
          await _techniqueService.getNinjaTechniques(_ninjaId);

      // Set des IDs de techniques déjà associées au ninja
      final Set<String> ninjaTechniqueIds =
          ninjaTechniques.map((nt) => nt.techniqueId).toSet();

      // Organisation des techniques par niveau
      final Map<int, List<Technique>> techniquesByLevel = {};

      for (var doc in querySnapshot.docs) {
        final technique = Technique.fromFirestore(doc);

        // Mise à jour du statut de débloquage basé sur la table pivot
        final bool isUnlocked = ninjaTechniqueIds.contains(technique.id);

        // Créer une copie avec le statut de débloquage mis à jour
        final updatedTechnique = Technique(
          id: technique.id,
          name: technique.name,
          description: technique.description,
          cost: technique.cost,
          powerPerSecond: technique.powerPerSecond,
          sound: technique.sound,
          type: technique.type,
          trigger: technique.trigger,
          effect: technique.effect,
          chakraCost: technique.chakraCost,
          cooldown: technique.cooldown,
          animation: technique.animation,
          isDefault: technique.isDefault,
          level: technique.level,
          affinity: technique.affinity,
          effectDetails: technique.effectDetails,
          conditionGenerated: technique.conditionGenerated,
          unlocked: isUnlocked,
          techLevel: technique.techLevel,
          parentTechId: technique.parentTechId,
        );

        // Ajouter à la map par niveau
        if (!techniquesByLevel.containsKey(updatedTechnique.techLevel)) {
          techniquesByLevel[updatedTechnique.techLevel] = [];
        }
        techniquesByLevel[updatedTechnique.techLevel]?.add(updatedTechnique);
      }

      setState(() {
        _techniquesByLevel = techniquesByLevel;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des techniques: $e');

      // En cas d'erreur, charger les techniques par défaut
      _loadDefaultTechniques();
    }
  }

  // Méthode de secours pour charger les techniques par défaut
  Future<void> _loadDefaultTechniques() async {
    try {
      final defaultTechniques = await _techniqueService.getDefaultTechniques();

      final Map<int, List<Technique>> techniquesByLevel = {};

      for (var technique in defaultTechniques) {
        // Ajouter à la map par niveau
        if (!techniquesByLevel.containsKey(technique.techLevel)) {
          techniquesByLevel[technique.techLevel] = [];
        }
        techniquesByLevel[technique.techLevel]?.add(technique);
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

  Future<void> _unlockTechnique(Technique technique) async {
    try {
      // Vérifier si le joueur a assez d'XP
      if (_playerXp < technique.cost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'XP insuffisante pour débloquer cette technique (${technique.cost} XP nécessaires)'),
            backgroundColor: KaiColors.error,
          ),
        );
        return;
      }

      if (_ninjaId.isEmpty) {
        throw Exception('Aucun ninja actif trouvé');
      }

      // 1. Déduire l'XP du ninja en utilisant ninjaId correctement
      await _firestore.collection('ninjas').doc(_ninjaId).update({
        'xp': FieldValue.increment(-technique.cost),
      });

      // 2. Marquer la technique comme débloquée pour l'utilisateur
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('techniques')
          .doc(technique.id)
          .set({
        'unlocked': true,
        'unlockedAt': FieldValue.serverTimestamp(),
      });

      // 3. Créer la relation dans la table pivot ninjaTechniques
      await _techniqueService.addTechniqueToNinja(_ninjaId, technique.id);

      // 4. Rafraîchir les données
      await _getCurrentNinja();
      await _loadTechniques();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaiColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arbre des Techniques',
              style: TextStyle(color: KaiColors.textPrimary),
            ),
            Text(
              'Fracturé: $_ninjaName',
              style: TextStyle(
                color: KaiColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: KaiColors.primaryDark,
        iconTheme: IconThemeData(color: KaiColors.textPrimary),
        elevation: 8.0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KaiColors.primaryDark,
                KaiColors.primaryDark.withOpacity(0.8),
                KaiColors.accent.withOpacity(0.3),
              ],
            ),
          ),
        ),
        actions: [
          // Filtre par affinité
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            margin: EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              color: KaiColors.cardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<String>(
              value: _selectedAffinity,
              dropdownColor: KaiColors.primaryDark,
              style: TextStyle(color: KaiColors.textPrimary),
              icon: Icon(Icons.filter_list, color: KaiColors.accent),
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedAffinity = newValue;
                  });
                }
              },
              items: _affinities.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
              ),
            )
          : Column(
              children: [
                // XP disponible
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KaiColors.primaryDark,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KaiColors.primaryDark,
                        KaiColors.primaryDark.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'XP disponible:',
                        style: TextStyle(
                          color: KaiColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: KaiColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '$_playerXp',
                          style: TextStyle(
                            color: KaiColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arbre des techniques
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/academy.webp'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          KaiColors.primaryDark.withOpacity(0.8),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: _techniquesByLevel.length,
                      itemBuilder: (context, index) {
                        // Niveau de technique (index + 1 car les niveaux commencent à 1)
                        final level = index + 1;
                        final techniques = _techniquesByLevel[level] ?? [];

                        // Filtrer par affinité si nécessaire
                        final filteredTechniques = _selectedAffinity == 'Tous'
                            ? techniques
                            : techniques
                                .where((t) => t.affinity == _selectedAffinity)
                                .toList();

                        if (filteredTechniques.isEmpty) {
                          return SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre du niveau
                            Container(
                              margin:
                                  EdgeInsets.only(top: 16, left: 16, right: 16),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    KaiColors.primaryDark,
                                    KaiColors.accent.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.insights,
                                    color: KaiColors.accent,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Niveau $level',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: KaiColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Grille de techniques
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: filteredTechniques.length,
                              itemBuilder: (context, techIndex) {
                                final technique = filteredTechniques[techIndex];

                                // Déterminer si la technique peut être débloquée
                                // Pour niveau 1, toujours disponible
                                // Pour niveau supérieur, vérifier si parent débloqué
                                bool canUnlock = technique.techLevel == 1 ||
                                    (technique.parentTechId != null &&
                                        _techniquesByLevel.values
                                            .expand((techList) => techList)
                                            .where((t) =>
                                                t.id == technique.parentTechId)
                                            .any((t) => t.unlocked));

                                return _buildTechniqueCard(technique, level);
                              },
                            ),
                            SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTechniqueCard(Technique technique, int level) {
    // Couleur basée sur l'affinité
    Color affinityColor;
    switch (technique.affinity) {
      case 'Flux':
        affinityColor = KaiColors.fluxColor;
        break;
      case 'Fracture':
        affinityColor = KaiColors.fractureColor;
        break;
      case 'Sceau':
        affinityColor = KaiColors.sealColor;
        break;
      case 'Dérive':
        affinityColor = KaiColors.driftColor;
        break;
      case 'Frappe':
        affinityColor = KaiColors.strikeColor;
        break;
      default:
        affinityColor = KaiColors.textSecondary;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: technique.unlocked
              ? affinityColor.withOpacity(0.7)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      elevation: 8,
      color: KaiColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTechniqueDetails(technique),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: technique.unlocked
                  ? [
                      affinityColor.withOpacity(0.2),
                      KaiColors.cardBackground,
                    ]
                  : [
                      KaiColors.cardBackground,
                      KaiColors.cardBackground,
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Contenu de la carte
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et icône d'affinité
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            technique.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: technique.unlocked
                                  ? KaiColors.textPrimary
                                  : KaiColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: affinityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: affinityColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            technique.affinity ?? 'Neutre',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: affinityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Description
                    Text(
                      technique.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: technique.unlocked
                            ? KaiColors.textSecondary
                            : KaiColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 12),
                    Spacer(),
                    // Puissance
                    Text(
                      _techniqueService.getFormattedPower(technique),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: technique.unlocked
                            ? KaiColors.accent
                            : KaiColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Coût et niveau
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _techniqueService.getFormattedCost(technique),
                          style: TextStyle(
                            fontSize: 12,
                            color: technique.unlocked
                                ? KaiColors.textSecondary
                                : KaiColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                        if (technique.unlocked)
                          Text(
                            _techniqueService.getFormattedLevel(technique),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: KaiColors.accent,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Indicateur de technique verrouillée
              if (!technique.unlocked)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            color: KaiColors.textSecondary.withOpacity(0.7),
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'XP Requis: ${technique.cost}',
                            style: TextStyle(
                              color: KaiColors.textSecondary.withOpacity(0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTechniqueDetails(Technique technique) async {
    // Récupérer le niveau actuel de la technique pour ce ninja (si déjà débloquée)
    int techLevel = 1;
    NinjaTechnique? ninjaTechnique;

    if (technique.unlocked) {
      final relations = await _techniqueService.getNinjaTechniquesForTechnique(
          _ninjaId, technique.id);
      if (relations.isNotEmpty) {
        ninjaTechnique = relations.first;
        techLevel = ninjaTechnique.level;
      }
    }

    // Calculer le coût d'amélioration (augmente de 50% à chaque niveau)
    int upgradeCost = (technique.cost * 0.5 * techLevel).round();

    // Calculer les statistiques en fonction du niveau
    double powerMultiplier = 1.0 + (0.25 * (techLevel - 1));
    int currentPower = (technique.powerPerSecond * powerMultiplier).round();
    int nextLevelPower =
        (technique.powerPerSecond * (powerMultiplier + 0.25)).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: KaiColors.primaryDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec le nom de la technique
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        KaiColors.primaryDark,
                        KaiColors.accent.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              technique.name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: KaiColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              technique.affinity ?? 'Neutre',
                              style: TextStyle(
                                fontSize: 14,
                                color: KaiColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: KaiColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Contenu principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status de débloquage
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: technique.unlocked
                                ? KaiColors.success.withOpacity(0.1)
                                : KaiColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: technique.unlocked
                                  ? KaiColors.success.withOpacity(0.5)
                                  : KaiColors.accent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                technique.unlocked
                                    ? Icons.check_circle
                                    : Icons.lock,
                                color: technique.unlocked
                                    ? KaiColors.success
                                    : KaiColors.accent,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  technique.unlocked
                                      ? 'Technique débloquée (Niveau $techLevel)'
                                      : 'Technique verrouillée',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: technique.unlocked
                                        ? KaiColors.success
                                        : KaiColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        // Description
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: KaiColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          technique.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: KaiColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 24),
                        // Statistiques
                        Text(
                          'Statistiques',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: KaiColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),
                        // Grille de statistiques
                        GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatItem(
                                'Type', technique.type.toUpperCase()),
                            _buildStatItem(
                                'Coût Kai', '${technique.chakraCost}'),
                            _buildStatItem('Puissance', '$currentPower'),
                            _buildStatItem(
                                'Temps de recharge', '${technique.cooldown}s'),
                            if (technique.type == 'auto' &&
                                technique.trigger != null)
                              _buildStatItem('Déclencheur', technique.trigger!),
                            if (technique.conditionGenerated != null)
                              _buildStatItem(
                                  'Génère', technique.conditionGenerated!),
                          ],
                        ),

                        // Niveau et progression
                        if (technique.unlocked) ...[
                          SizedBox(height: 24),
                          Text(
                            'Niveau et Amélioration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: KaiColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 12),
                          // Niveau actuel
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: KaiColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Niveau actuel: $techLevel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: KaiColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Prochain: ${techLevel + 1}',
                                      style: TextStyle(
                                        color: KaiColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Comparaison des statistiques
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Puissance',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: KaiColors.textSecondary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '$currentPower',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: KaiColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: KaiColors.accent,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Prochaine',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: KaiColors.textSecondary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '$nextLevelPower',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: KaiColors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Bouton d'amélioration
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _playerXp >= upgradeCost
                                        ? () => _upgradeTechnique(
                                            technique, techLevel, upgradeCost)
                                        : null,
                                    icon: Icon(Icons.upgrade),
                                    label: Text(
                                      _playerXp >= upgradeCost
                                          ? 'Améliorer ($upgradeCost XP)'
                                          : 'XP insuffisante (${_playerXp}/$upgradeCost)',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: KaiColors.accent,
                                      foregroundColor: KaiColors.primaryDark,
                                      disabledBackgroundColor: Colors.grey,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Bouton d'action (débloquer si non débloqué)
                if (!technique.unlocked)
                  Container(
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _playerXp >= technique.cost
                          ? () {
                              Navigator.pop(context);
                              _unlockTechnique(technique);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KaiColors.accent,
                        foregroundColor: KaiColors.primaryDark,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open),
                          SizedBox(width: 8),
                          Text(
                            _playerXp >= technique.cost
                                ? 'Débloquer (${technique.cost} XP)'
                                : 'XP insuffisante (${_playerXp}/${technique.cost})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 8, right: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KaiColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: KaiColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: KaiColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _upgradeTechnique(
      Technique technique, int currentLevel, int upgradeCost) async {
    try {
      if (_ninjaId.isEmpty) {
        throw Exception('Aucun ninja actif trouvé');
      }

      // 1. Déduire l'XP du ninja
      await _firestore.collection('ninjas').doc(_ninjaId).update({
        'xp': FieldValue.increment(-upgradeCost),
      });

      // 2. Mettre à jour le niveau de la technique dans la table pivot
      await _techniqueService.upgradeTechnique(
          _ninjaId, technique.id, currentLevel + 1);

      // 3. Rafraîchir les données
      await _getCurrentNinja();
      await _loadTechniques();

      // 4. Fermer le modal
      Navigator.pop(context);

      // 5. Afficher le message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Technique améliorée au niveau ${currentLevel + 1}'),
          backgroundColor: KaiColors.success,
        ),
      );
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
}
