import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../features/sell/presentation/widgets/sell_bottom_sheet.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/messages/application/providers/message_providers.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';

/// Layout principal de l'application avec BottomNavigationBar
///
/// Ce widget wrappera toutes les pages principales de l'app et affichera
/// une barre de navigation en bas avec 5 onglets.
///
/// **Onglets :**
/// - Accueil (Home)
/// - Rechercher (Search)
/// - Vendre (Sell) - Ouvre un bottom sheet
/// - Messages (avec badge de notification)
/// - Profil
class MainLayout extends ConsumerWidget {
  /// Shell de navigation fourni par go_router
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  /// Gère la navigation entre les onglets
  void _onItemTapped(
    BuildContext context,
    int index,
    StatefulNavigationShell shell,
  ) {
    // Si c'est le bouton "Vendre" (index 2), on ouvre le bottom sheet
    if (index == 2) {
      SellBottomSheet.show(context);
      return;
    }

    // Sinon, on change de branche
    shell.goBranch(
      index,
      // Retourne à la route initiale de la branche si on tape sur l'onglet déjà actif
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Badge de l'onglet Messages = messages non lus + notifications non lues
    // (les notifications n'ont pas leur propre onglet dans la bottom nav,
    // elles vivent dans un second onglet de la page Messages).
    final currentUser = ref.watch(authStateProvider).value;
    final unreadMessages = currentUser != null
        ? ref.watch(totalUnreadCountStreamProvider(currentUser.uid)).value ?? 0
        : 0;
    final unreadNotifications = currentUser != null
        ? ref.watch(unreadNotificationsCountProvider(currentUser.uid))
        : 0;
    final unreadCount = unreadMessages + unreadNotifications;

    // Sur l'onglet Accueil, un back normal (quitte l'app) reste attendu.
    // Sur les autres onglets, à la racine de leur pile (rien à dépiler dans
    // la branche elle-même — go_router gère déjà ce cas), un back doit
    // ramener à Accueil plutôt que fermer l'app.
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onItemTapped(context, 0, navigationShell);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => _onItemTapped(context, index, navigationShell),
          type: BottomNavigationBarType.fixed,

          // Couleurs adaptées au thème
          backgroundColor: Theme.of(
            context,
          ).bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,

          // Style du texte
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),

          // Toujours afficher les labels
          showSelectedLabels: true,
          showUnselectedLabels: true,

          // Élévation pour l'ombre
          elevation: 8,

          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              activeIcon: const Icon(Icons.search),
              label: l10n.navSearch,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline),
              activeIcon: const Icon(Icons.add_circle),
              label: l10n.navSell,
            ),
            BottomNavigationBarItem(
              icon: unreadCount > 0
                  ? Badge(
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.mail_outline),
                    )
                  : const Icon(Icons.mail_outline),
              activeIcon: unreadCount > 0
                  ? Badge(
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.mail),
                    )
                  : const Icon(Icons.mail),
              label: l10n.navMessages,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
