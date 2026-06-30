import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_clicker/services/auth_service.dart';

void main() {
  group('AuthService access guard', () {
    test('bloque l’accès si l’utilisateur est connecté mais son email n’est pas vérifié', () {
      expect(
        AuthService.canAccessApp(
          isAuthenticated: true,
          isEmailVerified: false,
        ),
        isFalse,
      );
    });

    test('autorise l’accès quand l’email est vérifié', () {
      expect(
        AuthService.canAccessApp(
          isAuthenticated: true,
          isEmailVerified: true,
        ),
        isTrue,
      );
    });
  });
}
