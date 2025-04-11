import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/saved_game.dart';
import '../services/save_service.dart';
import 'game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      print('WelcomeScreen: Début du chargement des sauvegardes');

      // Obtenons directement l'instance de SharedPreferences pour vérifier
      final prefs = await SharedPreferences.getInstance();
      final rawSavedGames = prefs.getStringList('saved_games');
      print(
          'WelcomeScreen: SharedPreferences contient ${rawSavedGames?.length ?? 0} sauvegardes brutes');

      // Utiliser le service pour charger les sauvegardes
      final savedGames = await _saveService.loadSavedGames();
      print(
          'WelcomeScreen: SaveService a retourné ${savedGames.length} sauvegardes');

      setState(() {
        _savedGames = savedGames;
      });

      // Vérifier si les sauvegardes sont chargées correctement
      if (savedGames.isEmpty && (rawSavedGames?.isNotEmpty ?? false)) {
        print(
            'ALERTE: Problème de chargement - SharedPreferences contient des données mais aucune sauvegarde n\'a été chargée');
      }
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
                  child: const Text(
                    'Charger une Partie',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Bouton de débogage - uniquement visible en mode développement
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final keys = prefs.getKeys();
                          final data = {
                            for (var key in keys)
                              key: key == 'saved_games' || key == 'missions'
                                  ? prefs.getStringList(key)
                                  : prefs.get(key)
                          };

                          // Afficher les données dans une boîte de dialogue
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Données sauvegardées'),
                                  content: SingleChildScrollView(
                                    child: Text(data.toString()),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Fermer'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                        ),
                        child: const Text('Vérifier les sauvegardes'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          // Confirmer la suppression
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Réinitialiser'),
                                content: const Text(
                                    'Supprimer toutes les données sauvegardées ? Cette action est irréversible.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            await _saveService.clearAllData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Toutes les données ont été réinitialisées'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              // Recharger les sauvegardes
                              _loadSavedGames();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Réinitialiser les données'),
                      ),
                    ],
                  ),
                ),

                // Ajout des boutons d'export/import manuel
                const SizedBox(height: 20),
                Text(
                  'Exporter/Importer les sauvegardes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _saveService.exportAllSavesToFile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fichier de sauvegarde téléchargé'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Exporter les sauvegardes'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        _showImportDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Importer les sauvegardes'),
                    ),
                  ],
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

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importer des sauvegardes'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Cliquez sur le bouton ci-dessous pour sélectionner un fichier de sauvegarde (.json)'),
              SizedBox(height: 20),
              Text('Note: Cette action remplacera vos sauvegardes actuelles',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Créer un élément input de type fichier
                final uploadInput = html.FileUploadInputElement()
                  ..accept = '.json';
                uploadInput.click();

                // Gérer la sélection de fichier
                uploadInput.onChange.listen((event) {
                  final file = uploadInput.files!.first;
                  final reader = html.FileReader();
                  reader.readAsText(file);
                  reader.onLoadEnd.listen((event) {
                    if (reader.result != null) {
                      final content = reader.result as String;
                      _saveService.importSavesFromFile(content).then((success) {
                        Navigator.pop(context);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Sauvegardes importées avec succès'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadSavedGames();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Erreur lors de l\'importation des sauvegardes'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });
                    }
                  });
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Sélectionner un fichier'),
            ),
          ],
        );
      },
    );
  }
}
