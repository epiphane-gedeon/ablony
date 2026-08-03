import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/services/delivery_confirmation_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../reviews/presentation/providers/review_provider.dart';

/// Scanner de code QR utilisé par l'acheteur pour confirmer la réception
/// d'un article remis en main propre par le vendeur. Débloque le paiement
/// (pendingAmount → availableAmount du vendeur) via [DeliveryConfirmationService],
/// puis propose de noter le vendeur — c'est le seul moment où l'acheteur a
/// effectivement l'article en main.
class ScanDeliveryQrPage extends ConsumerStatefulWidget {
  final String transactionRef;
  final String sellerId;
  final String productId;
  final String productTitle;

  const ScanDeliveryQrPage({
    super.key,
    required this.transactionRef,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
  });

  @override
  ConsumerState<ScanDeliveryQrPage> createState() => _ScanDeliveryQrPageState();
}

class _ScanDeliveryQrPageState extends ConsumerState<ScanDeliveryQrPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final qrCodeId = capture.barcodes.first.rawValue;
    if (qrCodeId == null || qrCodeId.isEmpty) return;

    await _confirmDelivery(qrCodeId: qrCodeId, stopScannerOnFailure: true);
  }

  Future<void> _confirmDelivery({
    String? qrCodeId,
    String? manualTransactionRef,
    bool stopScannerOnFailure = false,
  }) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    await _controller.stop();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final service = ref.read(deliveryConfirmationServiceProvider);
      await service.confirmDelivery(qrCodeId: qrCodeId, transactionRef: manualTransactionRef);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(l10n.deliveryConfirmedTitle),
            ],
          ),
          content: Text(l10n.deliveryConfirmedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      await _proceedToRatingOrClose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGenericMsg(e.toString()))),
      );
      setState(() => _isProcessing = false);
      if (stopScannerOnFailure) _controller.start();
    }
  }

  /// Propose la notation du vendeur pour cette commande, sauf si l'acheteur
  /// l'a déjà notée (ex. double confirmation via le code puis la référence).
  Future<void> _proceedToRatingOrClose() async {
    final repository = ref.read(reviewRepositoryProvider);
    final alreadyReviewed = await repository.hasReviewed(widget.transactionRef);
    if (!mounted) return;

    if (alreadyReviewed) {
      context.pop(true);
      return;
    }

    context.go(
      '/rate-seller',
      extra: {
        'transactionRef': widget.transactionRef,
        'sellerId': widget.sellerId,
        'productId': widget.productId,
        'productTitle': widget.productTitle,
      },
    );
  }

  Future<void> _showManualEntryDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reference = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.scanQrManualEntryDialogTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: l10n.scanQrManualEntryHint),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? l10n.scanQrManualEntryError : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: Text(l10n.validate),
          ),
        ],
      ),
    );

    if (reference == null || !mounted) return;
    await _confirmDelivery(manualTransactionRef: reference);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanQrPageTitle),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.scanQrInstructions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _isProcessing ? null : _showManualEntryDialog,
                  icon: const Icon(Icons.keyboard, color: Colors.white),
                  label: Text(
                    l10n.scanQrManualEntryButton,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
