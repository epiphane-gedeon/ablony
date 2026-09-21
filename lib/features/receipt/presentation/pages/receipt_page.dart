import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/receipt_provider.dart';
import '../../../../core/services/delivery_confirmation_service.dart';
import '../../../delivery/data/parcel_repository.dart';
import '../../../delivery/domain/models/delivery_choice.dart';
import '../../../delivery/domain/models/parcel.dart';
import '../../domain/models/receipt.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dispute/domain/models/dispute.dart';
import '../../../dispute/presentation/providers/dispute_provider.dart';
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

/// L'état du dossier, sur le reçu.
///
/// L'acheteur qui a signalé doit voir que son signalement existe : sans
/// preuve visible, il recommence, ou il écrit ailleurs.
class _BandeauLitige extends StatelessWidget {
  const _BandeauLitige({required this.litige, required this.estAcheteur});

  final Dispute litige;
  final bool estAcheteur;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ouvert = litige.status.estOuvert;

    final String titre;
    final String detail;
    if (ouvert) {
      titre = l10n.disputeUnderReview;
      detail = l10n.disputeUnderReviewHint;
    } else if (litige.status == DisputeStatus.refunded) {
      titre = l10n.disputeResolvedRefunded;
      detail = litige.resolutionNote ?? '';
    } else {
      titre = l10n.disputeResolvedReleased;
      detail = litige.resolutionNote ?? '';
    }

