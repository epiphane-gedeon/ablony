import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/application/notification_router.dart';
import '../navigation/navigator_key.dart';

/// Ce que l'utilisateur a décidé des notifications, tel qu'un écran de
/// réglages doit pouvoir l'afficher sans rien provoquer.
enum EtatNotifications {
  /// Le navigateur ne sait pas les recevoir — Safari iOS hors application
  /// installée, notamment.
  indisponible,

  /// Rien n'a encore été demandé.
  aActiver,

  /// Refusées : seule la page des réglages du navigateur peut revenir
  /// dessus, une seconde demande ne rouvrirait aucune invite.
  refusees,

  /// En place.
  activees,

  /// Permission accordée, mais aucun jeton obtenu.
  ///
  /// Cet état existe parce qu'il s'est produit : l'écran affichait
  /// « Activées » en lisant la seule permission du navigateur, alors que
  /// `getToken()` échouait et qu'aucune notification ne pouvait arriver.
  /// Une permission n'est pas un abonnement.
  sansJeton,
}

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

  /// Clé publique Web Push (VAPID) du projet, si on en déclare une.
  ///
  /// Facultative : sans elle, le SDK utilise sa propre clé publique par
  /// défaut et les notifications web fonctionnent. La renseigner (console
  /// Firebase → Cloud Messaging → Certificats Web Push) rattache les
  /// abonnements au projet plutôt qu'à la clé partagée de Firebase.
  static const String _cleVapid = String.fromEnvironment('FCM_VAPID_KEY');

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _listenersInitialized = false;

  /// Demande la permission de notification, enregistre le token FCM du
  /// device pour [uid] et le maintient à jour lors d'un renouvellement.
  Future<void> registerDevice(String uid) async {
    // **Rien ne part avant d'avoir vérifié que le navigateur sait recevoir.**
    // Safari sur iOS n'expose Firebase Messaging que dans une application
    // installée sur l'écran d'accueil ; dans un onglet ordinaire, le SDK
    // lève. Sur mobile natif, la réponse est toujours vraie.
    if (!await estDisponible()) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _obtenirToken();
    if (token != null) {
      await _saveToken(uid, token);
    } else {
      await _noterEchec(uid, _derniereErreurJeton ?? 'jeton nul sans erreur');
    }

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(uid, newToken);
    });

    _initListenersOnce();
  }

  /// Retire le token FCM du device courant (utile à la déconnexion).
  Future<void> unregisterDevice(String uid) async {
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

  /// Le navigateur (ou l'appareil) sait-il recevoir des notifications push ?
  ///
  /// Ne lève jamais : sur un navigateur où même la question échoue, la
  /// réponse est « non ».
  Future<bool> estDisponible() async {
    try {
      return await _messaging.isSupported();
    } catch (e) {
      debugPrint('Messagerie push indisponible : $e');
      return false;
    }
  }

  /// Ce que l'utilisateur a déjà décidé, **sans rien lui demander**.
  ///
  /// `getNotificationSettings` lit l'état courant sans ouvrir d'invite : un
  /// écran de réglages doit pouvoir afficher la situation sans la provoquer.
  Future<EtatNotifications> etatActuel({String? uid}) async {
    if (!await estDisponible()) return EtatNotifications.indisponible;
    try {
      final reglages = await _messaging.getNotificationSettings();
      switch (reglages.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          // La permission ne suffit pas : sans jeton, le serveur n'a personne
          // à qui écrire. On le vérifie au lieu de l'annoncer.
          if (uid != null && !await _jetonEnregistre(uid)) {
            return EtatNotifications.sansJeton;
          }
          return EtatNotifications.activees;
        case AuthorizationStatus.denied:
          return EtatNotifications.refusees;
        case AuthorizationStatus.notDetermined:
          return EtatNotifications.aActiver;
      }
    } catch (e) {
      debugPrint('État des notifications illisible : $e');
      return EtatNotifications.indisponible;
    }
  }

  /// Active les notifications **à la demande explicite de l'utilisateur**.
  ///
  /// C'est le seul chemin sur le web, et ce n'est pas un détail de confort :
  /// iOS n'autorise la demande de permission qu'à partir d'un geste, et une
  /// version précédente qui s'exécutait à l'ouverture empêchait purement et
  /// simplement l'application de se charger sur iPhone.
  ///
  /// Renvoie l'état obtenu, pour que l'écran dise ce qui s'est passé.
  Future<EtatNotifications> activerSurDemande(String uid) async {
    try {
      await registerDevice(uid);
    } catch (e) {
      debugPrint('Activation des notifications échouée : $e');
      await _noterEchec(uid, e.toString());
      return EtatNotifications.indisponible;
    }
    return etatActuel(uid: uid);
  }

  /// Ce device a-t-il un jeton côté serveur ?
  Future<bool> _jetonEnregistre(String uid) async {
    final token = await _obtenirToken();
    if (token == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final jetons = (doc.data()?['fcmTokens'] as List?) ?? const [];
      return jetons.contains(token);
    } catch (e) {
      debugPrint('Lecture des jetons impossible : $e');
      return false;
    }
  }

  /// Garde la trace du dernier échec sur le profil.
  ///
  /// Une panne de notification ne se voit nulle part : il n'y a ni message
  /// d'erreur, ni journal côté serveur — seulement un silence identique à
  /// « personne ne vous a écrit ». Sans cette trace, diagnostiquer exige
  /// d'avoir l'appareil en main. À retirer une fois la cause connue.
  Future<void> _noterEchec(String uid, String raison) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'pushDiagnostic': {
          'raison': raison.length > 400 ? raison.substring(0, 400) : raison,
          'plateforme': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'le': FieldValue.serverTimestamp(),
        },
      });
    } catch (_) {
      // Le diagnostic ne doit jamais devenir lui-même une source d'échec.
    }
  }

  /// Demande le jeton FCM, en signalant un échec plutôt que de laisser
  /// remonter une erreur asynchrone que personne n'attrape.
  Future<String?> _obtenirToken() async {
    try {
      return await _messaging.getToken(
        vapidKey: kIsWeb && _cleVapid.isNotEmpty ? _cleVapid : null,
      );
    } catch (e) {
      debugPrint('Jeton FCM indisponible : $e');
      _derniereErreurJeton = e.toString();
      return null;
    }
  }

  /// Dernière erreur rencontrée en demandant un jeton, pour la consigner.
  String? _derniereErreurJeton;

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
