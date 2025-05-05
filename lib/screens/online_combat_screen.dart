import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/kaijin.dart';
import '../styles/kai_colors.dart';
import '../services/kaijin_service.dart';

class OnlineCombatScreen extends StatefulWidget {
  const OnlineCombatScreen({Key? key}) : super(key: key);

  @override
  _OnlineCombatScreenState createState() => _OnlineCombatScreenState();
}

class _OnlineCombatScreenState extends State<OnlineCombatScreen> {
  final KaijinService _kaijinService = KaijinService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isLoading = true;
  bool _isSearching = false;
  String _kaijinName = '';
  String _kaijinId = '';
  int _kaijinPower = 0;
  List<Map<String, dynamic>> _availableOpponents = [];
  String? _selectedOpponentId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _loadCurrentKaijin();
      await _loadAvailableOpponents();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur d\'initialisation: $e');
      setState(() {
        _isLoading = false;
      });

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: KaiColors.error,
        ),
      );
    }
  }

  Future<void> _loadCurrentKaijin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final currentKaijin = await _kaijinService.getCurrentKaijin(user.uid);
      if (currentKaijin == null) {
        throw Exception('Aucun personnage trouvé pour l\'utilisateur');
      }

      setState(() {
        _kaijinId = currentKaijin.id;
        _kaijinName = currentKaijin.name;
        // Utiliser la propriété power au lieu de powerLevel
        _kaijinPower = currentKaijin.power;
      });
    } catch (e) {
      print('Erreur lors du chargement du kaijin: $e');
      setState(() {
        _kaijinId = '';
        _kaijinName = 'Fracturé inconnu';
        _kaijinPower = 0;
      });
      throw e;
    }
  }

  Future<void> _loadAvailableOpponents() async {
    try {
      // Simuler le chargement d'adversaires disponibles
      // À remplacer par une véritable requête Firebase pour obtenir des adversaires en ligne

      final kaijinsSnapshot = await _firestore
          .collection('kaijins')
          .where('userId', isNotEqualTo: _userId)
          .limit(10)
          .get();

      final opponents = kaijinsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Inconnu',
          'power': data['power'] ?? 100,
          'level': data['level'] ?? 1,
          'clan': data['clan'] ?? 'Aucun',
          'lastActive': data['lastConnected'] ?? Timestamp.now(),
        };
      }).toList();

      setState(() {
        _availableOpponents = opponents;
      });
    } catch (e) {
      print('Erreur lors du chargement des adversaires: $e');
      setState(() {
        _availableOpponents = [];
      });
      throw e;
    }
  }

  Future<void> _startSearchingForOpponent() async {
    setState(() {
      _isSearching = true;
    });

    // Simuler une recherche d'adversaire
    await Future.delayed(Duration(seconds: 3));

    // Mettre à jour l'état après la recherche
    if (mounted) {
      setState(() {
        _isSearching = false;
        // Sélectionner un adversaire aléatoire pour la démonstration
        if (_availableOpponents.isNotEmpty) {
          _selectedOpponentId = _availableOpponents[0]['id'];
        }
      });
    }
  }

  Future<void> _startCombat() async {
    if (_selectedOpponentId == null) return;

    // Rediriger vers l'écran de combat avec l'adversaire sélectionné
    // Note: À implémenter dans une prochaine version
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Combat en ligne en cours de développement!'),
        backgroundColor: KaiColors.accent,
      ),
    );
  }

  Future<void> _cancelSearch() async {
    setState(() {
      _isSearching = false;
      _selectedOpponentId = null;
    });
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
              'Combat En Ligne',
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
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte du joueur
                  _buildPlayerCard(),

                  // Options de recherche
                  _buildSearchOptions(),

                  // Liste des adversaires disponibles
                  if (!_isSearching && _selectedOpponentId == null)
                    _buildOpponentsList(),

                  // Écran de recherche
                  if (_isSearching) _buildSearchingView(),

                  // Affichage de l'adversaire trouvé
                  if (!_isSearching && _selectedOpponentId != null)
                    _buildFoundOpponentView(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlayerCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KaiColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: KaiColors.accent.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KaiColors.cardBackground,
            KaiColors.primaryDark,
          ],
        ),
        border: Border.all(
          color: KaiColors.accent.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre Combattant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: KaiColors.accent,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              // Avatar (simulé)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: KaiColors.primaryDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: KaiColors.accent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KaiColors.accent.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: KaiColors.accent,
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Informations du joueur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _kaijinName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: KaiColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: KaiColors.accent,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Puissance: $_kaijinPower',
                          style: TextStyle(
                            color: KaiColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Combats: 0 | Victoires: 0',
                          style: TextStyle(
                            color: KaiColors.textSecondary,
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
    );
  }

  Widget _buildSearchOptions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KaiColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Options de recherche',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: KaiColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.search),
                  label: Text('Rechercher un adversaire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KaiColors.accent,
                    foregroundColor: KaiColors.primaryDark,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSearching ? null : _startSearchingForOpponent,
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.refresh),
                color: KaiColors.accent,
                tooltip: 'Actualiser la liste',
                onPressed: _isSearching ? null : _loadAvailableOpponents,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentsList() {
    if (_availableOpponents.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: KaiColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_alt_outlined,
                color: KaiColors.textSecondary,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Aucun adversaire disponible',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KaiColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Revenez plus tard ou recherchez automatiquement',
                style: TextStyle(
                  color: KaiColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Adversaires Disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KaiColors.textPrimary,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _availableOpponents.length,
            itemBuilder: (context, index) {
              final opponent = _availableOpponents[index];

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                color: KaiColors.cardBackground,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: KaiColors.primaryDark,
                    child: Icon(
                      Icons.person,
                      color: KaiColors.accent,
                    ),
                  ),
                  title: Text(
                    opponent['name'],
                    style: TextStyle(
                      color: KaiColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clan: ${opponent['clan']}',
                        style: TextStyle(
                          color: KaiColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Puissance: ${opponent['power']} | Niveau: ${opponent['level']}',
                        style: TextStyle(
                          color: KaiColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: Text('Défier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KaiColors.accent,
                      foregroundColor: KaiColors.primaryDark,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedOpponentId = opponent['id'];
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingView() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KaiColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KaiColors.accent.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
          ),
          SizedBox(height: 24),
          Text(
            'Recherche d\'un adversaire en cours...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: KaiColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Nous recherchons un adversaire à votre niveau',
            style: TextStyle(
              color: KaiColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _cancelSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: KaiColors.error,
              foregroundColor: KaiColors.textPrimary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Annuler la recherche'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundOpponentView() {
    // Trouver l'adversaire sélectionné
    final opponent = _availableOpponents.firstWhere(
      (o) => o['id'] == _selectedOpponentId,
      orElse: () => {
        'id': 'unknown',
        'name': 'Adversaire Inconnu',
        'power': 100,
        'level': 1,
        'clan': 'Aucun',
      },
    );

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KaiColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KaiColors.primaryDark,
            KaiColors.cardBackground,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: KaiColors.accent.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: KaiColors.accent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Adversaire Trouvé!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: KaiColors.accent,
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Joueur
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: KaiColors.primaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: KaiColors.accent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: KaiColors.accent,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _kaijinName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: KaiColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Puissance: $_kaijinPower',
                    style: TextStyle(
                      color: KaiColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // VS
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: KaiColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: KaiColors.accent,
                    ),
                  ),
                ),
              ),

              // Adversaire
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: KaiColors.primaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    opponent['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: KaiColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Puissance: ${opponent['power']}',
                    style: TextStyle(
                      color: KaiColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 32),
          Text(
            'Statistiques du Combat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: KaiColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KaiColors.primaryDark.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Victoire:',
                      style: TextStyle(
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    Text(
                      _kaijinPower > opponent['power']
                          ? 'Probable'
                          : 'Difficile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _kaijinPower > opponent['power']
                            ? KaiColors.success
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Récompense:',
                      style: TextStyle(
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    Text(
                      _kaijinPower < opponent['power'] ? 'Élevée' : 'Standard',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _kaijinPower < opponent['power']
                            ? KaiColors.accent
                            : KaiColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Difficulté:',
                      style: TextStyle(
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getDifficultyText(_kaijinPower, opponent['power']),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(
                            _kaijinPower, opponent['power']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.close),
                label: Text('Refuser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaiColors.error,
                  foregroundColor: KaiColors.textPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _cancelSearch,
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.flash_on),
                label: Text('Combattre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaiColors.success,
                  foregroundColor: KaiColors.textPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _startCombat,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDifficultyText(int playerPower, int opponentPower) {
    final ratio = playerPower / opponentPower;

    if (ratio > 1.5) return 'Facile';
    if (ratio > 1.0) return 'Modérée';
    if (ratio > 0.7) return 'Difficile';
    return 'Extrême';
  }

  Color _getDifficultyColor(int playerPower, int opponentPower) {
    final ratio = playerPower / opponentPower;

    if (ratio > 1.5) return KaiColors.success;
    if (ratio > 1.0) return Colors.green;
    if (ratio > 0.7) return Colors.orange;
    return KaiColors.error;
  }
}
