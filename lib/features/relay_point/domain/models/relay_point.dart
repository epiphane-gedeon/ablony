import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Point relais où un colis peut être déposé/récupéré (livraison en point
/// relais, cf. étape paiement). Collection Firestore `relayPoints`,
/// gérée côté backend (écriture bloquée par les règles de sécurité).
class RelayPoint extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String hours;
  final String? phone;

  const RelayPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.hours,
    this.phone,
  });

  factory RelayPoint.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return RelayPoint(
      id: doc.id,
      name: data['name'] as String,
      address: data['address'] as String,
      city: data['city'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      hours: data['hours'] as String,
      phone: data['phone'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, address, city, latitude, longitude, hours, phone];
}
