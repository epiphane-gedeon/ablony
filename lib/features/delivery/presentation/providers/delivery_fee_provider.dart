import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/delivery_pricing.dart';

/// Frais d'acheminement (relais / domicile) pour une sous-catégorie.
class DeliveryFees {
  const DeliveryFees({
    required this.relayXof,
    required this.homeXof,
    required this.pickupXof,
  });
  final int relayXof;
  final int homeXof;

  /// Frais de ramassage à domicile (le vendeur fait venir chercher le colis).
  final int pickupXof;
}

/// Lit les frais depuis Firestore : le tarif posé sur la sous-catégorie du
/// produit s'il existe, sinon le défaut global (`config/delivery`), sinon le
/// repli code (`DeliveryPricing`). Le serveur applique EXACTEMENT la même règle
/// (`fraisLivraison` dans functions/index.js) — c'est ce qui garantit que le
/// total affiché colle au total facturé.
final deliveryFeesProvider =
    FutureProvider.family<DeliveryFees, String?>((ref, subcategoryId) async {
  final fs = FirebaseFirestore.instance;
  int relay = DeliveryPricing.relayFeeXof;
  int home = DeliveryPricing.homeFeeXof;
  int pickup = DeliveryPricing.pickupFeeXof;

  try {
    final def = await fs.collection('config').doc('delivery').get();
    final d = def.data();
    if (d != null) {
      if (d['defaultRelayXof'] is num) {
        relay = (d['defaultRelayXof'] as num).round();
      }
      if (d['defaultHomeXof'] is num) {
        home = (d['defaultHomeXof'] as num).round();
      }
      if (d['defaultPickupXof'] is num) {
        pickup = (d['defaultPickupXof'] as num).round();
      }
    }
  } catch (_) {
    // Doc absent : on garde le repli code.
  }

  if (subcategoryId != null && subcategoryId.isNotEmpty) {
    try {
      final sub = await fs
          .collection('config')
          .doc('subcategories')
          .collection('items')
          .doc(subcategoryId)
          .get();
      final s = sub.data();
      if (s != null) {
        if (s['deliveryRelayXof'] is num) {
          relay = (s['deliveryRelayXof'] as num).round();
        }
        if (s['deliveryHomeXof'] is num) {
          home = (s['deliveryHomeXof'] as num).round();
        }
        if (s['pickupXof'] is num) {
          pickup = (s['pickupXof'] as num).round();
        }
      }
    } catch (_) {
      // Sous-catégorie sans tarif : on garde le défaut.
    }
  }

  return DeliveryFees(relayXof: relay, homeXof: home, pickupXof: pickup);
});
