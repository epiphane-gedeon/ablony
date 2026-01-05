/// Fichier: main.dart
/// Description: Point d'entrée principal de l'application Ablony.
/// Ce fichier initialise Firebase et lance l'application avec son thème configuré.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/navigation/app_router.dart';
import 'l10n/app_localizations.dart';

/// Fonction principale qui lance l'application.
/// Marqée async car elle initialise Firebase de manière asynchrone.
void main() async {
  // S'assure que les bindings Flutter sont initialisés avant toute opération async
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase avec les options de configuration pour la plateforme actuelle
  // (Android, iOS, Web, etc.)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔥 CONFIGURATION DES ÉMULATEURS FIREBASE (en mode debug uniquement)
  // Permet de tester localement sans toucher aux données de production
  if (FirebaseConfig.useEmulators) {
    try {
      final host = FirebaseConfig.emulatorHost;

      // Émulateur Auth
      await FirebaseAuth.instance.useAuthEmulator(
        host,
        FirebaseConfig.authPort,
      );

      // Émulateur Firestore
      FirebaseFirestore.instance.useFirestoreEmulator(
        host,
        FirebaseConfig.firestorePort,
      );

      // Émulateur Storage
      await FirebaseStorage.instance.useStorageEmulator(
        host,
        FirebaseConfig.storagePort,
      );

      // Afficher la configuration
      FirebaseConfig.printConfig();
    } catch (e) {
      debugPrint('⚠️ Erreur configuration émulateurs: $e');
    }
  }

  // Lance l'application avec Riverpod pour la gestion d'état
  runApp(const ProviderScope(child: MainApp()));
}

/// Widget racine de l'application Ablony.
/// Configure MaterialApp avec le thème, la localisation et la page d'accueil.
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Charger la langue sauvegardée au démarrage
    ref.listen(localeProvider, (previous, next) {});
    Future.microtask(
      () => ref.read(localeProvider.notifier).loadSavedLanguage(),
    );

    // Observer la locale actuelle depuis le provider
    final locale = ref.watch(localeProvider);

    // Observer le mode de thème actuel
    final themeMode = ref.watch(themeProvider);

    // Observer le router configuré avec go_router
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // Titre de l'application (visible dans le gestionnaire de tâches)
      title: 'Ablony',

      // Thème clair
      theme: AppTheme.lightTheme,

      // Thème sombre
      darkTheme: AppTheme.darkTheme,

      // Mode de thème (system/light/dark)
      themeMode: themeMode,

      // Animation de transition entre les thèmes
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,

      // Cache le bandeau \"Debug\" en haut à droite
      debugShowCheckedModeBanner: false,

      // Configuration de la localisation
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Langues supportées par l'application
      supportedLocales: const [
        Locale('fr'), // Français
        Locale('en'), // Anglais
      ],

      // Langue actuelle de l'application
      locale: locale,

      // Configuration du router go_router
      // Remplace 'home' pour gérer la navigation avec des routes nommées
      routerConfig: router,
    );
  }
}
