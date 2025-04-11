import 'package:flutter/material.dart';
import '../models/saved_game.dart';
import '../services/save_service.dart';
import 'game_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<SavedGame> _savedGames = [];
  bool _isLoading = true;
  final SaveService _saveService = SaveService();

  @override
  void initState() {
    super.initState();
    _loadSavedGames();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Charger les sauvegardes existantes
  Future<void> _loadSavedGames() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final savedGames = await _saveService.loadSavedGames();

      setState(() {
        _savedGames = savedGames;
      });
    } catch (e) {
      print('Erreur lors du chargement des sauvegardes: $e');
    } finally {
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
                  _startNewGame(_nameController.text.trim());
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

  // Démarrer une nouvelle partie
  void _startNewGame(String playerName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerName: playerName,
          savedGame: null, // Pas de sauvegarde pour une nouvelle partie
        ),
      ),
    );
  }

  // Charger une partie sauvegardée
  void _loadGame(SavedGame savedGame) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerName: savedGame.nom,
          savedGame: savedGame,
        ),
      ),
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
                const Text(
                  'NINJA CLICKER',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),

                // Boutons principale
                ElevatedButton(
                  onPressed: _showNewGameDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Nouvelle Partie',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _savedGames.isEmpty
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => _buildSavedGamesSheet(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Charger une Partie',
                    style: TextStyle(
                      fontSize: 20,
                      color: _savedGames.isEmpty ? Colors.grey : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Affichage du chargement ou du nombre de sauvegardes
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.orange)
                else if (_savedGames.isNotEmpty)
                  Text(
                    '${_savedGames.length} sauvegarde${_savedGames.length > 1 ? 's' : ''} disponible${_savedGames.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white),
                  )
                else
                  const Text(
                    'Aucune sauvegarde trouvée',
                    style: TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Construire la feuille des parties sauvegardées
  Widget _buildSavedGamesSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choisir une sauvegarde',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _savedGames.length,
              itemBuilder: (context, index) {
                final save = _savedGames[index];
                final date = save.date;
                final formattedDate =
                    '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.save, color: Colors.orange),
                    title: Text(save.nom),
                    subtitle: Text(
                      '${formattedDate}\nPuissance: ${save.puissance} - Clones: ${save.nombreDeClones}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmed =
                                await _confirmDeleteSavedGame(save.nom);
                            if (confirmed && context.mounted) {
                              await _saveService.deleteSavedGame(save.nom);
                              Navigator.pop(context);
                              _loadSavedGames();
                            }
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: Colors.green),
                          onPressed: () {
                            Navigator.pop(context);
                            _loadGame(save);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _loadGame(save);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteSavedGame(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la sauvegarde'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer la sauvegarde de "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
