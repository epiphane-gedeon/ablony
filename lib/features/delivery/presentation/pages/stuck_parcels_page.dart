import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../data/parcel_scan_service.dart';
import '../../domain/models/stuck_parcel.dart';
import '../providers/stuck_parcels_provider.dart';
import '../widgets/agent_parcel_sheet.dart';

/// Ce qui n'avance plus, et attend une décision.
///
/// C'est la porte de sortie du système : rien ne se libère sans qu'un agent
/// ait constaté la remise, ce qui est sûr mais laisse un vendeur bloqué quand
/// le scan a été oublié. Cette liste rend le silence visible.
class StuckParcelsPage extends ConsumerWidget {
  const StuckParcelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final parcels = ref.watch(stuckParcelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stuckParcelsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: l10n.scanParcelStaff,
            onPressed: () => context.pushNamed('scan_parcel'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(stuckParcelsProvider),
        child: parcels.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('$e', textAlign: TextAlign.center)),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(l10n.stuckParcelsEmpty)),
                ],
              );
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _StuckTile(parcel: list[i]),
            );
          },
        ),
      ),
    );
  }
}

enum _Action { checkpoint, refund, release }

class _StuckTile extends ConsumerWidget {
  const _StuckTile({required this.parcel});

  final StuckParcel parcel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isAdmin =
        ref.watch(currentUserProvider).value?.role == UserRole.admin;

    final (color, reason) = switch (parcel.reason) {
      StuckReason.neverDroppedOff => (
        theme.colorScheme.error,
        l10n.stuckNeverDroppedOff,
      ),
      StuckReason.inTransitTooLong => (
        Colors.orange.shade800,
        l10n.stuckInTransitTooLong,
      ),
      StuckReason.waitingAtRelay => (
        theme.colorScheme.onSurfaceVariant,
        l10n.stuckWaitingAtRelay,
      ),
    };

    return ListTile(
      isThreeLine: true,
      leading: Container(width: 4, height: 48, color: color),
      title: Text(
        parcel.productTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reason, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          Text(
            [
              parcel.code,
              if (parcel.createdAt != null)
                DateFormat.yMMMd(locale).format(parcel.createdAt!),
              // Le fait qui tranche le plus de dossiers : l'acheteur a eu le
              // colis en main, même s'il n'a rien confirmé ensuite.
              if (parcel.buyerScannedAt != null) l10n.stuckBuyerScanned,
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      trailing: PopupMenuButton<_Action>(
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _Action.checkpoint,
            child: Text(l10n.parcelRecordStep),
          ),
          // Rembourser est le seul geste qui sorte l'argent du séquestre sans
          // qu'aucune remise n'ait été constatée. Réservé à l'administration,
          // et le serveur le revérifie : masquer l'entrée n'est qu'un confort.
          if (isAdmin) ...[
            PopupMenuItem(value: _Action.refund, child: Text(l10n.refundBuyer)),
            PopupMenuItem(
              value: _Action.release,
              child: Text(l10n.releaseSeller),
            ),
          ],
        ],
        onSelected: (action) => switch (action) {
          _Action.checkpoint => _openSheet(context, ref),
          _Action.refund => _decide(context, ref, refund: true),
          _Action.release => _decide(context, ref, refund: false),
        },
      ),
      onTap: () => _openSheet(context, ref),
    );
  }

  /// Ouvre la même fiche que celle d'un scan : les gestes doivent être les
  /// mêmes, qu'on arrive par la caméra ou par la file.
  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    try {
      final resolved =
          await ref.read(parcelScanServiceProvider).resolve(parcel.code);
      if (!context.mounted) return;
      final done = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AgentParcelSheet(parcel: resolved),
      );
      if (done == true) ref.invalidate(stuckParcelsProvider);
    } on ParcelScanException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Les deux issues possibles d'une vente bloquée. L'argent va à l'un ou à
  /// l'autre : il n'y a pas de troisième voie, et Ablony ne le garde jamais.
  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required bool refund,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final title = refund ? l10n.refundBuyer : l10n.releaseSeller;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Le motif part aux deux parties : il doit expliquer, pas
            // seulement laisser une trace.
            Text(l10n.refundReasonHint),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.refundReasonLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(title),
          ),
        ],
      ),
    );

    final reason = controller.text.trim();
    if (confirmed != true || reason.isEmpty || !context.mounted) return;

    try {
      final service = ref.read(parcelScanServiceProvider);
      if (refund) {
        await service.refund(
          transactionRef: parcel.transactionRef,
          reason: reason,
        );
      } else {
        await service.release(
          transactionRef: parcel.transactionRef,
          reason: reason,
        );
      }
      if (!context.mounted) return;
      ref.invalidate(stuckParcelsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(refund ? l10n.refundDone : l10n.releaseDone)),
      );
    } on ParcelScanException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
