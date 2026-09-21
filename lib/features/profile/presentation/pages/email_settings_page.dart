import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_providers.dart';

/// L'adresse e-mail et son état.
///
/// La vérification existe côté serveur depuis toujours et n'était exposée
/// nulle part : quelqu'un dont l'adresse n'est pas vérifiée ne recevait pas
/// ses alertes de vente et n'avait aucun moyen de le découvrir.
class EmailSettingsPage extends ConsumerStatefulWidget {
  const EmailSettingsPage({super.key});

  @override
  ConsumerState<EmailSettingsPage> createState() => _EmailSettingsPageState();
}

class _EmailSettingsPageState extends ConsumerState<EmailSettingsPage> {
  bool _envoi = false;

  Future<void> _renvoyer() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _envoi = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.emailLinkSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGenericMsg(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final utilisateur = fb.FirebaseAuth.instance.currentUser;
    final verifiee = utilisateur?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emailSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined),
            title: Text(utilisateur?.email ?? '—'),
            subtitle: Text(
              verifiee ? l10n.emailVerified : l10n.emailNotVerified,
              style: TextStyle(
                color: verifiee ? Colors.green : theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              verifiee ? Icons.verified : Icons.error_outline,
              color: verifiee ? Colors.green : theme.colorScheme.error,
            ),
          ),
          if (!verifiee) ...[
            const SizedBox(height: 8),
            // Dire à quoi sert la vérification, pas seulement qu'elle manque :
            // sans conséquence énoncée, personne ne clique.
            Text(
              l10n.emailNotVerifiedHint,
              style: TextStyle(color: theme.hintColor),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _envoi ? null : () => _renvoyer(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.emailResendLink),
            ),
          ],
        ],
      ),
    );
  }
}
