import 'package:firebase_auth/firebase_auth.dart';

/// Configuration centralisée Firebase Auth (URLs, deep links, templates).
class FirebaseAuthConfig {
  FirebaseAuthConfig._();

  static const String projectId = 'ninjaclicker-9bad6';
  static const String authDomain = 'ninjaclicker-9bad6.firebaseapp.com';
  static const String appName = 'Kaijin';
  static const String supportEmail = 'support@kaijin-game.fr';

  static const String androidPackageName = 'com.example.ninja_clicker';
  static const String iosBundleId = 'com.example.ninjaClicker';

  /// URL de retour après clic sur le lien de vérification email.
  static const String emailVerificationContinueUrl =
      'https://ninjaclicker-9bad6.firebaseapp.com/email-verified';

  /// URL de retour après reset mot de passe.
  static const String passwordResetContinueUrl =
      'https://ninjaclicker-9bad6.firebaseapp.com/password-reset';

  static ActionCodeSettings get emailVerificationSettings => ActionCodeSettings(
        url: emailVerificationContinueUrl,
        handleCodeInApp: true,
        androidPackageName: androidPackageName,
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: iosBundleId,
      );

  static ActionCodeSettings get passwordResetSettings => ActionCodeSettings(
        url: passwordResetContinueUrl,
        handleCodeInApp: true,
        androidPackageName: androidPackageName,
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: iosBundleId,
      );
}
