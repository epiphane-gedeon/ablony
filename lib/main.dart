/// Fichier: main.dart
/// Description: Point d'entrée principal de l'application Ablony.
/// Ce fichier initialise Firebase et lance l'application avec son thème configuré.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
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

  // Lance l'application avec Riverpod pour la gestion d'état
  runApp(const ProviderScope(child: MainApp()));
}

/// Widget racine de l'application Ablony.
/// Configure MaterialApp avec le thème, la localisation et la page d'accueil.
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
