import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/parcel_scan_service.dart';
import '../../domain/models/scanned_parcel.dart';

/// Ce qu'un agent voit après un scan, et ce qu'il peut en faire.
///
/// Les étapes proposées viennent du serveur : un colis jamais déposé ne peut
/// pas être « remis », et la liste ne le propose donc pas. Le serveur refuse
/// de toute façon — la liste évite seulement de proposer un geste voué à
/// l'échec.
class AgentParcelSheet extends ConsumerStatefulWidget {
  const AgentParcelSheet({super.key, required this.parcel});

  final ScannedParcel parcel;

  @override
  ConsumerState<AgentParcelSheet> createState() => _AgentParcelSheetState();
}

class _AgentParcelSheetState extends ConsumerState<AgentParcelSheet> {
  String? _running;
  String? _error;

  Future<void> _record(String kind) async {
    setState(() {
      _running = kind;
      _error = null;
    });
    try {
      await ref
          .read(parcelScanServiceProvider)
          .recordCheckpoint(code: widget.parcel.code, kind: kind);
      if (mounted) Navigator.of(context).pop(true);
    } on ParcelScanException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _running = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parcel = widget.parcel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              parcel.code,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(parcel.productTitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),

            _Line(
              icon: Icons.local_shipping_outlined,
              label: l10n.parcelStatusLabel,
              value: _statusLabel(l10n, parcel.status),
            ),
            if (parcel.destination != null)
              _Line(
                icon: parcel.destination!.isRelayPoint
                    ? Icons.store_outlined
                    : Icons.home_outlined,
                label: parcel.destination!.isRelayPoint
                    ? l10n.parcelDestinationRelay
                    : l10n.parcelDestinationHome,
                value: parcel.destination!.summary,
              ),

            const SizedBox(height: 20),
            if (parcel.nextSteps.isEmpty)
              Text(
                l10n.parcelNoStepLeft,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(l10n.parcelRecordStep, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final step in parcel.nextSteps)
                    FilledButton.tonal(
                      onPressed: _running == null ? () => _record(step) : null,
                      child: _running == step
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_stepLabel(l10n, step)),
                    ),
                ],
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
    'awaiting_dropoff' => l10n.parcelAwaitingDropoff,
    'dropped_off' => l10n.parcelDroppedOff,
    'in_transit' => l10n.parcelInTransit,
    'ready_for_pickup' => l10n.parcelReadyForPickup,
    'out_for_delivery' => l10n.parcelOutForDelivery,
    'delivered' => l10n.parcelDelivered,
    'returned' => l10n.parcelReturned,
    _ => l10n.parcelLost,
  };

  String _stepLabel(AppLocalizations l10n, String step) => switch (step) {
    'dropped_off' => l10n.stepDroppedOff,
    'in_transit' => l10n.stepInTransit,
    'arrived' => l10n.stepArrived,
    'out_for_delivery' => l10n.stepOutForDelivery,
    'delivered' => l10n.stepDelivered,
    'returned' => l10n.stepReturned,
    _ => l10n.stepLost,
  };
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
