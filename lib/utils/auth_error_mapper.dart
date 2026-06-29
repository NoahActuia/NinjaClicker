import 'package:firebase_auth/firebase_auth.dart';

/// Convertit les erreurs Firebase en messages utilisateur sans fuite d'infos techniques.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String map(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Adresse email invalide.';
        case 'user-disabled':
          return 'Ce compte a été désactivé. Contactez le support.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email ou mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cette adresse email est déjà utilisée.';
        case 'weak-password':
          return 'Mot de passe trop faible. Utilisez au moins 12 caractères avec majuscules, chiffres et symboles.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez dans quelques minutes.';
        case 'network-request-failed':
          return 'Erreur réseau. Vérifiez votre connexion.';
        case 'operation-not-allowed':
          return 'Cette opération n\'est pas autorisée.';
        case 'requires-recent-login':
          return 'Reconnectez-vous pour effectuer cette action sensible.';
        case 'multi-factor-auth-required':
          return 'Vérification à deux facteurs requise.';
        case 'invalid-verification-code':
        case 'invalid-verification-id':
          return 'Code de vérification invalide ou expiré.';
        default:
          return 'Erreur d\'authentification. Veuillez réessayer.';
      }
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
