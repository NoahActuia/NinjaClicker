import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_model;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer l'utilisateur actuel
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  bool get isLoggedIn => _auth.currentUser != null;

  // Stream sur l'état de l'authentification
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Inscription avec email et mot de passe
  Future<app_model.User?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Créer le document utilisateur dans Firestore
        final userData = {
          'username': username,
          'email': email,
          'createdAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
        };

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        // Retourner l'utilisateur sous forme de modèle
        return app_model.User(
          id: userCredential.user!.uid,
          username: username,
          email: email,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      throw e;
    }
    return null;
  }

  // Connexion avec email et mot de passe
  Future<app_model.User?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Connecter l'utilisateur
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Mettre à jour la dernière connexion
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'lastLogin': Timestamp.now()});

        // Récupérer les données utilisateur
        final docSnapshot = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (docSnapshot.exists) {
          // Créer et retourner l'utilisateur
          return app_model.User.fromFirestore(docSnapshot);
        }
      }
    } catch (e) {
      print('Erreur lors de la connexion: $e');
      throw e;
    }
    return null;
  }

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Récupérer les données de l'utilisateur actuel
  Future<app_model.User?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        return app_model.User.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
    }
    return null;
  }
}
