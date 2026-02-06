import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_type.dart';
import 'offer.dart';
import 'user_info.dart';

class Message {
  final String id;
  final String senderId;
  final MessageType type;
  final DateTime timestamp;
  final bool read;

  // Pour type system
  final UserInfo? userInfo;

  // Pour type offer/counterOffer
  final Offer? offer;

  // Pour type text
  final String? text;

  const Message({
    required this.id,
    required this.senderId,
    required this.type,
    required this.timestamp,
    this.read = false,
    this.userInfo,
    this.offer,
    this.text,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Message(
      id: doc.id,
      senderId: data['senderId'] as String,
      type: MessageType.fromFirestore(data['type'] as String),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] as bool? ?? false,
      userInfo: data['userInfo'] != null
          ? UserInfo.fromFirestore(data['userInfo'] as Map<String, dynamic>)
          : null,
      offer: data['offer'] != null
          ? Offer.fromFirestore(data['offer'] as Map<String, dynamic>)
          : null,
      text: data['text'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'type': type.toFirestore(),
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      if (userInfo != null) 'userInfo': userInfo!.toFirestore(),
      if (offer != null) 'offer': offer!.toFirestore(),
      if (text != null) 'text': text,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    MessageType? type,
    DateTime? timestamp,
    bool? read,
    UserInfo? userInfo,
    Offer? offer,
    String? text,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      userInfo: userInfo ?? this.userInfo,
      offer: offer ?? this.offer,
      text: text ?? this.text,
    );
  }
}
