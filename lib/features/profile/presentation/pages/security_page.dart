import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';

/// Changer son mot de passe.
///
/// Firebase exige une ré-authentification avant tout changement : sans elle,
/// un téléphone laissé déverrouillé une minute suffirait à changer le mot de
/// passe et à verrouiller son propriétaire dehors. D'où la demande du mot de
/// passe actuel, qui n'est pas une formalité.
class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  static const int _longueurMinimale = 8;

  @override
  void dispose() {
    _actuel.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _changer() async {
    final l10n = AppLocalizations.of(context)!;

    if (_nouveau.text.length < _longueurMinimale) {
      setState(() => _erreur = l10n.securityTooShort);
      return;
    }
    if (_nouveau.text != _confirmation.text) {
      setState(() => _erreur = l10n.securityMismatch);
      return;
    }

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      final utilisateur = fb.FirebaseAuth.instance.currentUser!;
      await utilisateur.reauthenticateWithCredential(
        fb.EmailAuthProvider.credential(
          email: utilisateur.email!,
          password: _actuel.text,
        ),
      );
      await utilisateur.updatePassword(_nouveau.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.securityPasswordChanged)),
      );
      Navigator.of(context).pop();
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        // Deux codes pour la même cause selon la version du SDK.
        _erreur = (e.code == 'wrong-password' || e.code == 'invalid-credential')
            ? l10n.securityWrongPassword
            : e.message ?? e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final utilisateur = fb.FirebaseAuth.instance.currentUser;

    // Un compte Google ou Facebook n'a pas de mot de passe chez nous. Montrer
    // le formulaire quand même produirait une erreur incompréhensible.
    final fournisseurs =
        utilisateur?.providerData.map((p) => p.providerId).toList() ?? [];
    final avecMotDePasse = fournisseurs.contains('password');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.securityTitle)),
      body: !avecMotDePasse
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.securitySocialAccount(
                      fournisseurs.isEmpty
                          ? '—'
                          : _nomFournisseur(fournisseurs.first),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.securitySocialHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _champ(_actuel, l10n.securityCurrentPassword),
                const SizedBox(height: 16),
                _champ(_nouveau, l10n.securityNewPassword),
                const SizedBox(height: 16),
                _champ(_confirmation, l10n.securityConfirmPassword),
                if (_erreur != null) ...[
                  const SizedBox(height: 16),
                  Text(_erreur!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _envoi ? null : () => _changer(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.securityChangePassword),
                ),
              ],
            ),
    );
  }

  String _nomFournisseur(String id) {
    switch (id) {
      case 'google.com':
        return 'Google';
      case 'facebook.com':
        return 'Facebook';
      case 'apple.com':
        return 'Apple';
      default:
        return id;
    }
  }

  Widget _champ(TextEditingController controleur, String libelle) => TextField(
        controller: controleur,
        enabled: !_envoi,
        obscureText: true,
        decoration: InputDecoration(
          labelText: libelle,
          border: const OutlineInputBorder(),
        ),
      );
}
