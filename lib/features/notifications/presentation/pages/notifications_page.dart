import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/notification_router.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

/// La boîte de réception.
///
/// Ce qui lui donne sa valeur n'est pas la liste mais le routage : un vendeur
/// qui appuie sur « Nouvelle vente » doit atterrir là où il imprime son
/// étiquette, pas sur l'accueil.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final utilisateur = ref.watch(authStateProvider).value;

    if (utilisateur == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.notificationsTitle)));
    }

    final notifications = ref.watch(notificationsProvider(utilisateur.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if ((notifications.value ?? []).any((n) => !n.read))
            TextButton(
              onPressed: () => ref
                  .read(notificationRepositoryProvider)
                  .markAllAsRead(utilisateur.uid),
              child: Text(l10n.notificationsMarkAllRead),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (liste) {
          if (liste.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: l10n.notificationsEmpty,
              message: l10n.notificationsEmptyHint,
            );
          }

          return ListView.separated(
            itemCount: liste.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = liste[i];
              return Dismissible(
                key: ValueKey(n.id),
                // Balayer vers la gauche pour supprimer.
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref
                      .read(notificationRepositoryProvider)
                      .delete(n.id)
                      .catchError((_) {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.notificationDeleted)),
                  );
                },
                child: NotificationTile(
                  notification: n,
                  onTap: () {
                  // Marquer d'abord : si la navigation échoue ou si la
                  // personne revient en arrière, la ligne ne doit pas
                  // réapparaître comme non lue.
                  if (!n.read) {
                    ref
                        .read(notificationRepositoryProvider)
                        .markAsRead(n.id)
                        .catchError((_) {});
                  }
                  final destination = destinationOfNotification(n);
                  // Un type inconnu n'ouvre rien — et ne plante pas.
                  if (destination != null) context.push(destination);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
