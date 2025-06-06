import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/kaijin.dart';
import '../styles/kai_colors.dart';
import '../services/kaijin_service.dart';
import '../services/challenge_service.dart';
import '../screens/online_battle_screen.dart';

class OnlineCombatScreen extends StatefulWidget {
  const OnlineCombatScreen({Key? key}) : super(key: key);

  @override
  _OnlineCombatScreenState createState() => _OnlineCombatScreenState();
}

class _OnlineCombatScreenState extends State<OnlineCombatScreen> {
  final KaijinService _kaijinService = KaijinService();
  final ChallengeService _challengeService = ChallengeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _challengeSubscription;
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _pendingChallenges = [];

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
    _listenToChallenges();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _challengeSubscription?.cancel();
    _refreshTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _listenToChallenges() {
    print('=== DÉMARRAGE DE L\'ÉCOUTE DES DÉFIS ===');
    _challengeSubscription?.cancel();

    // Écouter tous les défis (envoyés et reçus)
    _challengeSubscription = _firestore
        .collection('challenges')
        .where(Filter.or(
          Filter('challengerId', isEqualTo: _userId),
          Filter('targetId', isEqualTo: _userId),
        ))
        .snapshots()
        .listen((QuerySnapshot snapshot) async {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>;
        print('Changement détecté dans le défi: ${change.doc.id}');
        print('Status: ${data['status']}');

        // Si c'est un nouveau défi en attente pour nous
        if (change.type == DocumentChangeType.added &&
            data['status'] == 'pending' &&
            data['targetId'] == _userId) {
          print('Nouveau défi reçu');
          if (mounted) {
            _showChallengeDialog(change.doc.id, data);
          }
        }

        // Si un défi est accepté (pour les deux joueurs)
        if (data['status'] == 'accepted') {
          print('Défi accepté détecté');
          final bool isChallenger = data['challengerId'] == _userId;

          // Vérifier si un combat existe déjà pour ce défi
          final battleDoc =
              await _firestore.collection('battles').doc(change.doc.id).get();

          if (battleDoc.exists) {
            final battleData = battleDoc.data() as Map<String, dynamic>;
            // Ne pas rediriger si le combat est déjà terminé
            if (battleData['status'] == 'finished') {
              print('Combat déjà terminé, pas de redirection');
              return;
            }
          }

          if (mounted) {
            print(
                'Navigation vers l\'écran de combat (${isChallenger ? "challenger" : "défenseur"})');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OnlineBattleScreen(
                  challengeId: change.doc.id,
                  opponentId: isChallenger
                      ? data['targetKaijinId']
                      : data['challengerKaijinId'],
                  isChallenger: isChallenger,
                  kaijinId: _kaijinId,
                ),
              ),
            );
          }
        }
      }
    });
  }

  void _showChallengeDialog(
      String challengeId, Map<String, dynamic> challengeData) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: KaiColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: KaiColors.accent, width: 2),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: KaiColors.accent, size: 30),
                SizedBox(width: 10),
                Text(
                  'Défi reçu !',
                  style: TextStyle(
                      color: KaiColors.accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${challengeData['challengerName']} vous défie en combat !',
                  style: TextStyle(color: KaiColors.textPrimary, fontSize: 16),
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: KaiColors.primaryDark.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.flash_on, color: KaiColors.accent, size: 20),
                      Text(
                        'Puissance: ${challengeData['challengerPower']}',
                        style: TextStyle(
                          color: KaiColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await _challengeService.rejectChallenge(challengeId);
                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  } catch (e) {
                    print('Erreur lors du refus du défi: $e');
                  }
                },
                child: Text(
                  'Refuser',
                  style: TextStyle(
                      color: KaiColors.error, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    Navigator.of(dialogContext).pop();
                    await _challengeService.acceptChallenge(challengeId);

                    // Vérifier si un combat existe déjà et son statut
                    final battleDoc = await _firestore
                        .collection('battles')
                        .doc(challengeId)
                        .get();

                    if (battleDoc.exists) {
                      final battleData =
                          battleDoc.data() as Map<String, dynamic>;
                      // Ne pas rediriger si le combat est déjà terminé
                      if (battleData['status'] == 'finished') {
                        print('Combat déjà terminé, pas de redirection');
                        return;
                      }
                    }

                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnlineBattleScreen(
                            challengeId: challengeId,
                            opponentId: challengeData['challengerKaijinId'],
                            isChallenger: false,
                            kaijinId: _kaijinId,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Erreur lors de l\'acceptation du défi: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaiColors.success,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Accepter',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
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
        _kaijinPower = currentKaijin.power;
      });

      // Rafraîchir les défis après avoir chargé le Kaijin
      _refreshPendingChallenges();
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
      final kaijinsSnapshot = await _firestore
          .collection('kaijins')
          .where('userId', isNotEqualTo: _userId)
          .limit(10)
          .get();

      final opponents = kaijinsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['userId'] ?? 'unknown', // ID de l'utilisateur
          'kaijinId': doc.id, // ID du Kaijin
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

  Future<void> _sendChallenge(Map<String, dynamic> opponent) async {
    try {
      print('Envoi d\'un défi à: ${opponent['name']} (${opponent['id']})');
      print('Données de l\'adversaire: $opponent');

      final challengeId = await _challengeService.createChallenge(
        challengerId: _userId,
        challengerName: _kaijinName,
        challengerPower: _kaijinPower,
        challengerKaijinId: _kaijinId,
        targetId: opponent['id'],
        targetName: opponent['name'],
        targetPower: opponent['power'],
        targetKaijinId: opponent['kaijinId'],
      );

      print('Défi créé avec l\'ID: $challengeId');
      print('Écoute des mises à jour du défi');

      // Écouter l'acceptation du défi
      _firestore.collection('challenges').doc(challengeId).snapshots().listen(
          (snapshot) async {
        if (!snapshot.exists) {
          print('Le document du défi n\'existe plus');
          return;
        }

        final data = snapshot.data() as Map<String, dynamic>;
        print('Mise à jour du défi reçue: ${data.toString()}');

        if (data['status'] == 'accepted') {
          print('Défi accepté, vérification du statut du combat');

          // Vérifier si un combat existe déjà et son statut
          final battleDoc =
              await _firestore.collection('battles').doc(challengeId).get();

          if (battleDoc.exists) {
            final battleData = battleDoc.data() as Map<String, dynamic>;
            // Ne pas rediriger si le combat est déjà terminé
            if (battleData['status'] == 'finished') {
              print('Combat déjà terminé, pas de redirection');
              return;
            }
          }

          if (mounted) {
            print('kaijinId: $_kaijinId');
            print('opponentId: ${opponent['kaijinId']}');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OnlineBattleScreen(
                  challengeId: challengeId,
                  opponentId: opponent['kaijinId'],
                  isChallenger: true,
                  kaijinId: _kaijinId,
                ),
              ),
            );
            print('Navigation terminée');
          } else {
            print('Widget non monté, impossible de naviguer');
          }
        }
      }, onError: (error) {
        print('Erreur dans l\'écoute du défi: $error');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Défi envoyé à ${opponent['name']}'),
          backgroundColor: KaiColors.success,
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'envoi du défi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi du défi: $e'),
          backgroundColor: KaiColors.error,
        ),
      );
    }
  }

  void _startPeriodicRefresh() {
    // Rafraîchir toutes les 5 secondes
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _refreshPendingChallenges();
    });
    // Premier rafraîchissement immédiat
    _refreshPendingChallenges();
  }

  Future<void> _refreshPendingChallenges() async {
    try {
      print('Rafraîchissement des défis pour l\'utilisateur: $_userId');

      if (_userId.isEmpty) {
        print(
            'ID de l\'utilisateur non disponible, impossible de récupérer les défis');
        return;
      }

      final snapshot = await _firestore
          .collection('challenges')
          .where('targetId',
              isEqualTo: _userId) // Utilisation de l'ID utilisateur
          .where('status', isEqualTo: 'pending')
          .get();

      print('Nombre de défis trouvés: ${snapshot.docs.length}');

      if (mounted) {
        setState(() {
          _pendingChallenges = snapshot.docs.map((doc) {
            final data = doc.data();
            print('Défi trouvé: ${doc.id} - ${data.toString()}');
            return {
              ...data,
              'id': doc.id,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Erreur lors du rafraîchissement des défis: $e');
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
                  _buildPlayerCard(),
                  _buildChallengesSection(),
                  _buildSearchOptions(),
                  if (!_isSearching && _selectedOpponentId == null)
                    _buildOpponentsList(),
                  if (_isSearching) _buildSearchingView(),
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
          colors: [KaiColors.cardBackground, KaiColors.primaryDark],
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
                  border: Border.all(color: KaiColors.accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: KaiColors.accent.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.person, size: 40, color: KaiColors.accent),
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
                        Icon(Icons.flash_on, color: KaiColors.accent, size: 16),
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
                        Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Combats: 0 | Victoires: 0',
                          style: TextStyle(color: KaiColors.textSecondary),
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

  Widget _buildChallengesSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: KaiColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KaiColors.accent.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: KaiColors.accent,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Défis Reçus',
                      style: TextStyle(
                        color: KaiColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: KaiColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_pendingChallenges.length}',
                    style: TextStyle(
                      color: KaiColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_pendingChallenges.isEmpty)
            Container(
              margin: EdgeInsets.symmetric(vertical: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KaiColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: KaiColors.accent.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'Aucun défi en attente',
                  style: TextStyle(
                    color: KaiColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _pendingChallenges.length,
              itemBuilder: (context, index) {
                final challenge = _pendingChallenges[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  color: KaiColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: KaiColors.accent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              challenge['challengerName'] ?? 'Inconnu',
                              style: TextStyle(
                                color: KaiColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: KaiColors.primaryDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    color: KaiColors.accent,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${challenge['challengerPower']}',
                                    style: TextStyle(
                                      color: KaiColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await _challengeService
                                    .rejectChallenge(challenge['id']);
                                _refreshPendingChallenges();
                              },
                              child: Text(
                                'Refuser',
                                style: TextStyle(
                                  color: KaiColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await _challengeService
                                    .acceptChallenge(challenge['id']);
                                _refreshPendingChallenges();

                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OnlineBattleScreen(
                                        challengeId: challenge['id'],
                                        opponentId:
                                            challenge['challengerKaijinId'],
                                        isChallenger: false,
                                        kaijinId: _kaijinId,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KaiColors.success,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              child: Text('Accepter'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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
                style: TextStyle(color: KaiColors.textSecondary),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: KaiColors.primaryDark,
                    child: Icon(Icons.person, color: KaiColors.accent),
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
                        style: TextStyle(color: KaiColors.textSecondary),
                      ),
                      Text(
                        'Puissance: ${opponent['power']} | Niveau: ${opponent['level']}',
                        style: TextStyle(color: KaiColors.textSecondary),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: Text('Défier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KaiColors.accent,
                      foregroundColor: KaiColors.primaryDark,
                    ),
                    onPressed: () => _sendChallenge(opponent),
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
        border: Border.all(color: KaiColors.accent.withOpacity(0.5), width: 1),
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
            style: TextStyle(color: KaiColors.textSecondary),
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
          colors: [KaiColors.primaryDark, KaiColors.cardBackground],
        ),
        boxShadow: [
          BoxShadow(
            color: KaiColors.accent.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: KaiColors.accent, width: 2),
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
                      border: Border.all(color: KaiColors.accent, width: 2),
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
                    style: TextStyle(color: KaiColors.textSecondary),
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
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Center(
                      child: Icon(Icons.person, size: 40, color: Colors.red),
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
                    style: TextStyle(color: KaiColors.textSecondary),
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
                      style: TextStyle(color: KaiColors.textSecondary),
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
                      style: TextStyle(color: KaiColors.textSecondary),
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
                      style: TextStyle(color: KaiColors.textSecondary),
                    ),
                    Text(
                      _getDifficultyText(_kaijinPower, opponent['power']),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(
                          _kaijinPower,
                          opponent['power'],
                        ),
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
