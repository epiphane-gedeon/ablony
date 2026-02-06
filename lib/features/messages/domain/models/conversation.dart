import 'package:cloud_firestore/cloud_firestore.dart';
import 'participant_details.dart';
import 'product_details.dart';
import 'last_message.dart';

class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, ParticipantDetails> participantDetails;
  final String productId;
  final ProductDetails productDetails;
  final LastMessage? lastMessage;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participants,
    required this.participantDetails,
    required this.productId,
    required this.productDetails,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final participantDetailsData =
        data['participantDetails'] as Map<String, dynamic>;
    final participantDetailsMap = <String, ParticipantDetails>{};
    participantDetailsData.forEach((key, value) {
      participantDetailsMap[key] = ParticipantDetails.fromFirestore(
        value as Map<String, dynamic>,
      );
    });

    final unreadCountData = data['unreadCount'] as Map<String, dynamic>;
    final unreadCountMap = <String, int>{};
    unreadCountData.forEach((key, value) {
      unreadCountMap[key] = value as int;
    });

    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List),
      participantDetails: participantDetailsMap,
      productId: data['productId'] as String,
      productDetails: ProductDetails.fromFirestore(
        data['productDetails'] as Map<String, dynamic>,
      ),
      lastMessage: data['lastMessage'] != null
          ? LastMessage.fromFirestore(
              data['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      unreadCount: unreadCountMap,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final participantDetailsMap = <String, dynamic>{};
    participantDetails.forEach((key, value) {
      participantDetailsMap[key] = value.toFirestore();
    });

    return {
      'participants': participants,
      'participantDetails': participantDetailsMap,
      'productId': productId,
      'productDetails': productDetails.toFirestore(),
      if (lastMessage != null) 'lastMessage': lastMessage!.toFirestore(),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.first,
    );
  }

  ParticipantDetails? getOtherParticipantDetails(String currentUserId) {
    final otherParticipantId = getOtherParticipantId(currentUserId);
    return participantDetails[otherParticipantId];
  }

  Conversation copyWith({
    String? id,
    List<String>? participants,
    Map<String, ParticipantDetails>? participantDetails,
    String? productId,
    ProductDetails? productDetails,
    LastMessage? lastMessage,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantDetails: participantDetails ?? this.participantDetails,
      productId: productId ?? this.productId,
      productDetails: productDetails ?? this.productDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
