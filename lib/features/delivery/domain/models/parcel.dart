import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'delivery_choice.dart';

/// Où en est le colis.
///
/// Ces états ne sont pas déclarés par le vendeur ni par l'acheteur : ils sont
/// constatés par Ablony au fil des scans du code imprimé sur le carton. C'est
/// ce qui permet de payer le vendeur sans demander à l'acheteur de le
/// confirmer — et de rembourser l'acheteur sans demander l'avis du vendeur.
enum ParcelStatus {
  /// Vendu, en attente du dépôt en point relais par le vendeur.
  awaitingDropoff,

  /// Déposé : le travail du vendeur est terminé.
  droppedOff,

  /// En cours d'acheminement.
  inTransit,

  /// Arrivé au point relais de l'acheteur.
  readyForPickup,

  /// En tournée de livraison à domicile.
  outForDelivery,

  /// Remis à l'acheteur.
  delivered,

  /// Retourné au vendeur — dépôt jamais effectué, ou remise impossible.
  returned,

  /// Égaré pendant l'acheminement. C'est notre responsabilité.
  lost;

  static ParcelStatus fromWire(String? value) => switch (value) {
    'dropped_off' => ParcelStatus.droppedOff,
    'in_transit' => ParcelStatus.inTransit,
    'ready_for_pickup' => ParcelStatus.readyForPickup,
    'out_for_delivery' => ParcelStatus.outForDelivery,
    'delivered' => ParcelStatus.delivered,
    'returned' => ParcelStatus.returned,
    'lost' => ParcelStatus.lost,
    _ => ParcelStatus.awaitingDropoff,
  };

  /// Le vendeur a-t-il encore quelque chose à faire ?
  bool get needsSellerAction => this == ParcelStatus.awaitingDropoff;

  /// Le colis est-il passé sous la garde d'Ablony ?
  bool get isInOurHands => switch (this) {
    ParcelStatus.droppedOff ||
    ParcelStatus.inTransit ||
    ParcelStatus.readyForPickup ||
    ParcelStatus.outForDelivery => true,
    _ => false,
  };

  /// Ce que l'acheteur doit lire, dit de son point de vue.
  ///
  /// « En attente de dépôt » plutôt que « le vendeur n'a rien fait » : le
  /// message informe sans accuser, tant que le délai court encore.
  String get buyerLabel => switch (this) {
    ParcelStatus.awaitingDropoff => 'En attente du dépôt par le vendeur',
    ParcelStatus.droppedOff => 'Colis déposé, il part bientôt',
    ParcelStatus.inTransit => 'En cours d\'acheminement',
    ParcelStatus.readyForPickup => 'Disponible en point relais',
    ParcelStatus.outForDelivery => 'En cours de livraison',
    ParcelStatus.delivered => 'Colis remis',
    ParcelStatus.returned => 'Colis retourné au vendeur',
    ParcelStatus.lost => 'Colis égaré — nous vous recontactons',
  };

  IconData get icon => switch (this) {
    ParcelStatus.awaitingDropoff => Icons.inventory_2_outlined,
    ParcelStatus.droppedOff => Icons.store_outlined,
    ParcelStatus.inTransit => Icons.local_shipping_outlined,
    ParcelStatus.readyForPickup => Icons.location_on_outlined,
    ParcelStatus.outForDelivery => Icons.delivery_dining_outlined,
    ParcelStatus.delivered => Icons.check_circle_outline,
    ParcelStatus.returned => Icons.undo_outlined,
    ParcelStatus.lost => Icons.error_outline,
  };

  /// Rang dans le parcours normal, pour situer une étape sur la frise. Le
  /// dernier maillon (point relais / livraison) partage le même rang : un colis
  /// suit l'un OU l'autre selon le mode choisi.
  int get sequenceIndex => switch (this) {
    ParcelStatus.awaitingDropoff => 0,
    ParcelStatus.droppedOff => 1,
    ParcelStatus.inTransit => 2,
    ParcelStatus.readyForPickup => 3,
    ParcelStatus.outForDelivery => 3,
    ParcelStatus.delivered => 4,
    // Hors parcours normal : traités à part par l'UI.
    ParcelStatus.returned => 5,
    ParcelStatus.lost => 5,
  };

  /// Clé telle qu'écrite dans `stepsAt` sur le document (= valeur « wire »).
  String get wire => switch (this) {
    ParcelStatus.awaitingDropoff => 'awaiting_dropoff',
    ParcelStatus.droppedOff => 'dropped_off',
    ParcelStatus.inTransit => 'in_transit',
    ParcelStatus.readyForPickup => 'ready_for_pickup',
    ParcelStatus.outForDelivery => 'out_for_delivery',
    ParcelStatus.delivered => 'delivered',
    ParcelStatus.returned => 'returned',
    ParcelStatus.lost => 'lost',
  };
}

