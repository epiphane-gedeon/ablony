import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../product/domain/entities/entities.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../follow/presentation/widgets/follow_button.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../../../reviews/presentation/widgets/star_rating.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../l10n/app_localizations.dart';

/// Page de profil public d'un autre utilisateur.
///
/// Affichée quand on clique sur un utilisateur depuis la fiche produit ou la recherche.
/// Contient les onglets Annonces, Évaluations, À propos.
/// Un bouton "Suivre" s'affiche dans les onglets Annonces et À propos (si ce n'est pas notre profil).
class PublicProfilePage extends ConsumerWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
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
                _buildListingsTab(context, ref, user, isOwnProfile),
                _buildReviewsTab(context, ref, user),
                _buildAboutTab(context, ref, user, isOwnProfile),
              ],
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

  /// Onglet "Annonces" — en-tête avec infos vendeur + grille de produits non vendus
  Widget _buildListingsTab(BuildContext context, WidgetRef ref, User user, bool isOwnProfile) {
    final productsAsync = ref.watch(sellerProductsProvider(user.uid));
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── En-tête infos vendeur ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(
                        user.username.substring(0, 1).toUpperCase(),
                        style: theme.textTheme.headlineSmall,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    StarRatingDisplay(rating: user.rating, reviewsCount: user.reviewsCount),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          user.country.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    _FollowCountsRow(user: user),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Bouton Suivre (uniquement si ce n'est pas notre profil) ──
        if (!isOwnProfile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: FollowButton(
              targetUserId: user.uid,
              onChanged: () => ref.invalidate(userByIdProvider(user.uid)),
            ),
          ),

        const Divider(height: 1),

        // ── Grille de produits (non vendus uniquement) ──
        Expanded(
          child: productsAsync.when(
            skipLoadingOnReload: true,
            skipError: true,
            data: (products) {
              final unsoldProducts = products.where((p) => !p.isSold).toList();

              if (unsoldProducts.isEmpty) {
                return _buildEmptyState(context, theme);
              }

              return ResponsiveProductGrid<Product>(
                itemsBuilder: (_) => unsoldProducts,
                itemBuilder: (context, product) {
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
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noProductsAvailable,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Quand le membre ajoute un article, il apparaît ici',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Onglet "Évaluations"
  Widget _buildReviewsTab(BuildContext context, WidgetRef ref, User user) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final reviewsAsync = ref.watch(sellerReviewsProvider(user.uid));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.noReviewsYet,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    l10n.noReviewsSubtitle,
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

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(review.productTitle, style: theme.textTheme.bodySmall),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(review.comment!, style: theme.textTheme.bodyMedium),
                ],
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(l10n.errorGenericMsg(error.toString()))),
    );
  }

  /// Onglet "À propos" — informations du membre avec bouton Suivre
  Widget _buildAboutTab(BuildContext context, WidgetRef ref, User user, bool isOwnProfile) {
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
              const SizedBox(height: 6),
              StarRatingDisplay(rating: user.rating, reviewsCount: user.reviewsCount),
              const SizedBox(height: 12),
              _buildInfoRow(context, Icons.check_circle_outline, 'E-mail, Google', true),
              const SizedBox(height: 4),
              _buildInfoRow(
                context,
                Icons.location_on_outlined,
                user.country.name,
                true,
                color: theme.colorScheme.onSurface,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.rss_feed, size: 20, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 8),
                    _FollowCountsRow(user: user, color: theme.colorScheme.onSurface),
                  ],
                ),
              ),
              if (!isOwnProfile) ...[
                const SizedBox(height: 20),
                FollowButton(
                  targetUserId: user.uid,
                  onChanged: () => ref.invalidate(userByIdProvider(user.uid)),
                ),
              ],
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

/// Ligne "N abonnés · N abonnements", tappable vers les listes correspondantes.
class _FollowCountsRow extends StatelessWidget {
  final User user;
  final Color? color;

  const _FollowCountsRow({required this.user, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final textColor = color ?? theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final textStyle = theme.textTheme.bodySmall?.copyWith(color: textColor);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.push('/profile/${user.uid}/followers'),
          child: Text(l10n.followersCountLabel(user.followersCount), style: textStyle),
        ),
        Text(' · ', style: textStyle),
        GestureDetector(
          onTap: () => context.push('/profile/${user.uid}/following'),
          child: Text(l10n.followingCountLabel(user.followingCount), style: textStyle),
        ),
      ],
    );
  }
}
