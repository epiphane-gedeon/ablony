import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
class ParcelLabelPage extends StatelessWidget {
  final Parcel parcel;

  const ParcelLabelPage({super.key, required this.parcel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Étiquette du colis'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (parcel.status.needsSellerAction)
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

          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copier le code'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: parcel.code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copié')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          if (parcel.status.needsSellerAction)
            _Consigne(
              icon: Icons.schedule_outlined,
              titre: parcel.daysLeftToDropOff > 0
                  ? 'Il vous reste ${parcel.daysLeftToDropOff} jour(s)'
                  : 'Dernier jour',
              texte:
                  'Déposez le colis avant le '
                  '${dateFormat.format(parcel.dropoffDeadline)}. Passé ce '
                  'délai, l\'acheteur est remboursé automatiquement.',
              couleur: theme.colorScheme.error,
            ),
        ],
      ),
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
