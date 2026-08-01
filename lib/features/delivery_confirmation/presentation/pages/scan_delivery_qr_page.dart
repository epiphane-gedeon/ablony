import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/services/delivery_confirmation_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Scanner de code QR utilisé par l'acheteur pour confirmer la réception
/// d'un article remis en main propre par le vendeur. Débloque le paiement
/// (pendingAmount → availableAmount du vendeur) via [DeliveryConfirmationService].
class ScanDeliveryQrPage extends ConsumerStatefulWidget {
  const ScanDeliveryQrPage({super.key});

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

    setState(() => _isProcessing = true);
    await _controller.stop();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final service = ref.read(deliveryConfirmationServiceProvider);
      await service.confirmDelivery(qrCodeId: qrCodeId);
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
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGenericMsg(e.toString()))),
      );
      setState(() => _isProcessing = false);
      _controller.start();
    }
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
            child: Text(
              l10n.scanQrInstructions,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
