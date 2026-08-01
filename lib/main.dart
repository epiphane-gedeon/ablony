/// Fichier: main.dart
/// Description: Point d'entrée principal de l'application Ablony.
/// Ce fichier initialise Firebase et lance l'application avec son thème configuré.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_config.dart';
import 'core/navigation/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/push_notification_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

/// Handler des notifications push reçues alors que l'app est en
/// arrière-plan/terminée. Tourne dans un isolate séparé : Firebase doit y
/// être réinitialisé. Ne doit contenir aucune logique UI.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Fonction principale qui lance l'application.
/// Marqée async car elle initialise Firebase de manière asynchrone.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseConfig.printConfig();


  // if (FirebaseConfig.useEmulators) {
  //   try {
  //     final host = FirebaseConfig.emulatorHost;

  //     await FirebaseAuth.instance.useAuthEmulator(
  //       host,
  //       FirebaseConfig.authPort,
  //     );

  //     FirebaseFirestore.instance.useFirestoreEmulator(
  //       host,
  //       FirebaseConfig.firestorePort,
  //     );

  //     await FirebaseStorage.instance.useStorageEmulator(
  //       host,
  //       FirebaseConfig.storagePort,
  //     );

  //     FirebaseConfig.printConfig();
  //   } catch (e) {
  //     debugPrint('⚠️ Erreur configuration émulateurs: $e');
  //   }
  // }

  runApp(const ProviderScope(child: MainApp()));
}

/// Widget racine de l'application Ablony.
/// Configure MaterialApp avec le thème, la localisation et la page d'accueil.
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(localeProvider, (previous, next) {});

    // Enregistre le token FCM du device dès qu'un utilisateur est connecté,
    // pour qu'il puisse recevoir les notifications push (achat, vente, etc.).
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        ref.read(pushNotificationServiceProvider).registerDevice(user.uid);
      }
    });

    Future.microtask(
      () => ref.read(localeProvider.notifier).loadSavedLanguage(),
    );

    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ablony',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: locale,
      routerConfig: router,
    );
  }
}
