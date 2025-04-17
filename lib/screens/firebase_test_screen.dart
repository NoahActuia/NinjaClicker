import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/firebase_service.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _connectionStatus = "Vérification de la connexion...";
  bool _isConnected = false;
  String _lastError = "";
  Map<String, bool> _testResults = {
    'initialization': false,
    'firestore': false,
    'auth': false,
  };
  Map<String, bool> _collectionResults = {};
  bool _isInitializing = false;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      // Vérifier si Firebase est initialisé
      final apps = Firebase.apps;
      _testResults['initialization'] = apps.isNotEmpty;
      if (apps.isEmpty) {
        setState(() {
          _connectionStatus = "Firebase n'est pas initialisé";
          _isConnected = false;
        });
        return;
      }

      // Vérifier Firestore
      try {
        final result = await FirebaseFirestore.instance
            .collection('test')
            .doc('connection_test')
            .set({'timestamp': Timestamp.now()}, SetOptions(merge: true));
        _testResults['firestore'] = true;
      } catch (e) {
        _testResults['firestore'] = false;
        _lastError = "Erreur Firestore: $e";
        print(_lastError);
      }

      // Vérifier Auth (anonyme)
      try {
        // Essayer de se connecter anonymement
        await FirebaseAuth.instance.signInAnonymously();
        _testResults['auth'] = true;
      } catch (e) {
        _testResults['auth'] = false;
        if (_lastError.isEmpty) {
          _lastError = "Erreur Auth: $e";
        }
        print("Erreur Auth: $e");
      }

      // Vérifier les collections avec FirebaseService
      _collectionResults = await _firebaseService.testCollections();

      // Mise à jour du statut global
      setState(() {
        if (_testResults['initialization']! &&
            (_testResults['firestore']! || _testResults['auth']!)) {
          _connectionStatus = "Connexion Firebase établie";
          _isConnected = true;
        } else {
          _connectionStatus = "Problème de connexion Firebase";
          _isConnected = false;
        }
      });
    } catch (e) {
      setState(() {
        _connectionStatus = "Erreur lors de la vérification: $e";
        _isConnected = false;
        _lastError = e.toString();
      });
      print("Erreur globale: $e");
    }
  }

  Future<void> _testWriteCollection(String collection) async {
    try {
      await FirebaseFirestore.instance.collection(collection).add({
        'test_id': 'test_${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': Timestamp.now()
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Écriture réussie dans $collection!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'écriture dans $collection: $e')),
      );
    }
  }

  Future<void> _initializeDefaultData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      await _firebaseService.initializeData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Données de base initialisées avec succès!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'initialisation: $e')),
      );
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Firebase')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut de connexion
            Card(
              color: _isConnected ? Colors.green[100] : Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionStatus,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_lastError.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Dernière erreur: $_lastError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Résultats des tests
            const Text(
              'Détails des tests:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildTestResultItem(
              'Initialisation Firebase',
              _testResults['initialization'] ?? false,
            ),
            _buildTestResultItem(
              'Connexion Firestore',
              _testResults['firestore'] ?? false,
            ),
            _buildTestResultItem(
              'Authentification Firebase',
              _testResults['auth'] ?? false,
            ),
            const SizedBox(height: 10),

            if (_collectionResults.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Accès aux collections:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final entry in _collectionResults.entries)
                _buildTestResultItem(
                  'Collection ${entry.key}',
                  entry.value,
                ),
            ],

            const SizedBox(height: 20),

            // Bouton de rafraîchissement
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _connectionStatus = "Vérification de la connexion...";
                  _lastError = "";
                });
                _checkFirebaseConnection();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer la connexion'),
            ),
            const SizedBox(height: 20),

            // Tests d'écriture dans différentes collections
            const Text(
              'Tester l\'écriture dans les collections:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _testWriteCollection('users'),
                  child: const Text('Tester users'),
                ),
                ElevatedButton(
                  onPressed: () => _testWriteCollection('techniques'),
                  child: const Text('Tester techniques'),
                ),
                ElevatedButton(
                  onPressed: () => _testWriteCollection('ninjas'),
                  child: const Text('Tester ninjas'),
                ),
                ElevatedButton(
                  onPressed: () => _testWriteCollection('senseis'),
                  child: const Text('Tester senseis'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Initialisation des données par défaut
            const Text(
              'Initialisation des données:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isInitializing ? null : _initializeDefaultData,
              icon: _isInitializing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isInitializing
                  ? 'Initialisation en cours...'
                  : 'Initialiser les données par défaut'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TechniquesListScreen(),
                  ),
                );
              },
              child: const Text('Voir les techniques'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultItem(String testName, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(testName),
        ],
      ),
    );
  }
}

class TechniquesListScreen extends StatelessWidget {
  const TechniquesListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Techniques')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('techniques').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Aucune technique trouvée'),
                  SizedBox(height: 16),
                  Text(
                    'La collection existe mais elle est vide, ou la collection n\'existe pas.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final technique = snapshot.data!.docs[index];
              final data = technique.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['name'] ?? 'Sans nom'),
                subtitle: Text(data['description'] ?? ''),
                trailing: Text('${data['cost'] ?? 0} XP'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSampleTechnique(context),
        child: const Icon(Icons.add),
        tooltip: 'Ajouter technique de test',
      ),
    );
  }

  Future<void> _addSampleTechnique(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('techniques').add({
        'name': 'Technique de Test ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'Technique créée pour tester la connexion Firebase',
        'cost': 100,
        'powerPerSecond': 5,
        'sound': 'sounds/technique_test.mp3',
        'type': 'special',
        'effect': 'damage',
        'kaiCost': 50,
        'cooldown': 3,
        'isDefault': true,
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Technique de test ajoutée!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout: $e')),
      );
    }
  }
}
