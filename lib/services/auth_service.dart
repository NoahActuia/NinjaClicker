import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_model;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/security_config.dart';
import 'mfa_service.dart';

/// Résultat d'une tentative de connexion (avec ou sans MFA).
class AuthResult {
  final app_model.User? user;
  final firebase_auth.MultiFactorResolver? mfaResolver;
  final bool requiresMfa;

  const AuthResult({
    this.user,
    this.mfaResolver,
    this.requiresMfa = false,
  });
}

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MfaService _mfaService = MfaService();

  int _failedLoginAttempts = 0;
  DateTime? _lockoutUntil;

  firebase_auth.User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<bool> get isMfaEnabled => _mfaService.isMfaEnabled();

  void _checkLoginLockout() {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inMinutes + 1;
      throw Exception(
        'Trop de tentatives. Réessayez dans $remaining minute(s).',
      );
    }
    if (_lockoutUntil != null && DateTime.now().isAfter(_lockoutUntil!)) {
      _failedLoginAttempts = 0;
      _lockoutUntil = null;
    }
  }

  void _recordFailedLogin() {
    _failedLoginAttempts++;
    if (_failedLoginAttempts >= SecurityConfig.maxLoginAttempts) {
      _lockoutUntil =
          DateTime.now().add(SecurityConfig.loginLockoutDuration);
      _failedLoginAttempts = 0;
    }
  }

  void _resetLoginAttempts() {
    _failedLoginAttempts = 0;
    _lockoutUntil = null;
  }

  Future<app_model.User?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final emailError = SecurityConfig.validateEmail(email);
    if (emailError != null) throw Exception(emailError);

    final passwordError = SecurityConfig.validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    final usernameError = SecurityConfig.validateUsername(username);
    if (usernameError != null) throw Exception(usernameError);

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (userCredential.user == null) return null;

    await userCredential.user!.updateDisplayName(username.trim());

    final userData = {
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
      'mfaEnabled': false,
    };

    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(userData);

    await sendEmailVerification();

    return app_model.User(
      id: userCredential.user!.uid,
      username: username.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      mfaEnabled: false,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _checkLoginLockout();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      _resetLoginAttempts();

      if (userCredential.user != null) {
        final user = await _syncUserDocument(userCredential.user!);
        return AuthResult(user: user);
      }
      return const AuthResult();
    } on firebase_auth.FirebaseAuthMultiFactorException catch (e) {
      _resetLoginAttempts();
      return AuthResult(
        mfaResolver: e.resolver,
        requiresMfa: true,
      );
    } catch (e) {
      _recordFailedLogin();
      rethrow;
    }
  }

  Future<app_model.User?> completeMfaLogin({
    required firebase_auth.MultiFactorResolver resolver,
    required String verificationCode,
  }) async {
    final credential = await _mfaService.resolveMfaSignIn(
      resolver: resolver,
      verificationCode: verificationCode,
    );

    if (credential.user != null) {
      return _syncUserDocument(credential.user!);
    }
    return null;
  }

  Future<app_model.User?> _syncUserDocument(firebase_auth.User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final mfaEnabled = (await firebaseUser.multiFactor.getEnrolledFactors()).isNotEmpty;
      await docRef.update({
        'lastLogin': Timestamp.now(),
        'mfaEnabled': mfaEnabled,
      });
      return app_model.User.fromFirestore(docSnapshot);
    }

    final mfaEnabled = (await firebaseUser.multiFactor.getEnrolledFactors()).isNotEmpty;
    final newUser = app_model.User(
      id: firebaseUser.uid,
      username: firebaseUser.displayName ??
          firebaseUser.email?.split('@')[0] ??
          'Joueur',
      email: firebaseUser.email ?? '',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      mfaEnabled: mfaEnabled,
    );

    await docRef.set(newUser.toFirestore());
    return newUser;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final emailError = SecurityConfig.validateEmail(email);
    if (emailError != null) throw Exception(emailError);

    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> logout() async {
    await _auth.signOut();
    _resetLoginAttempts();
  }

  Future<app_model.User?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docSnapshot =
        await _firestore.collection('users').doc(user.uid).get();

    if (docSnapshot.exists) {
      return app_model.User.fromFirestore(docSnapshot);
    }
    return null;
  }
}
