import 'package:firebase_auth/firebase_auth.dart';
import '../config/firebase_auth_config.dart';

/// Envoi des emails Firebase Auth avec deep links et gestion des liens entrants.
class EmailActionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;

    await user.sendEmailVerification(
      FirebaseAuthConfig.emailVerificationSettings,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
      actionCodeSettings: FirebaseAuthConfig.passwordResetSettings,
    );
  }

  /// Traite un lien Firebase Auth (vérification email, reset MDP) ouvert dans l'app.
  Future<EmailActionResult> handleIncomingLink(String link) async {
    if (!link.contains('mode=') && !link.contains('oobCode=')) {
      return EmailActionResult.none;
    }

    try {
      if (_auth.isSignInWithEmailLink(link)) {
        return EmailActionResult.emailLinkSignIn;
      }
    } catch (_) {}

    final uri = Uri.parse(link);
    final mode = uri.queryParameters['mode'];
    final oobCode = uri.queryParameters['oobCode'];

    if (oobCode == null) return EmailActionResult.none;

    switch (mode) {
      case 'verifyEmail':
        await _auth.applyActionCode(oobCode);
        await _auth.currentUser?.reload();
        return EmailActionResult.emailVerified;
      case 'resetPassword':
        return EmailActionResult.passwordResetReady;
      default:
        return EmailActionResult.none;
    }
  }
}

enum EmailActionResult {
  none,
  emailVerified,
  passwordResetReady,
  emailLinkSignIn,
}
