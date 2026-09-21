import 'package:equatable/equatable.dart';

/// Ce qu'un agent voit après avoir scanné une étiquette.
///
/// Volontairement réduit : de quoi acheminer le colis, rien de plus. Ni prix,
/// ni identité — un agent n'a pas à savoir combien vaut ce qu'il manipule, ni
/// pour qui. Ce qui lui manque ne peut pas fuiter.
class ScannedParcel extends Equatable {
  const ScannedParcel({
    required this.code,
    required this.status,
    required this.method,
    required this.productTitle,
    required this.nextSteps,
    this.destination,
  });

  final String code;
  final String status;
  final String method;
  final String productTitle;

  /// Les étapes possibles depuis l'état courant. Elles viennent du serveur,
  /// qui refusera de toute façon les autres : la liste évite simplement de
  /// proposer un geste voué à l'échec.
  final List<String> nextSteps;

  /// Où le colis doit aller. Un point relais est une adresse publique ; un
  /// domicile ne l'est pas, et n'est communiqué qu'au personnel qui s'y rend.
  final ParcelDestination? destination;

  factory ScannedParcel.fromJson(Map<String, dynamic> json) => ScannedParcel(
    code: json['code'] as String? ?? '',
    status: json['status'] as String? ?? 'awaiting_dropoff',
    method: json['method'] as String? ?? 'relay',
    productTitle: json['productTitle'] as String? ?? 'Article',
    nextSteps:
        (json['nextSteps'] as List<dynamic>?)?.cast<String>() ?? const [],
    destination: json['destination'] == null
        ? null
        : ParcelDestination.fromJson(
            json['destination'] as Map<String, dynamic>,
          ),
  );

  @override
  List<Object?> get props => [code, status, nextSteps];
}

class ParcelDestination extends Equatable {
  const ParcelDestination({
    required this.isRelayPoint,
    this.name,
    this.street,
    this.city,
    this.phone,
  });

  final bool isRelayPoint;
  final String? name;
  final String? street;
  final String? city;
  final String? phone;

  factory ParcelDestination.fromJson(Map<String, dynamic> json) =>
      ParcelDestination(
        isRelayPoint: json['kind'] == 'relay',
        name: (json['name'] ?? json['fullName']) as String?,
        street: (json['address'] ?? json['street']) as String?,
        city: json['city'] as String?,
        phone: json['phone'] as String?,
      );

  /// Une ligne lisible d'un coup d'œil, à l'écran d'un agent en tournée.
  String get summary => [
    if (name != null && name!.isNotEmpty) name,
    if (street != null && street!.isNotEmpty) street,
    if (city != null && city!.isNotEmpty) city,
  ].whereType<String>().join(' · ');

  @override
  List<Object?> get props => [isRelayPoint, name, street, city];
}

/// Ce que l'acheteur reçoit après avoir scanné son colis.
class AttestedParcel extends Equatable {
  const AttestedParcel({
    required this.code,
    required this.transactionRef,
    required this.productTitle,
    required this.status,
    required this.alreadySettled,
  });

  final String code;
  final String transactionRef;
  final String productTitle;
  final String status;

  /// La vente est déjà dénouée : il n'y a plus rien à décider.
  final bool alreadySettled;

  factory AttestedParcel.fromJson(Map<String, dynamic> json) => AttestedParcel(
    code: json['code'] as String? ?? '',
    transactionRef: json['transactionRef'] as String? ?? '',
    productTitle: json['productTitle'] as String? ?? 'Article',
    status: json['status'] as String? ?? '',
    alreadySettled: json['alreadySettled'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [code, transactionRef, status];
}
