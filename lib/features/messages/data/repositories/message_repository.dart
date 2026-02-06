import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/participant_details.dart';
import '../../domain/models/product_details.dart';
import '../../domain/models/user_info.dart';
import '../../domain/models/offer.dart';
import '../../domain/models/offer_status.dart';
import '../../domain/models/message_type.dart';
import '../../domain/models/last_message.dart';

class MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ========== CONVERSATIONS ==========

  /// Stream de toutes les conversations pour un utilisateur
  Stream<List<Conversation>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Conversation.fromFirestore(doc))
              .where(
                (conversation) => conversation.lastMessage != null,
              ) // Filtrer les conversations vides
              .toList(),
        );
  }

  /// Récupère une conversation spécifique
  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!doc.exists) return null;
    return Conversation.fromFirestore(doc);
  }

  /// Trouve une conversation existante entre deux utilisateurs pour un produit
  Future<String?> findConversation({
    required String userId1,
    required String userId2,
    required String productId,
  }) async {
    final query = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId1)
        .where('productId', isEqualTo: productId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(
        doc.data()['participants'] as List,
      );
      if (participants.contains(userId2)) {
        return doc.id;
      }
    }

    return null;
  }

  /// Crée une nouvelle conversation
  Future<String> createConversation({
    required String buyerId,
    required String sellerId,
    required ParticipantDetails buyerDetails,
    required ParticipantDetails sellerDetails,
    required String productId,
    required ProductDetails productDetails,
  }) async {
    final now = DateTime.now();

    final conversationData = {
      'participants': [buyerId, sellerId],
      'participantDetails': {
        buyerId: buyerDetails.toFirestore(),
        sellerId: sellerDetails.toFirestore(),
      },
      'productId': productId,
      'productDetails': productDetails.toFirestore(),
      'unreadCount': {buyerId: 0, sellerId: 0},
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    final docRef = await _firestore
        .collection('conversations')
        .add(conversationData);

    return docRef.id;
  }

  /// Met à jour le compteur de messages non lus
  Future<void> updateUnreadCount({
    required String conversationId,
    required String userId,
    required int count,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.$userId': count,
    });
  }

  /// Réinitialise le compteur de non lus pour un utilisateur
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await updateUnreadCount(
      conversationId: conversationId,
      userId: userId,
      count: 0,
    );
  }

  /// Met à jour le dernier message de la conversation
  Future<void> updateLastMessage({
    required String conversationId,
    required LastMessage lastMessage,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': lastMessage.toFirestore(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ========== MESSAGES ==========

  /// Stream de tous les messages d'une conversation
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  /// Envoie un message système avec les infos utilisateur (début de conversation)
  Future<void> sendSystemMessage({
    required String conversationId,
    required String userId,
    required UserInfo userInfo,
  }) async {
    final message = Message(
      id: '',
      senderId: userId,
      type: MessageType.system,
      timestamp: DateTime.now(),
      read: false,
      userInfo: userInfo,
    );

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toFirestore());
  }

  /// Envoie une offre
  Future<void> sendOffer({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required Offer offer,
  }) async {
    final now = DateTime.now();

    // Rejeter automatiquement toutes les offres en attente avant d'envoyer la nouvelle offre
    await _rejectPendingOffers(conversationId);

    final message = Message(
      id: '',
      senderId: senderId,
      type: MessageType.offer,
      timestamp: now,
      read: false,
      offer: offer,
    );

    // Ajouter le message
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toFirestore());

    // Mettre à jour le dernier message
    final lastMessage = LastMessage(
      text: '${offer.amount.toStringAsFixed(2)} € En attente',
      senderId: senderId,
      timestamp: now,
      type: MessageType.offer,
    );

    await updateLastMessage(
      conversationId: conversationId,
      lastMessage: lastMessage,
    );

    // Incrémenter le compteur de non lus du receveur
    final conversation = await getConversation(conversationId);
    if (conversation != null) {
      final currentUnread = conversation.unreadCount[receiverId] ?? 0;
      await updateUnreadCount(
        conversationId: conversationId,
        userId: receiverId,
        count: currentUnread + 1,
      );
    }
  }

  /// Envoie une contre-offre
  Future<void> sendCounterOffer({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required Offer counterOffer,
  }) async {
    final now = DateTime.now();

    // Rejeter automatiquement toutes les offres en attente avant d'envoyer la contre-offre
    await _rejectPendingOffers(conversationId);

    final message = Message(
      id: '',
      senderId: senderId,
      type: MessageType.counterOffer,
      timestamp: now,
      read: false,
      offer: counterOffer,
    );

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toFirestore());

    final lastMessage = LastMessage(
      text: '${counterOffer.amount.toStringAsFixed(2)} € Contre-offre',
      senderId: senderId,
      timestamp: now,
      type: MessageType.counterOffer,
    );

    await updateLastMessage(
      conversationId: conversationId,
      lastMessage: lastMessage,
    );

    final conversation = await getConversation(conversationId);
    if (conversation != null) {
      final currentUnread = conversation.unreadCount[receiverId] ?? 0;
      await updateUnreadCount(
        conversationId: conversationId,
        userId: receiverId,
        count: currentUnread + 1,
      );
    }
  }

  /// Envoie un message texte
  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final now = DateTime.now();

    final message = Message(
      id: '',
      senderId: senderId,
      type: MessageType.text,
      timestamp: now,
      read: false,
      text: text,
    );

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toFirestore());

    final lastMessage = LastMessage(
      text: text,
      senderId: senderId,
      timestamp: now,
      type: MessageType.text,
    );

    await updateLastMessage(
      conversationId: conversationId,
      lastMessage: lastMessage,
    );

    final conversation = await getConversation(conversationId);
    if (conversation != null) {
      final currentUnread = conversation.unreadCount[receiverId] ?? 0;
      await updateUnreadCount(
        conversationId: conversationId,
        userId: receiverId,
        count: currentUnread + 1,
      );
    }
  }

  /// Met à jour le statut d'une offre (accepter/refuser)
  Future<void> updateOfferStatus({
    required String conversationId,
    required String messageId,
    required OfferStatus newStatus,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'offer.status': newStatus.toFirestore()});
  }

  /// Marque un message comme lu
  Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'read': true});
  }

  /// Récupère le nombre total de messages non lus pour un utilisateur
  Future<int> getTotalUnreadCount(String userId) async {
    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    int total = 0;
    for (var doc in conversations.docs) {
      final data = doc.data();
      final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
      if (unreadCount != null) {
        total += (unreadCount[userId] as int? ?? 0);
      }
    }

    return total;
  }

  /// Stream du nombre total de messages non lus
  Stream<int> getTotalUnreadCountStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadCount != null) {
              total += (unreadCount[userId] as int? ?? 0);
            }
          }
          return total;
        });
  }

  /// Rejette automatiquement toutes les offres en attente dans une conversation
  Future<void> _rejectPendingOffers(String conversationId) async {
    final messagesSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('type', whereIn: ['offer', 'counterOffer'])
        .get();

    final batch = _firestore.batch();

    for (var doc in messagesSnapshot.docs) {
      final message = Message.fromFirestore(doc);
      if (message.offer?.status == OfferStatus.pending) {
        final updatedOffer = message.offer!.copyWith(
          status: OfferStatus.rejected,
        );
        batch.update(doc.reference, {'offer': updatedOffer.toFirestore()});
      }
    }

    await batch.commit();
  }
}
