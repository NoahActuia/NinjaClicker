import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';
import '../../styles/kai_colors.dart';
import '../combat/combat_screen.dart';
import '../combat/combat_screen_extension.dart';
import '../../services/technique_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'training_enemy_generator.dart';
import 'training_appbar_background.dart';

class TrainingScreen extends StatefulWidget {
  final int playerPuissance;
  final List<Technique> playerTechniques;
  final String? kaijinId;

  const TrainingScreen({
    Key? key,
    required this.playerPuissance,
    required this.playerTechniques,
    this.kaijinId,
  }) : super(key: key);

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  String _selectedDifficulty = 'Novice';
  final List<String> _difficulties = [
    'Novice',
    'Adepte',
    'Maître',
    'Légendaire'
  ];
  final Random _random = Random();
  final TrainingEnemyGenerator _enemyGenerator = TrainingEnemyGenerator();
  final TechniqueService _techniqueService = TechniqueService();

  // Techniques de combat sélectionnées par le joueur
  List<Technique> _playerCombatTechniques = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerCombatTechniques();
  }

  // Chargement des techniques de combat sélectionnées par le joueur
  Future<void> _loadPlayerCombatTechniques() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Si aucun kaijinId n'est fourni, utiliser les techniques déjà disponibles
      if (widget.kaijinId == null || widget.kaijinId!.isEmpty) {
        setState(() {
          _playerCombatTechniques = widget.playerTechniques;
          _isLoading = false;
        });
        return;
      }

      // Récupération des techniques de combat configurées pour le kaijin actif
      final snapshot = await FirebaseFirestore.instance
          .collection('kaijins')
          .doc(widget.kaijinId)
          .collection('combat_settings')
          .doc('techniques')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        // Récupérer les IDs des techniques actives
        final List<String> activeIds =
            List<String>.from(data['active_techniques'] ?? []);

        if (activeIds.isNotEmpty) {
          // Filtrer les techniques du joueur par les IDs des techniques actives
          _playerCombatTechniques = widget.playerTechniques
              .where((technique) => activeIds.contains(technique.id))
              .toList();
        } else {
          // Aucune technique active configurée, utiliser les techniques par défaut
          _playerCombatTechniques = widget.playerTechniques
              .where((technique) =>
                  technique.type == 'active' && technique.isDefault)
              .take(3)
              .toList();
        }
      } else {
        // Si aucune configuration n'existe, utiliser les techniques par défaut
        _playerCombatTechniques = widget.playerTechniques
            .where((technique) =>
                technique.type == 'active' && technique.isDefault)
            .take(3)
            .toList();
      }
    } catch (error) {
      print('Erreur lors du chargement des techniques de combat: $error');
      // En cas d'erreur, utiliser les techniques disponibles
      _playerCombatTechniques = widget.playerTechniques;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor: KaiColors.primaryDark,
            flexibleSpace: const TrainingAppBarBackground(),
            title: const Text('Chargement...'),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [KaiColors.background, KaiColors.backgroundDark],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: KaiColors.accent,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: KaiColors.primaryDark,
          elevation: 10,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          flexibleSpace: const TrainingAppBarBackground(),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Salle d\'Entraînement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: KaiColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: KaiColors.accent.withOpacity(0.5), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: KaiColors.accent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.playerPuissance.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KaiColors.background, KaiColors.backgroundDark],
          ),
        ),
        child: Stack(
          children: [
            // Contenu défilable
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et description
                  const Text(
                    'Entraînement au Combat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Affûtez vos compétences de combat en affrontant des adversaires générés par le Kai Fracturé. Ces combats n\'affectent pas votre progression dans l\'histoire principale.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Techniques disponibles
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KaiColors.cardBackground.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: KaiColors.accent.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Techniques de Combat Sélectionnées',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_playerCombatTechniques.isEmpty)
                          const Text(
                            'Aucune technique de combat sélectionnée. Configurez vos techniques dans l\'écran "Techniques de Combat".',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _playerCombatTechniques.length,
                              itemBuilder: (context, index) {
                                final technique =
                                    _playerCombatTechniques[index];
                                final Color affinityColor =
                                    _getAffinityColor(technique.affinity);

                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: affinityColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: affinityColor.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        technique.conditionGenerated == 'shield'
                                            ? Icons.shield
                                            : Icons.flash_on,
                                        color: affinityColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        technique.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sélection de la difficulté
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KaiColors.cardBackground.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: KaiColors.accent.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Niveau de l\'adversaire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedDifficulty,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                KaiColors.cardBackground.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: KaiColors.cardBackground,
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: KaiColors.accent),
                          items: _difficulties
                              .map((difficulty) => DropdownMenuItem<String>(
                                    value: difficulty,
                                    child: Text(
                                      difficulty,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description de la difficulté
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KaiColors.cardBackground.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: KaiColors.accent.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDifficultyDescription().$1,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: KaiColors.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDifficultyDescription().$2,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Résumé de l'adversaire
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KaiColors.cardBackground.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: KaiColors.accent.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aperçu de l\'adversaire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color:
                                    KaiColors.backgroundLight.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(
                                Icons.person,
                                color: _getDifficultyColor(),
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getRandomEnemyName(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.flash_on,
                                        color: _getDifficultyColor(),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Puissance: ${_getEnemyPower()}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: _getDifficultyColor(),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Techniques: ${_getDifficultyLevel() + 2}', // +2 pour les techniques de base
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Espace pour le bouton en bas fixe
                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Bouton fixe en bas
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      KaiColors.backgroundDark.withOpacity(0.1),
                      KaiColors.backgroundDark,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _playerCombatTechniques.isEmpty
                            ? null
                            : _startTraining,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KaiColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: const Text(
                          'COMMENCER L\'ENTRAÎNEMENT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    if (_playerCombatTechniques.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Vous devez configurer vos techniques de combat avant de pouvoir vous entraîner.',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  (String, String) _getDifficultyDescription() {
    switch (_selectedDifficulty) {
      case 'Novice':
        return (
          'Adversaire de niveau Novice',
          'Un adversaire avec des techniques basiques, idéal pour apprendre les mécaniques de combat. Puissance adaptée pour les débutants.',
        );
      case 'Adepte':
        return (
          'Adversaire de niveau Adepte',
          'Un combattant expérimenté avec des techniques variées. Représente un défi modéré pour tester vos stratégies.',
        );
      case 'Maître':
        return (
          'Adversaire de niveau Maître',
          'Un expert du Kai avec des techniques avancées et une intelligence tactique. Un défi sérieux même pour les combattants accomplis.',
        );
      case 'Légendaire':
        return (
          'Adversaire de niveau Légendaire',
          'Un adversaire d\'élite utilisant des techniques rares et puissantes. Seuls les plus grands maîtres du Kai peuvent espérer triompher.',
        );
      default:
        return (
          'Adversaire d\'entraînement',
          'Un adversaire généré pour vous permettre de vous entraîner au combat.',
        );
    }
  }

  Future<void> _startTraining() async {
    // Créer une mission fictive pour l'entraînement
    final enemyName = _getRandomEnemyName();
    final enemyLevel = _getDifficultyLevel();

    // Obtenir des techniques aléatoires de la base de données pour l'ennemi
    List<Technique> enemyTechniques = await _fetchEnemyTechniques();

    // Créer les récompenses (qui seront vides pour l'entraînement)
    final Map<String, dynamic> rewards = {
      'puissance': 0,
      'experience': 0,
      'techniques': [],
    };

    final trainingMission = Mission(
      id: 'training_${_selectedDifficulty.toLowerCase()}_${_random.nextInt(1000)}',
      name: 'Entraînement: $_selectedDifficulty',
      description:
          'Session d\'entraînement contre un adversaire de niveau $_selectedDifficulty',
      difficulty: enemyLevel,
      rewards: rewards,
      enemyLevel: enemyLevel,
      image: _getRandomEnemyImage(),
      histoire:
          'Vous affrontez $enemyName dans une session d\'entraînement intensif. Montrez votre maîtrise du Kai!',
      completed: false,
      puissanceRequise: 0,
    );

    // Utiliser notre fonction d'extension pour le combat d'entraînement avec les techniques du joueur
    navigateToTrainingCombat(
      context: context,
      mission: trainingMission,
      playerPuissance: widget.playerPuissance,
      enemyTechniques: enemyTechniques,
      playerTechniques: _playerCombatTechniques,
      enemyName: enemyName,
      onVictory: (result) {
        // Fonction appelée en cas de victoire
        Navigator.pop(context); // Retour à l'écran d'entraînement
      },
    );
  }

  // Récupère des techniques aléatoires pour l'ennemi depuis la base de données
  Future<List<Technique>> _fetchEnemyTechniques() async {
    try {
      // Récupérer toutes les techniques disponibles
      List<Technique> allTechniques =
          await _techniqueService.getAllTechniques();

      // Filtrer les techniques actives
      List<Technique> activeTechniques = allTechniques
          .where((technique) => technique.type == 'active')
          .toList();

      // Nombre de techniques basé sur la difficulté
      int techniqueCount = _getDifficultyLevel() + 1;

      // Mélanger les techniques pour en sélectionner aléatoirement
      activeTechniques.shuffle(_random);

      // Sélectionner des techniques aléatoires
      List<Technique> selectedTechniques =
          activeTechniques.take(techniqueCount).toList();

      // Ajouter au moins une technique défensive
      Technique? defensiveTechnique = activeTechniques
          .where((t) =>
              t.conditionGenerated == 'shield' ||
              t.conditionGenerated == 'barrier')
          .firstOrNull;

      if (defensiveTechnique != null &&
          !selectedTechniques.contains(defensiveTechnique)) {
        selectedTechniques.add(defensiveTechnique);
      }

      // Si on n'a pas pu récupérer assez de techniques, utiliser le générateur
      if (selectedTechniques.isEmpty) {
        return _enemyGenerator.generateEnemyTechniques(_selectedDifficulty);
      }

      return selectedTechniques;
    } catch (error) {
      print(
          'Erreur lors de la récupération des techniques pour l\'ennemi: $error');
      // En cas d'erreur, utiliser le générateur d'ennemis
      return _enemyGenerator.generateEnemyTechniques(_selectedDifficulty);
    }
  }

  int _getDifficultyLevel() {
    switch (_selectedDifficulty) {
      case 'Novice':
        return 1;
      case 'Adepte':
        return 2;
      case 'Maître':
        return 3;
      case 'Légendaire':
        return 4;
      default:
        return 1;
    }
  }

  String _getRandomEnemyName() {
    final names = [
      'Ombre du Kai',
      'Manifestation Fractale',
      'Echo de Résonance',
      'Reflet Dérivant',
      'Simulacre de Combat',
      'Émanation du Vide',
    ];
    return names[_random.nextInt(names.length)];
  }

  String _getRandomEnemyImage() {
    // Ces chemins devront correspondre à des images existantes dans votre projet
    final images = [
      'assets/images/enemies/training_dummy_1.png',
      'assets/images/enemies/training_dummy_2.png',
      'assets/images/enemies/training_shadow.png',
    ];
    return images[_random.nextInt(images.length)];
  }

  // Obtient la couleur associée au niveau de difficulté
  Color _getDifficultyColor() {
    switch (_selectedDifficulty) {
      case 'Novice':
        return Colors.green;
      case 'Adepte':
        return Colors.blue;
      case 'Maître':
        return Colors.orange;
      case 'Légendaire':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  // Calcule la puissance simulée de l'ennemi
  int _getEnemyPower() {
    final int baseMultiplier = _getDifficultyLevel();
    final int randomFactor = _random.nextInt(20) - 10; // -10 à +10

    // Calculer en fonction de la puissance du joueur
    int enemyPower =
        (widget.playerPuissance * 0.8 * baseMultiplier / 2).round() +
            randomFactor;

    // Assurer un minimum
    return enemyPower < 10 ? 10 * baseMultiplier : enemyPower;
  }

  // Obtient la couleur associée à l'affinité
  Color _getAffinityColor(String? affinity) {
    switch (affinity) {
      case 'Flux':
        return Colors.blue;
      case 'Fracture':
        return Colors.purple;
      case 'Sceau':
        return Colors.amber;
      case 'Dérive':
        return Colors.teal;
      case 'Frappe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
