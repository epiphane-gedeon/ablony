import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Page des paramètres de l'application.
///
/// Permet à l'utilisateur de gérer son profil, ses notifications,
/// la langue de l'app, le thème sombre et de se déconnecter.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle), centerTitle: true),
      body: ContentContainer(
        applyPadding: false,
        child: ListView(
          children: [
            // ============================================================
            // SECTION 1 : PROFIL & COMPTE
            // ============================================================
            _buildSettingsTile(
              context: context,
              title: l10n.profileInfo,
              onTap: () {},
            ),
            _buildSettingsTile(
              context: context,
              title: l10n.accountSettings,
              onTap: () {},
            ),
            _buildSettingsTile(
              context: context,
              title: l10n.payments,
              onTap: () {},
            ),
            _buildSettingsTile(
              context: context,
              title: l10n.shipping,
              onTap: () {},
            ),
            _buildSettingsTile(
              context: context,
              title: l10n.security,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // ============================================================
            // SECTION 2 : NOTIFICATIONS
            // ============================================================
            _buildSectionHeader(context, l10n.notifications),
            _buildSettingsTile(
              context: context,
              title: l10n.mobile,
              onTap: () {},
            ),
            _buildSettingsTile(
              context: context,
              title: l10n.email,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // ============================================================
            // SECTION 3 : LANGUE
            // ============================================================
            _buildSectionHeader(context, l10n.appLanguage),
            _buildSettingsTile(
              context: context,
              title: l10n.language,
              icon: Icons.language_outlined,
              trailing: locale.languageCode.toUpperCase(),
              onTap: () => _showLanguageDialog(context, ref),
            ),

            const SizedBox(height: 32),

            // ============================================================
            // SECTION 4 : AFFICHAGE & CONFIDENTIALITÉ
            // ============================================================
            _buildSettingsTile(
              context: context,
              title: l10n.darkMode,
              trailing: themeMode == ThemeMode.dark
                  ? l10n.activatedStr
                  : l10n.deactivatedStr,
              onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),
            _buildSettingsTile(
              context: context,
              title: l10n.privacySettings,
              onTap: () {},
            ),

            const SizedBox(height: 48),

            // ============================================================
            // SECTION 5 : DÉCONNEXION
            // ============================================================
            _buildSettingsTile(
              context: context,
              title: l10n.logout,
              titleColor: Colors.red,
              showChevron: false,
              onTap: () => _showLogoutConfirmation(context, ref),
            ),

            const SizedBox(height: 32),

            // ============================================================
            // FOOTER : VERSION
            // ============================================================
            Center(
              child: Text(
                l10n.appVersion('v26.12.0'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Construit un en-tête de section.
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  /// Construit une tuile de paramètre.
  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    IconData? icon,
    String? trailing,
    required VoidCallback onTap,
    Color? titleColor,
    bool showChevron = true,
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
            if (icon != null) ...[
              Icon(
                icon,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(color: titleColor),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (showChevron)
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

  /// Affiche le dialogue de changement de langue.
  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Français'),
              onTap: () {
                ref.read(localeProvider.notifier).setLanguage('fr');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                ref.read(localeProvider.notifier).setLanguage('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le dialogue de confirmation de déconnexion.
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
              context.go('/onboarding');
            },
            child: Text(
              AppLocalizations.of(context)!.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
