import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/providers/message_providers.dart';
import '../../domain/models/conversation.dart';

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navMessages),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.messagesTab),
              Tab(text: l10n.notificationsTab),
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
              return const Center(child: Text('Veuillez vous connecter'));
            }

            return TabBarView(
              children: [
                // Onglet Messages
                _buildConversationsList(context, ref, theme, user),

                // Onglet Notifications
                _buildEmptyState(
                  context,
                  icon: Icons.notifications_none_outlined,
                  message: l10n.noNotifications,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur : $error')),
        ),
      ),
    );
  }

  Widget _buildConversationsList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    firebase_auth.User user,
  ) {
    final conversationsAsync = ref.watch(conversationsStreamProvider(user.uid));

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.chat_bubble_outline,
            message: 'Aucun message',
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
          Center(child: Text('Erreur de chargement : $error')),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    ThemeData theme,
    Conversation conversation,
    String currentUserId,
  ) {
    final otherParticipant = conversation.getOtherParticipantDetails(
      currentUserId,
    );
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;

    // Configure la locale française pour timeago
    timeago.setLocaleMessages('fr', timeago.FrMessages());

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
                otherParticipant?.name ?? 'Utilisateur',
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
                  locale: 'fr',
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
                    conversation.lastMessage?.text ?? '',
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
}
