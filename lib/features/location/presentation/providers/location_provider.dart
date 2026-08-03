import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../data/models/location_data.dart';

/// Provider pour gérer la localisation
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  /// Vérifie et demande les permissions de localisation
  Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifie si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Vérifie les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Vérifie les permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        throw Exception('Permission de localisation refusée');
      }

      // Obtient la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convertit les coordonnées en adresse
      return await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Convertit des coordonnées GPS en adresse formatée
  Future<LocationData?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Reverse geocoding
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;

      // Formate l'adresse
      final formattedAddress = _formatAddress(place);

      return LocationData(
        latitude: latitude,
        longitude: longitude,
        formattedAddress: formattedAddress,
        street: place.street,
        postalCode: place.postalCode,
        city: place.locality,
        country: place.country,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Formate une adresse à partir d'un Placemark
  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }

    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      if (place.locality != null && place.locality!.isNotEmpty) {
        parts.add('${place.postalCode} ${place.locality}');
      } else {
        parts.add(place.postalCode!);
      }
    } else if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    return parts.join(', ');
  }

  /// Ouvre les paramètres de localisation
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
