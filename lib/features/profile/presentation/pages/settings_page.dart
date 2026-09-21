import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/account_deletion_service.dart';
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
              onTap: () => context.pushNamed('edit_profile'),
            ),
            _buildSettingsTile(
              context: context,
              title: l10n.security,
              onTap: () => context.pushNamed('security'),
            ),

            const SizedBox(height: 32),

            // ============================================================
            // SECTION 2 : NOTIFICATIONS
            // ============================================================
            _buildSectionHeader(context, l10n.notifications),
            _buildSettingsTile(
              context: context,
              title: l10n.email,
              onTap: () => context.pushNamed('email_settings'),
            ),
            // Consentement marketing modifiable à tout moment (RGPD : se
            // désinscrire doit être aussi simple que s'inscrire). Ne concerne
            // QUE le promotionnel — les emails de sécurité/vérification partent
            // quoi qu'il arrive.
            const _MarketingEmailToggle(),

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
              title: l10n.blockedUsersTitle,
              onTap: () => context.pushNamed('blocked_users'),
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
            _buildSettingsTile(
              context: context,
              title: l10n.deleteAccount,
              titleColor: Colors.red,
              showChevron: false,
              onTap: () => _showDeleteAccountConfirmation(context, ref),
            ),

            const SizedBox(height: 32),

            // ============================================================
            // FOOTER : VERSION
            // ============================================================
            // La version est lue sur le paquet installé, et non écrite ici :
            // la constante en dur affichait « v26.12.0 » alors que le binaire
            // était en 1.0.0. Une version fausse rend tout rapport de bogue
            // inexploitable — on ne sait plus de quelle build on parle.
            Center(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  // Tant que la lecture n'a pas abouti, on n'affiche rien
                  // plutôt qu'un numéro provisoire qui serait faux.
                  if (info == null) return const SizedBox(height: 16);
                  return Text(
                    l10n.appVersion('v${info.version} (${info.buildNumber})'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  );
                },
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
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.logout),
        content: Text(AppLocalizations.of(dialogContext)!.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              // On ferme la confirmation tout de suite (sinon elle reste
              // affichée pendant la déconnexion réseau et on a l'impression
              // que le bouton n'a rien fait → double tap).
              Navigator.pop(dialogContext);
              await ref.read(authRepositoryProvider).signOut();
              // La redirection du routeur suit l'état auth ; on force aussi
              // explicitement pour ne pas dépendre du timing du stream.
              if (context.mounted) context.go('/onboarding');
            },
            child: Text(
              AppLocalizations.of(dialogContext)!.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue de confirmation de suppression de compte.
  ///
  /// Le texte prévient explicitement que la suppression est définitive et
  /// qu'un nouveau compte pourra être recréé avec les mêmes identifiants —
  /// l'utilisateur doit comprendre ça avant de confirmer, pas après.
  void _showDeleteAccountConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performAccountDeletion(context, ref);
            },
            child: Text(
              l10n.deleteAccountConfirmAction,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Supprime le compte (anonymisation Firestore + suppression Firebase
  /// Auth côté serveur), déconnecte l'utilisateur puis le renvoie vers
  /// l'onboarding.
  Future<void> _performAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(accountDeletionServiceProvider).deleteAccount();
      // Nettoie l'état local (tokens Firebase Auth, sessions Google/
      // Facebook) : le compte Firebase Auth est déjà supprimé côté serveur
      // à ce stade, mais le SDK client garde encore la session en mémoire.
      await ref.read(authRepositoryProvider).signOut();

      if (!context.mounted) return;
      Navigator.pop(context); // Ferme le loader

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteAccountDoneTitle),
          content: Text(l10n.deleteAccountDoneMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );

      if (context.mounted) context.go('/onboarding');
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Ferme le loader
      final message = e is AppException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGenericMsg(message)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Bascule « Emails marketing » : lit la valeur sur le profil courant et la met
/// à jour dans Firestore. Optimiste (bascule tout de suite, revient en arrière
/// si l'écriture échoue) pour ne pas donner l'impression que rien ne se passe.
class _MarketingEmailToggle extends ConsumerStatefulWidget {
  const _MarketingEmailToggle();

  @override
  ConsumerState<_MarketingEmailToggle> createState() =>
      _MarketingEmailToggleState();
}

class _MarketingEmailToggleState extends ConsumerState<_MarketingEmailToggle> {
  bool? _optimistic;
  bool _saving = false;

  Future<void> _onChanged(bool value, String uid) async {
    setState(() {
      _optimistic = value;
      _saving = true;
    });
    try {
      await ref.read(authRepositoryProvider).updateUserProfile(
            uid: uid,
            marketingEmailsEnabled: value,
          );
    } catch (e) {
      if (mounted) {
        setState(() => _optimistic = null); // Revient à la vérité serveur.
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGenericMsg(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final serverValue = user.marketingEmailsEnabled;
    if (_optimistic != null && _optimistic == serverValue) {
      _optimistic = null;
    }
    final value = _optimistic ?? serverValue;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          l10n.marketingEmailToggleTitle,
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          l10n.marketingEmailToggleSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        value: value,
        onChanged: _saving ? null : (v) => _onChanged(v, user.uid),
      ),
    );
  }
}
