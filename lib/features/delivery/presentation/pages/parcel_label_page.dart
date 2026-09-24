import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/app_mode.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../data/parcel_seller_service.dart';
import '../../domain/models/parcel.dart';

/// L'étiquette que le vendeur imprime et colle sur son colis.
///
/// Remplace l'ancien « code de remise » : le vendeur y affichait un QR que
/// l'acheteur devait scanner en main propre. Ablony achemine lui-même les
/// colis — les deux personnes ne se rencontrent jamais, et ce geste n'avait
/// donc jamais lieu.
///
/// Le code est affiché **deux fois**, en QR et en clair. Le QR est pour la
/// douchette de nos agents ; le texte est pour l'humain, quand l'étiquette
/// s'est froissée ou que le téléphone n'arrive pas à lire. L'alphabet exclut
/// O/0 et I/1 pour qu'on puisse le dicter sans se tromper.
class ParcelLabelPage extends ConsumerWidget {
  final Parcel parcel;

  const ParcelLabelPage({super.key, required this.parcel});

  /// Génère l'étiquette en PDF et ouvre la feuille de partage/impression.
  ///
  /// Le QR est dessiné par le paquet `pdf` lui-même (`pw.BarcodeWidget`), pas
  /// rasterisé depuis l'écran : l'impression reste nette à toute taille. Le
  /// code figure aussi en clair, comme à l'écran, pour le cas où le QR ne se
  /// lit pas.
  /// Force toutes les couleurs d'un SVG au bleu de la marque, pour un logo
  /// monochrome affiché en bleu quel que soit son remplissage d'origine.
  /// `fill="none"` est préservé (sinon on remplirait les vides).
  String _svgEnBleu(String svg) {
    const bleu = '#2385AE';
    return svg
        .replaceAllMapped(
          RegExp(r'fill="(?!none)[^"]*"'),
          (_) => 'fill="$bleu"',
        )
        .replaceAllMapped(
          RegExp(r'stroke="(?!none)[^"]*"'),
          (_) => 'stroke="$bleu"',
        )
        .replaceAll('currentColor', bleu)
        .replaceAll(RegExp(r'fill:\s*(?!none)#?[0-9a-zA-Z(),.%\s]+'), 'fill:$bleu');
  }

