import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/firebase_test_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/auth_wrapper.dart';
import 'services/database_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase avec gestion d'erreur
  bool firebaseInitialized = false;
  String firebaseError = '';

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print('Firebase initialisé avec succès');

    // Initialiser la base de données avec les techniques et senseis
    final databaseInitializer = DatabaseInitializer();
    await databaseInitializer.initializeDatabase();
    print('Base de données initialisée avec succès');
  } catch (e) {
    firebaseError = e.toString();
    print('Erreur lors de l\'initialisation de Firebase: $e');
  }

  runApp(MyApp(
    firebaseInitialized: firebaseInitialized,
    firebaseError: firebaseError,
  ));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String firebaseError;

  const MyApp({
    super.key,
    required this.firebaseInitialized,
    required this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'logo.png',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          secondary: Colors.blue,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => firebaseInitialized
            ? const AuthWrapper()
            : FirebaseErrorScreen(error: firebaseError),
        '/auth': (context) => const AuthScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/firebase_test': (context) => const FirebaseTestScreen(),
      },
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  final String error;

  const FirebaseErrorScreen({
    Key? key,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'Erreur d\'initialisation Firebase',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                error.isNotEmpty
                    ? 'Détails: $error'
                    : 'Impossible d\'initialiser la connexion à Firebase',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
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
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Diagnostiquer le problème'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
