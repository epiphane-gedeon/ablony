import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/message_bubble.dart';
import '../../../../shared/widgets/input.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../make_offer_feature/presentation/widgets/make_offer_bottom_sheet.dart';
import '../../application/providers/message_providers.dart';
import '../../application/services/messaging_service.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_type.dart';
import '../../domain/models/conversation.dart';
import '../../../../l10n/app_localizations.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatPage({super.key, required this.conversationId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Marquer la conversation comme lue dès l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser != null) {
        ref
            .read(messagingServiceProvider)
            .markAsRead(
              conversationId: widget.conversationId,
              userId: currentUser.uid,
            );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    try {
      final conversation = await ref.read(
        conversationProvider(widget.conversationId).future,
      );
      if (conversation == null) return;

      final receiverId = conversation.getOtherParticipantId(currentUser.uid);

      await ref
          .read(messagingServiceProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            senderId: currentUser.uid,
            receiverId: receiverId,
            text: text,
          );

      _messageController.clear();

      // Scroll vers le bas après l'envoi
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorGenericMsg(e.toString()))));
      }
    }
  }

  Future<void> _acceptOffer(String messageId) async {
    try {
      await ref
          .read(messagingServiceProvider)
          .acceptOffer(
            conversationId: widget.conversationId,
            messageId: messageId,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.offerAcceptedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorGenericMsg(e.toString()))));
      }
    }
  }

  Future<void> _rejectOffer(String messageId) async {
    try {
      await ref
          .read(messagingServiceProvider)
          .rejectOffer(
            conversationId: widget.conversationId,
            messageId: messageId,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.offerRejectedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorGenericMsg(e.toString()))));
      }
    }
  }

  Future<void> _buyProduct(Conversation conversation) async {
    try {
      // Utiliser directement productId de la conversation (pas de requête supplémentaire)
      // Le produit est probablement déjà en cache si on vient de la page produit
      final product = await ref.read(
        productByIdProvider(conversation.productId).future,
      );

      if (mounted) {
        // Naviguer vers la page de paiement avec le produit
        context.push('/payment', extra: product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorGenericMsg(e.toString()))));
      }
    }
  }

  Future<void> _showMakeOfferBottomSheet(Conversation conversation) async {
    try {
      // Récupérer le produit complet depuis le productId
      final product = await ref.read(
        productByIdProvider(conversation.productId).future,
      );

      if (mounted) {
        await MakeOfferBottomSheet.show(context, product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorGenericMsg(e.toString()))));
      }
    }
  }

  Widget _buildProductSection(
    Conversation conversation,
    String currentUserId,
    ThemeData theme,
  ) {
    final product = conversation.productDetails;
    // Si sellerId est null ou différent de l'utilisateur actuel, c'est l'acheteur
    final isOwner =
        product.sellerId != null && product.sellerId == currentUserId;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du produit
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.image != null
                      ? Image.network(
                          product.image!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: theme.dividerColor.withOpacity(0.2),
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: theme.dividerColor.withOpacity(0.2),
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                const SizedBox(width: 12),
                // Titre et prix
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.price.toStringAsFixed(0)} FCFA',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Boutons d'action
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: isOwner
                ? // Vendeur : seulement "Faire une offre"
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: SecondaryButton(
                      text: AppLocalizations.of(context)!.makeOffer,
                      fontSize: 14,
                      borderRadius: 8,
                      padding: EdgeInsets.zero,
                      onPressed: () => _showMakeOfferBottomSheet(conversation),
                    ),
                  )
                : // Acheteur : "Acheter" et "Faire une offre"
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: PrimaryButton(
                            text: AppLocalizations.of(context)!.buyNow,
                            fontSize: 14,
                            borderRadius: 8,
                            padding: EdgeInsets.zero,
                            onPressed: () => _buyProduct(conversation),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: SecondaryButton(
                            text: AppLocalizations.of(context)!.makeOffer,
                            fontSize: 14,
                            borderRadius: 8,
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                _showMakeOfferBottomSheet(conversation),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authStateProvider).value;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.chatTitle)),
        body: Center(child: Text(AppLocalizations.of(context)!.userNotConnected)),
      );
    }

    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(
      messagesStreamProvider(widget.conversationId),
    );

    return conversationAsync.when(
      data: (conversation) {
        if (conversation == null) {
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context)!.chatTitle)),
            body: Center(child: Text(AppLocalizations.of(context)!.conversationNotFound)),
          );
        }

        final otherParticipant = conversation.getOtherParticipantDetails(
          currentUser.uid,
        );

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage: otherParticipant?.avatar != null
                      ? NetworkImage(otherParticipant!.avatar!)
                      : null,
                  child: otherParticipant?.avatar == null
                      ? Text(
                          otherParticipant?.name
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              '?',
                        )
                      : null,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  otherParticipant?.name ?? AppLocalizations.of(context)!.defaultUser,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Section sticky avec les infos du produit
              _buildProductSection(conversation, currentUser.uid, theme),
              // Carte d'info fixe avec les détails de l'autre personne
              _buildContactInfoCard(conversation, currentUser.uid, theme),
              // Liste des messages
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Scroll vers le bas quand de nouveaux messages arrivent
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _buildMessage(
                          message,
                          currentUser.uid,
                          conversation,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text('Erreur : $error')),
                ),
              ),
              _buildInputSection(theme),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.chatTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.chatTitle)),
        body: Center(child: Text(AppLocalizations.of(context)!.errorGenericMsg(error.toString()))),
      ),
    );
  }

  Widget _buildContactInfoCard(
    Conversation conversation,
    String currentUserId,
    ThemeData theme,
  ) {
    // Récupérer l'ID de l'autre personne
    final otherParticipantId = conversation.getOtherParticipantId(
      currentUserId,
    );

    // Utiliser FutureBuilder pour récupérer les infos complètes de l'utilisateur
    return FutureBuilder(
      future: ref.read(authRepositoryProvider).getUserById(otherParticipantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final otherUser = snapshot.data!;

        // Carte stylisée comme une bulle de message reçu
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.chatWelcomeMessage(otherUser.username),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${otherUser.country.name}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🕐 ${AppLocalizations.of(context)!.memberSinceYear(otherUser.createdAt.year)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessage(
    Message message,
    String currentUserId,
    Conversation conversation,
  ) {
    final isMe = message.senderId == currentUserId;
    final senderName =
        conversation.participantDetails[message.senderId]?.name ??
        'Utilisateur';

    switch (message.type) {
      case MessageType.system:
        // Pour les messages système, inverser isMe car le message décrit l'autre personne
        // Si c'est mon userId, c'est mes infos, donc ça doit être affiché du côté de l'autre (isMe = false)
        return MessageBubble(
          isMe: !isMe,
          text: message.userInfo != null
              ? '${AppLocalizations.of(context)!.chatWelcomeMessage(message.userInfo!.name)}\n'
                    '${message.userInfo!.country != null ? '📍 ${message.userInfo!.country}\n' : ''}'
                    '${message.userInfo!.memberSince != null ? '🕐 ${AppLocalizations.of(context)!.memberSinceYear(message.userInfo!.memberSince!.year)}' : ''}'
              : AppLocalizations.of(context)!.systemMessage,
        );

      case MessageType.offer:
      case MessageType.counterOffer:
        // Identifier si l'utilisateur actuel est l'acheteur
        final isBuyer = conversation.productDetails.sellerId != null
            ? conversation.productDetails.sellerId != currentUserId
            : true; // Par défaut, si pas de sellerId, on considère comme acheteur

        return MessageBubble(
          isMe: isMe,
          isOffer: true,
          offerAmount: message.offer?.amount,
          offerStatus: message.offer?.status.name,
          senderName: senderName,
          onAccept: !isMe && message.offer?.status.name == 'pending'
              ? () => _acceptOffer(message.id)
              : null,
          onRefuse: !isMe && message.offer?.status.name == 'pending'
              ? () => _rejectOffer(message.id)
              : null,
          // Le bouton "Acheter" apparaît seulement si :
          // 1. L'offre est acceptée
          // 2. L'utilisateur actuel est l'acheteur (pas le vendeur)
          onBuy: message.offer?.status.name == 'accepted' && isBuyer
              ? () => _buyProduct(conversation)
              : null,
          // Le bouton "Faire une offre" dans la bulle appelle la même fonction que celle du haut
          onCounterOffer: () => _showMakeOfferBottomSheet(conversation),
        );

      case MessageType.text:
        return MessageBubble(isMe: isMe, text: message.text ?? '');
    }
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () {},
            ),
            Expanded(
              child: Input(
                controller: _messageController,
                placeholder: AppLocalizations.of(context)!.sendMessagePlaceholder,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                borderRadius: 7,
                borderColor: Colors.transparent,
                focusedBorderColor: Colors.transparent,
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}
