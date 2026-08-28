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
}
