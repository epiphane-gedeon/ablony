import 'package:equatable/equatable.dart';

import '../../../location/data/models/location_data.dart';
import '../../../relay_point/domain/models/relay_point.dart';

/// Mode d'acheminement choisi par l'acheteur.
enum DeliveryMethod {
  /// Retrait dans un point relais Ablony.
  relay,

  /// Remise à l'adresse de l'acheteur.
  home,

  /// Le vendeur expédie lui-même (auto-expédition). Ablony n'achemine pas :
  /// acheteur et vendeur coordonnent le transport dans le chat. Aucun frais de
  /// livraison Ablony. Proposé en mode « beg » (toujours hors Lomé, en option à
  /// Lomé).
  selfShip;

  String get wireValue => this == DeliveryMethod.selfShip
      ? 'self_ship'
      : name;

  static DeliveryMethod fromWire(String? value) {
    switch (value) {
      case 'home':
        return DeliveryMethod.home;
      case 'self_ship':
        return DeliveryMethod.selfShip;
      default:
        return DeliveryMethod.relay;
    }
  }
}

/// Adresse de remise, recopiée sur la commande.
///
/// Recopiée, et non référencée : si l'acheteur déménage ensuite, le colis en
/// cours doit continuer d'aller au bon endroit.
class DeliveryAddress extends Equatable {
  final String fullName;

  /// Téléphone du destinataire, pour le joindre à la livraison. Rangé côté
  /// serveur dans le sous-document privé du colis (invisible du vendeur).
  final String phone;
  final String street;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;

  const DeliveryAddress({
    required this.fullName,
    required this.phone,
    required this.street,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddress.fromLocation({
    required String fullName,
    required String phone,
    required LocationData location,
  }) {
    return DeliveryAddress(
      fullName: fullName,
      phone: phone,
      street: location.street?.isNotEmpty == true
          ? location.street!
          : location.formattedAddress,
      city: location.city,
      country: location.country,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  /// Une ligne lisible, pour l'afficher dans le récapitulatif de commande.
  String get summary => [fullName, street, city].whereType<String>()
      .where((part) => part.isNotEmpty)
      .join(', ');

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'street': street,
    if (city != null) 'city': city,
    if (country != null) 'country': country,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props =>
      [fullName, phone, street, city, country, latitude, longitude];
}

/// Le choix de livraison, tel qu'il part vers le serveur.
///
/// Ce type n'existait pas : l'écran de paiement gardait le *nom* du point
/// relais et une adresse déjà mise en forme, puis n'envoyait ni l'un ni
/// l'autre. L'article était vendu et attendu nulle part. Ce qui compte est
/// ici — l'identifiant du point relais, et une adresse structurée.
class DeliveryChoice extends Equatable {
  final DeliveryMethod method;

  /// Renseigné pour [DeliveryMethod.relay] uniquement.
  final RelayPoint? relayPoint;

  /// Renseignée pour [DeliveryMethod.home] uniquement.
  final DeliveryAddress? address;

  /// Coordonnées de contact de l'acheteur, exigées pour LES DEUX modes
  /// (traçabilité : pouvoir le joindre, qu'il retire en relais ou soit livré).
  /// Rangées côté serveur dans le sous-document privé du colis.
  final String? contactName;
  final String? contactPhone;

  const DeliveryChoice({
    required this.method,
    this.relayPoint,
    this.address,
    this.contactName,
    this.contactPhone,
  });

  const DeliveryChoice.relay(RelayPoint point, {this.contactName, this.contactPhone})
    : method = DeliveryMethod.relay,
      relayPoint = point,
      address = null;

  const DeliveryChoice.home(DeliveryAddress destination, {this.contactName, this.contactPhone})
    : method = DeliveryMethod.home,
      relayPoint = null,
      address = destination;

  /// `true` quand le choix est complet et peut accompagner un paiement.
  ///
  /// En auto-expédition, rien à renseigner : acheteur et vendeur coordonnent le
  /// transport dans le chat (aucun contact révélé). Sinon le contact (nom +
  /// téléphone) est requis, plus le point relais ou l'adresse selon le mode.
  bool get isComplete {
    if (method == DeliveryMethod.selfShip) return true;
    final hasContact = (contactName?.trim().isNotEmpty ?? false) &&
        (contactPhone?.trim().isNotEmpty ?? false);
    if (!hasContact) return false;
    return switch (method) {
      DeliveryMethod.relay => relayPoint != null,
      DeliveryMethod.home => address != null,
      DeliveryMethod.selfShip => true,
    };
  }

  /// Où le colis doit arriver, en une ligne.
  String get destinationSummary => switch (method) {
    DeliveryMethod.relay => relayPoint?.name ?? '',
    DeliveryMethod.home => address?.summary ?? '',
    DeliveryMethod.selfShip => 'Envoi par le vendeur',
  };

  Map<String, dynamic> toJson() => {
    'method': method.wireValue,
    if (relayPoint != null) 'relayPointId': relayPoint!.id,
    if (address != null) 'address': address!.toJson(),
    if (contactName != null && contactName!.trim().isNotEmpty)
      'contactName': contactName!.trim(),
    if (contactPhone != null && contactPhone!.trim().isNotEmpty)
      'contactPhone': contactPhone!.trim(),
  };

  @override
  List<Object?> get props =>
      [method, relayPoint?.id, address, contactName, contactPhone];
}
