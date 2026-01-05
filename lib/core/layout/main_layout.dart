import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../features/sell/presentation/widgets/sell_bottom_sheet.dart';

/// Layout principal de l'application avec BottomNavigationBar
///
/// Ce widget wrappera toutes les pages principales de l'app et affichera
/// une barre de navigation en bas avec 5 onglets.
///
/// **Onglets :**
/// - Accueil (Home)
/// - Rechercher (Search)
/// - Vendre (Sell) - Ouvre un bottom sheet
/// - Messages
/// - Profil
class MainLayout extends StatelessWidget {
  /// Shell de navigation fourni par go_router
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  /// Gère la navigation entre les onglets
  void _onItemTapped(BuildContext context, int index) {
    // Si c'est le bouton "Vendre" (index 2), on ouvre le bottom sheet
    if (index == 2) {
      SellBottomSheet.show(context);
      return;
    }

    // Sinon, on change de branche
    navigationShell.goBranch(
      index,
      // Retourne à la route initiale de la branche si on tape sur l'onglet déjà actif
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onItemTapped(context, index),
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
            icon: const Icon(Icons.mail_outline),
            activeIcon: const Icon(Icons.mail),
            label: l10n.navMessages,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
