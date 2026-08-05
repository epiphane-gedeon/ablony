import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../responsive/responsive.dart';
import '../../features/sell/presentation/widgets/sell_bottom_sheet.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/messages/application/providers/message_providers.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';

/// Décrit un onglet de navigation, indépendamment de la façon dont il est
/// rendu (barre en bas, rail compact ou rail étendu).
class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Layout principal de l'application, avec une navigation **adaptative**.
///
/// La navigation change de forme selon la largeur de fenêtre, en suivant les
/// recommandations Material 3 :
///
/// | Largeur      | Navigation                        |
/// |--------------|-----------------------------------|
/// | < 600        | Barre en bas (`BottomNavigationBar`) |
/// | 600 – 1199   | Rail latéral (icônes + libellés courts) |
/// | ≥ 1200       | Rail latéral étendu (icônes + libellés) |
///
/// Le raisonnement se fait sur la **largeur de fenêtre**, pas sur le type
/// d'appareil : une fenêtre de navigateur réduite sur un grand écran retombe
/// naturellement sur la barre du bas.
///
/// **Onglets :** Accueil, Rechercher, Vendre (ouvre un bottom sheet),
/// Messages (avec badge), Profil.
class MainLayout extends ConsumerWidget {
  /// Shell de navigation fourni par go_router
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  /// Index de l'onglet « Vendre », qui n'est pas une vraie branche de
  /// navigation mais ouvre un bottom sheet.
  static const int _sellIndex = 2;

  /// Gère la navigation entre les onglets
  void _onItemTapped(
    BuildContext context,
    int index,
    StatefulNavigationShell shell,
  ) {
    // Si c'est le bouton "Vendre", on ouvre le bottom sheet
    if (index == _sellIndex) {
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

    final destinations = <_NavDestination>[
      _NavDestination(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: l10n.navHome,
      ),
      _NavDestination(
        icon: Icons.search,
        activeIcon: Icons.search,
        label: l10n.navSearch,
      ),
      _NavDestination(
        icon: Icons.add_circle_outline,
        activeIcon: Icons.add_circle,
        label: l10n.navSell,
      ),
      _NavDestination(
        icon: Icons.mail_outline,
        activeIcon: Icons.mail,
        label: l10n.navMessages,
      ),
      _NavDestination(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: l10n.navProfile,
      ),
    ];

    final screenSize = context.screenSize;
    final useRail = screenSize.isWide;
    final useExtendedRail = screenSize.isAtLeast(ScreenSize.large);

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
        body: useRail
            ? Row(
                children: [
                  _buildRail(
                    context,
                    destinations: destinations,
                    unreadCount: unreadCount,
                    extended: useExtendedRail,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: navigationShell),
                ],
              )
            : navigationShell,
        bottomNavigationBar: useRail
            ? null
            : _buildBottomBar(
                context,
                destinations: destinations,
                unreadCount: unreadCount,
              ),
      ),
    );
  }

  /// Ajoute le badge de messages non lus à une icône, le cas échéant.
  Widget _withBadge(Widget icon, int unreadCount) {
    if (unreadCount <= 0) return icon;
    return Badge(label: Text(unreadCount.toString()), child: icon);
  }

  /// Navigation latérale, pour les écrans à partir de 600 px.
  ///
  /// [extended] passe du rail compact (icône + libellé sous l'icône) au rail
  /// étendu (icône + libellé côte à côte), à partir de 1200 px.
  Widget _buildRail(
    BuildContext context, {
    required List<_NavDestination> destinations,
    required int unreadCount,
    required bool extended,
  }) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        // Un rail plus haut que la fenêtre (petit écran en paysage) doit
        // pouvoir défiler plutôt que déborder.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical,
          ),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) =>
                  _onItemTapped(context, index, navigationShell),
              extended: extended,
              labelType: extended ? null : NavigationRailLabelType.all,
              backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
              ),
              unselectedIconTheme: IconThemeData(
                color: theme.textTheme.bodySmall?.color,
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
              destinations: [
                for (var i = 0; i < destinations.length; i++)
                  NavigationRailDestination(
                    icon: i == 3
                        ? _withBadge(Icon(destinations[i].icon), unreadCount)
                        : Icon(destinations[i].icon),
                    selectedIcon: i == 3
                        ? _withBadge(
                            Icon(destinations[i].activeIcon),
                            unreadCount,
                          )
                        : Icon(destinations[i].activeIcon),
                    label: Text(destinations[i].label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navigation en bas d'écran, pour les téléphones en portrait (< 600 px).
  Widget _buildBottomBar(
    BuildContext context, {
    required List<_NavDestination> destinations,
    required int unreadCount,
  }) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      currentIndex: navigationShell.currentIndex,
      onTap: (index) => _onItemTapped(context, index, navigationShell),
      type: BottomNavigationBarType.fixed,

      // Couleurs adaptées au thème
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.textTheme.bodySmall?.color,

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
        for (var i = 0; i < destinations.length; i++)
          BottomNavigationBarItem(
            icon: i == 3
                ? _withBadge(Icon(destinations[i].icon), unreadCount)
                : Icon(destinations[i].icon),
            activeIcon: i == 3
                ? _withBadge(Icon(destinations[i].activeIcon), unreadCount)
                : Icon(destinations[i].activeIcon),
            label: destinations[i].label,
          ),
      ],
    );
  }
}
