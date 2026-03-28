/// Modèle de données pour représenter une localisation
class LocationData {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? street;
  final String? postalCode;
  final String? city;
  final String? country;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.street,
    this.postalCode,
    this.city,
    this.country,
  });

  /// Crée une copie avec certains champs modifiés
  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? formattedAddress,
    String? street,
    String? postalCode,
    String? city,
    String? country,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
      'street': street,
      'postalCode': postalCode,
      'city': city,
      'country': country,
    };
  }

  /// Crée depuis Map Firestore
  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      formattedAddress: map['formattedAddress'] as String,
      street: map['street'] as String?,
      postalCode: map['postalCode'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $formattedAddress)';
  }
}
