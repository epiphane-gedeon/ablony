import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/wallet_entry.dart';
import '../providers/wallet_entry_provider.dart';

/// Le relevé du porte-monnaie.
///
/// Un solde est un nombre ; il ne dit pas d'où il vient. Cet écran est ce
/// qu'on ouvre quand on ne comprend pas son solde — et c'est aussi ce qu'on
/// demande à quelqu'un de regarder avant de répondre à « il me manque de
/// l'argent ». Chaque ligne porte donc sa référence : c'est elle qu'on cite.
class WalletStatementPage extends ConsumerWidget {
  const WalletStatementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entries = ref.watch(walletEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walletStatement)),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: Icons.cloud_off_outlined,
          title: l10n.walletStatementError,
        ),
        data: (list) {
          if (list.isEmpty) {
            return _Message(
              icon: Icons.receipt_long_outlined,
              title: l10n.walletStatementEmpty,
              detail: l10n.walletStatementEmptyDetail,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _EntryTile(entry: list[i]),
          );
        },
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final amounts = NumberFormat.decimalPattern(locale);

    final isCredit = entry.kind.isCredit;
    // Le séquestre n'est ni un isCredit franc ni un débit : l'argent est acquis
    // mais pas encore disponible. Le montrer en vert laisserait croire qu'on
    // peut le retirer.
    // Deux situations « en attente » : une vente non confirmée, et un retrait
    // demandé mais pas encore versé. Toutes deux se lisent en gris.
    final onHold = entry.kind == WalletEntryKind.salePending || entry.isPending;
    final color = onHold
        ? theme.colorScheme.onSurfaceVariant
        : isCredit
        ? const Color(0xFF1B7F4C)
        : theme.colorScheme.onSurface;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(entry.icon, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(
        _title(l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        '${DateFormat.yMMMd(locale).add_Hm().format(entry.createdAt)}'
        ' · ${entry.reference}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isCredit ? '+' : '−'}${amounts.format(entry.amountXof)} FCFA',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onHold)
            Text(
              entry.isPending
                  ? l10n.withdrawPending
                  : l10n.walletEntryOnHold,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
        ],
      ),
      onTap: entry.parcelCode == null
          ? null
          : () => context.pushNamed(
              'parcel_label',
              pathParameters: {'parcelCode': entry.parcelCode!},
            ),
    );
  }

  String _title(AppLocalizations l10n) => switch (entry.kind) {
    WalletEntryKind.topUp => l10n.walletEntryTopUp,
    WalletEntryKind.purchase => l10n.walletEntryPurchase,
    WalletEntryKind.boost => l10n.walletEntryBoost,
    WalletEntryKind.refund => l10n.walletEntryRefund,
    WalletEntryKind.withdrawal => l10n.walletEntryWithdrawal,
    WalletEntryKind.withdrawalRefund => l10n.walletEntryWithdrawalRefund,
    WalletEntryKind.salePending ||
    WalletEntryKind.saleReleased => entry.label ?? l10n.walletEntrySale,
  };
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.detail});

  final IconData icon;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
