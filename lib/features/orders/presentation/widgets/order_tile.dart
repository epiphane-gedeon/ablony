import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/order_summary.dart';

/// Une commande, en une ligne.
///
/// Elle doit répondre à « où en est ma commande ? » sans qu'on l'ouvre. Et
/// quand un geste est attendu, il est **en bouton** — un libellé de plus au
/// milieu d'autres libellés se lit comme de l'information, et personne n'agit.
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.commande});

  final OrderSummary commande;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final montant = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    ).format(commande.amountXof);

    final etat = _etat(l10n, montant);
    final urgent = commande.appelleUnGeste;

    return InkWell(
      onTap: () => context.push('/receipt/${commande.transactionRef}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
          ),
          // Une bande à gauche sur les seules lignes qui appellent un geste :
          // on repère ce qu'il y a à faire sans lire.
          gradient: urgent
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.01, 0.01],
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 64,
                height: 64,
                child: commande.productImage != null
                    ? Image.network(
                        commande.productImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _vignetteVide(theme),
                      )
                    : _vignetteVide(theme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commande.productTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$montant FCFA',
                    style: TextStyle(color: theme.hintColor, fontSize: 13),
                  ),
                  if (_pastilleSuivi(theme) != null) ...[
                    const SizedBox(height: 6),
                    _pastilleSuivi(theme)!,
                  ],
                  const SizedBox(height: 6),
                  Text(
                    etat,
                    style: TextStyle(
                      fontWeight: urgent ? FontWeight.bold : FontWeight.normal,
                      color: urgent
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  if (commande.estRembourse &&
                      (commande.refundReason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      commande.refundReason!,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ],
                  if (_bouton(context, l10n) != null) ...[
                    const SizedBox(height: 8),
                    _bouton(context, l10n)!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vignetteVide(ThemeData theme) => Container(
        color: theme.dividerColor.withValues(alpha: 0.2),
        child: Icon(Icons.image_outlined, color: theme.hintColor),
      );

  /// Pastille de suivi : l'état du colis quand il est entre nos mains, pour le
  /// voir d'un coup d'œil dans la liste. Rien avant le dépôt (la ligne d'état
  /// dit déjà quoi faire) ni après la remise (le reçu le dit).
  Widget? _pastilleSuivi(ThemeData theme) {
    const labels = {
      'dropped_off': 'Déposé',
      'in_transit': 'En acheminement',
      'ready_for_pickup': 'En point relais',
      'out_for_delivery': 'En livraison',
    };
    final label = labels[commande.parcelStatus];
    if (label == null) return null;
    final c = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  String _etat(AppLocalizations l10n, String montant) {
    if (commande.estRembourse) {
      return commande.side == OrderSide.sale
          ? l10n.orderCancelled
          : l10n.orderRefunded(montant);
    }
    if (commande.deliveryConfirmed) {
      return commande.side == OrderSide.sale
          ? l10n.orderPaid(montant)
          : l10n.orderReceived;
    }

    switch (commande.action) {
      case OrderAction.dropOff:
        final limite = commande.dropoffDeadline;
        if (limite == null) return l10n.orderPrintLabel;
        if (limite.isBefore(DateTime.now())) return l10n.orderDropOffLate;
        return l10n.orderDropOffBy(DateFormat('d MMMM').format(limite));
      case OrderAction.confirmReception:
        return l10n.orderConfirmReception;
      case OrderAction.pickUp:
        return l10n.orderAwaitingPickup;
      case OrderAction.track:
        return l10n.orderInTransit;
      case OrderAction.none:
        if (commande.parcelStatus == 'awaiting_dropoff') {
          return l10n.orderSellerPreparing;
        }
        if (commande.parcelStatus == 'delivered') {
          return l10n.orderDeliveredWaiting;
        }
        return l10n.orderInTransit;
    }
  }

  Widget? _bouton(BuildContext context, AppLocalizations l10n) {
    switch (commande.action) {
      case OrderAction.dropOff:
        if (commande.parcelCode == null) return null;
        return FilledButton.tonal(
          onPressed: () =>
              context.push('/delivery/label/${commande.parcelCode}'),
          child: Text(l10n.orderPrintLabel),
        );
      case OrderAction.confirmReception:
        return FilledButton.tonal(
          onPressed: () => context.push('/receipt/${commande.transactionRef}'),
          child: Text(l10n.orderConfirmReception),
        );
      case OrderAction.pickUp:
      case OrderAction.track:
        return TextButton(
          onPressed: () => context.push('/receipt/${commande.transactionRef}'),
          child: Text(l10n.orderTrack),
        );
      // Les lignes qui n'attendent rien ne portent aucun bouton : un bouton
      // partout ne distingue plus rien.
      case OrderAction.none:
        return null;
    }
  }
}