/// Un colis, de son étiquette à sa remise.
///
/// Le champ décisif est [code] : c'est **le même code partout**. Le vendeur
/// l'imprime une fois et le colle sur le carton ; nos agents le scannent au
/// dépôt, en transit, à l'arrivée et à la remise ; l'acheteur le retrouve
/// dans son suivi. Il n'y a pas un code par étape, ni un code par rôle.
///
/// Ce code n'autorise rien. Il est imprimé sur un carton que tout le monde
/// peut voir : ce n'est pas lui qui déclenche une étape, mais l'agent qui le
/// scanne.
class Parcel extends Equatable {
  /// Le code imprimé sur l'étiquette, de la forme `AB-XXXXX-XXXXX`.
  final String code;
  final String transactionRef;
  final String sellerId;
  final String buyerId;
  final String productId;
  final String productTitle;
  final DeliveryMethod method;
  final ParcelStatus status;

  /// Date avant laquelle le vendeur doit avoir déposé le colis. Passé ce
  /// délai, l'acheteur est remboursé.
  final DateTime dropoffDeadline;

  final DateTime? droppedOffAt;
  final DateTime? deliveredAt;
  final String? relayPointId;
  final DateTime createdAt;

  /// `true` si le vendeur a payé pour qu'on vienne récupérer le colis chez lui
  /// (ramassage à domicile) au lieu de le déposer en point relais.
  final bool pickupRequested;

  /// Auto-expédition (`method == selfShip`) : état de la preuve d'expédition.
  /// null (rien soumis) · `pending` (en modération) · `approved` · `refused`.
  final String? shipmentStatus;

  /// URL de la preuve d'expédition soumise par le vendeur.
  final String? shipmentProofUrl;

  /// Horodatage de chaque étape franchie, pour la frise de suivi. Alimenté par
  /// les scans des agents (`recordParcelCheckpoint`).
  final Map<ParcelStatus, DateTime> stepsAt;

  const Parcel({
    required this.code,
    required this.transactionRef,
    required this.sellerId,
    required this.buyerId,
    required this.productId,
    required this.productTitle,
    required this.method,
    required this.status,
    required this.dropoffDeadline,
    required this.createdAt,
    this.droppedOffAt,
    this.deliveredAt,
    this.relayPointId,
    this.stepsAt = const {},
    this.pickupRequested = false,
    this.shipmentStatus,
    this.shipmentProofUrl,
  });

  factory Parcel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Parcel(
      code: data['code'] as String? ?? doc.id,
      transactionRef: data['transactionRef'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      productTitle: data['productTitle'] as String? ?? 'Article',
      method: DeliveryMethod.fromWire(data['method'] as String?),
      status: ParcelStatus.fromWire(data['status'] as String?),
      dropoffDeadline:
          (data['dropoffDeadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      droppedOffAt: (data['droppedOffAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      relayPointId: data['relayPointId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stepsAt: _lireStepsAt(data['stepsAt']),
      pickupRequested: data['pickupRequested'] as bool? ?? false,
      shipmentStatus: data['shipmentStatus'] as String?,
      shipmentProofUrl: data['shipmentProofUrl'] as String?,
    );
  }

  /// L'article est expédié par le vendeur lui-même (auto-expédition).
  bool get isSelfShip => method == DeliveryMethod.selfShip;

  static Map<ParcelStatus, DateTime> _lireStepsAt(Object? raw) {
    if (raw is! Map) return const {};
    final out = <ParcelStatus, DateTime>{};
    raw.forEach((key, value) {
      if (value is Timestamp) {
        out[ParcelStatus.fromWire(key as String?)] = value.toDate();
      }
    });
    return out;
  }

  /// Jours restants au vendeur pour déposer le colis.
  ///
  /// Arrondi vers le bas, volontairement : annoncer « 2 jours » à qui en a
  /// deux et vingt-trois heures fait agir plus tôt. L'inverse ferait rater
  /// l'échéance à qui a cru sur parole.
  int get daysLeftToDropOff {
    final restant = dropoffDeadline.difference(DateTime.now()).inDays;
    return restant < 0 ? 0 : restant;
  }

  @override
  List<Object?> get props => [
        code, status, droppedOffAt, deliveredAt, pickupRequested,
        shipmentStatus, shipmentProofUrl,
      ];
}
