import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/technique.dart';
import '../styles/kai_colors.dart';

class CombatTechniquesScreen extends StatefulWidget {
  const CombatTechniquesScreen({Key? key}) : super(key: key);

  @override
  _CombatTechniquesScreenState createState() => _CombatTechniquesScreenState();
}

class _CombatTechniquesScreenState extends State<CombatTechniquesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isLoading = true;

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
    _loadTechniques();
    _loadSelectedTechniques();
  }

  Future<void> _loadTechniques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer toutes les techniques débloquées par le joueur
      final userTechniquesSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('techniques')
          .where('unlocked', isEqualTo: true)
          .get();

      final userTechniqueIds =
          userTechniquesSnapshot.docs.map((doc) => doc.id).toSet();

      // Récupérer les détails complets des techniques
      final techniqueSnapshot = await _firestore.collection('techniques').get();

      // Trier les techniques par type
      _activeTechniques = [];
      _autoTechniques = [];
      _passiveTechniques = [];
      _simpleTechniques = [];

      for (var doc in techniqueSnapshot.docs) {
        final technique = Technique.fromFirestore(doc);

        // Vérifier si la technique est débloquée par le joueur ou est par défaut
        if (userTechniqueIds.contains(technique.id) || technique.isDefault) {
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
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des techniques: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedTechniques() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
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

        // Chargement des données complètes des techniques
        final allTechsSnapshot =
            await _firestore.collection('techniques').get();
        final allTechniques = allTechsSnapshot.docs
            .map((doc) => Technique.fromFirestore(doc))
            .toList();

        // Mise à jour des listes de techniques sélectionnées
        _selectedActives =
            allTechniques.where((t) => activeIds.contains(t.id)).toList();
        _selectedAutos =
            allTechniques.where((t) => autoIds.contains(t.id)).toList();
        _selectedPassives =
            allTechniques.where((t) => passiveIds.contains(t.id)).toList();

        // Correction du problème de typage pour _selectedSimple
        if (simpleId != null) {
          final matchingTechniques =
              allTechniques.where((t) => t.id == simpleId);
          if (matchingTechniques.isNotEmpty) {
            _selectedSimple = matchingTechniques.first;
          } else if (_simpleTechniques.isNotEmpty) {
            final defaultTechs = _simpleTechniques.where((t) => t.isDefault);
            _selectedSimple = defaultTechs.isNotEmpty
                ? defaultTechs.first
                : _simpleTechniques.first;
          } else if (allTechniques.isNotEmpty) {
            _selectedSimple = allTechniques.first;
          }
        } else if (_simpleTechniques.isNotEmpty) {
          final defaultTechs = _simpleTechniques.where((t) => t.isDefault);
          _selectedSimple = defaultTechs.isNotEmpty
              ? defaultTechs.first
              : _simpleTechniques.first;
        }
      } else {
        // Aucune configuration existante, utiliser des valeurs par défaut
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
    // Sélectionner les techniques par défaut
    _selectedActives =
        _activeTechniques.where((t) => t.isDefault).take(_maxActives).toList();
    _selectedAutos =
        _autoTechniques.where((t) => t.isDefault).take(_maxAutos).toList();
    _selectedPassives = _passiveTechniques
        .where((t) => t.isDefault)
        .take(_maxPassives)
        .toList();

    // La fonction firstWhere avec orElse doit retourner un objet Technique et non null
    if (_simpleTechniques.isNotEmpty) {
      final defaultTechs = _simpleTechniques.where((t) => t.isDefault).toList();
      _selectedSimple = defaultTechs.isNotEmpty
          ? defaultTechs.first
          : _simpleTechniques.first;
    } else {
      _selectedSimple = null;
    }
  }

  Future<void> _saveSelectedTechniques() async {
    try {
      // Préparer les données à sauvegarder
      final Map<String, dynamic> data = {
        'active_techniques': _selectedActives.map((t) => t.id).toList(),
        'auto_techniques': _selectedAutos.map((t) => t.id).toList(),
        'passive_techniques': _selectedPassives.map((t) => t.id).toList(),
        'simple_technique': _selectedSimple?.id,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Enregistrer dans Firestore
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('combat_settings')
          .doc('techniques')
          .set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration de combat sauvegardée'),
          backgroundColor: KaiColors.success,
        ),
      );
    } catch (e) {
      print('Erreur lors de la sauvegarde des techniques: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde'),
          backgroundColor: KaiColors.error,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaiColors.background,
      appBar: AppBar(
        title: const Text(
          'Techniques de Combat',
          style: TextStyle(color: KaiColors.textPrimary),
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
                          _buildTechniqueList(
                            _activeTechniques,
                            _selectedActives,
                            (t) => _toggleActiveTechnique(t),
                            'active',
                            _maxActives,
                          ),
                          // Onglet Techniques Auto
                          _buildTechniqueList(
                            _autoTechniques,
                            _selectedAutos,
                            (t) => _toggleAutoTechnique(t),
                            'auto',
                            _maxAutos,
                          ),
                          // Onglet Techniques Passives
                          _buildTechniqueList(
                            _passiveTechniques,
                            _selectedPassives,
                            (t) => _togglePassiveTechnique(t),
                            'passive',
                            _maxPassives,
                          ),
                          // Onglet Technique Simple
                          _buildTechniqueList(
                            _simpleTechniques,
                            _selectedSimple != null ? [_selectedSimple!] : [],
                            (t) => _setSimpleTechnique(t),
                            'simple',
                            1,
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
    final double progress = count / max;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KaiColors.cardBackground.withOpacity(0.8),
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
          color: isComplete ? typeColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isComplete ? typeColor : KaiColors.textSecondary,
              ),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isComplete ? typeColor : KaiColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Stack(
            children: [
              // Barre de fond
              Container(
                height: 4,
                width: 60,
                decoration: BoxDecoration(
                  color: KaiColors.primaryDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Barre de progression
              Container(
                height: 4,
                width: 60 * progress,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(2),
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
            ],
          ),
          SizedBox(height: 2),
          Text(
            '$count/$max',
            style: TextStyle(
              color: KaiColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueList(
      List<Technique> techniques,
      List<Technique> selectedTechniques,
      Function(Technique) onToggle,
      String type,
      int maxSelection,
      {bool singleSelection = false}) {
    if (techniques.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(20),
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
                Icons.warning_amber_rounded,
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
                'Débloque de nouvelles techniques dans l\'arbre des techniques',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: KaiColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: techniques.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final technique = techniques[index];
        final isSelected = singleSelection
            ? _selectedSimple?.id == technique.id
            : selectedTechniques.any((t) => t.id == technique.id);

        return _buildTechniqueListItem(
          technique,
          isSelected,
          () => onToggle(technique),
          type,
          selectedTechniques.length,
          maxSelection,
          singleSelection,
        );
      },
    );
  }

  Widget _buildTechniqueListItem(
    Technique technique,
    bool isSelected,
    Function() onToggle,
    String type,
    int currentCount,
    int maxCount,
    bool singleSelection,
  ) {
    // Couleur basée sur l'affinité
    Color affinityColor;
    switch (technique.affinity) {
      case 'Flux':
        affinityColor = Colors.lightBlue;
        break;
      case 'Fracture':
        affinityColor = Colors.deepPurple;
        break;
      case 'Sceau':
        affinityColor = Colors.amber;
        break;
      case 'Dérive':
        affinityColor = Colors.teal;
        break;
      case 'Frappe':
        affinityColor = Colors.redAccent;
        break;
      default:
        affinityColor = KaiColors.accent;
    }

    return Card(
      elevation: 8,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? affinityColor : Colors.transparent,
          width: 2,
        ),
      ),
      color: KaiColors.cardBackground,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      KaiColors.cardBackground,
                      affinityColor.withOpacity(0.15),
                    ]
                  : [
                      KaiColors.cardBackground,
                      KaiColors.cardBackground.withOpacity(0.7),
                    ],
            ),
          ),
          child: Row(
            children: [
              // Icône de sélection
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isSelected
                        ? [affinityColor, affinityColor.withOpacity(0.7)]
                        : [Colors.grey[800]!, Colors.grey[700]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? affinityColor.withOpacity(0.3)
                          : Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    singleSelection
                        ? (isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked)
                        : (isSelected ? Icons.check : Icons.add),
                    color: KaiColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Détails de la technique
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et affinité
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            technique.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: KaiColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: affinityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: affinityColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            technique.affinity ?? 'Neutre',
                            style: TextStyle(
                              color: affinityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Description
                    Text(
                      technique.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    // Détails techniques
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildTechniqueDetail(
                          'Kai: ${technique.chakraCost}',
                          Icons.water_drop,
                          affinityColor,
                        ),
                        _buildTechniqueDetail(
                          'CD: ${technique.cooldown}',
                          Icons.timelapse,
                          affinityColor,
                        ),
                        if (technique.conditionGenerated != null)
                          _buildTechniqueDetail(
                            'Génère: ${technique.conditionGenerated}',
                            Icons.add_circle_outline,
                            affinityColor,
                          ),
                        if (type == 'auto' && technique.trigger != null)
                          _buildTechniqueDetail(
                            'Si: ${technique.trigger}',
                            Icons.bolt,
                            affinityColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechniqueDetail(
      String text, IconData icon, Color affinityColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: KaiColors.primaryDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: affinityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: affinityColor,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: KaiColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
