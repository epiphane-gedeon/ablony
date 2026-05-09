import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../l10n/app_localizations.dart';

/// Provider pour charger un utilisateur par son ID
final userByIdProvider = FutureProvider.family<User, String>((ref, userId) async {
  final authRepository = ref.read(authRepositoryProvider);
  return authRepository.getUserById(userId);
});

/// Page de profil public d'un autre utilisateur.
///
/// Affichée quand on clique sur un utilisateur depuis la recherche.
/// Contient les mêmes onglets que [UserListingsPage] (Annonces, Évaluations, À propos)
/// mais charge les données depuis l'ID passé en paramètre.
/// Un bouton "Suivre" est fixé en bas de l'écran.
class PublicProfilePage extends ConsumerWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        // Vérifier si c'est notre propre profil → rediriger
        final currentUser = currentUserAsync.value;
        final isOwnProfile = currentUser?.uid == userId;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(user.username),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              bottom: TabBar(
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.listings),
                  Tab(text: AppLocalizations.of(context)!.reviews),
                  Tab(text: AppLocalizations.of(context)!.aboutTab),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildListingsTab(context, ref, user.uid),
                _buildReviewsTab(context),
                _buildAboutTab(context, user),
              ],
            ),
            // Bouton "Suivre" fixé en bas (uniquement si ce n'est pas notre profil)
            bottomNavigationBar: isOwnProfile
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: PrimaryButton(
                        text: AppLocalizations.of(context)!.followButton,
                        onPressed: () {
                          // TODO: Implémenter la logique de suivi
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!
                                    .followComingSoon(user.username),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.errorGenericMsg(error.toString())),
        ),
      ),
    );
  }

  /// Onglet "Annonces" — affiche la grille de produits du membre
  Widget _buildListingsTab(BuildContext context, WidgetRef ref, String uid) {
    final productsAsync = ref.watch(sellerProductsProvider(uid));
    final theme = Theme.of(context);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                AppLocalizations.of(context)!.noProductsAvailable,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () => context.push('/product/${product.id}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(AppLocalizations.of(context)!.errorGenericMsg(error.toString())),
      ),
    );
  }

  /// Onglet "Évaluations"
  Widget _buildReviewsTab(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.noReviewsYet,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppLocalizations.of(context)!.noReviewsSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Onglet "À propos" — informations du membre
  Widget _buildAboutTab(BuildContext context, User user) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        // Photo de couverture / Avatar
        Container(
          height: 200,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.headlineMedium,
                    )
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.verifiedInfo,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(context, Icons.check_circle_outline, 'E-mail', true),
              const SizedBox(height: 24),
              _buildInfoRow(
                context,
                Icons.location_on_outlined,
                user.country.name,
                true,
                color: theme.colorScheme.onSurface,
              ),
              _buildInfoRow(
                context,
                Icons.rss_feed,
                '0 Abonné, 0 Abonnement',
                true,
                color: theme.colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text,
    bool isVerified, {
    Color? color,
  }) {
    if (!isVerified) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final rowColor = color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: rowColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: rowColor),
          ),
        ],
      ),
    );
  }
}
