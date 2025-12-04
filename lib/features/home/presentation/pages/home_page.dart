import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/providers.dart';
import '../../../../core/providers/theme_provider.dart';

/// Page d'accueil principale de l'application Ablony.
///
/// Cette page est affichée après une inscription réussie ou une connexion.
/// Pour l'instant, c'est un simple placeholder avec "Hello World".
///
/// **TODO :**
/// - [ ] Ajouter le feed de produits
/// - [ ] Ajouter la barre de recherche
/// - [ ] Ajouter les catégories
/// - [ ] Ajouter la navigation bottom bar
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Vérifie si l'utilisateur est connecté
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          l10n.homeTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Affiche le bouton de déconnexion uniquement si connecté
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                // Déconnexion
                await ref.read(authRepositoryProvider).signOut();
                // Redirection explicite vers l'onboarding après déconnexion
                if (context.mounted) {
                  context.go('/onboarding');
                }
              },
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.homeWelcome,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.homeSubtitle,
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeSuccess,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      // Bouton flottant temporaire pour tester le changement de thème
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(themeProvider.notifier).toggleTheme();
        },
        tooltip: 'Toggle Theme',
        child: Icon(
          Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode
              : Icons.dark_mode,
        ),
      ),
    );
  }
}
