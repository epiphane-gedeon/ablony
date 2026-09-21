import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/application/auth_providers.dart';
import '../../data/parcel_scan_service.dart';
import '../widgets/agent_parcel_sheet.dart';

/// L'écran de scan, un seul pour tout le monde.
///
/// Le code est le même partout : imprimé une fois par le vendeur, scanné par
/// nos agents à chaque étape, scanné par l'acheteur à la réception. Ce qui
/// change, c'est **qui scanne** — et c'est le serveur qui en décide, pas cet
/// écran. Un membre qui appellerait la route des agents recevrait 403 ; le
/// rôle affiché ici ne fait qu'éviter de proposer un geste voué à l'échec.
class ScanParcelPage extends ConsumerStatefulWidget {
  const ScanParcelPage({super.key});

  @override
  ConsumerState<ScanParcelPage> createState() => _ScanParcelPageState();
}

class _ScanParcelPageState extends ConsumerState<ScanParcelPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Empêche qu'un code lu plusieurs fois par seconde déclenche autant
  /// d'appels. La caméra émet en continu ; l'utilisateur, lui, a scanné une
  /// fois.
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((v) => v.trim().isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final isStaff = ref.read(currentUserProvider).value?.isStaff ?? false;
    try {
      if (isStaff) {
        await _handleAsStaff(raw.trim());
      } else {
        await _handleAsBuyer(raw.trim());
      }
    } on ParcelScanException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.scanFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleAsStaff(String code) async {
    final service = ref.read(parcelScanServiceProvider);
    final parcel = await service.resolve(code);
    if (!mounted) return;

    await _controller.stop();
    final recorded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AgentParcelSheet(parcel: parcel),
    );
    if (!mounted) return;

    if (recorded == true) {
      // L'étape est prise : on revient au scan pour le colis suivant, ce qui
      // est le geste d'une tournée.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.checkpointRecorded),
        ),
      );
    }
    await _controller.start();
  }

  Future<void> _handleAsBuyer(String code) async {
    final service = ref.read(parcelScanServiceProvider);
    final parcel = await service.attestReceipt(code);
    if (!mounted) return;

    // Le scan atteste, il ne décide pas. L'acheteur arrive sur sa commande,
    // où il choisit entre « tout est conforme » et « il y a un problème » —
    // après avoir ouvert le carton, et non devant le comptoir.
    context.pushReplacementNamed(
      'receipt',
      pathParameters: {'receiptId': parcel.transactionRef},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isStaff = ref.watch(currentUserProvider).value?.isStaff ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStaff ? l10n.scanParcelStaff : l10n.scanParcelBuyer),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
            tooltip: l10n.scanTorch,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _ScanOverlay(
            hint: isStaff ? l10n.scanHintStaff : l10n.scanHintBuyer,
            error: _error,
            busy: _busy,
          ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.hint, required this.busy, this.error});

  final String hint;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (busy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      error == null
                          ? Icons.qr_code_scanner
                          : Icons.error_outline,
                      color: error == null ? Colors.white : Colors.orangeAccent,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error ?? hint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: error == null
                            ? Colors.white
                            : Colors.orangeAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
