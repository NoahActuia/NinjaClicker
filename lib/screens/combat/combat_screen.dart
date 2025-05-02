import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';
import '../../theme/app_colors.dart';
import 'dart:math';
import '../story/mission_victory_sequence.dart';
import '../story/mission_defeat_sequence.dart';
import '../story/mission_victory_sequence_b.dart';
import '../story/mission_defeat_sequence_b.dart';
import '../story/mission_intro_sequence_b.dart';

class CombatScreen extends StatefulWidget {
  final Mission mission;
  final int playerPuissance;
  final Function(Map<String, dynamic>) onVictory;

  const CombatScreen({
    super.key,
    required this.mission,
    required this.playerPuissance,
    required this.onVictory,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  bool _isLoading = false;
  double _playerHealth = 100;
  double _enemyHealth = 100;
  bool _isPlayerTurn = true; // Pour le tour par tour
  bool _showVictoryDialog = false; // Pour afficher le dialogue de victoire
  bool _showDefeatDialog = false; // Pour afficher le dialogue de défaite
  
  // Techniques du joueur (à remplacer par les techniques réelles débloquées)
  List<Technique> _playerTechniques = [];
  // Techniques pour la simulation
  List<Technique> _demoTechniques = [
    Technique(
      id: '1',
      name: 'Frappe du Kai Fluctuant',
      description: 'Une frappe simple mais puissante qui concentre le Kai dans les poings.',
      type: 'active',
      affinity: 'Frappe',
      cost_kai: 15,
      cooldown: 1,
      damage: 25,
      unlock_type: 'naturelle',
    ),
    Technique(
      id: '2',
      name: 'Vague de Fracture',
      description: 'Crée une fissure temporelle qui blesse tous les ennemis.',
      type: 'active',
      affinity: 'Fracture',
      cost_kai: 30,
      cooldown: 3,
      damage: 40,
      condition_generated: 'fissure',
      unlock_type: 'naturelle',
    ),
    Technique(
      id: '3',
      name: 'Barrière du Sceau',
      description: 'Crée une barrière qui absorbe les dégâts pendant plusieurs tours.',
      type: 'active',
      affinity: 'Sceau',
      cost_kai: 25,
      cooldown: 4,
      damage: 0,
      condition_generated: 'shield',
      unlock_type: 'naturelle',
    ),
  ];
  
  // Cooldowns des techniques
  Map<String, int> _cooldowns = {};
  
  // État du bouclier
  int _playerShieldTurns = 0;
  int _enemyShieldTurns = 0;
  
  // Techniques de l'ennemi (pour simulation)
  List<Map<String, dynamic>> _enemyTechniques = [
    {
      'name': 'Frappe simple',
      'damage': 10,
      'type': 'attack',
    },
    {
      'name': 'Bouclier',
      'damage': 0,
      'type': 'shield',
      'turns': 2,
    },
    {
      'name': 'Attaque puissante',
      'damage': 10,
      'type': 'attack',
    },
  ];
  
  // Messages de combat
  String _combatMessage = "Le combat commence!";
  List<String> _combatLog = [];

  // Déterminer si c'est le combat du niveau A
  bool get _isLevelA => 
    widget.mission.id == 1 || widget.mission.id == '1' || widget.mission.id == 'monde1_combat1';
    
  // Déterminer si c'est le combat du niveau B
  bool get _isLevelB => 
    widget.mission.id == 2 || widget.mission.id == '2' || widget.mission.id == 'monde1_combat2';

  @override
  void initState() {
    super.initState();
    // Charger les techniques débloquées (ici simulées)
    _loadPlayerTechniques();
    
    // Initialiser les cooldowns
    for (var technique in _playerTechniques) {
      _cooldowns[technique.id] = 0;
    }
    
    // Ajuster les dégâts de l'ennemi pour le niveau B
    if (_isLevelB) {
      _enemyTechniques = [
        {
          'name': 'Frappe simple',
          'damage': 20,
          'type': 'attack',
        },
        {
          'name': 'Bouclier',
          'damage': 0,
          'type': 'shield',
          'turns': 2,
        },
        {
          'name': 'Attaque puissante',
          'damage': 20,
          'type': 'attack',
        },
      ];
    }
  }
  
  // Simuler le chargement des techniques
  void _loadPlayerTechniques() {
    // Dans un cas réel, vous chargeriez les techniques débloquées par le joueur
    // Pour cette démo, nous utilisons simplement les techniques de démonstration
    _playerTechniques = _demoTechniques;
  }

  // Fonction pour utiliser une technique
  void _useTechnique(Technique technique) {
    if (!_isPlayerTurn) return;
    if (_cooldowns[technique.id]! > 0) {
      _updateCombatMessage("Cette technique est en recharge (${_cooldowns[technique.id]} tours restants)");
      return;
    }
    
    setState(() {
      // Appliquer les effets de la technique
      switch (technique.conditionGenerated) {
        case 'shield':
          _playerShieldTurns = 2; // 2 tours de bouclier
          _updateCombatMessage("Vous avez activé un bouclier pour 2 tours!");
          break;
        default: // Attaque par défaut
          double damage = technique.damage.toDouble();
          // Réduire les dégâts si l'ennemi a un bouclier
          if (_enemyShieldTurns > 0) {
            damage *= 0.5;
            _updateCombatMessage("Votre ${technique.name} inflige $damage dégâts (réduits par le bouclier)!");
      } else {
            _updateCombatMessage("Votre ${technique.name} inflige $damage dégâts!");
          }
          _enemyHealth = (_enemyHealth - damage).clamp(0.0, 100.0);
          break;
      }
      
      // Appliquer le cooldown
      _cooldowns[technique.id] = technique.cooldown;
      
      // Fin du tour du joueur
      _endPlayerTurn();
    });
  }
  
  // Fonction pour terminer le tour du joueur
  void _endPlayerTurn() {
    _isPlayerTurn = false;
    
    // Vérifier si le combat est terminé
    if (_enemyHealth <= 0) {
      _finishCombat(true);
      return;
    }
    
    // Tour de l'ennemi (délai pour effet visuel)
    Future.delayed(const Duration(milliseconds: 1000), () {
      _enemyTurn();
    });
  }
  
  // Tour de l'ennemi
  void _enemyTurn() {
    if (!mounted) return;
    
    // Réduire les cooldowns
    for (var id in _cooldowns.keys) {
      if (_cooldowns[id]! > 0) {
        _cooldowns[id] = _cooldowns[id]! - 1;
      }
    }
    
    // Choisir une technique aléatoire pour l'ennemi
    final rng = Random();
    final technique = _enemyTechniques[rng.nextInt(_enemyTechniques.length)];
    
        setState(() {
      // Appliquer les effets de la technique ennemie
      switch (technique['type']) {
        case 'shield':
          _enemyShieldTurns = technique['turns'];
          _updateCombatMessage("L'ennemi active un bouclier pour ${technique['turns']} tours!");
          break;
        case 'attack':
          double damage = technique['damage'].toDouble();
          // Réduire les dégâts si le joueur a un bouclier
          if (_playerShieldTurns > 0) {
            damage *= 0.5;
            _updateCombatMessage("L'ennemi utilise ${technique['name']} et inflige $damage dégâts (réduits par votre bouclier)!");
          } else {
            _updateCombatMessage("L'ennemi utilise ${technique['name']} et inflige $damage dégâts!");
          }
          _playerHealth = (_playerHealth - damage).clamp(0.0, 100.0);
          break;
      }
      
      // Réduire la durée des boucliers
      if (_playerShieldTurns > 0) _playerShieldTurns--;
      if (_enemyShieldTurns > 0) _enemyShieldTurns--;
      
      // Fin du tour de l'ennemi
      _isPlayerTurn = true;
      
      // Vérifier si le combat est terminé
      if (_playerHealth <= 0) {
        _finishCombat(false);
      }
    });
  }

  // Mettre à jour le message de combat
  void _updateCombatMessage(String message) {
    _combatMessage = message;
    _combatLog.add(message);
    if (_combatLog.length > 5) {
      _combatLog.removeAt(0);
    }
  }
  
  // Terminer le combat
  void _finishCombat(bool victory) {
    if (victory) {
      _updateCombatMessage("Victoire! Vous avez vaincu l'ennemi!");
      setState(() {
        _showVictoryDialog = true;
      });
    } else {
      _updateCombatMessage("Défaite! Votre santé est tombée à zéro.");
      setState(() {
        _showDefeatDialog = true;
      });
    }
  }

  // Afficher la séquence de victoire
  void _showVictorySequence() {
    if (_isLevelB) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MissionVictoryBSequence(
            onComplete: () {
              // Quand la séquence de victoire est terminée, retourner au chemin et donner les récompenses
              Navigator.of(context).pop(); // Fermer l'écran de combat
              
              // En cas de victoire, on veut animer le ninja
              Map<String, dynamic> rewards = {...widget.mission.rewards};
              rewards['animate_ninja'] = true;  // Indiquer qu'il faut animer le ninja
              widget.onVictory(rewards);
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MissionVictorySequence(
            onComplete: () {
              // Quand la séquence de victoire est terminée, retourner au chemin et donner les récompenses
              Navigator.of(context).pop(); // Fermer l'écran de combat
              
              // En cas de victoire, on veut animer le ninja
              Map<String, dynamic> rewards = {...widget.mission.rewards};
              rewards['animate_ninja'] = true;  // Indiquer qu'il faut animer le ninja
              widget.onVictory(rewards);
            },
          ),
        ),
      );
    }
  }
  
  // Afficher la séquence de défaite
  void _showDefeatSequence() {
    if (_isLevelB) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MissionDefeatBSequence(
            onComplete: () {
              // Quand la séquence de défaite est terminée, retourner directement au chemin
              // Sans animer le ninja (comportement par défaut)
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MissionDefeatSequence(
            onComplete: () {
              // Quand la séquence de défaite est terminée, retourner directement au chemin
              // Sans animer le ninja (comportement par défaut)
    Navigator.of(context).pop();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showVictoryDialog) {
      return _buildVictoryDialog();
    }
    
    if (_showDefeatDialog) {
      return _buildDefeatDialog();
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(widget.mission.name),
        backgroundColor: AppColors.primary,
      ),
      body: Container(
        decoration: _isLevelA
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images_histoire/environnement/environnement1.png'),
                  fit: BoxFit.cover,
                  opacity: 0.7,
                ),
              )
            : _isLevelB
                ? const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images_histoire/environnement/environnement2.png'),
                      fit: BoxFit.cover,
                      opacity: 0.7,
                    ),
                  )
                : null,
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barres de vie
              _buildHealthBar("Joueur", _playerHealth, Colors.blue, hasShield: _playerShieldTurns > 0),
              const SizedBox(height: 8),
              _buildHealthBar("Ennemi", _enemyHealth, Colors.red, hasShield: _enemyShieldTurns > 0),
              
              // Zone des combattants
              Expanded(
                flex: 5,
                child: (_isLevelA || _isLevelB)
                    ? _buildCombatantsView()
                    : const SizedBox.shrink(),
              ),
              
              // Message de combat et tour actuel
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _combatMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    if (_isPlayerTurn)
                      const Text(
                        "VOTRE TOUR",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      const Text(
                        "TOUR DE L'ADVERSAIRE",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Techniques toujours visibles, juste désactivées pendant le tour de l'adversaire
              SizedBox(
                height: 100, // Plus grand
                child: _buildTechniquesGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Widget pour afficher l'écran de victoire
  Widget _buildVictoryDialog() {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.kaiEnergy,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.kaiEnergy.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
                children: [
              // Titre
              const Text(
                "VICTOIRE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Icône de victoire
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 80,
                shadows: [
                  Shadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Message
              const Text(
                "Vous avez triomphé de votre adversaire!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Bouton continuer
                  ElevatedButton(
                onPressed: _showVictorySequence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kaiEnergy,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                    ),
                    child: const Text(
                  "CONTINUER",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Widget pour afficher l'écran de défaite
  Widget _buildDefeatDialog() {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.shade700,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade900.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              const Text(
                "VAINCU",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Icône de défaite
              Icon(
                Icons.cancel_outlined,
                color: Colors.red.shade700,
                size: 80,
                shadows: [
                  Shadow(
                    color: Colors.red.shade700.withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Message
              const Text(
                "Vous avez été vaincu par votre adversaire!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Bouton revenez plus fort
              ElevatedButton(
                onPressed: _showDefeatSequence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "REVENEZ PLUS FORT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour afficher la grille des techniques
  Widget _buildTechniquesGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Afficher 3 techniques sur une ligne
        childAspectRatio: 2.2, // Plus haut pour avoir plus d'espace pour le texte
        crossAxisSpacing: 5, // Moins d'espace horizontal
        mainAxisSpacing: 5, // Moins d'espace vertical
      ),
      padding: EdgeInsets.zero, // Pas de padding
      itemCount: _playerTechniques.length,
      itemBuilder: (context, index) {
        final technique = _playerTechniques[index];
        final onCooldown = _cooldowns[technique.id]! > 0;
        final isDisabled = !_isPlayerTurn || onCooldown;
        
        // Déterminer la raison de la désactivation pour le texte d'info
        String? disabledReason;
        if (!_isPlayerTurn) {
          disabledReason = "Tour de l'adversaire";
        } else if (onCooldown) {
          disabledReason = "Recharge: ${_cooldowns[technique.id]}";
        }
        
        return GestureDetector(
          onTap: isDisabled ? null : () => _useTechnique(technique),
          child: Container(
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.3)
                  : _getAffinityColor(technique.affinity).withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.5)
                    : _getAffinityColor(technique.affinity),
                width: isDisabled ? 1 : 2, // Bordure plus épaisse quand actif
              ),
              boxShadow: isDisabled 
                  ? null
                  : [
                      BoxShadow(
                        color: _getAffinityColor(technique.affinity).withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                      )
                    ],
            ),
            child: Center( // Utiliser Center pour un centrage parfait
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      technique.name,
                      style: TextStyle(
                        color: isDisabled ? Colors.white.withOpacity(0.7) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min, // Taille minimale pour le centrage
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          technique.conditionGenerated == 'shield'
                              ? Icons.shield
                              : Icons.flash_on,
                          color: isDisabled ? Colors.white.withOpacity(0.7) : Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          technique.conditionGenerated == 'shield'
                              ? "DEF"
                              : "${technique.damage} DMG",
                          style: TextStyle(
                            color: isDisabled ? Colors.white.withOpacity(0.7) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (disabledReason != null)
                      Text(
                        disabledReason == "Tour de l'adversaire" ? "En attente" : "CD: ${_cooldowns[technique.id]}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Obtenir la couleur en fonction de l'affinité
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

  // Widget pour afficher les combattants - Rendre fixe sans animation
  Widget _buildCombatantsView() {
    return Container(
      width: double.infinity,
      height: 280, // Augmenter la hauteur pour pouvoir descendre les images
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Joueur à gauche - Position fixe
          Container(
            width: 160, // Plus large
            padding: const EdgeInsets.only(left: 10, top: 40), // Décalé plus à droite et descendu
            child: Stack(
              alignment: Alignment.bottomCenter, // Aligner en bas
              children: [
                // Effet de bouclier (conditionnel)
                if (_playerShieldTurns > 0)
                  Container(
                    width: 160,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                // Image du joueur
                Image.asset(
                  'assets/images_histoire/joueur/joueur1.png',
                  width: 150, // Beaucoup plus grand
                  height: 220, // Beaucoup plus grand
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          
          // Adversaire à droite - Position fixe
          Container(
            width: 160, // Plus large
            padding: const EdgeInsets.only(right: 10, top: 40), // Décalé plus à gauche et descendu
            child: Stack(
              alignment: Alignment.bottomCenter, // Aligner en bas
              children: [
                // Effet de bouclier (conditionnel)
                if (_enemyShieldTurns > 0)
                  Container(
                    width: 160,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                // Image de l'adversaire
                Image.asset(
                  _isLevelB
                      ? 'assets/images_histoire/joueur/joueur3.png'
                      : 'assets/images_histoire/joueur/joueur2.png',
                  width: 150, // Beaucoup plus grand
                  height: 220, // Beaucoup plus grand
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, double value, Color color, {bool hasShield = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
      children: [
        Text(
          label,
              style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black,
                  )
                ],
              ),
            ),
            if (hasShield)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Barre de base
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 20,
          ),
            ),
            // Valeur numérique
            Positioned.fill(
              child: Center(
                child: Text(
                  "${value.toInt()}/100",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 