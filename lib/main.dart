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
import 'screens/mfa_onboarding_screen.dart';
import 'screens/unsupported_platform_screen.dart';
import 'navigation/app_routes.dart';
import 'services/database_initializer.dart';
import 'utils/security_config.dart';
import 'utils/platform_support.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'styles/kai_colors.dart';
import 'services/resonance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!PlatformSupport.isFirebaseSupported) {
    runApp(MyApp(
      firebaseInitialized: false,
      firebaseError: PlatformSupport.unsupportedPlatformMessage,
      unsupportedPlatform: true,
    ));
    return;
  }

  var firebaseInitialized = false;
  var firebaseError = '';

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }
  } catch (e) {
    firebaseError = e.toString();
    debugPrint('Erreur lors de l\'initialisation Firebase: $e');
  }

  if (firebaseInitialized && SecurityConfig.allowClientDatabaseSeeding) {
    try {
      final dbInitializer = DatabaseInitializer();
      await dbInitializer.initializeDatabase();

      final resonanceService = ResonanceService();
      await resonanceService.initDefaultResonances();
    } catch (e) {
      debugPrint('Erreur initialisation base: $e');
    }
  }

  runApp(MyApp(
    firebaseInitialized: firebaseInitialized,
    firebaseError: firebaseError,
    unsupportedPlatform: false,
  ));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String firebaseError;
  final bool unsupportedPlatform;

  const MyApp({
    super.key,
    required this.firebaseInitialized,
    required this.firebaseError,
    this.unsupportedPlatform = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaijin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
        AppRoutes.root: (context) {
          if (unsupportedPlatform) {
            return UnsupportedPlatformScreen(message: firebaseError);
          }
          if (!firebaseInitialized) {
            return FirebaseErrorScreen(error: firebaseError);
          }
          return const AuthWrapper();
        },
        AppRoutes.auth: (context) => const AuthScreen(),
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        if (kDebugMode)
          AppRoutes.firebaseTest: (context) => const FirebaseTestScreen(),
        AppRoutes.techniqueTree: (context) => const TechniqueTreeScreen(),
        AppRoutes.onlineCombat: (context) => const OnlineCombatScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.emailVerification: (context) => const EmailVerificationScreen(),
        AppRoutes.mfaOnboarding: (context) => const MfaOnboardingScreen(),
        AppRoutes.securitySettings: (context) => const SecuritySettingsScreen(),
      },
    );
  }
}
