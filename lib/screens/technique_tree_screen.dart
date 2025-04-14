import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/technique.dart';
import '../styles/kai_colors.dart';

class TechniqueTreeScreen extends StatefulWidget {
  const TechniqueTreeScreen({Key? key}) : super(key: key);

  @override
  _TechniqueTreeScreenState createState() => _TechniqueTreeScreenState();
}

class _TechniqueTreeScreenState extends State<TechniqueTreeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
  int _playerPuissance = 0;

  @override
  void initState() {
    super.initState();
    _loadTechniques();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        setState(() {
          _playerPuissance = doc.data()?['puissance'] ?? 0;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données joueur: $e');
    }
  }

  Future<void> _loadTechniques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await _firestore.collection('techniques').get();

      // Récupération des techniques débloquées par le joueur
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

      // Organisation des techniques par niveau
      final Map<int, List<Technique>> techniquesByLevel = {};

      for (var doc in querySnapshot.docs) {
        final technique = Technique.fromFirestore(doc);

        // Mise à jour du statut de débloquage basé sur les données utilisateur
        final bool isUnlocked =
            unlockedTechniques[technique.id] ?? technique.unlocked;

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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _unlockTechnique(Technique technique) async {
    try {
      // Vérifier si le joueur a assez de puissance
      if (_playerPuissance < technique.cost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Puissance insuffisante pour débloquer cette technique'),
            backgroundColor: KaiColors.error,
          ),
        );
        return;
      }

      // Mettre à jour la technique pour le joueur
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('techniques')
          .doc(technique.id)
          .set({
        'unlocked': true,
        'level': 1,
      });

      // Déduire le coût de puissance
      await _firestore.collection('users').doc(_userId).update({
        'puissance': FieldValue.increment(-technique.cost),
      });

      // Rafraîchir les données
      await _loadTechniques();
      await _loadPlayerData();

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
        title: const Text(
          'Arbre des Techniques',
          style: TextStyle(color: KaiColors.textPrimary),
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
                // Puissance disponible
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
                        'Puissance disponible:',
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
                          '$_playerPuissance',
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

                                return _buildTechniqueCard(
                                    technique, canUnlock);
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

  Widget _buildTechniqueCard(Technique technique, bool canUnlock) {
    // Déterminer la couleur en fonction de l'affinité
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

    // Icône en fonction du type de technique
    IconData typeIcon;
    switch (technique.type) {
      case 'active':
        typeIcon = Icons.flash_on;
        break;
      case 'auto':
        typeIcon = Icons.autorenew;
        break;
      case 'passive':
        typeIcon = Icons.shield;
        break;
      case 'simple':
        typeIcon = Icons.accessibility_new;
        break;
      default:
        typeIcon = Icons.help_outline;
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: technique.unlocked ? affinityColor : Colors.grey[700]!,
          width: 2,
        ),
      ),
      color: KaiColors.cardBackground,
      child: InkWell(
        onTap: () {
          _showTechniqueDetails(technique, canUnlock);
        },
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: technique.unlocked
                  ? [
                      KaiColors.cardBackground,
                      affinityColor.withOpacity(0.15),
                    ]
                  : [
                      KaiColors.cardBackground,
                      KaiColors.cardBackground.withOpacity(0.8),
                    ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Afficher type et affinité
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: affinityColor.withOpacity(0.8),
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
                      technique.affinity ?? 'Neutre',
                      style: TextStyle(
                        color: KaiColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: technique.unlocked
                          ? affinityColor.withOpacity(0.2)
                          : KaiColors.cardBackground.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      typeIcon,
                      color:
                          technique.unlocked ? affinityColor : Colors.grey[600],
                      size: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Nom de la technique
              Text(
                technique.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: technique.unlocked
                      ? KaiColors.textPrimary
                      : KaiColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              // Description courte
              Expanded(
                child: Text(
                  technique.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: technique.unlocked
                        ? KaiColors.textSecondary
                        : Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Coût et statut
              Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: KaiColors.primaryDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          color: _playerPuissance >= technique.cost
                              ? KaiColors.accent
                              : Colors.grey[600],
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${technique.cost}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _playerPuissance >= technique.cost
                                ? KaiColors.accent
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      technique.unlocked
                          ? Icons.check_circle
                          : canUnlock
                              ? Icons.lock_open
                              : Icons.lock,
                      color: technique.unlocked
                          ? KaiColors.success
                          : canUnlock
                              ? KaiColors.accent
                              : Colors.grey[600],
                      size: 18,
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

  void _showTechniqueDetails(Technique technique, bool canUnlock) {
    // Déterminer la couleur en fonction de l'affinité
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: KaiColors.cardBackground,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KaiColors.primaryDark,
              KaiColors.cardBackground,
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Cercle décoratif
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: affinityColor.withOpacity(0.1),
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec nom et affinité
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              technique.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: KaiColors.textPrimary,
                                shadows: [
                                  Shadow(
                                    color: affinityColor.withOpacity(0.5),
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Affinité: ${technique.affinity ?? "Neutre"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: affinityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: technique.unlocked
                              ? KaiColors.success
                              : Colors.grey[700],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          technique.unlocked ? Icons.check : Icons.lock,
                          color: KaiColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Type et coût
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailChip('Type: ${technique.type}',
                          Icons.category, affinityColor),
                      _buildDetailChip('Coût: ${technique.cost}',
                          Icons.monetization_on, affinityColor),
                      _buildDetailChip('Kai: ${technique.chakraCost}',
                          Icons.water_drop, affinityColor),
                      _buildDetailChip('CD: ${technique.cooldown}',
                          Icons.timelapse, affinityColor),
                      if (technique.conditionGenerated != null)
                        _buildDetailChip(
                            'Génère: ${technique.conditionGenerated}',
                            Icons.add_circle_outline,
                            affinityColor),
                      if (technique.type == 'auto' && technique.trigger != null)
                        _buildDetailChip('Si: ${technique.trigger}', Icons.bolt,
                            affinityColor),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Description complète
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KaiColors.primaryDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: affinityColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: KaiColors.accent,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          technique.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: KaiColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Détails de l'effet
                  if (technique.effectDetails != null) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KaiColors.primaryDark.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: affinityColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de l\'effet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: KaiColors.accent,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...technique.effectDetails!.entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_right,
                                    color: affinityColor,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${entry.key}: ${entry.value}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: KaiColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  Spacer(),
                  // Bouton de débloquage
                  if (!technique.unlocked && canUnlock) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _playerPuissance >= technique.cost
                            ? () {
                                Navigator.pop(context);
                                _unlockTechnique(technique);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: affinityColor,
                          foregroundColor: KaiColors.textPrimary,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: affinityColor.withOpacity(0.5),
                          elevation: 8,
                          disabledBackgroundColor: Colors.grey[700],
                          disabledForegroundColor: Colors.grey[400],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt),
                            SizedBox(width: 8),
                            Text(
                              _playerPuissance >= technique.cost
                                  ? 'Débloquer (${technique.cost} puissance)'
                                  : 'Puissance insuffisante (${_playerPuissance}/${technique.cost})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (!technique.unlocked && !canUnlock) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KaiColors.primaryDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[700]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Débloque d\'abord les techniques parentes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon, Color affinityColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KaiColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: affinityColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: affinityColor),
          SizedBox(width: 4),
          Text(
            label,
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
