import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/auth_error_mapper.dart';
import '../styles/kai_colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  final VoidCallback? onVerified;

  const EmailVerificationScreen({super.key, this.onVerified});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String _message = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerification(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_isLoading) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
        _message = '';
      });
    }

    try {
      await _authService.reloadUser();
      if (_authService.isEmailVerified) {
        _pollTimer?.cancel();
        widget.onVerified?.call();
        if (mounted && Navigator.canPop(context)) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else if (!silent && mounted) {
        setState(() => _message =
            'Email pas encore vérifié. Consultez votre boîte mail (et les spams).');
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _message = AuthErrorMapper.map(e));
      }
    } finally {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await _authService.sendEmailVerification();
      if (mounted) {
        setState(() => _message = 'Email de vérification renvoyé !');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = AuthErrorMapper.map(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_unread, size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'Vérifiez votre email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Un email Kaijin a été envoyé à :\n$email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cliquez sur le lien dans l\'email, puis revenez ici.\n'
                  'Vérification automatique toutes les 5 secondes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _message.contains('renvoyé')
                            ? Colors.greenAccent
                            : Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  ElevatedButton(
                    onPressed: () => _checkVerification(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KaiColors.primaryDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('J\'ai vérifié mon email'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resendEmail,
                    child: const Text(
                      'Renvoyer l\'email',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _authService.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/auth');
                      }
                    },
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
