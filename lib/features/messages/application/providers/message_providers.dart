import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/message_repository.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';

/// Provider pour le MessageRepository singleton
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

/// Provider pour le stream des conversations d'un utilisateur
final conversationsStreamProvider =
    StreamProvider.family<List<Conversation>, String>((ref, userId) {
      final repository = ref.watch(messageRepositoryProvider);
      return repository.getConversationsStream(userId);
    });

/// Provider pour le stream des messages d'une conversation
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  conversationId,
) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getMessagesStream(conversationId);
});

/// Provider pour le stream du nombre total de messages non lus
final totalUnreadCountStreamProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getTotalUnreadCountStream(userId);
});

/// Provider pour récupérer une conversation spécifique
final conversationProvider = FutureProvider.family<Conversation?, String>((
  ref,
  conversationId,
) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getConversation(conversationId);
});
