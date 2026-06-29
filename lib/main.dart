import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/firebase_test_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/technique_tree_screen.dart';
import 'screens/online_combat_screen.dart';
import 'screens/intro_video_screen.dart' show IntroVideoScreen;
import 'screens/game_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/security_settings_screen.dart';
import 'navigation/app_routes.dart';
import 'services/database_initializer.dart';
import 'utils/security_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'styles/kai_colors.dart';
import 'services/resonance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Crashlytics uniquement pour les plateformes mobiles
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }
  } catch (e) {
    print("Erreur lors de l'initialisation: $e");
  }
  final dbInitializer = DatabaseInitializer();
  if (SecurityConfig.allowClientDatabaseSeeding) {
    await dbInitializer.initializeDatabase();
  }

  // Initialiser les résonances par défaut (uniquement en debug)
  if (SecurityConfig.allowClientDatabaseSeeding) {
    final resonanceService = ResonanceService();
    await resonanceService.initDefaultResonances();
  }

  runApp(const MyApp(firebaseInitialized: true, firebaseError: ''));
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
      title: 'Kaijin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Thème partagé pour Android et iOS
        colorScheme: ColorScheme.fromSeed(
          seedColor: KaiColors.primaryDark,
          secondary: KaiColors.accent,
          brightness: Brightness.light,
        ),
        primaryColor: KaiColors.primaryDark,
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        textTheme: TextTheme(
          headlineMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: KaiColors.accent,
          ),
        ),
        // Surcharge iOS spécifique
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryColor: KaiColors.primaryDark,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.introVideo) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final playerName = args['playerName'] as String? ?? 'Fracturé';
          return MaterialPageRoute(
            builder: (_) => IntroVideoScreen(playerName: playerName),
          );
        }
        if (settings.name == AppRoutes.game) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final playerName = args['playerName'] as String? ?? 'Fracturé';
          final resetState = args['resetState'] as bool? ?? false;
          return MaterialPageRoute(
            builder: (_) => GameScreen(
              playerName: playerName,
              savedGame: null,
              resetState: resetState,
            ),
          );
        }
        return null;
      },
      routes: {
        AppRoutes.root:
            (context) =>
                firebaseInitialized
                    ? const AuthWrapper()
                    : FirebaseErrorScreen(error: firebaseError),
        AppRoutes.auth: (context) => const AuthScreen(),
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        if (kDebugMode)
          AppRoutes.firebaseTest: (context) => const FirebaseTestScreen(),
        AppRoutes.techniqueTree: (context) => const TechniqueTreeScreen(),
        AppRoutes.onlineCombat: (context) => const OnlineCombatScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.emailVerification: (context) => const EmailVerificationScreen(),
        AppRoutes.securitySettings: (context) => const SecuritySettingsScreen(),
      },
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  final String error;

  const FirebaseErrorScreen({Key? key, required this.error}) : super(key: key);

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
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
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
                onPressed: kDebugMode
                    ? () => Navigator.pushNamed(context, AppRoutes.firebaseTest)
                    : null,
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
