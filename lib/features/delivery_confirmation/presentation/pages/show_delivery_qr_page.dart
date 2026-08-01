import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../l10n/app_localizations.dart';

/// Affiché au vendeur pour la remise en main propre : l'acheteur scanne ce
/// code pour confirmer la réception, ce qui débloque le paiement
/// (pendingAmount → availableAmount).
class ShowDeliveryQrPage extends StatelessWidget {
  /// Id du document `qrcodes` — c'est cette valeur, et non la référence de
  /// transaction, qui est encodée dans le QR affiché.
  final String qrCodeId;
  final bool deliveryConfirmed;

  const ShowDeliveryQrPage({
    super.key,
    required this.qrCodeId,
    this.deliveryConfirmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deliveryQrPageTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: deliveryConfirmed
                ? [
                    Icon(Icons.check_circle, size: 72, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      l10n.deliveryAlreadyConfirmed,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ]
                : [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                        ],
                      ),
                      child: QrImageView(
                        data: qrCodeId,
                        size: 240,
                        version: QrVersions.auto,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.deliveryQrInstructions,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
