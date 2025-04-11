import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/saved_game.dart';
import '../services/save_service.dart';
import 'game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_test_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ninja_service.dart';
import '../models/ninja.dart';

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
              color: Colors.orange,
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
                backgroundColor: Colors.orange,
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

        // Démarrer le jeu avec ce ninja
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(
                playerName: playerName,
                savedGame: null,
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
                backgroundColor: Colors.orange,
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
              backgroundColor: Colors.orange,
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
                // Titre du jeu
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),

                // Liste des ninjas
                Container(
                  height: 300,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vos Ninjas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildNinjasList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton pour créer un nouveau ninja
                if (_playerNinjas.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _showNewGameDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau Ninja'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                  ),

                const SizedBox(height: 40),

                // Boutons du bas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FirebaseTestScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('Tester Firebase'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
