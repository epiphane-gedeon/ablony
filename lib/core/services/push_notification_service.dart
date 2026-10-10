import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/application/notification_router.dart';
import '../navigation/navigator_key.dart';

/// Gère l'enregistrement du device pour les notifications push (FCM) et
/// le routage vers l'écran concerné lors d'un tap sur une notification.
///
/// Chaque notification serveur écrit aussi un document dans la collection
/// `notifications`, ce qui met à jour en temps réel la pastille de l'onglet
/// Messages (cf. [unreadNotificationsCountProvider]) — pas de bannière
/// intrusive à l'ouverture de l'app, comme pour les messages.
///
/// Deux notifications déclenchées côté serveur (Cloud Functions) sont
/// gérées ici :
/// - `purchase_received` : le vendeur vient de vendre un article → ouvre le produit
/// - `purchase_confirmed` : l'acheteur vient d'acheter un article → ouvre le reçu
class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Clé publique Web Push (VAPID) du projet, si on en a déclaré une.
  ///
  /// Facultative : sans elle, le SDK Firebase utilise sa propre clé publique
  /// par défaut et les notifications web fonctionnent. La renseigner (console
  /// Firebase → Cloud Messaging → Certificats Web Push) rattache les
  /// abonnements au projet plutôt qu'à la clé partagée de Firebase.
  static const String _vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _listenersInitialized = false;

  /// Dernier uid pour lequel l'enregistrement a été tenté.
  ///
  /// [registerDevice] est appelé à la fois sur changement d'authentification
  /// et à chaque reconstruction du widget racine, pour couvrir l'arrivée
  /// « déjà connecté ». Sans cette mémoire, chaque reconstruction
  /// redemanderait la permission et réécrirait en base.
  String? _uidEnregistre;

  /// Demande la permission de notification, enregistre le token FCM du
  /// device pour [uid] et le maintient à jour lors d'un renouvellement.
  ///
  /// Ne lève jamais : appelée au démarrage, une erreur ici empêcherait
  /// l'application de s'ouvrir.
  Future<void> registerDevice(String uid) async {
    if (_uidEnregistre == uid) return;
    // Posé avant l'await : deux reconstructions rapprochées ne doivent pas
    // lancer deux enregistrements en parallèle.
    _uidEnregistre = uid;

    // **Rien ne doit partir d'ici avant d'avoir vérifié que le navigateur
    // sait le recevoir.** Safari sur iOS n'expose Firebase Messaging que
    // dans une application installée sur l'écran d'accueil : dans un onglet
    // ordinaire, `Notification` n'existe pas et le SDK lève. Tant que cet
    // appel n'avait lieu qu'à la connexion, le cas ne se présentait jamais
    // au chargement de la page ; depuis qu'il a lieu au démarrage, il
    // décidait du sort de l'application entière.
    //
    // D'où la double protection : on demande au SDK s'il est utilisable, et
    // on enveloppe quand même — une notification qu'on n'affiche pas est un
    // désagrément, une application qui ne s'ouvre pas est une panne.
    try {
      if (!await _messaging.isSupported()) {
        debugPrint('Messagerie push non disponible sur ce navigateur.');
        return;
      }
    } catch (e) {
      debugPrint('Messagerie push non disponible : $e');
      return;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // Sur le web, l'obtention du jeton dépend de l'enregistrement du service
    // worker `firebase-messaging-sw.js`. Une erreur ici est silencieuse pour
    // l'utilisateur — il a accordé la permission et ne verra simplement jamais
    // de notification — d'où le message explicite dans la console.
    final token = await _obtenirToken();
    if (token != null) {
      await _saveToken(uid, token);
    } else {
      // Échec passager : ne pas condamner les tentatives suivantes.
      _uidEnregistre = null;
    }

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(uid, newToken);
    });

    _initListenersOnce();
  }

  /// Variante sans risque pour les appels qu'on ne surveille pas.
  void registerDeviceSansRisque(String uid) {
    registerDevice(uid).catchError((Object e) {
      debugPrint('Enregistrement push ignoré : $e');
    });
  }

  /// Retire le token FCM du device courant (utile à la déconnexion).
  Future<void> unregisterDevice(String uid) async {
    _uidEnregistre = null;
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final token = await _obtenirToken();
    if (token == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('⚠️ Impossible de retirer le token FCM: $e');
    }
  }

  /// Demande le jeton FCM du device, en signalant clairement un échec plutôt
  /// que de laisser remonter une erreur asynchrone que personne n'attrape.
  Future<String?> _obtenirToken() async {
    try {
      return await _messaging.getToken(
        vapidKey: kIsWeb && _vapidKey.isNotEmpty ? _vapidKey : null,
      );
    } catch (e) {
      debugPrint(
        '⚠️ Jeton FCM indisponible : $e'
        '${kIsWeb ? "\n   Sur le web, vérifier que /firebase-messaging-sw.js "
            "est bien servi en JavaScript (la réécriture SPA renvoie sinon "
            "index.html, que le navigateur refuse d'enregistrer)." : ""}',
      );
      return null;
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      debugPrint('⚠️ Impossible d\'enregistrer le token FCM: $e');
    }
  }

  /// Ecoute les messages reçus app ouverte/au premier plan, les taps sur une
  /// notification (app en arrière-plan) et le lancement à froid via une
  /// notification. Idempotent : les abonnements ne sont créés qu'une fois.
  void _initListenersOnce() {
    if (_listenersInitialized) return;
    _listenersInitialized = true;

    // App au premier plan : pas de bannière, la pastille sur l'onglet
    // Messages (badge messages + notifications) suffit à signaler la
    // nouveauté, alimentée directement par le document Firestore écrit
    // côté serveur en parallèle du push.

    // Tap sur la notification alors que l'app est en arrière-plan.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Lancement à froid de l'app via un tap sur la notification.
    _messaging.getInitialMessage().then((message) {
      if (message != null) _handleTap(message);
    });
  }

  /// Où mène un appui sur une notification système.
  ///
  /// La table de routage est partagée avec la boîte de réception
  /// (`notification_router.dart`) : deux tables parallèles finiraient par
  /// diverger, et un push mènerait ailleurs que la ligne qui lui correspond —
  /// sans que rien ne le signale.
  void _handleTap(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final destination = destinationOf(
      message.data['type'] as String? ?? '',
      Map<String, dynamic>.from(message.data),
    );
    // Un type inconnu, écrit par une version plus récente du serveur, n'ouvre
    // rien plutôt que de planter.
    if (destination != null) GoRouter.of(context).push(destination);
  }
}