    final couleur = ouvert ? Colors.orange : Colors.blueGrey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.shade50,
        border: Border.all(color: couleur.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ouvert ? Icons.hourglass_top : Icons.gavel,
                size: 18,
                color: couleur.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: couleur.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(detail, style: TextStyle(color: couleur.shade900)),
          ],
          // Dit à celui qui n'a pas ouvert le dossier d'où il vient.
          if (ouvert && !litige.ouvertPar(estAcheteur ? litige.buyerId : litige.sellerId)) ...[
            const SizedBox(height: 6),
            Text(
              l10n.disputeOpenedByOther,
              style: TextStyle(fontSize: 13, color: couleur.shade800),
            ),
          ],
        ],
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

    // Un litige ouvert change ce que la page propose : confirmer la réception
    // paierait le vendeur qu'on conteste. Le serveur le refuserait de toute
    // façon, mais laisser le bouton, c'est promettre une action impossible.
    final litige = ref
        .watch(disputeForTransactionProvider(receipt.transactionRef))
        .value;
    final litigeOuvert = litige?.status.estOuvert ?? false;

    final montantEnAvant = isSeller
        ? receipt.productPrice
        : receipt.totalAmount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── En-tête : ce que la commande est, et le montant qui compte ──
        _EnTete(
          titre: isSeller ? l10n.receiptSaleTitle : l10n.receiptPurchaseTitle,
          article: receipt.productTitle,
          montant: montantEnAvant,
          // Le vendeur touche le prix de l'article ; l'acheteur a payé le
          // total, frais compris. Afficher le même chiffre aux deux ferait
          // croire au vendeur qu'on lui prélève une commission, ou qu'il
          // encaisse des frais qu'il n'encaisse pas.
          libelleMontant:
              isSeller ? l10n.receiptYouReceive : l10n.receiptTotalPaidLabel,
          indice: isSeller ? l10n.receiptYouReceiveHint : null,
        ),

        // ── Un litige prime tout : il change ce que la page propose ──────
        if (litige != null) ...[
          const SizedBox(height: 16),
          _BandeauLitige(litige: litige, estAcheteur: isBuyer),
        ],

        // ── Détails de la transaction ───────────────────────────────────
        const SizedBox(height: 16),
        _Carte(
          titre: l10n.receiptDetails,
          enfants: [
            _ReceiptRow(
              label: l10n.receiptReference,
              value: receipt.transactionRef,
            ),
            _ReceiptRow(
              label: l10n.receiptDate,
              value: dateFormat.format(receipt.createdAt),
            ),
            // Le moyen de paiement est celui par lequel l'acheteur a réglé.
            // Le vendeur, lui, est toujours crédité sur son porte-monnaie
            // Ablony, quel que soit ce moyen : le lui montrer n'apporte rien
            // et laisse croire qu'il le concerne.
            if (isBuyer)
              _ReceiptRow(
                label: l10n.receiptPaymentMethod,
                value: receipt.paymentMethod,
              ),
            const Divider(height: 20),
            _ReceiptRow(
              label: l10n.receiptProductPrice,
              value: '${receipt.productPrice.toStringAsFixed(0)} FCFA',
            ),
            // Le total n'est montré qu'à l'acheteur : c'est lui qui l'a payé.
            if (isBuyer)
              _ReceiptRow(
                label: l10n.receiptTotalPaid,
                value: '${receipt.totalAmount.toStringAsFixed(0)} FCFA',
                isBold: true,
              ),
          ],
        ),

        // ── Parties ─────────────────────────────────────────────────────
        const SizedBox(height: 12),
        _Carte(
          titre: l10n.receiptParties,
          enfants: [
            _ReceiptRow(
              label: l10n.receiptSeller,
              value: sellerAsync.value?.username ?? '—',
            ),
            _ReceiptRow(
              label: l10n.receiptBuyer,
              value: buyerAsync.value?.username ?? '—',
            ),
          ],
        ),

        // ── Livraison : le code, le suivi, et l'état ────────────────────
        if (receipt.parcelCode != null) ...[
          const SizedBox(height: 12),
          _Carte(
            titre: l10n.receiptDeliverySection,
            enfants: [
              _ReceiptRow(
                label: l10n.receiptParcelCode,
                value: receipt.parcelCode!,
              ),
              _SuiviColis(code: receipt.parcelCode!),
              if (receipt.deliveryConfirmed) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 18, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      l10n.deliveryAlreadyConfirmed,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],

        // ── Actions, groupées, selon le rôle et l'état ──────────────────
        const SizedBox(height: 16),

        // Le vendeur n'a qu'une chose à faire : imprimer l'étiquette.
        if (isSeller && receipt.parcelCode != null) ...[
          SecondaryButton(
            text: l10n.parcelLabelButton,
            icon: Icons.local_shipping_outlined,
            onPressed: () => context.push(
              '/delivery/label/${receipt.parcelCode}',
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (isBuyer && !receipt.deliveryConfirmed && !litigeOuvert) ...[
          // Scanner d'abord, décider ensuite : le scan atteste qu'on a le
          // colis en main, il ne libère rien.
          if (receipt.parcelCode != null) ...[
            SecondaryButton(
              text: l10n.scanParcelBuyer,
              icon: Icons.qr_code_scanner,
              onPressed: () => context.pushNamed('scan_parcel'),
            ),
            const SizedBox(height: 12),
          ],
          SecondaryButton(
            text: l10n.confirmDeliveryButton,
            icon: Icons.check_circle_outline,
            onPressed: () => _confirmReception(context, ref, l10n, receipt),
          ),
          const SizedBox(height: 12),
        ],

        // Signaler un problème : sous les actions positives, jamais au-dessus.
        // La grande majorité des commandes se passent bien.
        if (!receipt.deliveryConfirmed && !litigeOuvert && (isBuyer || isSeller))
          Center(
            child: TextButton.icon(
              onPressed: () => context.push(
                '/receipt/${receipt.transactionRef}/probleme'
                '${isSeller ? '?role=seller' : ''}',
              ),
              icon: const Icon(Icons.report_problem_outlined, size: 18),
              label: Text(l10n.disputeOpen),
            ),
          ),

        // Le reçu d'achat est le document de l'acheteur : c'est lui qui a
        // payé, et c'est son total qui y figure. Le vendeur, lui, suit sa
        // vente par son porte-monnaie et sa liste de ventes.
        if (isBuyer) ...[
          const SizedBox(height: 8),
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

    // Le bleu de la marque, pour que le PDF ressemble à l'application.
    const bleu = PdfColor.fromInt(0xFF2385AE);

    // Le logo, chargé depuis les assets. Sur fond blanc, il s'affiche quelle
    // que soit sa couleur — un bandeau bleu masquerait un logo bleu.
    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      // Le PDF reste valide sans logo plutôt que d'échouer.
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Bandeau bleu : le logo de la marque est blanc, il lui faut
              // un fond coloré pour se voir.
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(28),
                color: bleu,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logo != null)
                      pw.Image(logo, height: 40)
                    else
                      pw.Text(
                        'Ablony',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Reçu d\'achat',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      receipt.productTitle,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 24),
                    _pdfRow(l10n.receiptReference, receipt.transactionRef),
                    _pdfRow(l10n.receiptDate, dateFormat.format(receipt.createdAt)),
                    _pdfRow(l10n.receiptSeller, sellerUsername ?? receipt.sellerId),
                    _pdfRow(l10n.receiptBuyer, buyerUsername ?? receipt.buyerId),
                    _pdfRow(l10n.receiptPaymentMethod, receipt.paymentMethod),
                    pw.Divider(color: PdfColors.grey300),
                    _pdfRow(
                      l10n.receiptProductPrice,
                      '${receipt.productPrice.toStringAsFixed(0)} FCFA',
                    ),
                    pw.SizedBox(height: 8),
                    // Le total en évidence : c'est le chiffre du document.
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFEAF4F9),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(l10n.receiptTotalPaid,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                            '${receipt.totalAmount.toStringAsFixed(0)} FCFA',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: bleu,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      // Confirmer la réception est le seul moment où l'acheteur a de quoi juger
      // le vendeur : on enchaîne sur la notation. La refonte du parcours de
      // livraison (passage au colis Ablony) avait supprimé le scan QR qui y
      // menait — sans le rebrancher ici, plus personne ne pouvait noter.
      context.push('/rate-seller', extra: {
        'transactionRef': receipt.transactionRef,
        'sellerId': receipt.sellerId,
        'productId': receipt.productId,
        'productTitle': receipt.productTitle,
      });
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
/// L'en-tête du reçu : l'article, et le montant qui compte pour ce rôle.
///
/// Le montant est l'élément qu'on cherche des yeux en ouvrant un reçu. Il est
/// donc grand, encadré, isolé — la même hiérarchie que le « montant à
/// envoyer » de la console d'administration, pour la même raison : ce chiffre
/// ne doit jamais se confondre avec un autre.
class _EnTete extends StatelessWidget {
  const _EnTete({
    required this.titre,
    required this.article,
    required this.montant,
    required this.libelleMontant,
    this.indice,
  });

  final String titre;
  final String article;
  final double montant;
  final String libelleMontant;
  final String? indice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaire = theme.colorScheme.primary;
    final montantFmt = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    ).format(montant);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaire.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaire.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, size: 20, color: primaire),
              const SizedBox(width: 8),
              Text(
                titre.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: primaire,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            article,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            libelleMontant,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$montantFmt FCFA',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaire,
              // Les chiffres de montants s'alignent en colonne d'un reçu à
              // l'autre.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (indice != null) ...[
            const SizedBox(height: 6),
            Text(
              indice!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une carte de section : un intitulé discret, un contenu encadré.
///
/// Regrouper plutôt qu'empiler : détails, parties et livraison sont trois
/// choses distinctes, et une longue liste de lignes séparées par des traits
/// ne le montre pas.
class _Carte extends StatelessWidget {
  const _Carte({required this.titre, required this.enfants});

  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            titre.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(children: enfants),
        ),
      ],
    );
  }
}

class _SuiviColis extends ConsumerWidget {
  final String code;

  const _SuiviColis({required this.code});

  static String _labelCourt(ParcelStatus s) => switch (s) {
    ParcelStatus.droppedOff => 'Déposé',
    ParcelStatus.inTransit => 'En acheminement',
    ParcelStatus.readyForPickup => 'Arrivé en point relais',
    ParcelStatus.outForDelivery => 'En livraison',
    ParcelStatus.delivered => 'Remis',
    _ => s.buyerLabel,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final parcel = ref.watch(parcelByCodeProvider(code)).value;
    if (parcel == null) return const SizedBox.shrink();

    // Tant qu'aucun dépôt n'a été scanné, nous ne savons rien du colis
    // physique. Afficher « en attente du dépôt par le vendeur » reviendrait à
    // désigner un coupable sur la foi d'une absence d'information — et le
    // colis est peut-être déjà en route. On dit donc ce qu'on sait.
    if (parcel.status == ParcelStatus.awaitingDropoff) {
      return _EtatSimple(
        icon: Icons.schedule_outlined,
        texte: l10n.parcelNoTrackingYet,
        couleur: theme.colorScheme.primary,
      );
    }
    // Sorties hors parcours : une frise n'aurait pas de sens.
    if (parcel.status == ParcelStatus.returned ||
        parcel.status == ParcelStatus.lost) {
      return _EtatSimple(
        icon: parcel.status.icon,
        texte: parcel.status.buyerLabel,
        couleur: theme.colorScheme.error,
      );
    }

    // Le dernier maillon dépend du mode : point relais OU livraison à domicile.
    final dernier = parcel.method == DeliveryMethod.home
        ? ParcelStatus.outForDelivery
        : ParcelStatus.readyForPickup;
    final etapes = <ParcelStatus>[
      ParcelStatus.droppedOff,
      ParcelStatus.inTransit,
      dernier,
      ParcelStatus.delivered,
    ];
    final fmt = DateFormat('dd/MM HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < etapes.length; i++)
          _EtapeFrise(
            label: _labelCourt(etapes[i]),
            date: parcel.stepsAt[etapes[i]],
            fait: parcel.status.sequenceIndex > etapes[i].sequenceIndex,
            actuel: parcel.status == etapes[i],
            dernier: i == etapes.length - 1,
            fmt: fmt,
          ),
      ],
    );
  }
}

/// Un état de colis résumé en une ligne (pas encore déposé, retourné, égaré).
class _EtatSimple extends StatelessWidget {
  final IconData icon;
  final String texte;
  final Color couleur;

  const _EtatSimple({
    required this.icon,
    required this.texte,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: couleur),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: couleur,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une étape de la frise : une pastille (faite / en cours / à venir), le
/// libellé, et l'heure de passage si elle est connue.
class _EtapeFrise extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool fait;
  final bool actuel;
  final bool dernier;
  final DateFormat fmt;

  const _EtapeFrise({
    required this.label,
    required this.date,
    required this.fait,
    required this.actuel,
    required this.dernier,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atteint = fait || actuel;
    final actif = theme.colorScheme.primary;
    final inactif = theme.colorScheme.outline;
    final couleur = atteint ? actif : inactif;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colonne pastille + trait de liaison vers l'étape suivante.
          Column(
            children: [
              Icon(
                actuel
                    ? Icons.radio_button_checked
                    : fait
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                size: 18,
                color: couleur,
              ),
              if (!dernier)
                Expanded(
                  child: Container(
                    width: 2,
                    color: fait ? actif : inactif.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Padding(
            padding: EdgeInsets.only(bottom: dernier ? 0 : 14, top: 1),
            child: Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: atteint
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                    fontWeight: actuel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    fmt.format(date!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
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
