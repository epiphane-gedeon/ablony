import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';

/// Page de profil utilisateur
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), centerTitle: true),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utilisateur non connecté'));
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
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
                          Text(
                            user.username,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Voir mes annonces',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
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
              _buildMenuTile(
                context: context,
                icon: Icons.favorite_border,
                title: 'Favoris',
                onTap: () => context.push('/profile/favorites'),
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.email_outlined,
                title: 'Inviter des amis',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.wallet_outlined,
                title: 'Mon porte-monnaie',
                trailing: user.wallet != null
                    ? '${user.wallet!.availableAmount} FCFA'
                    : '0 FCFA',
                onTap: () => context.push('/profile/wallet'),
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.receipt_long_outlined,
                title: 'Mes ventes et achats',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.rocket_launch_outlined,
                title: 'Outils de promotion',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.tune_outlined,
                title: 'Personnalisation',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.discount_outlined,
                title: 'Réduction sur les lots',
                trailing: 'Désactivé',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.beach_access_outlined,
                title: 'Mode vacances',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.favorite_outline,
                title: 'Dons',
                trailing: 'Désactivé',
                onTap: () {},
              ),

              const Divider(height: 32),

              _buildMenuTile(
                context: context,
                icon: Icons.help_outline,
                title: 'Ton guide Vinted',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.support_agent_outlined,
                title: 'Centre d\'aide',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.settings_outlined,
                title: 'Paramètres',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.cookie_outlined,
                title: 'Paramètres des cookies',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.info_outline,
                title: 'À propos de nous',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.description_outlined,
                title: 'Informations légales',
                onTap: () {},
              ),

              _buildMenuTile(
                context: context,
                icon: Icons.verified_outlined,
                title: 'Notre plateforme',
                onTap: () {},
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
        error: (error, stack) => Center(child: Text('Erreur: $error')),
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
