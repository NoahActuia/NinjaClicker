import 'package:flutter/foundation.dart';

/// Configuration centralisée de la sécurité de l'application.
class SecurityConfig {
  SecurityConfig._();

  /// Écran de test Firebase accessible uniquement en mode debug.
  static bool get isDebugToolsEnabled => kDebugMode;

  /// Initialisation de la base depuis le client (seed) uniquement en debug.
  static bool get allowClientDatabaseSeeding => kDebugMode;

  /// Longueur minimale du mot de passe.
  static const int minPasswordLength = 12;

  /// Nombre max de tentatives de connexion avant blocage temporaire.
  static const int maxLoginAttempts = 5;

  /// Durée du blocage après trop de tentatives.
  static const Duration loginLockoutDuration = Duration(minutes: 15);

  /// Regex : au moins 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial.
  static final RegExp passwordComplexityRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~]).+$',
  );

  /// Validation du mot de passe côté client (complémentaire à Firebase).
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (password.length < minPasswordLength) {
      return 'Le mot de passe doit contenir au moins $minPasswordLength caractères';
    }
    if (!passwordComplexityRegex.hasMatch(password)) {
      return 'Le mot de passe doit contenir une majuscule, une minuscule, un chiffre et un caractère spécial';
    }
    return null;
  }

  /// Validation de l'email.
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Veuillez entrer un email';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  /// Validation du pseudo (anti-injection basique dans les champs texte).
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Veuillez entrer un pseudo';
    }
    if (username.length < 3 || username.length > 20) {
      return 'Le pseudo doit faire entre 3 et 20 caractères';
    }
    if (!RegExp(r'^[a-zA-Z0-9_\-àâäéèêëïîôùûüçÀÂÄÉÈÊËÏÎÔÙÛÜÇ]+$')
        .hasMatch(username)) {
      return 'Le pseudo ne peut contenir que des lettres, chiffres, _ et -';
    }
    return null;
  }
}
