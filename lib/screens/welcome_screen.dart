import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
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
import '../services/ninja_service.dart';
import '../models/ninja.dart';
import 'intro_video_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<Ninja> _playerNinjas = [];
  bool _isLoading = true;
  final NinjaService _ninjaService = NinjaService();

  @override
  void initState() {
    super.initState();
    _loadNinjas();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Charger les ninjas de l'utilisateur courant
  Future<void> _loadNinjas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ninjas = await _ninjaService.getNinjasByUser(user.uid);

        setState(() {
          _playerNinjas = ninjas;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des ninjas: $e");
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
          title: const Text(
            'Nouvelle Partie',
            style: TextStyle(
              color: KaiColors.background,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Entrez votre nom de ninja',
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
                  _createNinjaAndStartGame(_nameController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KaiColors.background,
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

  // Créer un nouveau ninja et démarrer le jeu
  Future<void> _createNinjaAndStartGame(String playerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Créer un nouveau ninja dans Firebase
        final ninja = await _ninjaService.createNinja(
          userId: user.uid,
          name: playerName,
        );

        // Démarrer la vidéo d'introduction puis le jeu avec ce ninja
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
        print("Erreur lors de la création du ninja: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la création du ninja: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous devez être connecté pour créer un ninja"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Charger un ninja et démarrer le jeu
  void _loadNinjaAndStartGame(Ninja ninja) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerName: ninja.name,
          savedGame: null, // Le ninja sera chargé directement dans GameScreen
        ),
      ),
    );
  }

  // Construire la liste des ninjas
  Widget _buildNinjasList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playerNinjas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Aucun ninja disponible',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showNewGameDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: KaiColors.background,
              ),
              child: const Text('Créer un ninja'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _playerNinjas.length,
      itemBuilder: (context, index) {
        final ninja = _playerNinjas[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: KaiColors.background,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              ninja.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Niveau ${ninja.level} • ${ninja.xp} XP',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: () => _loadNinjaAndStartGame(ninja),
                  tooltip: 'Jouer',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteNinja(ninja),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Confirmation de suppression d'un ninja
  void _confirmDeleteNinja(Ninja ninja) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le ninja'),
          content: Text('Êtes-vous sûr de vouloir supprimer ${ninja.name} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Supprimer le ninja
                final success = await _ninjaService.deleteNinja(ninja.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${ninja.name} a été supprimé'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadNinjas(); // Recharger la liste
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la suppression du ninja'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
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
                              KaiColors.background.withOpacity(0.9),
                              KaiColors.background.withOpacity(0.7),
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

                // Affichage des ninjas existants
                if (_playerNinjas.isNotEmpty) ...[
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
                        Text(
                          'Personnages disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: KaiColors.kaiNeutral,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(
                          _playerNinjas.length,
                          (index) => _buildNinjaCard(_playerNinjas[index]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Bouton de création
                ElevatedButton(
                  onPressed: _showNewGameDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KaiColors.background,
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
                    color: KaiColors.kaiNeutral,
                  ),
                  label: Text(
                    'Classement mondial',
                    style: TextStyle(
                      color: KaiColors.kaiNeutral,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Bouton de déconnexion
                if (_playerNinjas.isNotEmpty)
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

  // Carte pour afficher un ninja
  Widget _buildNinjaCard(Ninja ninja) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KaiColors.background.withOpacity(0.2),
            KaiColors.background.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: KaiColors.background,
          child: const Icon(
            Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          ninja.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Niveau ${ninja.level} • XP: ${ninja.xp} • Puissance: ${ninja.power}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white70,
        ),
        onTap: () => _loadNinjaAndStartGame(ninja),
      ),
    );
  }

  // Affichage de la boîte de dialogue de création de ninja
  void _showCreateNinjaDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Créer un nouveau personnage',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: KaiColors.background,
            ),
          ),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Nom du personnage',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: KaiColors.background,
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
                  _createNinjaAndStartGame(name);
                  _nameController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KaiColors.background,
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
