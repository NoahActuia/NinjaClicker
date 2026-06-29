import 'package:firebase_auth/firebase_auth.dart';

/// Gestion de l'authentification à deux facteurs (TOTP) via Firebase Auth MFA.
/// Nécessite Firebase Authentication with Identity Platform activé dans la console.
class MfaService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Indique si l'utilisateur connecté a le MFA activé.
  Future<bool> isMfaEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final factors = await user.multiFactor.getEnrolledFactors();
    return factors.isNotEmpty;
  }

  /// Génère un secret TOTP pour l'enrôlement (Google Authenticator, etc.).
  Future<TotpEnrollmentData> startTotpEnrollment() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final session = await user.multiFactor.getSession();
    final secret = await TotpMultiFactorGenerator.generateSecret(session);

    final qrCodeUri = await secret.generateQrCodeUrl(
      accountName: user.email ?? user.uid,
      issuer: 'Kaijin',
    );

    return TotpEnrollmentData(
      secret: secret,
      qrCodeUri: qrCodeUri,
      accountName: user.email ?? user.uid,
    );
  }

  /// Finalise l'enrôlement TOTP avec le code de l'app authenticator.
  Future<void> completeTotpEnrollment({
    required TotpSecret secret,
    required String verificationCode,
    String displayName = 'Authenticator',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(
      secret,
      verificationCode.trim(),
    );

    await user.multiFactor.enroll(assertion, displayName: displayName);
  }

  /// Résout une connexion MFA après signInWithEmailAndPassword.
  Future<UserCredential> resolveMfaSignIn({
    required MultiFactorResolver resolver,
    required String verificationCode,
    int hintIndex = 0,
  }) async {
    final hint = resolver.hints[hintIndex];
    final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(
      hint.uid,
      verificationCode.trim(),
    );
    return resolver.resolveSignIn(assertion);
  }

  /// Désactive le MFA (nécessite une connexion récente).
  Future<void> unenrollMfa({int factorIndex = 0}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }
    final factors = await user.multiFactor.getEnrolledFactors();
    if (factors.isEmpty) return;
    await user.multiFactor.unenroll(multiFactorInfo: factors[factorIndex]);
  }
}

class TotpEnrollmentData {
  final TotpSecret secret;
  final String qrCodeUri;
  final String accountName;

  TotpEnrollmentData({
    required this.secret,
    required this.qrCodeUri,
    required this.accountName,
  });
}
