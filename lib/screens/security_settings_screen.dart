import 'package:flutter/material.dart';
import '../services/mfa_service.dart';
import '../services/auth_service.dart';
import '../utils/auth_error_mapper.dart';
import '../styles/kai_colors.dart';
import 'totp_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _mfaService = MfaService();
  final _authService = AuthService();
  bool _mfaEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMfaStatus();
  }

  Future<void> _loadMfaStatus() async {
    final enabled = await _mfaService.isMfaEnabled();
    if (mounted) {
      setState(() {
        _mfaEnabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggleMfa() async {
    if (_mfaEnabled) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Désactiver la 2FA ?'),
          content: const Text(
            'Votre compte sera moins protégé. Confirmer la désactivation ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Désactiver', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await _mfaService.unenrollMfa();
        if (mounted) setState(() => _mfaEnabled = false);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AuthErrorMapper.map(e))),
          );
        }
      }
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const TotpSetupScreen()),
      );
      if (result == true && mounted) {
        await _loadMfaStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';
    final emailVerified = _authService.isEmailVerified;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité du compte'),
        backgroundColor: KaiColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          ListTile(
            leading: Icon(
              emailVerified ? Icons.verified : Icons.warning,
              color: emailVerified ? Colors.green : Colors.orange,
            ),
            title: const Text('Email vérifié'),
            subtitle: Text(email),
            trailing: emailVerified
                ? const Icon(Icons.check, color: Colors.green)
                : TextButton(
                    onPressed: () async {
                      await _authService.sendEmailVerification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email de vérification envoyé'),
                          ),
                        );
                      }
                    },
                    child: const Text('Renvoyer'),
                  ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.security, color: Colors.orange),
            title: const Text('Double authentification (2FA)'),
            subtitle: const Text(
              'Protège votre compte avec un code TOTP (Google Authenticator)',
            ),
            value: _mfaEnabled,
            onChanged: (_) => _toggleMfa(),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.shield, color: KaiColors.primaryDark),
            title: Text('Politique de mot de passe'),
            subtitle: Text(
              '12+ caractères, majuscule, minuscule, chiffre et symbole requis',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.lock_clock, color: KaiColors.primaryDark),
            title: Text('Protection anti-bruteforce'),
            subtitle: Text(
              '5 tentatives max, blocage 15 minutes',
            ),
          ),
        ],
      ),
    );
  }
}
