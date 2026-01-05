import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/application/providers.dart';

/// Page de profil utilisateur
///
/// Cette page affiche le profil de l'utilisateur avec ses paramètres.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar et infos utilisateur
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nom d\'utilisateur',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'email@example.com',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Section Paramètres
          Text(
            'Paramètres',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Changement de thème
          _buildSettingTile(
            context: context,
            icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
            title: 'Thème',
            subtitle: isDarkMode ? 'Mode sombre' : 'Mode clair',
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),

          const Divider(height: 32),

          // Sélection de la langue
          _buildSettingTile(
            context: context,
            icon: Icons.language,
            title: 'Langue',
            subtitle: currentLocale.languageCode == 'fr'
                ? 'Français'
                : 'English',
            trailing: DropdownButton<String>(
              value: currentLocale.languageCode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(localeProvider.notifier).setLanguage(newValue);
                }
              },
            ),
          ),

          const Divider(height: 32),
          _buildSettingTile(
            context: context,
            icon: Icons.shopping_bag_outlined,
            title: 'Mes annonces',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigation vers mes annonces
            },
          ),

          // Favoris
          _buildSettingTile(
            context: context,
            icon: Icons.favorite_border,
            title: 'Favoris',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigation vers favoris
            },
          ),

          // Paramètres du compte
          _buildSettingTile(
            context: context,
            icon: Icons.settings_outlined,
            title: 'Paramètres du compte',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigation vers paramètres
            },
          ),

          const Divider(height: 32),

          // Section Aide
          Text(
            'Aide',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Centre d'aide
          _buildSettingTile(
            context: context,
            icon: Icons.help_outline,
            title: 'Centre d\'aide',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Ouvrir centre d'aide
            },
          ),

          // À propos
          _buildSettingTile(
            context: context,
            icon: Icons.info_outline,
            title: 'À propos',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Afficher à propos
            },
          ),

          const SizedBox(height: 32),

          // Bouton de déconnexion
          ElevatedButton.icon(
            onPressed: () async {
              // Afficher dialogue de confirmation
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text(
                    'Êtes-vous sûr de vouloir vous déconnecter ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Déconnexion',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                // Déconnexion
                await ref.read(authRepositoryProvider).signOut();
                // Redirection vers onboarding
                if (context.mounted) {
                  context.go('/onboarding');
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Widget réutilisable pour les éléments de paramètres
  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
