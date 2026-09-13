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

  /// Part du prix de l'article prélevée au titre de la protection acheteur.
  static const double protectionRate = 0.05;

  static int shippingFeeFor(DeliveryMethod method) => switch (method) {
    DeliveryMethod.relay => relayFeeXof,
    DeliveryMethod.home => homeFeeXof,
  };
}
