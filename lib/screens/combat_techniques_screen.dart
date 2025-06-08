import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/technique.dart';
import '../models/kaijin_technique.dart';
import '../models/kaijin.dart';
import '../services/kaijin_service.dart';
import '../services/technique_service.dart';
import '../styles/kai_colors.dart';

class CombatTechniquesScreen extends StatefulWidget {
  const CombatTechniquesScreen({Key? key}) : super(key: key);

  @override
  _CombatTechniquesScreenState createState() => _CombatTechniquesScreenState();
}

class _CombatTechniquesScreenState extends State<CombatTechniquesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TechniqueService _techniqueService = TechniqueService();
  final KaijinService _kaijinService = KaijinService();

  bool _isLoading = true;
  String _kaijinId = '';
  String _kaijinName = '';

  // Techniques du joueur par catégorie
  List<Technique> _activeTechniques = [];
  List<Technique> _autoTechniques = [];
  List<Technique> _passiveTechniques = [];
  List<Technique> _simpleTechniques = [];

  // Techniques sélectionnées pour le combat
  List<Technique> _selectedActives = [];
  List<Technique> _selectedAutos = [];
  List<Technique> _selectedPassives = [];
  Technique? _selectedSimple;

  // Limites de sélection
  final int _maxActives = 4;
  final int _maxAutos = 3;
  final int _maxPassives = 2;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentKaijin();
    await _loadTechniques();
    await _checkForLegacySettings();
    await _loadSelectedTechniques();
  }

  // Récupérer le kaijin actuel
  Future<void> _getCurrentKaijin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Utiliser la nouvelle méthode getCurrentkaijin du service
      final currentKaijin = await _kaijinService.getCurrentKaijin(user.uid);

      if (currentKaijin == null) {
        throw Exception('Aucun personnage trouvé pour l\'utilisateur');
      }

      print(
          'Kaijin sélectionné: ${currentKaijin.name} (dernière connexion: ${currentKaijin.lastConnected})');

      setState(() {
        _kaijinId = currentKaijin.id;
        _kaijinName = currentKaijin.name;
      });
    } catch (e) {
      print('Erreur lors de la récupération du kaijin: $e');
      setState(() {
        _kaijinId = '';
        _kaijinName = 'Fracturé inconnu';
      });
    }
  }

  Future<void> _loadTechniques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_kaijinId.isEmpty) {
        throw Exception('ID du kaijin non disponible');
      }

      // Ne récupérer que les techniques associées au kaijin actuel
      final kaijinTechniques =
          await _techniqueService.getTechniquesForKaijin(_kaijinId);

      // Réinitialiser toutes les listes
      _activeTechniques = [];
      _autoTechniques = [];
      _passiveTechniques = [];
      _simpleTechniques = [];

      // Réinitialiser les sélections
      _selectedActives = [];
      _selectedAutos = [];
      _selectedPassives = [];
      _selectedSimple = null;

      // Trier les techniques débloquées par type
      for (var technique in kaijinTechniques) {
        switch (technique.type) {
          case 'active':
            _activeTechniques.add(technique);
            break;
          case 'auto':
            _autoTechniques.add(technique);
            break;
          case 'passive':
            _passiveTechniques.add(technique);
            break;
          case 'simple':
            _simpleTechniques.add(technique);
            break;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des techniques: $e');
      // En cas d'erreur, initialiser avec des listes vides
      _activeTechniques = [];
      _autoTechniques = [];
      _passiveTechniques = [];
      _simpleTechniques = [];
      _selectedActives = [];
      _selectedAutos = [];
      _selectedPassives = [];
      _selectedSimple = null;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedTechniques() async {
    try {
      // Vérifier que nous avons un ID de kaijin valide
      if (_kaijinId.isEmpty) {
        print(
            'Aucun kaijin actif trouvé, impossible de charger la configuration');
        _initializeDefaultSelection();
        return;
      }

      final snapshot = await _firestore
          .collection('kaijins')
          .doc(_kaijinId)
          .collection('combat_settings')
          .doc('techniques')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        // Techniques actives sélectionnées
        final List<String> activeIds =
            List<String>.from(data['active_techniques'] ?? []);
        // Techniques auto sélectionnées
        final List<String> autoIds =
            List<String>.from(data['auto_techniques'] ?? []);
        // Techniques passives sélectionnées
        final List<String> passiveIds =
            List<String>.from(data['passive_techniques'] ?? []);
        // Technique simple sélectionnée
        final String? simpleId = data['simple_technique'];

        // Ne sélectionner que parmi les techniques déjà chargées (débloquées)
        _selectedActives =
            _activeTechniques.where((t) => activeIds.contains(t.id)).toList();
        _selectedAutos =
            _autoTechniques.where((t) => autoIds.contains(t.id)).toList();
        _selectedPassives =
            _passiveTechniques.where((t) => passiveIds.contains(t.id)).toList();

        // Trouver la technique simple sélectionnée parmi les techniques débloquées
        if (simpleId != null) {
          final matchingTechniques =
              _simpleTechniques.where((t) => t.id == simpleId);
          _selectedSimple =
              matchingTechniques.isNotEmpty ? matchingTechniques.first : null;
        } else {
          _selectedSimple = null;
        }
      } else {
        // Aucune configuration existante, initialiser avec des listes vides
        _initializeDefaultSelection();
      }

      setState(() {});
    } catch (e) {
      print('Erreur lors du chargement des techniques sélectionnées: $e');
      _initializeDefaultSelection();
      setState(() {});
    }
  }

  void _initializeDefaultSelection() {
    // Ne sélectionner aucune technique par défaut si le kaijin n'en a pas débloqué
    _selectedActives = [];
    _selectedAutos = [];
    _selectedPassives = [];
    _selectedSimple = null;
  }

  Future<void> _saveSelectedTechniques() async {
    try {
      // Vérifier que nous avons un ID de kaijin valide
      if (_kaijinId.isEmpty) {
        throw Exception(
            'Aucun kaijin actif trouvé, impossible de sauvegarder la configuration');
      }

      // Préparer les données à sauvegarder
      final Map<String, dynamic> data = {
        'active_techniques': _selectedActives.map((t) => t.id).toList(),
        'auto_techniques': _selectedAutos.map((t) => t.id).toList(),
        'passive_techniques': _selectedPassives.map((t) => t.id).toList(),
        'simple_technique': _selectedSimple?.id,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Enregistrer dans Firestore - directement dans le document du kaijin
      await _firestore
          .collection('kaijins')
          .doc(_kaijinId)
          .collection('combat_settings')
          .doc('techniques')
          .set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration de combat de $_kaijinName sauvegardée'),
          backgroundColor: KaiColors.success,
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde des techniques: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erreur lors de la sauvegarde: ${e.toString().split(':').last}'),
          backgroundColor: KaiColors.error,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: () => _saveSelectedTechniques(),
          ),
        ),
      );
    }
  }

  void _toggleActiveTechnique(Technique technique) {
    setState(() {
      if (_selectedActives.any((t) => t.id == technique.id)) {
        // Retirer de la sélection
        _selectedActives.removeWhere((t) => t.id == technique.id);
      } else if (_selectedActives.length < _maxActives) {
        // Ajouter à la sélection
        _selectedActives.add(technique);
      } else {
        // Remplacer la première technique
        _selectedActives.removeAt(0);
        _selectedActives.add(technique);
      }
    });
  }

  void _toggleAutoTechnique(Technique technique) {
    setState(() {
      if (_selectedAutos.any((t) => t.id == technique.id)) {
        // Retirer de la sélection
        _selectedAutos.removeWhere((t) => t.id == technique.id);
      } else if (_selectedAutos.length < _maxAutos) {
        // Ajouter à la sélection
        _selectedAutos.add(technique);
      } else {
        // Remplacer la première technique
        _selectedAutos.removeAt(0);
        _selectedAutos.add(technique);
      }
    });
  }

  void _togglePassiveTechnique(Technique technique) {
    setState(() {
      if (_selectedPassives.any((t) => t.id == technique.id)) {
        // Retirer de la sélection
        _selectedPassives.removeWhere((t) => t.id == technique.id);
      } else if (_selectedPassives.length < _maxPassives) {
        // Ajouter à la sélection
        _selectedPassives.add(technique);
      } else {
        // Remplacer la première technique
        _selectedPassives.removeAt(0);
        _selectedPassives.add(technique);
      }
    });
  }

  void _setSimpleTechnique(Technique technique) {
    setState(() {
      _selectedSimple = technique;
    });
  }

  // Vérifier si l'utilisateur a une ancienne configuration et la migrer vers le kaijin
  Future<void> _checkForLegacySettings() async {
    try {
      // Ne vérifier que si nous avons un ID de kaijin et un ID d'utilisateur
      if (_kaijinId.isEmpty || _userId.isEmpty) {
        return;
      }

      // Vérifier si une ancienne configuration existe
      final legacySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('combat_settings')
          .doc('techniques')
          .get();

      // Si une ancienne configuration existe, la migrer vers le kaijin
      if (legacySnapshot.exists) {
        final data = legacySnapshot.data() as Map<String, dynamic>;

        // Vérifier si le kaijin a déjà une configuration
        final kaijinConfigSnapshot = await _firestore
            .collection('kaijins')
            .doc(_kaijinId)
            .collection('combat_settings')
            .doc('techniques')
            .get();

        // Ne migrer que si le kaijin n'a pas encore de configuration
        if (!kaijinConfigSnapshot.exists) {
          print(
              'Migration des paramètres de combat depuis l\'utilisateur vers le kaijin');

          // Ajouter un marqueur de migration
          final migratedData = Map<String, dynamic>.from(data);
          migratedData['migrated_from_user'] = true;
          migratedData['migration_date'] = FieldValue.serverTimestamp();

          // Enregistrer dans le document du kaijin
          await _firestore
              .collection('kaijins')
              .doc(_kaijinId)
              .collection('combat_settings')
              .doc('techniques')
              .set(migratedData);

          // Option: Supprimer l'ancienne configuration après migration réussie
          // await _firestore
          //    .collection('users')
          //    .doc(_userId)
          //    .collection('combat_settings')
          //    .doc('techniques')
          //    .delete();
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification des anciens paramètres: $e');
      // Ne pas bloquer le flux principal en cas d'erreur
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
              'Techniques de Combat',
              style: TextStyle(color: KaiColors.textPrimary),
            ),
            Text(
              'Fracturé: $_kaijinName',
              style: TextStyle(
                color: KaiColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: KaiColors.primaryDark,
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
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: KaiColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(Icons.save, color: KaiColors.accent),
              onPressed: _saveSelectedTechniques,
              tooltip: 'Sauvegarder la configuration',
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
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  // Résumé de la sélection actuelle
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
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Techniques sélectionnées:',
                          style: TextStyle(
                            color: KaiColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSelectionSummary(
                                'Actives',
                                _selectedActives.length,
                                _maxActives,
                                Icons.flash_on,
                                Colors.lightBlue),
                            _buildSelectionSummary(
                                'Auto',
                                _selectedAutos.length,
                                _maxAutos,
                                Icons.autorenew,
                                Colors.deepPurple),
                            _buildSelectionSummary(
                                'Passives',
                                _selectedPassives.length,
                                _maxPassives,
                                Icons.shield,
                                Colors.teal),
                            _buildSelectionSummary(
                                'Simple',
                                _selectedSimple != null ? 1 : 0,
                                1,
                                Icons.accessibility_new,
                                Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Onglets pour chaque type de technique
                  Container(
                    decoration: BoxDecoration(
                      color: KaiColors.cardBackground,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.flash_on), text: 'Actives'),
                        Tab(icon: Icon(Icons.autorenew), text: 'Auto'),
                        Tab(icon: Icon(Icons.shield), text: 'Passives'),
                        Tab(
                            icon: Icon(Icons.accessibility_new),
                            text: 'Simple'),
                      ],
                      labelColor: KaiColors.accent,
                      unselectedLabelColor: KaiColors.textSecondary,
                      indicatorColor: KaiColors.accent,
                      indicatorWeight: 3,
                    ),
                  ),
                  // Contenu des onglets
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/chunin_exam.webp'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            KaiColors.primaryDark.withOpacity(0.85),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: TabBarView(
                        children: [
                          // Onglet Techniques Actives
                          _buildTechniqueTab(
                            _activeTechniques,
                            _selectedActives,
                            'Actives',
                            Icons.flash_on,
                            Colors.lightBlue,
                            (t) => _toggleActiveTechnique(t),
                          ),
                          // Onglet Techniques Auto
                          _buildTechniqueTab(
                            _autoTechniques,
                            _selectedAutos,
                            'Auto',
                            Icons.autorenew,
                            Colors.deepPurple,
                            (t) => _toggleAutoTechnique(t),
                          ),
                          // Onglet Techniques Passives
                          _buildTechniqueTab(
                            _passiveTechniques,
                            _selectedPassives,
                            'Passives',
                            Icons.shield,
                            Colors.teal,
                            (t) => _togglePassiveTechnique(t),
                          ),
                          // Onglet Technique Simple
                          _buildTechniqueTab(
                            _simpleTechniques,
                            _selectedSimple != null ? [_selectedSimple!] : [],
                            'Simple',
                            Icons.accessibility_new,
                            Colors.redAccent,
                            (t) => _setSimpleTechnique(t),
                            singleSelection: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectionSummary(
      String label, int count, int max, IconData icon, Color typeColor) {
    final bool isComplete = count == max;
    final double progress = max > 0 ? count / max : 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isComplete
              ? [
                  typeColor.withOpacity(0.2),
                  KaiColors.cardBackground.withOpacity(0.9),
                ]
              : [
                  KaiColors.cardBackground.withOpacity(0.9),
                  KaiColors.cardBackground.withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isComplete
                ? typeColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isComplete ? typeColor.withOpacity(0.7) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isComplete
                      ? typeColor.withOpacity(0.2)
                      : KaiColors.primaryDark.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isComplete ? typeColor : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: isComplete
                      ? [
                          BoxShadow(
                            color: typeColor.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isComplete ? typeColor : KaiColors.textSecondary,
                ),
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isComplete ? typeColor : KaiColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Barre de progression stylisée
          Container(
            height: 24,
            width: 60,
            decoration: BoxDecoration(
              color: KaiColors.primaryDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KaiColors.primaryDark,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Barre de progression
                Container(
                  height: 22,
                  width: 58 * progress,
                  margin: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        typeColor,
                        typeColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isComplete
                        ? [
                            BoxShadow(
                              color: typeColor.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
                // Texte centré sur la barre
                Center(
                  child: Text(
                    '$count/$max',
                    style: TextStyle(
                      color: KaiColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueTab(
      List<Technique> allTechniques,
      List<Technique> selectedTechniques,
      String tabTitle,
      IconData tabIcon,
      Color iconColor,
      Function(Technique) toggleFunction,
      {bool singleSelection = false}) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre du niveau avec style amélioré
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    KaiColors.primaryDark,
                    iconColor.withOpacity(0.3),
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
                    tabIcon,
                    color: iconColor,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Techniques $tabTitle (${selectedTechniques.length}/${tabTitle == 'Actives' ? _maxActives : tabTitle == 'Auto' ? _maxAutos : tabTitle == 'Passives' ? _maxPassives : 1})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: KaiColors.textPrimary,
                      ),
                    ),
                  ),
                  if (selectedTechniques.length ==
                      (tabTitle == 'Actives'
                          ? _maxActives
                          : tabTitle == 'Auto'
                              ? _maxAutos
                              : tabTitle == 'Passives'
                                  ? _maxPassives
                                  : 1))
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: KaiColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: KaiColors.success,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
            // Grille de techniques
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: allTechniques.length,
              itemBuilder: (context, index) {
                final technique = allTechniques[index];
                final isSelected =
                    selectedTechniques.any((t) => t.id == technique.id);

                return _buildTechniqueCard(
                  technique,
                  isSelected,
                  toggleFunction,
                );
              },
            ),
            // Message si aucune technique disponible
            if (allTechniques.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(top: 32),
                decoration: BoxDecoration(
                  color: KaiColors.cardBackground.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: KaiColors.accent,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune technique disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: KaiColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Explorez l\'Arbre des Techniques pour débloquer des techniques de type $tabTitle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/technique_tree');
                      },
                      icon: Icon(Icons.bolt),
                      label: Text('Arbre des Techniques'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KaiColors.accent,
                        foregroundColor: KaiColors.primaryDark,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniqueCard(
    Technique technique,
    bool isSelected,
    Function(Technique) toggleFunction,
  ) {
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

    // Couleur basée sur le type d'effet
    Color effectColor;
    IconData effectIcon;
    switch (technique.effect) {
      case 'damage':
        effectColor = Colors.redAccent;
        effectIcon = Icons.flash_on;
        break;
      case 'heal':
        effectColor = Colors.greenAccent;
        effectIcon = Icons.healing;
        break;
      case 'push':
        effectColor = Colors.orangeAccent;
        effectIcon = Icons.arrow_forward;
        break;
      case 'stun':
        effectColor = Colors.purpleAccent;
        effectIcon = Icons.blur_on;
        break;
      case 'shield':
        effectColor = Colors.blueAccent;
        effectIcon = Icons.shield;
        break;
      default:
        effectColor = Colors.grey;
        effectIcon = Icons.device_unknown;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? KaiColors.accent.withOpacity(0.7)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      elevation: 8,
      color: KaiColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => toggleFunction(technique),
        onLongPress: () => _showTechniqueDetails(technique),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      KaiColors.accent.withOpacity(0.2),
                      KaiColors.cardBackground,
                    ]
                  : [
                      affinityColor.withOpacity(0.1),
                      KaiColors.cardBackground,
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Contenu de la carte
              Padding(
                padding: EdgeInsets.all(14),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: KaiColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: affinityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: affinityColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            technique.affinity ?? 'Neutre',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: affinityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    // Type de technique
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: KaiColors.primaryDark.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        technique.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: KaiColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    // Description
                    Text(
                      technique.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Statistiques détaillées
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Coût en Kai
                        _buildStatBadge(
                          Icons.water_drop,
                          '${technique.cost_kai}',
                          Colors.blueAccent,
                        ),
                        // Temps de recharge
                        _buildStatBadge(
                          Icons.timer,
                          '${technique.cooldown} tours',
                          Colors.amberAccent,
                        ),
                        // Effet
                        _buildStatBadge(
                          effectIcon,
                          technique.effect,
                          effectColor,
                        ),
                        // Trigger pour les techniques auto
                        if (technique.type == 'auto' &&
                            technique.trigger != null)
                          _buildStatBadge(
                            Icons.bolt,
                            'Déclenche: ${technique.trigger}',
                            Colors.purpleAccent,
                          ),
                        // Condition générée
                        if (technique.condition_generated != null)
                          _buildStatBadge(
                            Icons.add_circle_outline,
                            'Génère: ${technique.condition_generated}',
                            Colors.greenAccent,
                          ),
                      ],
                    ),
                    Spacer(),
                    // Puissance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _techniqueService.getFormattedPower(technique),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: KaiColors.accent,
                          ),
                        ),
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
              // Indicateur de technique sélectionnée
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: KaiColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: KaiColors.primaryDark,
                      size: 16,
                    ),
                  ),
                ),
              // Indicateur d'aide
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: KaiColors.primaryDark.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KaiColors.textSecondary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: KaiColors.textSecondary,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Affiche un dialogue avec tous les détails de la technique
  void _showTechniqueDetails(Technique technique) {
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
        affinityColor = KaiColors.accent;
    }

    // Calculer la puissance actuelle en fonction du niveau
    double powerMultiplier = 1.0 + (0.25 * (technique.level - 1));
    int currentPower = (technique.damage * powerMultiplier).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                    affinityColor.withOpacity(0.3),
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
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: affinityColor.withOpacity(0.2),
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
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: KaiColors.primaryDark.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                technique.type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: KaiColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
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
                    // Statistiques principales
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
                            'Niveau', '${technique.level}', Icons.upgrade),
                        _buildStatItem('Type', technique.type.toUpperCase(),
                            Icons.category),
                        _buildStatItem('Affinité',
                            technique.affinity ?? 'Neutre', Icons.auto_awesome),
                        _buildStatItem(
                            'Effet', technique.effect, Icons.flash_on),
                        _buildStatItem('Coût Kai', '${technique.cost_kai}',
                            Icons.water_drop),
                        _buildStatItem('Recharge',
                            '${technique.cooldown} tours', Icons.timer),
                        _buildStatItem(
                            'Puissance', '$currentPower', Icons.bolt),
                      ],
                    ),
                    // Déclencheurs (trigger)
                    if (technique.trigger != null) ...[
                      SizedBox(height: 24),
                      Text(
                        'Déclencheur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: KaiColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: KaiColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.purpleAccent.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: Colors.purpleAccent,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                technique.trigger!,
                                style: TextStyle(
                                  color: KaiColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Condition de déclenchement
                    if (technique.trigger_condition != null) ...[
                      SizedBox(height: 24),
                      Text(
                        'Condition de déclenchement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: KaiColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: KaiColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.priority_high,
                              color: Colors.orangeAccent,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                technique.trigger_condition!,
                                style: TextStyle(
                                  color: KaiColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Condition générée
                    if (technique.condition_generated != null) ...[
                      SizedBox(height: 24),
                      Text(
                        'Condition générée',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: KaiColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: KaiColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.greenAccent.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.greenAccent,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                technique.condition_generated!,
                                style: TextStyle(
                                  color: KaiColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Détails des effets
                    if (technique.effectDetails != null) ...[
                      SizedBox(height: 24),
                      Text(
                        'Détails des effets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: KaiColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...technique.effectDetails!.entries.map((entry) {
                        return Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: KaiColors.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: KaiColors.accent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: KaiColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      entry.value.toString(),
                                      style: TextStyle(
                                        color: KaiColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les statisiques dans les détails
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8, right: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KaiColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: KaiColors.accent,
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: KaiColors.textSecondary,
                ),
              ),
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
        ],
      ),
    );
  }

  // Badge pour les statistiques
  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: KaiColors.primaryDark.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: KaiColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
