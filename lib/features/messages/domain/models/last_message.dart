import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_type.dart';

class LastMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;
  final MessageType type;

  const LastMessage({
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.type,
  });

  factory LastMessage.fromFirestore(Map<String, dynamic> data) {
    return LastMessage(
      text: data['text'] as String,
      senderId: data['senderId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.fromFirestore(data['type'] as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toFirestore(),
    };
  }
}