  Future<void> _downloadLabel(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Logo : un SVG (recoloré en bleu) de préférence, net à l'impression ;
      // repli sur le PNG s'il n'y a pas de SVG.
      pw.Widget? logo;
      try {
        final svg = await rootBundle.loadString('assets/icons/logo_full.svg');
        // Le logo est blanc (fait pour le splash sombre) : on le recolore en
        // bleu pour qu'il ressorte sur le fond blanc de l'étiquette.
        logo = pw.SvgImage(svg: _svgEnBleu(svg), height: 64);
      } catch (_) {
        try {
          final data = await rootBundle.load('assets/images/logo.png');
          logo = pw.Image(pw.MemoryImage(data.buffer.asUint8List()), height: 60);
        } catch (_) {
          // L'étiquette reste valide sans logo.
        }
      }

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            // Volontairement minimal : le logo, le QR et le code, rien d'autre.
            // Pas de nom de produit ni de date de dépôt — l'étiquette continue
            // de servir après le dépôt (scans agents à chaque étape).
            return pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(32),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logo != null) ...[
                      logo,
                      pw.SizedBox(height: 28),
                    ],
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: parcel.code,
                      width: 240,
                      height: 240,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      parcel.code,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 3,
                        font: pw.Font.courierBold(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'etiquette-${parcel.code}.pdf',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.parcelLabelError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    );
    // En mode « beg », le vendeur ne dépose plus en relais : un livreur Ablony
    // vient chercher le colis (collecte gratuite). Le paiement du ramassage est
    // donc masqué.
    final bool beg = ref.watch(currentAppModeProvider) == AppMode.beg;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.parcelLabelTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (parcel.status.needsSellerAction && parcel.isSelfShip)
            _Consigne(
              icon: Icons.local_shipping_outlined,
              titre: 'À expédier vous-même',
              texte:
                  'Vous avez choisi que le vendeur expédie « ${parcel.productTitle} ». '
                  'Convenez du transport avec l\'acheteur dans la discussion, '
                  'envoyez le colis, puis déclarez l\'expédition ci-dessous '
                  'avec une preuve.',
              couleur: theme.colorScheme.primary,
            )
          else if (parcel.status.needsSellerAction && beg)
            _Consigne(
              icon: Icons.inventory_2_outlined,
              titre: 'Tenez le colis prêt',
              texte:
                  'Emballez « ${parcel.productTitle} » et collez ce code bien à '
                  'plat sur le carton. Un livreur Ablony viendra le récupérer '
                  'chez vous — restez joignable.',
              couleur: theme.colorScheme.primary,
            )
          else if (parcel.status.needsSellerAction)
            _Consigne(
              icon: Icons.inventory_2_outlined,
              titre: 'À faire maintenant',
              texte:
                  'Emballez « ${parcel.productTitle} », collez ce code bien à '
                  'plat sur le carton, puis déposez-le dans un point relais '
                  'Ablony. Votre part s\'arrête là.',
              couleur: theme.colorScheme.primary,
            )
          else
            _Consigne(
              icon: Icons.check_circle_outline,
              titre: 'Colis pris en charge',
              texte:
                  'Le colis est entre nos mains. Vous n\'avez plus rien à '
                  'faire : le paiement suivra la livraison.',
              couleur: Colors.green,
            ),
          const SizedBox(height: 24),

          // L'étiquette elle-même. Fond blanc et bordure nette : elle est
          // faite pour être imprimée ou photographiée, pas contemplée.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: parcel.code,
                  size: 220,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'CODE DU COLIS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  parcel.code,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Télécharger l'étiquette en PDF, pour l'imprimer et la coller sur le
          // carton. Le vrai geste attendu du vendeur : le QR + le code, prêts à
          // l'impression, sur une page A4 propre.
          FilledButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: Text(AppLocalizations.of(context)!.parcelLabelDownload),
            onPressed: () => _downloadLabel(context),
          ),
          const SizedBox(height: 4),

          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: Text(AppLocalizations.of(context)!.parcelLabelCopyCode),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: parcel.code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.parcelLabelCodeCopied)),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Auto-expédition : déclaration + preuve + suivi de la modération.
          if (parcel.status.needsSellerAction && parcel.isSelfShip)
            _SelfShipAction(parcel: parcel),

          // Modèle relais/domicile (non auto-expédition).
          if (parcel.status.needsSellerAction && !parcel.isSelfShip) ...[
            // Ramassage payant : seulement en mode « def ». En « beg » la
            // collecte chez le vendeur est déjà le modèle (gratuite).
            if (!beg) ...[
              if (parcel.pickupRequested)
                _Consigne(
                  icon: Icons.local_shipping_outlined,
                  titre: 'Ramassage demandé',
                  texte:
                      'Un agent viendra récupérer le colis à l\'adresse que '
                      'vous avez indiquée. Gardez l\'étiquette collée sur le '
                      'carton.',
                  couleur: Colors.green,
                )
              else
                _BoutonRamassage(parcel: parcel),
              const SizedBox(height: 16),
            ],
            if (!parcel.pickupRequested)
              _Consigne(
                icon: Icons.schedule_outlined,
                titre: parcel.daysLeftToDropOff > 0
                    ? 'Il vous reste ${parcel.daysLeftToDropOff} jour(s)'
                    : 'Dernier jour',
                texte: beg
                    ? 'Un livreur passera récupérer le colis avant le '
                        '${dateFormat.format(parcel.dropoffDeadline)}. Tenez-le '
                        'prêt. Passé ce délai, l\'acheteur est remboursé.'
                    : 'Déposez le colis avant le '
                        '${dateFormat.format(parcel.dropoffDeadline)}. Passé ce '
                        'délai, l\'acheteur est remboursé automatiquement.',
                couleur: theme.colorScheme.error,
              ),
          ],
        ],
      ),
    );
  }
}

