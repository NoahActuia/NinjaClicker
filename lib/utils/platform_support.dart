import 'package:flutter/foundation.dart';

/// Plateformes supportées par FlutterFire dans ce projet.
class PlatformSupport {
  PlatformSupport._();

  static bool get isFirebaseSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  static String get unsupportedPlatformMessage {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'Firebase n\'est pas disponible sur Linux desktop.\n\n'
          'Lancez le projet avec Chrome :\n'
          'flutter run -d chrome';
    }
    return 'Firebase n\'est pas disponible sur cette plateforme.';
  }
}
