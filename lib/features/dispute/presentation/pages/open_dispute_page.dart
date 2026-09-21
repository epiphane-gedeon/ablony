import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../sell/presentation/widgets/image_picker_grid.dart';
import '../../data/dispute_service.dart';
import '../../domain/models/dispute.dart';
import '../../../../core/services/analytics_service.dart';

/// Le formulaire d'ouverture d'un litige.
///
/// Trois choses seulement : ce qui s'est passé, en quoi, et des photos. Chaque
/// champ supplémentaire est un abandon de plus — et un acheteur qui renonce à
/// signaler ne renonce pas au problème, il renonce à Ablony.
class OpenDisputePage extends ConsumerStatefulWidget {
  const OpenDisputePage({
    super.key,
    required this.transactionRef,
    this.isSeller = false,
  });

  final String transactionRef;

  /// Qui ouvre le litige : le vendeur voit des motifs distincts de l'acheteur
  /// (le colis, c'est lui qui le fait — parler d'un « colis abîmé » n'a pas de
  /// sens de son côté).
  final bool isSeller;

  @override
  ConsumerState<OpenDisputePage> createState() => _OpenDisputePageState();
}

class _OpenDisputePageState extends ConsumerState<OpenDisputePage> {
  DisputeReason? _motif;
  final _description = TextEditingController();
  List<dynamic> _images = [];
  bool _envoi = false;
  String? _erreur;

  /// Le serveur refuse en dessous ; le dire ici évite un aller-retour.
  static const int _minimum = 30;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  String _libelle(AppLocalizations l10n, DisputeReason r) {
    switch (r) {
      case DisputeReason.notReceived:
        return l10n.disputeNotReceived;
      case DisputeReason.notAsDescribed:
        return l10n.disputeNotAsDescribed;
      case DisputeReason.damaged:
        return l10n.disputeDamaged;
      case DisputeReason.buyerNotConfirming:
        return l10n.disputeBuyerNotConfirming;
      case DisputeReason.buyerNoValidReason:
        return l10n.disputeBuyerNoValidReason;
      case DisputeReason.other:
        return l10n.disputeOther;
    }
  }

  Future<void> _envoyer() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      final service = ref.read(disputeServiceProvider);
      // Les photos d'abord : si le dépôt échoue, aucun litige n'est ouvert et
      // l'acheteur peut recommencer sans se heurter à « déjà ouvert ».
      // Même piège que pour la photo de profil : la grille rend des `XFile`,
      // donc filtrer sur `File` renvoyait une liste toujours vide et le litige
      // partait sans ses photos.
      final fichiers = _images.whereType<XFile>().toList();
      final urls = fichiers.isEmpty
          ? <String>[]
          : await service.uploadPhotos(
              transactionRef: widget.transactionRef,
              fichiers: fichiers,
            );

      await service.open(
        transactionRef: widget.transactionRef,
        reason: _motif!,
        description: _description.text.trim(),
        photoUrls: urls,
      );
      ref.read(analyticsServiceProvider).logDisputeOpened(_motif!.wireValue);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.disputeSubmitted)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final longueur = _description.text.trim().length;
    final manque = _minimum - longueur;
    final complet = _motif != null && manque <= 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.disputeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.disputeReason,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          RadioGroup<DisputeReason>(
            groupValue: _motif,
            onChanged: (v) {
              // Pendant l'envoi, changer de motif enverrait le mauvais.
              if (_envoi) return;
              setState(() => _motif = v);
            },
            child: Column(
              children: (widget.isSeller
                      ? DisputeReason.sellerReasons
                      : DisputeReason.buyerReasons)
                  .map(
                    (r) => RadioListTile<DisputeReason>(
                      value: r,
                      title: Text(_libelle(l10n, r)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            l10n.disputeDescription,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.disputeDescriptionHint,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            enabled: !_envoi,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              // Le compte à rebours plutôt qu'un refus à l'envoi : on sait
              // toujours ce qu'il reste à faire.
              counterText:
                  manque > 0 ? l10n.disputeDescriptionTooShort(manque) : '',
            ),
          ),
          const SizedBox(height: 20),

          Text(
            l10n.disputePhotos,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.disputePhotosHint,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ImagePickerGrid(
            images: _images,
            maxImages: 4,
            onImagesChanged: (images) => setState(() => _images = images),
          ),

          if (_erreur != null) ...[
            const SizedBox(height: 16),
            Text(_erreur!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 24),
          FilledButton(
            onPressed: complet && !_envoi ? () => _envoyer() : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_envoi ? l10n.disputeSending : l10n.disputeSubmit),
          ),
        ],
      ),
    );
  }
}
