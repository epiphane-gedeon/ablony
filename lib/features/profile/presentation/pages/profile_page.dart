import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../../core/config/app_urls.dart';
import '../../../../core/presentation/pages/web_view_page.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/user_badges.dart';
import '../../../product/domain/boost_config.dart';

/// Page de profil utilisateur
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileTitle),
        centerTitle: true,
      ),
      body: ContentContainer(
        applyPadding: false,
        maxWidth: ContentWidth.standard,
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return Center(
                child: Text(AppLocalizations.of(context)!.userNotConnected),
              );
            }

            return ListView(
              children: [
                // Section profil avec avatar et nom
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () => context.push('/profile/my-listings'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.username,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    UserBadges(user: user),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!.viewMyListings,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des options
                // Profil public : réservé aux membres star. Un membre ordinaire
                // n'y a pas accès depuis son menu.
                if (user.isStar)
                  _buildMenuTile(
                    context: context,
                    icon: Icons.person_outline,
                    title: AppLocalizations.of(context)!.viewPublicProfile,
                    onTap: () => context.push('/profile/${user.uid}'),
                  ),

                _buildMenuTile(
                  context: context,
                  icon: Icons.favorite_border,
                  title: AppLocalizations.of(context)!.favorites,
                  onTap: () => context.push('/profile/favorites'),
                ),


                // Réservé au personnel. Masquer l'entrée n'est qu'un
                // confort : ce sont les Cloud Functions qui refusent, après
                // avoir relu le rôle en base.
                if (user.isStaff)
                  _buildMenuTile(
                    context: context,
                    icon: Icons.local_shipping_outlined,
                    title: AppLocalizations.of(context)!.staffTools,
                    onTap: () => context.push('/delivery/stuck'),
                  ),

                _buildMenuTile(
                  context: context,
                  icon: Icons.wallet_outlined,
                  title: AppLocalizations.of(context)!.myWallet,
                  trailing: user.wallet != null
                      ? '${user.wallet!.availableAmount} FCFA'
                      : '0 FCFA',
                  onTap: () => context.push('/profile/wallet'),
                ),

                _buildMenuTile(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  title: AppLocalizations.of(context)!.salesAndPurchases,
                  onTap: () => context.pushNamed('orders'),
                ),

                // Masqué sur mobile tant que la facturation du magasin n'est
                // pas branchée (cf. `boostsDisponibles`).
                if (boostsDisponibles)
                  _buildMenuTile(
                    context: context,
                    icon: Icons.rocket_launch_outlined,
                    title: AppLocalizations.of(context)!.promotionTools,
                    onTap: () => context.pushNamed('promotion'),
                  ),





                const Divider(height: 32),

                _buildMenuTile(
                  context: context,
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context)!.ablonyGuide,
                  onTap: () => WebViewPage.open(
                    context,
                    url: AppUrls.helpCenter,
                    title: AppLocalizations.of(context)!.ablonyGuide,
                    hideSelectors: AppUrls.legalPageHideSelectors,
                  ),
                ),

                // L'assistance est désormais interne : on écrit dans
                // l'application, avec pièce jointe, et la conversation reste
                // consultable. Le guide en ligne garde son entrée juste
                // au-dessus.
                _buildMenuTile(
                  context: context,
                  icon: Icons.support_agent_outlined,
                  title: AppLocalizations.of(context)!.supportOpen,
                  onTap: () => context.pushNamed('support'),
                ),

                _buildMenuTile(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: AppLocalizations.of(context)!.settingsTitle,
                  onTap: () => context.push('/profile/settings'),
                ),


                _buildMenuTile(
                  context: context,
                  icon: Icons.info_outline,
                  title: AppLocalizations.of(context)!.aboutUs,
                  onTap: () => WebViewPage.open(
                    context,
                    url: AppUrls.about,
                    title: AppLocalizations.of(context)!.aboutUs,
                    hideSelectors: AppUrls.legalPageHideSelectors,
                  ),
                ),

                _buildMenuTile(
                  context: context,
                  icon: Icons.description_outlined,
                  title: AppLocalizations.of(context)!.legalInfo,
                  onTap: () => _ouvrirPagesLegales(context),
                ),


                const SizedBox(height: 32),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Centre de protection de la vie privée  •  Conditions générales',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 80), // Espace pour la nav bar
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              AppLocalizations.of(context)!.errorGenericMsg(error.toString()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
            if (trailing != null) ...[
              Text(
                trailing,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Les trois pages légales, derrière une seule entrée.
///
/// Trois lignes de menu pour trois pages qu'on ouvre une fois dans sa vie
/// alourdiraient le profil ; une entrée qui n'en montre qu'une en cacherait
/// deux que la loi impose d'exposer.
Future<void> _ouvrirPagesLegales(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  await showModalBottomSheet<void>(
    context: context,
    builder: (feuille) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l10n.termsOfService),
            onTap: () {
              Navigator.pop(feuille);
              WebViewPage.open(
                context,
                url: AppUrls.termsOfService,
                title: l10n.termsOfService,
                hideSelectors: AppUrls.legalPageHideSelectors,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.privacyPolicy),
            onTap: () {
              Navigator.pop(feuille);
              WebViewPage.open(
                context,
                url: AppUrls.privacyPolicy,
                title: l10n.privacyPolicy,
                hideSelectors: AppUrls.legalPageHideSelectors,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: Text(l10n.legalNotice),
            onTap: () {
              Navigator.pop(feuille);
              WebViewPage.open(
                context,
                url: AppUrls.legalNotice,
                title: l10n.legalNotice,
                hideSelectors: AppUrls.legalPageHideSelectors,
              );
            },
          ),
        ],
      ),
    ),
  );
}
