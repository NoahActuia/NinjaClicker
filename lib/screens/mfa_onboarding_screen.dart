import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../styles/kai_colors.dart';
import 'totp_screen.dart';

/// Écran obligatoire après vérification email : configure la 2FA TOTP.
class MfaOnboardingScreen extends StatelessWidget {
  const MfaOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.shield_outlined, size: 90, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'Sécurisez votre compte',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pour protéger votre progression, activez la double authentification (2FA) avec Google Authenticator.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _buildStep(Icons.mark_email_read, 'Email vérifié', true),
                _buildStep(Icons.security, 'Configurer la 2FA', false),
                _buildStep(Icons.sports_esports, 'Accéder au jeu', false),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const TotpSetupScreen()),
                    );
                    if (result == true && context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Activer la 2FA maintenant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KaiColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/welcome'),
                    child: const Text(
                      'Passer (mode debug uniquement)',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(IconData icon, String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: done ? Colors.greenAccent : Colors.white38, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: done ? Colors.greenAccent : Colors.white54,
              fontWeight: done ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (done) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
          ],
        ],
      ),
    );
  }
}
