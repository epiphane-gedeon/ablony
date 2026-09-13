import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/receipt_provider.dart';
import '../../../../core/services/delivery_confirmation_service.dart';
import '../../../delivery/data/parcel_repository.dart';
import '../../domain/models/receipt.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/buttons.dart';
import '../../../../core/responsive/responsive.dart';

/// Page de détail d'un reçu d'achat, avec téléchargement/partage en PDF.
class ReceiptPage extends ConsumerWidget {
  final String receiptId;

  const ReceiptPage({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final receiptAsync = ref.watch(receiptByIdProvider(receiptId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receiptPageTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ContentContainer(
        applyPadding: false,
        maxWidth: ContentWidth.standard,
        child: receiptAsync.when(
          data: (receipt) => _ReceiptView(receipt: receipt),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text(l10n.errorGenericMsg(error.toString()))),
        ),
      ),
    );
  }
}

class _ReceiptView extends ConsumerWidget {
  final Receipt receipt;

  const _ReceiptView({required this.receipt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final buyerAsync = ref.watch(userByIdProvider(receipt.buyerId));
    final sellerAsync = ref.watch(userByIdProvider(receipt.sellerId));
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    );
    final currentUser = ref.watch(authStateProvider).value;
    final isBuyer = currentUser?.uid == receipt.buyerId;
    final isSeller = currentUser?.uid == receipt.sellerId;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.receipt_long, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          receipt.productTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _ReceiptRow(
          label: l10n.receiptReference,
          value: receipt.transactionRef,
        ),
        _ReceiptRow(
          label: l10n.receiptDate,
          value: dateFormat.format(receipt.createdAt),
        ),
        _ReceiptRow(
          label: l10n.receiptSeller,
          value: sellerAsync.value?.username ?? '—',
        ),
        _ReceiptRow(
          label: l10n.receiptBuyer,
          value: buyerAsync.value?.username ?? '—',
        ),
        _ReceiptRow(
          label: l10n.receiptPaymentMethod,
          value: receipt.paymentMethod,
        ),
        const Divider(height: 32),
        _ReceiptRow(
          label: l10n.receiptProductPrice,
          value: '${receipt.productPrice.toStringAsFixed(0)} FCFA',
        ),
        _ReceiptRow(
          label: l10n.receiptTotalPaid,
          value: '${receipt.totalAmount.toStringAsFixed(0)} FCFA',
          isBold: true,
        ),
        // Le vendeur n'a qu'une chose à faire, et elle doit être à portée de
        // main : imprimer l'étiquette, coller, déposer.
        if (isSeller && receipt.parcelCode != null) ...[
          const SizedBox(height: 32),
          SecondaryButton(
            text: l10n.parcelLabelButton,
            icon: Icons.local_shipping_outlined,
            onPressed: () => context.push(
              '/delivery/label/${receipt.parcelCode}',
            ),
          ),
        ],
        if (isBuyer && !receipt.deliveryConfirmed) ...[
          const SizedBox(height: 32),
          if (receipt.parcelCode != null) ...[
            _ReceiptRow(
              label: l10n.receiptParcelCode,
              value: receipt.parcelCode!,
            ),
            _SuiviColis(code: receipt.parcelCode!),
            const SizedBox(height: 12),
          ],
          SecondaryButton(
            text: l10n.confirmDeliveryButton,
            icon: Icons.check_circle_outline,
            onPressed: () => _confirmReception(context, ref, l10n, receipt),
          ),
        ] else if (isBuyer && receipt.deliveryConfirmed) ...[
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 18, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                l10n.deliveryAlreadyConfirmed,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          text: l10n.receiptDownloadButton,
          icon: Icons.download_outlined,
          onPressed: () => _downloadReceipt(
            context,
            receipt,
            buyerAsync.value?.username,
            sellerAsync.value?.username,
            dateFormat,
          ),
        ),
      ],
    );
  }

  Future<void> _downloadReceipt(
    BuildContext context,
    Receipt receipt,
    String? buyerUsername,
    String? sellerUsername,
    DateFormat dateFormat,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Ablony',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Reçu d\'achat',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 24),
                _pdfRow('Article', receipt.productTitle),
                _pdfRow('Référence', receipt.transactionRef),
                _pdfRow('Date', dateFormat.format(receipt.createdAt)),
                _pdfRow('Vendeur', sellerUsername ?? receipt.sellerId),
                _pdfRow('Acheteur', buyerUsername ?? receipt.buyerId),
                _pdfRow('Moyen de paiement', receipt.paymentMethod),
                pw.Divider(),
                _pdfRow(
                  'Prix de l\'article',
                  '${receipt.productPrice.toStringAsFixed(0)} FCFA',
                ),
                _pdfRow(
                  'Total payé',
                  '${receipt.totalAmount.toStringAsFixed(0)} FCFA',
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await doc.save();
    if (!context.mounted) return;

    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'recu_${receipt.transactionRef}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGenericMsg(e.toString()))),
        );
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Demande confirmation, puis débloque le paiement du vendeur.
///
/// Un dialogue, et non un scan : l'acheteur reçoit son colis d'un point relais
/// ou d'un livreur Ablony, jamais des mains du vendeur. Lui demander de
/// scanner l'écran de quelqu'un qu'il ne rencontrera pas n'avait pas de sens.
Future<void> _confirmReception(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  Receipt receipt,
) async {
  final confirme = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.confirmDeliveryTitle),
      content: Text(l10n.confirmDeliveryQuestion),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: Text(l10n.confirmDeliveryConfirm),
        ),
      ],
    ),
  );
  if (confirme != true || !context.mounted) return;

  try {
    await ref
        .read(deliveryConfirmationServiceProvider)
        .confirmDelivery(transactionRef: receipt.transactionRef);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deliveryConfirmedSuccess)),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

/// Où en est le colis, en une ligne.
///
/// L'état vient du colis lui-même, alimenté par les scans de nos agents : ni
/// l'acheteur ni le vendeur ne l'écrivent. C'est ce qui permet à l'acheteur
/// de savoir où en est sa commande sans avoir à croire le vendeur sur parole.
class _SuiviColis extends ConsumerWidget {
  final String code;

  const _SuiviColis({required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final parcel = ref.watch(parcelByCodeProvider(code)).value;
    if (parcel == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(parcel.status.icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parcel.status.buyerLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
