import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Type d'une notification in-app.
///
/// Correspond aux valeurs écrites par les Cloud Functions dans le champ
/// `type` du document `notifications/{id}`.
enum AppNotificationType {
  purchaseReceived('purchase_received'),
  purchaseConfirmed('purchase_confirmed'),
  newProductFromFollowed('new_product_from_followed'),
  unknown('unknown');

  final String value;
  const AppNotificationType(this.value);

  static AppNotificationType fromString(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AppNotificationType.unknown,
    );
  }
}

/// Notification in-app affichée dans l'onglet "Notifications" de la messagerie.
///
/// Stockage : collection `notifications`, entièrement écrite par les Cloud
/// Functions (ex : à la finalisation d'un achat).
class AppNotification extends Equatable {
  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: AppNotificationType.fromString(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      data: (data['data'] as Map<String, dynamic>?) ?? const {},
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id];
}
