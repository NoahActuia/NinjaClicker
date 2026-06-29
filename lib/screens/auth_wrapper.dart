import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/mfa_service.dart';
import '../utils/security_config.dart';
import 'auth_screen.dart';
import 'welcome_screen.dart';
import 'email_verification_screen.dart';
import 'mfa_onboarding_screen.dart';

/// Route guard complet : auth → email vérifié → 2FA → jeu.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _mfaService = MfaService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.active) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        if (!user.emailVerified) {
          return EmailVerificationScreen(
            onVerified: () => setState(() {}),
          );
        }

        if (SecurityConfig.requireMfaForAccess) {
          return FutureBuilder<bool>(
            future: _mfaService.isMfaEnabled(),
            builder: (context, mfaSnapshot) {
              if (mfaSnapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (mfaSnapshot.data != true) {
                return const MfaOnboardingScreen();
              }

              return const WelcomeScreen();
            },
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}
