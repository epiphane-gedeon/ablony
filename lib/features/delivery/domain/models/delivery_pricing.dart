import 'delivery_choice.dart';

/// Frais d'acheminement, en francs CFA.
///
/// Ces montants sont **indicatifs** : le serveur recalcule le total et refuse
/// un écart. Les garder ici sert à afficher le récapitulatif avant l'appel,
/// pas à fixer le prix — un client qui fixe ses propres frais n'en paie
/// aucun.
abstract final class DeliveryPricing {
  static const int relayFeeXof = 1000;
  static const int homeFeeXof = 1500;
  /// Repli pour le ramassage à domicile (le vendeur paie qu'on vienne chercher
  /// le colis chez lui). Le vrai tarif vient de la sous-catégorie, sinon du
  /// défaut Firestore, sinon d'ici.
  static const int pickupFeeXof = 1500;

  /// Part du prix de l'article prélevée au titre de la protection acheteur.
  // Portée à 6 % le 2026-10-02. Le prestataire de paiement prélève 5 % sur
  // tout ce qui transite — y compris sur la protection elle-même — donc le
  // taux plancher pour ne rien perdre est 5/95 = 5,27 %, pas 5 %.
  //
  // À garder synchrone avec DELIVERY_CONFIG.PROTECTION_RATE côté serveur : ce
  // taux ne fait qu'afficher, le serveur recalcule et tranche. Le serveur
  // tolère encore l'ancien taux, le temps que le parc installé se mette à
  // jour — un client resté à 5 % n'est donc pas bloqué.
  static const double protectionRate = 0.06;

  static int shippingFeeFor(DeliveryMethod method) => switch (method) {
    DeliveryMethod.relay => relayFeeXof,
    DeliveryMethod.home => homeFeeXof,
    // Auto-expédition : aucun acheminement Ablony, donc aucun frais.
    DeliveryMethod.selfShip => 0,
  };
}
