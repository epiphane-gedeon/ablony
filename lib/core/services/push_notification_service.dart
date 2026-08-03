import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

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

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _listenersInitialized = false;

  /// Demande la permission de notification, enregistre le token FCM du
  /// device pour [uid] et le maintient à jour lors d'un renouvellement.
  Future<void> registerDevice(String uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
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

    final token = await _messaging.getToken();
    if (token == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('⚠️ Impossible de retirer le token FCM: $e');
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

  void _handleTap(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final router = GoRouter.of(context);

    switch (message.data['type']) {
      case 'purchase_confirmed':
        final receiptId = message.data['receiptId'];
        if (receiptId != null) router.push('/receipt/$receiptId');
        break;
      case 'purchase_received':
      case 'new_product_from_followed':
        final productId = message.data['productId'];
        if (productId != null) router.push('/product/$productId');
        break;
    }
  }
}
