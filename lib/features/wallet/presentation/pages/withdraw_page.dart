import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_providers.dart';
import '../../data/withdrawal_service.dart';
import '../../domain/models/withdrawal.dart';
import '../providers/withdrawal_provider.dart';
import '../../../../core/services/analytics_service.dart';

/// Demander un retrait.
///
/// Le point important de cet écran : **montrer les frais avant de valider**.
/// Demander 15 000 et en recevoir 14 850 sans l'avoir su à l'avance est la
/// meilleure façon de recevoir un message au support — et de perdre la
/// confiance qu'on venait de gagner en payant le vendeur.
class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  final _montantController = TextEditingController();
  final _destinationController = TextEditingController();
  WithdrawalMethod _methode = WithdrawalMethod.tmoney;
  bool _envoiEnCours = false;
  String? _erreur;

  @override
  void dispose() {
    _montantController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  int get _montant => int.tryParse(_montantController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final nombres = NumberFormat.decimalPattern(locale);

    final wallet = ref.watch(currentUserProvider).value?.wallet;
    final disponible = wallet?.availableAmount ?? 0;
    final enAttente = ref.watch(hasPendingWithdrawalProvider);

    final montant = _montant;
    final frais = montant >= WithdrawalFees.minimumXof
        ? WithdrawalFees.of(montant)
        : 0;
    final net = montant - frais;

    final valide = montant >= WithdrawalFees.minimumXof &&
        montant <= disponible &&
        _destinationController.text.trim().length >= 6;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.withdrawTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Le solde en premier : c'est la contrainte, autant l'annoncer.
          Card(
            child: ListTile(
              title: Text(l10n.availableAmount),
              trailing: Text(
                '${nombres.format(disponible)} FCFA',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (enAttente) ...[
            const SizedBox(height: 12),
            _Bandeau(
              icone: Icons.hourglass_bottom_outlined,
              texte: l10n.withdrawAlreadyPending,
              couleur: theme.colorScheme.onSurfaceVariant,
            ),
          ],

          const SizedBox(height: 24),
          Text(l10n.withdrawAmount, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _montantController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              suffixText: 'FCFA',
              border: const OutlineInputBorder(),
              helperText: l10n.withdrawMinimum(
                nombres.format(WithdrawalFees.minimumXof),
              ),
            ),
            onChanged: (_) => setState(() => _erreur = null),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              // Les frais étant retenus **sur** le montant, retirer tout son
              // solde marche toujours — c'est le geste le plus courant.
              onPressed: disponible >= WithdrawalFees.minimumXof
                  ? () => setState(() {
                      _montantController.text = disponible.toString();
                      _erreur = null;
                    })
                  : null,
              child: Text(l10n.withdrawAll),
            ),
          ),

          const SizedBox(height: 16),
          Text(l10n.withdrawMethod, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<WithdrawalMethod>(
            segments: [
              for (final m in WithdrawalMethod.values)
                ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {_methode},
            onSelectionChanged: (s) => setState(() => _methode = s.first),
          ),

          const SizedBox(height: 16),
          Text(l10n.withdrawDestination, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _destinationController,
            keyboardType: _methode == WithdrawalMethod.bank
                ? TextInputType.text
                : TextInputType.phone,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _methode == WithdrawalMethod.bank
                  ? l10n.withdrawDestinationBankHint
                  : l10n.withdrawDestinationPhoneHint,
            ),
            onChanged: (_) => setState(() => _erreur = null),
          ),

          // Le détail, dès que le montant est valide. Pas après validation.
          if (montant >= WithdrawalFees.minimumXof) ...[
            const SizedBox(height: 24),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Ligne(
                      libelle: l10n.withdrawAmountRequested,
                      valeur: '${nombres.format(montant)} FCFA',
                    ),
                    _Ligne(
                      libelle: l10n.withdrawFee,
                      valeur: '− ${nombres.format(frais)} FCFA',
                      discret: true,
                    ),
                    const Divider(height: 20),
                    _Ligne(
                      libelle: l10n.withdrawYouReceive,
                      valeur: '${nombres.format(net)} FCFA',
                      gras: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.withdrawFeeExplained,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (montant > disponible && montant > 0) ...[
            const SizedBox(height: 16),
            _Bandeau(
              icone: Icons.error_outline,
              texte: l10n.withdrawInsufficient,
              couleur: theme.colorScheme.error,
            ),
          ],

          if (_erreur != null) ...[
            const SizedBox(height: 16),
            _Bandeau(
              icone: Icons.error_outline,
              texte: _erreur!,
              couleur: theme.colorScheme.error,
            ),
          ],

          const SizedBox(height: 32),
          FilledButton(
            onPressed: valide && !_envoiEnCours ? _demander : null,
            child: _envoiEnCours
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.withdrawConfirm),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.withdrawManualNotice,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _demander() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    try {
      final recu = await ref.read(withdrawalServiceProvider).request(
            amountXof: _montant,
            method: _methode.wireValue,
            destination: _destinationController.text.trim(),
          );
      ref
          .read(analyticsServiceProvider)
          .logWithdrawalRequested(_montant.toDouble());
      if (!mounted) return;

      // Le solde vient de changer côté serveur : sans cette invalidation,
      // l'écran précédent affiche encore l'ancien montant.
      ref.invalidate(currentUserProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.withdrawRequested(recu.netAmountXof.toString())),
        ),
      );
      context.pop();
    } on WithdrawalException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.message;
        _envoiEnCours = false;
      });
    }
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.libelle,
    required this.valeur,
    this.gras = false,
    this.discret = false,
  });

  final String libelle;
  final String valeur;
  final bool gras;
  final bool discret;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = gras
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium?.copyWith(
            color: discret ? theme.colorScheme.onSurfaceVariant : null,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(libelle, style: style), Text(valeur, style: style)],
      ),
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({
    required this.icone,
    required this.texte,
    required this.couleur,
  });

  final IconData icone;
  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: couleur),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texte,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: couleur),
          ),
        ),
      ],
    );
  }
}
