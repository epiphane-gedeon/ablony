/// Fichier: main.dart
/// Description: Point d'entrée principal de l'application Ablony.
/// Ce fichier initialise Firebase et lance l'application avec son thème configuré.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

/// Fonction principale qui lance l'application.
/// Marqée async car elle initialise Firebase de manière asynchrone.
void main() async {
  // S'assure que les bindings Flutter sont initialisés avant toute opération async
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase avec les options de configuration pour la plateforme actuelle
  // (Android, iOS, Web, etc.)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lance l'application
  runApp(const MainApp());
}

/// Widget racine de l'application Ablony.
/// Configure MaterialApp avec le thème et la page d'accueil.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Titre de l'application (visible dans le gestionnaire de tâches)
      title: 'Ablony',

      // Applique le thème personnalisé de l'application
      theme: AppTheme.lightTheme,

      // Cache le bandeau "Debug" en haut à droite
      debugShowCheckedModeBanner: false,

      // Page d'accueil temporaire (sera remplacée par le routeur plus tard)
      home: const Scaffold(body: Center(child: Text('Salut tout le monde !'))),
    );
  }
}
