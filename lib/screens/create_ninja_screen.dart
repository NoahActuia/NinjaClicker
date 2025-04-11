import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ninja_simple.dart';

class CreateNinjaScreen extends StatefulWidget {
  const CreateNinjaScreen({Key? key}) : super(key: key);

  @override
  _CreateNinjaScreenState createState() => _CreateNinjaScreenState();
}

class _CreateNinjaScreenState extends State<CreateNinjaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createNinja() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer le ninja
      final ninjaData = {
        'userId': user.uid,
        'name': _nameController.text.trim(),
        'xp': 0,
        'level': 1,
      };

      // Ajouter à Firestore
      final docRef =
          await FirebaseFirestore.instance.collection('ninjas').add(ninjaData);

      // Récupérer le ninja créé
      final ninjaDoc = await docRef.get();
      final ninja = NinjaSimple.fromFirestore(ninjaDoc);

      // Rediriger vers l'écran principal
      if (mounted) {
        Navigator.pop(context, ninja);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un Ninja'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du Ninja'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createNinja,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Créer mon Ninja'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
