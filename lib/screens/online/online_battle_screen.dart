import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';
import '../../styles/kai_colors.dart';
import '../combat/combat_screen.dart';

class OnlineBattleScreen extends StatefulWidget {
  final String challengeId;
  final String opponentId;
  final bool isChallenger;
  final String kaijinId;

  const OnlineBattleScreen({
    Key? key,
    required this.challengeId,
    required this.opponentId,
    required this.isChallenger,
    required this.kaijinId,
  }) : super(key: key);

  @override
  State<OnlineBattleScreen> createState() => _OnlineBattleScreenState();
}

class _OnlineBattleScreenState extends State<OnlineBattleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  late Mission _mission;
  late List<Technique> _playerTechniques;
  late List<Technique> _opponentTechniques;
  late String _opponentName;
  late int _playerPuissance;
  late int _opponentPuissance;

  // Variables pour le combat
  double _playerHealth = 1000;
  double _enemyHealth = 1000;
  double _playerKai = 100;
  double _enemyKai = 100;
  bool _isPlayerTurn = true;
  Map<String, int> _cooldowns = {};
  int _playerShieldTurns = 0;
  int _enemyShieldTurns = 0;
  String _combatMessage = "Le combat commence!";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Récupérer les données du combat
      final battleDoc =
          await _firestore.collection('battles').doc(widget.challengeId).get();
      final battleData = battleDoc.data() as Map<String, dynamic>;

      // Si le combat n'existe pas encore, le créer
      if (!battleDoc.exists) {
        await _firestore.collection('battles').doc(widget.challengeId).set({
          'status': 'in_progress',
          'player1': widget.isChallenger ? _userId : widget.opponentId,
          'player2': widget.isChallenger ? widget.opponentId : _userId,
          'player1Health': 1000.0,
          'player2Health': 1000.0,
          'player1Kai': 100.0,
          'player2Kai': 100.0,
          'currentTurn': widget.isChallenger ? _userId : widget.opponentId,
          'cooldowns': {},
          'player1ShieldTurns': 0,
          'player2ShieldTurns': 0,
          'lastUpdate': FieldValue.serverTimestamp(),
          'startedAt': FieldValue.serverTimestamp(),
        });
      }

      // Récupérer les données des joueurs
      final playerDoc =
          await _firestore.collection('kaijins').doc(widget.kaijinId).get();
      final opponentDoc =
          await _firestore.collection('kaijins').doc(widget.opponentId).get();

      final playerData = playerDoc.data() as Map<String, dynamic>;
      final opponentData = opponentDoc.data() as Map<String, dynamic>;

      // Créer une mission fictive pour le combat en ligne
      _mission = Mission(
        id: 'online_battle_${widget.challengeId}',
        name: 'Combat en ligne',
        description: 'Affrontez un autre joueur en combat en ligne.',
        difficulty: 1,
        rewards: {'puissance': 0, 'experience': 0, 'techniques': []},
        enemyLevel: 1,
        image: 'assets/images/online_battle.png',
        histoire: 'Un combat en ligne contre un autre Fracturé.',
        completed: false,
        puissanceRequise: 0,
      );

      // Récupérer les techniques des joueurs
      _playerTechniques = await _loadTechniques(widget.kaijinId);
      _opponentTechniques = await _loadTechniques(widget.opponentId);

      // Récupérer les noms et puissances
      _opponentName = opponentData['name'] ?? 'Fracturé inconnu';
      _playerPuissance = playerData['power'] ?? 100;
      _opponentPuissance = opponentData['power'] ?? 100;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation du combat: $e');
      Navigator.pop(context);
    }
  }

  Future<List<Technique>> _loadTechniques(String kaijinId) async {
    try {
      final techniques = await _firestore
          .collection('kaijins')
          .doc(kaijinId)
          .collection('techniques')
          .get();

      return techniques.docs.map((doc) {
        final data = doc.data();
        return Technique(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          type: data['type'] ?? 'active',
          affinity: data['affinity'] ?? 'Frappe',
          cost_kai: (data['cost_kai'] ?? 15).toDouble(),
          cooldown: data['cooldown'] ?? 1,
          damage: (data['damage'] ?? 25).toDouble(),
          condition_generated: data['condition_generated'],
          unlock_type: data['unlock_type'] ?? 'naturelle',
        );
      }).toList();
    } catch (e) {
      print('Erreur lors du chargement des techniques: $e');
      return [
        Technique(
          id: '1',
          name: 'Frappe du Kai Fluctuant',
          description:
              'Une frappe simple mais puissante qui concentre le Kai dans les poings.',
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
          description:
              'Crée une fissure temporelle qui blesse tous les ennemis.',
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
          description:
              'Crée une barrière qui absorbe les dégâts pendant plusieurs tours.',
          type: 'active',
          affinity: 'Sceau',
          cost_kai: 25,
          cooldown: 4,
          damage: 0,
          condition_generated: 'shield',
          unlock_type: 'naturelle',
        ),
      ];
    }
  }

  // Widget pour afficher la barre de vie
  Widget _buildHealthBar(String name, double health, Color color,
      {bool hasShield = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasShield) Icon(Icons.shield, color: Colors.blue, size: 16),
          ],
        ),
        SizedBox(height: 4),
        Stack(
          children: [
            // Fond de la barre
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Barre de vie
            Container(
              height: 20,
              width: (health / 1000) * MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Valeur numérique
            Center(
              child: Text(
                '${health.toInt()} / 1000',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget pour afficher la barre de Kai
  Widget _buildKaiBar(String name, double kai, double maxKai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kai',
          style: TextStyle(
            color: KaiColors.kaiEnergy,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Stack(
          children: [
            // Fond de la barre
            Container(
              height: 15,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Barre de Kai
            Container(
              height: 15,
              width: (kai / maxKai) * MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                color: KaiColors.kaiEnergy,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: KaiColors.kaiEnergy.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // Valeur numérique
            Center(
              child: Text(
                '${kai.toInt()} / ${maxKai.toInt()}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget pour afficher les techniques du joueur
  Widget _buildPlayerTechniquesCompact() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        mainAxisExtent: 70,
      ),
      itemCount: _playerTechniques.length,
      itemBuilder: (context, index) {
        final technique = _playerTechniques[index];
        final onCooldown = (_cooldowns[technique.id] ?? 0) > 0;
        final isDisabled = !_isPlayerTurn || onCooldown;

        return GestureDetector(
          onTap: isDisabled ? null : () => _useTechnique(technique),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.grey.withOpacity(0.3)
                  : _getAffinityColor(technique.affinity ?? '')
                      .withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.5)
                    : _getAffinityColor(technique.affinity ?? ''),
                width: isDisabled ? 1 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  technique.name,
                  style: TextStyle(
                    color: isDisabled
                        ? Colors.white.withOpacity(0.7)
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      technique.conditionGenerated == 'shield'
                          ? Icons.shield
                          : Icons.flash_on,
                      color: isDisabled
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      technique.conditionGenerated == 'shield'
                          ? "Défense"
                          : "${technique.damage} dmg",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.south_rounded,
                      color: KaiColors.kaiEnergy,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "${technique.cost_kai}",
                      style: TextStyle(
                        color: _playerKai < technique.cost_kai
                            ? Colors.red.withOpacity(0.9)
                            : KaiColors.kaiEnergy.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onCooldown) ...[
                      const SizedBox(width: 4),
                      Text(
                        "CD:${_cooldowns[technique.id]}",
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget pour afficher les techniques de l'adversaire
  Widget _buildEnemyTechniquesCompact() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        mainAxisExtent: 70,
      ),
      itemCount: _opponentTechniques.length,
      itemBuilder: (context, index) {
        final technique = _opponentTechniques[index];
        return Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getAffinityColor(technique.affinity ?? '').withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  _getAffinityColor(technique.affinity ?? '').withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Opacity(
            opacity: 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  technique.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      technique.conditionGenerated == 'shield'
                          ? Icons.shield
                          : Icons.flash_on,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      technique.conditionGenerated == 'shield'
                          ? "Défense"
                          : "${technique.damage} dmg",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fonction utilitaire pour obtenir la couleur d'affinité
  Color _getAffinityColor(String affinity) {
    switch (affinity.toLowerCase()) {
      case 'frappe':
        return Colors.orange;
      case 'fracture':
        return Colors.purple;
      case 'sceau':
        return Colors.blue;
      case 'dérive':
        return Colors.green;
      case 'flux':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  // Utiliser une technique
  void _useTechnique(Technique technique) async {
    if (!_isPlayerTurn) return;
    if ((_cooldowns[technique.id] ?? 0) > 0) return;
    if (_playerKai < technique.cost_kai) return;

    setState(() {
      _playerKai -= technique.cost_kai;
      _cooldowns[technique.id] = technique.cooldown;

      if (technique.conditionGenerated == 'shield') {
        _playerShieldTurns = 2;
        _combatMessage = "Vous activez une barrière protectrice!";
      } else {
        // Appliquer les dégâts
        if (_enemyShieldTurns > 0) {
          _enemyHealth -= technique.damage * 0.5;
          _combatMessage = "Votre attaque est partiellement bloquée!";
        } else {
          _enemyHealth -= technique.damage;
          _combatMessage =
              "Vous infligez ${technique.damage} points de dégâts!";
        }
      }

      // Vérifier la fin du combat
      if (_enemyHealth <= 0) {
        _enemyHealth = 0;
        _firestore.collection('battles').doc(widget.challengeId).update({
          'status': 'finished',
          'winner': _userId,
          'loser': widget.opponentId,
          'endedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Passer le tour
        _isPlayerTurn = false;
        // Mettre à jour l'état du combat
        _updateBattleState();
      }
    });
  }

  // Mettre à jour l'état du combat
  Future<void> _updateBattleState() async {
    await _firestore.collection('battles').doc(widget.challengeId).update({
      'player1Health': _playerHealth,
      'player2Health': _enemyHealth,
      'player1Kai': _playerKai,
      'player2Kai': _enemyKai,
      'currentTurn': _isPlayerTurn ? _userId : widget.opponentId,
      'cooldowns': _cooldowns,
      'player1ShieldTurns': _playerShieldTurns,
      'player2ShieldTurns': _enemyShieldTurns,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: KaiColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
              ),
              SizedBox(height: 16),
              Text(
                'Initialisation du combat...',
                style: TextStyle(
                  color: KaiColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KaiColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: KaiColors.primaryDark,
          elevation: 10,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Combat en ligne',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/combat_background.png'),
            fit: BoxFit.cover,
            opacity: 0.7,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barres de vie côte à côte
              Row(
                children: [
                  Expanded(
                    child: _buildHealthBar("Joueur", _playerHealth, Colors.blue,
                        hasShield: _playerShieldTurns > 0),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHealthBar(
                        _opponentName, _enemyHealth, Colors.red,
                        hasShield: _enemyShieldTurns > 0),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Barres de Kai côte à côte
              Row(
                children: [
                  Expanded(
                    child: _buildKaiBar("Joueur", _playerKai, 100),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKaiBar(_opponentName, _enemyKai, 100),
                  ),
                ],
              ),

              // Zone des combattants
              Expanded(
                flex: 4,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Avatar du joueur
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: KaiColors.primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Icon(Icons.person, size: 60, color: Colors.blue),
                      ),
                      // VS
                      Text(
                        "VS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Avatar de l'adversaire
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: KaiColors.primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Icon(Icons.person, size: 60, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),

              // Message de combat et tour actuel
              Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                decoration: BoxDecoration(
                  color: KaiColors.primaryDark.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _combatMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isPlayerTurn ? "VOTRE TOUR" : "TOUR DE L'ADVERSAIRE",
                      style: TextStyle(
                        color: _isPlayerTurn ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Interface de combat avec techniques
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: const Text(
                            "VOS TECHNIQUES",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        Expanded(
                          child: const Text(
                            "TECHNIQUES DE L'ADVERSAIRE",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildPlayerTechniquesCompact(),
                          ),
                          Container(
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          Expanded(
                            child: _buildEnemyTechniquesCompact(),
                          ),
                        ],
                      ),
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

  Future<void> _updatePlayerStats(bool isWinner) async {
    final kaijinId = isWinner ? widget.kaijinId : widget.opponentId;
    final kaijinRef = _firestore.collection('kaijins').doc(kaijinId);

    await _firestore.runTransaction((transaction) async {
      final kaijinDoc = await transaction.get(kaijinRef);
      if (!kaijinDoc.exists) return;

      final data = kaijinDoc.data() as Map<String, dynamic>;
      final currentWins = data['wins'] ?? 0;
      final currentLosses = data['losses'] ?? 0;
      final currentPower = data['power'] ?? 100;

      if (isWinner) {
        transaction.update(kaijinRef, {
          'wins': currentWins + 1,
          'power': currentPower + 10, // Bonus de puissance pour la victoire
        });
      } else {
        transaction.update(kaijinRef, {
          'losses': currentLosses + 1,
        });
      }
    });
  }
}
