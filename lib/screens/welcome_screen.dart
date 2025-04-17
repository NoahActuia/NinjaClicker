import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:math';
// Import conditionnel pour le web
// ignore: unused_import
import 'welcome_screen_web.dart'
    if (dart.library.io) 'welcome_screen_stub.dart';
import '../models/saved_game.dart';
import '../services/save_service.dart';
import 'game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_test_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/kaijin_service.dart';
import '../models/kaijin.dart';
import 'intro_video_screen.dart';
import '../styles/kai_colors.dart' as styles;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<Kaijin> _playerKaijins = [];
  bool _isLoading = true;
  final KaijinService _kaijinService = KaijinService();

  @override
  void initState() {
    super.initState();
    _loadKaijins();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Charger les kaijins de l'utilisateur courant
  Future<void> _loadKaijins() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Note: ici nous avons besoin de TOUS les kaijins de l'utilisateur pour afficher la liste,
        // et non pas seulement du kaijin actif, donc nous utilisons getKaijinsByUser
        final kaijins = await _kaijinService.getKaijinsByUser(user.uid);

        setState(() {
          _playerKaijins = kaijins;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des kaijins: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Afficher le dialogue pour la nouvelle partie
  void _showNewGameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Nouvelle Partie',
            style: TextStyle(
              color: styles.KaiColors.background,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Entrez votre nom de Kaijin',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _createKaijinAndStartGame(_nameController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: styles.KaiColors.background,
              ),
              child: const Text(
                'Commencer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Créer un nouveau kaijin et démarrer le jeu
  Future<void> _createKaijinAndStartGame(String playerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Créer un nouveau kaijin dans Firebase
        final kaijin = await _kaijinService.createKaijin(
          userId: user.uid,
          name: playerName,
        );

        // Démarrer la vidéo d'introduction puis le jeu avec ce kaijin
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => IntroVideoScreen(
                playerName: playerName,
              ),
            ),
          );
        }
      } catch (e) {
        print("Erreur lors de la création du kaijin: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la création du kaijin: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous devez être connecté pour créer un kaijin"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Charger un kaijin et démarrer le jeu
  Future<void> _loadKaijinAndStartGame(Kaijin kaijin) async {
    try {
      // Sauvegarder l'ancienne valeur de lastConnected dans previousLastConnected
      kaijin.previousLastConnected = kaijin.lastConnected;

      // Mettre à jour lastConnected avec la date actuelle
      kaijin.lastConnected = DateTime.now();

      // Sauvegarder les modifications
      await _kaijinService.updateKaijin(kaijin);
      print('Dates de connexion mises à jour pour ${kaijin.name}:');
      print('- previousLastConnected: ${kaijin.previousLastConnected}');
      print('- lastConnected: ${kaijin.lastConnected}');

      // Naviguer vers l'écran de jeu
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              playerName: kaijin.name,
              savedGame:
                  null, // Le kaijin sera chargé directement dans GameScreen
              resetState:
                  true, // Indiquer qu'il faut réinitialiser l'état du jeu quand on change de kaijin
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des dates de connexion: $e');

      // En cas d'erreur, continuer quand même vers l'écran de jeu
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              playerName: kaijin.name,
              savedGame: null,
              resetState: true,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo et titre
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 130,
                        width: 130,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Terre du Kai Fracturé',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              styles.KaiColors.background.withOpacity(0.9),
                              styles.KaiColors.background.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Un monde fracturé, un destin à forger',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Affichage des kaijins existants
                if (_playerKaijins.isNotEmpty) ...[
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Personnages disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: styles.KaiColors.accent,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(${_playerKaijins.length})',
                              style: TextStyle(
                                fontSize: 14,
                                color: styles.KaiColors.accent.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Kaijins limités à 2 avec scroll
                        _buildKaijinsList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Bouton de création
                ElevatedButton(
                  onPressed: _showNewGameDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: styles.KaiColors.background,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Créer un nouveau personnage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Bouton de classement
                TextButton.icon(
                  onPressed: _openRankingScreen,
                  icon: Icon(
                    Icons.emoji_events,
                    color: styles.KaiColors.accent,
                  ),
                  label: Text(
                    'Classement mondial',
                    style: TextStyle(
                      color: styles.KaiColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Bouton de déconnexion
                if (_playerKaijins.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        }
                      },
                      child: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Construire la liste des kaijins
  Widget _buildKaijinsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playerKaijins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Aucun personnage disponible',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showNewGameDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: styles.KaiColors.background,
              ),
              child: const Text('Créer un personnage'),
            ),
          ],
        ),
      );
    }

    // Hauteur fixe pour afficher 2 kaijins maximum
    final double containerHeight = min(160, _playerKaijins.length * 80);

    return Column(
      children: [
        Container(
          height: containerHeight,
          // Ajouter un petit effet d'ombre pour indiquer qu'on peut scroller
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: _playerKaijins.length,
            itemBuilder: (context, index) {
              final kaijin = _playerKaijins[index];
              return _buildKaijinCard(kaijin);
            },
          ),
        ),

        // Indicateur de défilement si plus de 2 kaijins
        if (_playerKaijins.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe_vertical,
                  color: Colors.white70,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Faire défiler pour voir plus',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Carte pour afficher un kaijin
  Widget _buildKaijinCard(Kaijin kaijin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            styles.KaiColors.background.withOpacity(0.2),
            styles.KaiColors.background.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: styles.KaiColors.background,
          child: const Icon(
            Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          kaijin.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Niveau ${kaijin.level} • XP: ${kaijin.xp} • Puissance: ${kaijin.power}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white70,
        ),
        onTap: () async {
          await _loadKaijinAndStartGame(kaijin);
        },
      ),
    );
  }

  // Affichage de la boîte de dialogue de création de kaijin
  void _showCreateKaijinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Créer un nouveau personnage',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: styles.KaiColors.background,
            ),
          ),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Nom du personnage',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: styles.KaiColors.background,
                  width: 2.0,
                ),
              ),
            ),
            maxLength: 20,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _nameController.clear();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                String name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _createKaijinAndStartGame(name);
                  _nameController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: styles.KaiColors.background,
              ),
              child: const Text(
                'Créer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openRankingScreen() {
    // Implementation of _openRankingScreen method
  }
}
