/// Fichier: main.dart
/// Description: Point d'entrée principal de l'application Ablony.
/// Ce fichier initialise Firebase et lance l'application avec son thème configuré.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
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

  // Sur le web, sert des URLs propres (/product/xyz) plutôt que des URLs à
  // fragment (/#/product/xyz) — nécessaire pour que les liens de partage
  // (cf. lib/features/share/) soient lisibles et fonctionnent une fois
  // ouverts directement dans un navigateur. No-op sur les autres plateformes.
  usePathUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Persistance hors-ligne activée explicitement sur TOUTES les plateformes.
  // Sur mobile elle l'est par défaut ; sur le web NON — sans elle, une écriture
  // (favori, offre, message…) ne remonte dans les streams qu'après l'aller-
  // retour serveur, d'où l'impression qu'il faut « recharger » ou taper deux
  // fois. Avec la persistance, l'écriture est émise depuis le cache local
  // immédiatement (mise à jour optimiste native de Firestore). À poser avant
  // toute utilisation de Firestore.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await _activerAppCheck();

  // Le web se connecte à Google par redirection : au retour, cet appel
  // finalise la connexion avant que le routeur ne décide où aller. Sans lui,
  // l'utilisateur revient de Google sans être reconnu.
  await _finaliserConnexionRedirigee();

  _brancherCrashlytics();

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

/// Active App Check : atteste que les appels viennent bien de l'application,
/// pas d'un script qui rejoue les URLs des Cloud Functions.
///
/// **Activé côté client seulement.** L'*enforcement* (le refus des appels sans
/// jeton valide) se règle dans la console Firebase, service par service, et ne
/// doit l'être qu'une fois cette version adoptée : l'imposer maintenant
/// bloquerait l'application déjà installée, qui n'envoie aucun jeton App Check.
/// D'ici là, les jetons partent et sont simplement observés.
///
/// Enveloppé dans un try/catch : une attestation qui échoue (émulateur,
/// appareil rooté, réseau coupé) ne doit jamais empêcher l'application de
/// démarrer. Elle se traduira, une fois l'enforcement actif, par un appel
/// refusé — pas par un écran noir.
Future<void> _activerAppCheck() async {
  // Désactivé sur le web pour l'instant : App Check charge reCAPTCHA v3, qui
  // interfère avec le flux d'authentification Google sur Safari (protection
  // anti-traçage). App Check n'est de toute façon pas encore imposé côté
  // serveur — le désactiver ici ne retire aucune protection active. À
  // réactiver une fois la connexion Safari confirmée et l'app enregistrée
  // dans la console App Check. Sur mobile natif, il reste actif.
  if (kIsWeb) return;
  try {
    await FirebaseAppCheck.instance.activate(
      // Web : reCAPTCHA v3, avec la clé de site déjà en place.
      webProvider: ReCaptchaV3Provider(
        '6Le3NxYsAAAAAITnIke4lK2zXMgIFlJSA6FIocL9',
      ),
      // Android : Play Integrity, l'attestation de Google Play.
      androidProvider: AndroidProvider.playIntegrity,
      // iOS / macOS : App Attest, avec repli DeviceCheck sur les anciens
      // appareils.
      appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (e) {
    debugPrint('App Check non activé : $e');
  }
}

/// Termine une connexion Google par redirection en attente (web).
///
/// `signInWithRedirect` emmène la page vers Google puis la ramène ; le SDK a
/// besoin de `getRedirectResult` pour finaliser et déclencher
/// `authStateChanges`. Enveloppé : une absence de redirection en attente n'est
/// pas une erreur, et rien ne doit bloquer le démarrage.
Future<void> _finaliserConnexionRedirigee() async {
  if (!kIsWeb) return;
  try {
    await FirebaseAuth.instance.getRedirectResult();
  } catch (e) {
    debugPrint('Pas de connexion redirigée à finaliser : $e');
  }
}

/// Fait remonter les plantages à Crashlytics.
///
/// **Mobile uniquement** : Crashlytics n'existe pas sur le web (le web
/// utilise déjà les rapports du navigateur). On y route les deux familles
/// d'erreurs : celles du framework Flutter, et les erreurs asynchrones non
/// interceptées, qui autrement disparaissent sans laisser de trace.
void _brancherCrashlytics() {
  if (kIsWeb) return;

  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
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
