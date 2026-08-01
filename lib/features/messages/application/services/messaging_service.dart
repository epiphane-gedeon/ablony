import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/message_repository.dart';
import '../../domain/models/participant_details.dart';
import '../../domain/models/product_details.dart';
import '../../domain/models/user_info.dart';
import '../../domain/models/offer.dart';
import '../../domain/models/offer_status.dart';
import '../providers/message_providers.dart';

/// Service pour gérer les opérations de messagerie
class MessagingService {
  final MessageRepository _repository;

  MessagingService(this._repository);

  /// Crée ou trouve une conversation et envoie une offre
  /// Retourne l'ID de la conversation
  Future<String> sendInitialOffer({
    required String buyerId,
    required String sellerId,
    required ParticipantDetails buyerDetails,
    required ParticipantDetails sellerDetails,
    required UserInfo buyerInfo,
    required UserInfo sellerInfo,
    required String productId,
    required ProductDetails productDetails,
    required double offerAmount,
  }) async {
    // Chercher une conversation existante
    String? conversationId = await _repository.findConversation(
      userId1: buyerId,
      userId2: sellerId,
      productId: productId,
    );

    // Créer la conversation si elle n'existe pas
    if (conversationId == null) {
      conversationId = await _repository.createConversation(
        buyerId: buyerId,
        sellerId: sellerId,
        buyerDetails: buyerDetails,
        sellerDetails: sellerDetails,
        productId: productId,
        productDetails: productDetails,
      );

      // Envoyer les messages système pour les deux utilisateurs
      await _repository.sendSystemMessage(
        conversationId: conversationId,
        userId: buyerId,
        userInfo: buyerInfo,
      );

      await _repository.sendSystemMessage(
        conversationId: conversationId,
        userId: sellerId,
        userInfo: sellerInfo,
      );
    }

    // Envoyer l'offre
    final offer = Offer(
      amount: offerAmount,
      status: OfferStatus.pending,
      productId: productId,
    );

    await _repository.sendOffer(
      conversationId: conversationId,
      senderId: buyerId,
      receiverId: sellerId,
      offer: offer,
    );

    return conversationId;
  }

  /// Accepte une offre
  Future<void> acceptOffer({
    required String conversationId,
    required String messageId,
  }) async {
    await _repository.updateOfferStatus(
      conversationId: conversationId,
      messageId: messageId,
      newStatus: OfferStatus.accepted,
    );
  }

  /// Refuse une offre
  Future<void> rejectOffer({
    required String conversationId,
    required String messageId,
  }) async {
    await _repository.updateOfferStatus(
      conversationId: conversationId,
      messageId: messageId,
      newStatus: OfferStatus.rejected,
    );
  }

  /// Envoie une contre-offre
  Future<void> sendCounterOffer({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String productId,
    required double counterOfferAmount,
  }) async {
    final counterOffer = Offer(
      amount: counterOfferAmount,
      status: OfferStatus.pending,
      productId: productId,
    );

    await _repository.sendCounterOffer(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      counterOffer: counterOffer,
    );
  }

  /// Envoie un message texte
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    await _repository.sendTextMessage(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
    );
  }

  /// Envoie une photo dans la conversation
  Future<void> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String imageUrl,
    String? caption,
  }) async {
    await _repository.sendImageMessage(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      imageUrl: imageUrl,
      caption: caption,
    );
  }

  /// Marque une conversation comme lue
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _repository.markConversationAsRead(
      conversationId: conversationId,
      userId: userId,
    );
  }
}

/// Provider pour le MessagingService
final messagingServiceProvider = Provider<MessagingService>((ref) {
  final repository = ref.watch(messageRepositoryProvider);
  return MessagingService(repository);
});
