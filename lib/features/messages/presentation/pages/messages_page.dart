import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'chat_page.dart';

/// Page de messages
///
/// Cette page affiche les conversations de l'utilisateur et les notifications.
/// Elle comporte deux onglets : Messages et Notifications.
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            dividerColor: Colors.transparent,
          ),
        ),
        body: TabBarView(
          children: [
            // Onglet Messages
            _buildMessagesList(context, theme),
            
            // Onglet Notifications
            _buildEmptyState(
              context,
              icon: Icons.notifications_none_outlined,
              message: l10n.noNotifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, ThemeData theme) {
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(
             backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=epiphane'), // Mock avatar
             radius: 24,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "epiphane-gedeonp",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                "A l'instant",
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                "Bonjour, accepterais-tu de me ven...",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              // Petite vignette produit simulée
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage('https://placehold.co/100x100/1e293b/ffffff/png?text=T-Shirt'), // Mock product img
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatPage(
                  userName: "epiphane-gedeonp",
                  userAvatar: "https://i.pravatar.cc/150?u=epiphane",
                ),
              ),
            );
          },
        ),
        // Divider
        Divider(color: theme.dividerColor.withOpacity(0.1)),
        
        // Mock Vinted message
        ListTile(
          leading: const CircleAvatar(
             backgroundColor: Colors.teal,
             child: Text('A', style: TextStyle(color: Colors.white)),
          ),
          title: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text("Ablony Team", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
               Text("Il y a 3 jours", style: theme.textTheme.bodySmall),
             ],
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text("Fin de mois, faites le tri 🧹"),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {required IconData icon, required String message}) {
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
