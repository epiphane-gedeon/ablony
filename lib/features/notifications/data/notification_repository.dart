import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> markAsRead(String notificationId) {
    return _notificationsRef.doc(notificationId).update({'read': true});
  }
}