/// Bouton « Faites-vous récupérer le colis à domicile (payant) ». Charge le
/// produit (pour son titre et sa sous-catégorie, qui fixe le tarif) puis ouvre
/// la page de paiement en mode ramassage.
class _BoutonRamassage extends ConsumerStatefulWidget {
  final Parcel parcel;
  const _BoutonRamassage({required this.parcel});

  @override
  ConsumerState<_BoutonRamassage> createState() => _BoutonRamassageState();
}

class _BoutonRamassageState extends ConsumerState<_BoutonRamassage> {
  bool _chargement = false;

  Future<void> _lancer() async {
    setState(() => _chargement = true);
    try {
      final produit = await ref
          .read(productRepositoryProvider)
          .getProductById(widget.parcel.productId);
      if (!mounted) return;
      context.push('/payment', extra: {
        'product': produit,
        'pickupParcelCode': widget.parcel.code,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger l\'article : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: _chargement
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.local_shipping_outlined),
      label: const Text('Faites-vous récupérer le colis à domicile (payant)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
      ),
      onPressed: _chargement ? null : _lancer,
    );
  }
}

class _Consigne extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String texte;
  final Color couleur;

  const _Consigne({
    required this.icon,
    required this.titre,
    required this.texte,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: couleur, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: couleur,
                  ),
                ),
                const SizedBox(height: 4),
                Text(texte, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section auto-expédition côté vendeur : déclarer l'envoi avec une preuve
/// (obligatoire), puis suivre l'état de sa modération.
class _SelfShipAction extends ConsumerStatefulWidget {
  const _SelfShipAction({required this.parcel});
  final Parcel parcel;

  @override
  ConsumerState<_SelfShipAction> createState() => _SelfShipActionState();
}

class _SelfShipActionState extends ConsumerState<_SelfShipAction> {
  bool _envoi = false;
  bool _soumisLocalement = false;

  Future<void> _declarer() async {
    setState(() => _envoi = true);
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (img == null) {
        if (mounted) setState(() => _envoi = false);
        return;
      }
      final bytes = await img.readAsBytes();
      final storageRef = FirebaseStorage.instance.ref(
        'parcels/${widget.parcel.code}/shipment/'
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await storageRef.getDownloadURL();
      await ref
          .read(parcelSellerServiceProvider)
          .markShipped(parcelCode: widget.parcel.code, proofUrl: url);
      if (mounted) {
        setState(() => _soumisLocalement = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expédition déclarée. En attente de vérification.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString().replaceAll('Exception:', '').trim()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.parcel.shipmentStatus;

    if (_soumisLocalement || status == 'pending') {
      return _Consigne(
        icon: Icons.schedule_outlined,
        titre: 'Preuve en vérification',
        texte:
            'Votre preuve d\'expédition est en cours de vérification par Ablony. '
            'Vous serez notifié dès qu\'elle est validée.',
        couleur: Colors.orange,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'refused') ...[
          _Consigne(
            icon: Icons.error_outline,
            titre: 'Preuve refusée',
            texte:
                'Votre preuve n\'a pas été validée. Renvoyez une preuve '
                'd\'expédition valable avant la fin du délai.',
            couleur: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          icon: _envoi
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.local_shipping_outlined),
          label: const Text('J\'ai expédié le colis (avec preuve)'),
          onPressed: _envoi ? null : _declarer,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Joignez une photo du reçu d\'envoi (gare routière, transporteur…). '
          'Elle est vérifiée par Ablony avant validation.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
