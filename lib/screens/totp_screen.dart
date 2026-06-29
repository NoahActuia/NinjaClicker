import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/mfa_service.dart';
import '../utils/auth_error_mapper.dart';
import '../styles/kai_colors.dart';

class TotpVerifyScreen extends StatefulWidget {
  final MultiFactorResolver resolver;

  const TotpVerifyScreen({super.key, required this.resolver});

  @override
  State<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends State<TotpVerifyScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeController.text.trim().length < 6) {
      setState(() => _errorMessage = 'Entrez le code à 6 chiffres');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await _authService.completeMfaLogin(
        resolver: widget.resolver,
        verificationCode: _codeController.text.trim(),
      );

      if (user != null && mounted) {
        if (_authService.isEmailVerified) {
          Navigator.pushReplacementNamed(context, '/welcome');
        } else {
          Navigator.pushReplacementNamed(context, '/email_verification');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = AuthErrorMapper.map(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Double authentification',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez le code de votre application Authenticator',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: TextStyle(color: Colors.white24),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KaiColors.primaryDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Vérifier'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  final _mfaService = MfaService();
  final _codeController = TextEditingController();
  TotpEnrollmentData? _enrollmentData;
  bool _isLoading = true;
  bool _isEnrolling = false;
  String _errorMessage = '';
  bool _enrolled = false;

  @override
  void initState() {
    super.initState();
    _startEnrollment();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    try {
      final data = await _mfaService.startTotpEnrollment();
      if (mounted) {
        setState(() {
          _enrollmentData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthErrorMapper.map(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeEnrollment() async {
    if (_enrollmentData == null) return;

    setState(() {
      _isEnrolling = true;
      _errorMessage = '';
    });

    try {
      await _mfaService.completeTotpEnrollment(
        secret: _enrollmentData!.secret,
        verificationCode: _codeController.text.trim(),
      );
      if (mounted) {
        setState(() => _enrolled = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = AuthErrorMapper.map(e));
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activer la 2FA'),
        backgroundColor: KaiColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrolled
              ? _buildSuccess()
              : _buildSetup(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            '2FA activée avec succès !',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '1. Scannez ce QR code avec Google Authenticator ou Authy',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_enrollmentData != null)
            QrImageView(
              data: _enrollmentData!.qrCodeUri,
              version: QrVersions.auto,
              size: 200,
            ),
          const SizedBox(height: 8),
          if (_enrollmentData != null)
            Text(
              'Clé manuelle : ${_enrollmentData!.secret.secretKey}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          const Text('2. Entrez le code à 6 chiffres généré'),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '000000',
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          _isEnrolling
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _completeEnrollment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KaiColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Activer la 2FA'),
                ),
        ],
      ),
    );
  }
}
