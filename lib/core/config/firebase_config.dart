/// Configuration Firebase pour basculer entre émulateurs et production
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  /// Indique si on utilise les émulateurs Firebase
  /// true en mode debug, false en production
  static bool get useEmulators => kDebugMode;

  /// Host pour les émulateurs
  /// - Android Emulator: '10.0.2.2' (pointe vers localhost de l'hôte)
  /// - iOS Simulator: 'localhost' ou '127.0.0.1'
  /// - Device physique: IP de votre machine (ex: '192.168.1.10')
  static String get emulatorHost {
    // Détection automatique de la plateforme
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2'; // Android Emulator → localhost de l'hôte
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'localhost'; // iOS Simulator
    } else {
      return 'localhost'; // Web ou autres
    }
  }

  /// Ports des émulateurs (définis dans firebase.json)
  static const int authPort = 9099;
  static const int firestorePort = 8080;
  static const int storagePort = 9199;
  static const int functionsPort = 5001;

  /// URL de l'interface UI des émulateurs
  static const String emulatorUiUrl = 'http://localhost:4001';

  /// Affiche les informations de configuration
  static void printConfig() {
    if (useEmulators) {
      debugPrint('🔥 FIREBASE EN MODE ÉMULATEURS');
      debugPrint('   Host: $emulatorHost');
      debugPrint('   Auth: $emulatorHost:$authPort');
      debugPrint('   Firestore: $emulatorHost:$firestorePort');
      debugPrint('   Storage: $emulatorHost:$storagePort');
      debugPrint('   Functions: $emulatorHost:$functionsPort');
      debugPrint('   UI: $emulatorUiUrl');
    } else {
      debugPrint('🔥 FIREBASE EN MODE PRODUCTION');
      debugPrint('   Projet: ablony-a5db9');
      debugPrint('   Region: us-central1');
    }
  }
}
