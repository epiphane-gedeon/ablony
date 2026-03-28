import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant une adresse de livraison
class Address {
  final String id;
  final String userId;
  final String fullName;
  final String country;
  final String streetAddress;
  final String? addressLine2;
  final String postalCode;
  final String city;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.country,
    required this.streetAddress,
    this.addressLine2,
    required this.postalCode,
    required this.city,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Address.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Address(
      id: doc.id,
      userId: data['userId'] as String,
      fullName: data['fullName'] as String,
      country: data['country'] as String,
      streetAddress: data['streetAddress'] as String,
      addressLine2: data['addressLine2'] as String?,
      postalCode: data['postalCode'] as String,
      city: data['city'] as String,
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'country': country,
      'streetAddress': streetAddress,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      'postalCode': postalCode,
      'city': city,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? country,
    String? streetAddress,
    String? addressLine2,
    String? postalCode,
    String? city,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      streetAddress: streetAddress ?? this.streetAddress,
      addressLine2: addressLine2 ?? this.addressLine2,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedAddress {
    final line2 = addressLine2 != null && addressLine2!.isNotEmpty
        ? '\n$addressLine2'
        : '';
    return '$streetAddress$line2\n$postalCode $city\n$country';
  }
}
