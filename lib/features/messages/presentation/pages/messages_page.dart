import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../application/providers/message_providers.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message_type.dart';
import '../../domain/models/last_message.dart';

/// Page de messages
///
/// Cette page affiche les conversations de l'utilisateur en temps réel.
/// Elle comporte deux onglets : Messages et Notifications.
class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Récupérer l'utilisateur connecté
    final currentUserAsync = ref.watch(authStateProvider);
    final currentUser = currentUserAsync.value;

    // Pastilles par onglet, alimentées par le même système que le badge de
    // la bottom nav (cf. main_layout.dart).
    final unreadMessages = currentUser != null
        ? ref.watch(totalUnreadCountStreamProvider(currentUser.uid)).value ?? 0
        : 0;
    final unreadNotifications = currentUser != null
        ? ref.watch(unreadNotificationsCountProvider(currentUser.uid))
        : 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navMessages),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(child: _buildTabLabel(l10n.messagesTab, unreadMessages)),
              Tab(child: _buildTabLabel(l10n.notificationsTab, unreadNotifications)),
            ],
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: theme.textTheme.titleMedium,
            labelColor: theme.colorScheme.onSurface,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.5,
            ),
            dividerColor: Colors.transparent,
          ),
        ),
        body: currentUserAsync.when(
          data: (user) {
            if (user == null) {
              return Center(child: Text(l10n.pleaseLogin));
            }

            return TabBarView(
              children: [
                // Onglet Messages
                _buildConversationsList(context, ref, theme, user),

                // Onglet Notifications
                _buildNotificationsList(context, ref, theme, user.uid),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(l10n.errorGenericMsg(error.toString()))),
        ),
      ),
    );
  }

  Widget _buildTabLabel(String text, int unreadCount) {
    if (unreadCount == 0) return Text(text);
    return Badge(label: Text(unreadCount.toString()), child: Text(text));
  }

  Widget _buildConversationsList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    firebase_auth.User user,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final conversationsAsync = ref.watch(conversationsStreamProvider(user.uid));

    return conversationsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      data: (conversations) {
        if (conversations.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.chat_bubble_outline,
            message: l10n.noMessages,
          );
        }

        return ListView.separated(
          itemCount: conversations.length,
          separatorBuilder: (context, index) =>
              Divider(color: theme.dividerColor.withOpacity(0.1), height: 1),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationTile(
              context,
              theme,
              conversation,
              user.uid,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text(l10n.errorLoading + ': $error')),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String userId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider(userId));

    return notificationsAsync.when(
      skipLoadingOnReload: true,
      skipError: true,
      data: (notifications) {
        if (notifications.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.notifications_none_outlined,
            message: l10n.noNotifications,
          );
        }

        return ListView.separated(
          itemCount: notifications.length,
          separatorBuilder: (context, index) =>
              Divider(color: theme.dividerColor.withOpacity(0.1), height: 1),
          itemBuilder: (context, index) {
            return _buildNotificationTile(context, ref, theme, notifications[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text(l10n.errorLoading + ': $error')),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppNotification notification,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'fr') {
      timeago.setLocaleMessages('fr', timeago.FrMessages());
    } else {
      timeago.setLocaleMessages('en', timeago.EnMessages());
    }

    IconData icon;
    switch (notification.type) {
      case AppNotificationType.purchaseReceived:
        icon = Icons.storefront_outlined;
        break;
      case AppNotificationType.purchaseConfirmed:
        icon = Icons.receipt_long_outlined;
        break;
      case AppNotificationType.newProductFromFollowed:
        icon = Icons.new_releases_outlined;
        break;
      case AppNotificationType.unknown:
        icon = Icons.notifications_none_outlined;
        break;
    }

    return Container(
      color: !notification.read
          ? theme.colorScheme.primary.withOpacity(0.05)
          : Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: !notification.read ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(notification.body),
        trailing: Text(
          timeago.format(notification.createdAt, locale: locale),
          style: theme.textTheme.bodySmall,
        ),
        onTap: () => _handleNotificationTap(context, ref, notification),
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    if (!notification.read) {
      ref.markNotificationAsRead(notification.id);
    }

    switch (notification.type) {
      case AppNotificationType.purchaseConfirmed:
        final receiptId = notification.data['receiptId'] as String?;
        if (receiptId != null) {
          context.push('/receipt/$receiptId');
        }
        break;
      case AppNotificationType.purchaseReceived:
      case AppNotificationType.newProductFromFollowed:
        final productId = notification.data['productId'] as String?;
        if (productId != null) {
          context.push('/product/$productId');
        }
        break;
      case AppNotificationType.unknown:
        break;
    }
  }

  Widget _buildConversationTile(
    BuildContext context,
    ThemeData theme,
    Conversation conversation,
    String currentUserId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final otherParticipant = conversation.getOtherParticipantDetails(
      currentUserId,
    );
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;

    // Configure la locale pour timeago
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'fr') {
      timeago.setLocaleMessages('fr', timeago.FrMessages());
    } else {
      timeago.setLocaleMessages('en', timeago.EnMessages());
    }

    return Container(
      color: hasUnread
          ? theme.colorScheme.primary.withOpacity(0.05)
          : Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: otherParticipant?.avatar != null
              ? NetworkImage(otherParticipant!.avatar!)
              : null,
          child: otherParticipant?.avatar == null
              ? Text(
                  otherParticipant?.name.substring(0, 1).toUpperCase() ?? '?',
                )
              : null,
          radius: 24,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                otherParticipant?.name ?? l10n.defaultUser,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.lastMessage != null)
              Text(
                timeago.format(
                  conversation.lastMessage!.timestamp,
                  locale: locale,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getLastMessageText(context, conversation.lastMessage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Vignette du produit
            if (conversation.productDetails.image != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(conversation.productDetails.image!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          context.push('/chat/${conversation.id}');
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getLastMessageText(BuildContext context, LastMessage? lastMessage) {
    if (lastMessage == null) return '';
    final l10n = AppLocalizations.of(context)!;

    if (lastMessage.type == MessageType.offer) {
      // Tente d'extraire le montant du texte (format: "2000.00 FCFA En attente")
      final amount = lastMessage.text.split(' ').first;
      return '$amount FCFA ${l10n.offerStatusPending}';
    } else if (lastMessage.type == MessageType.counterOffer) {
      // Format: "2000.00 FCFA Contre-offre"
      final amount = lastMessage.text.split(' ').first;
      return '$amount FCFA ${l10n.counterOffer}';
    } else if (lastMessage.type == MessageType.image) {
      // Le texte stocké est déjà "📷" ou "📷 <légende>" (cf. sendImageMessage)
      return lastMessage.text.trim() == '📷' ? l10n.photoMessage : lastMessage.text;
    }

    return lastMessage.text;
  }
}
