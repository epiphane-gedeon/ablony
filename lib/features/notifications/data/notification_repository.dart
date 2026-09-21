import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/exceptions/exceptions.dart';
import '../domain/models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notificationsRef {
    return _firestore.collection('notifications');
  }

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList(),
        );
  }

  /// Le nombre de non lues, en flux : c'est ce qui alimente la pastille.
  ///
  /// `count()` côté serveur plutôt que la longueur d'une liste téléchargée :
  /// on paie un document lu au lieu de tous.
  Stream<int> watchUnreadCount(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Marque toutes les non lues comme lues.
  ///
  /// Par lots de 500 — la limite d'une écriture groupée Firestore. Sans
  /// découpage, une boîte oubliée pendant six mois ferait échouer l'appel
  /// entier, et le bouton ne marcherait que pour ceux qui n'en ont pas besoin.
  Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (var i = 0; i < snap.docs.length; i += 500) {
        final lot = _firestore.batch();
        for (final doc in snap.docs.skip(i).take(500)) {
          lot.update(doc.reference, {'read': true});
        }
        await lot.commit();
      }
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'read': true});
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du marquage de la notification comme lue',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  /// Supprime une notification. Les règles n'autorisent que le destinataire.
  Future<void> delete(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la suppression de la notification',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }
}
