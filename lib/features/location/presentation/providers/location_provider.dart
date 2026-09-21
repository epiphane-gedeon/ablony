import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../../data/models/location_data.dart';

/// Recherche de lieu, côté serveur (cf. `geocodeSearch` dans functions/).
const String _geocodeSearchUrl =
    'https://us-central1-ablony-a5db9.cloudfunctions.net/geocodeSearch';

/// Suggestions au fil de la frappe (cf. `placeSearch` dans functions/).
const String _placeSearchUrl =
    'https://us-central1-ablony-a5db9.cloudfunctions.net/placeSearch';

/// Une proposition de lieu, telle qu'affichée pendant la frappe.
///
/// Elle ne porte pas de coordonnées : Google ne les donne qu'au moment où l'on
/// choisit vraiment un lieu, ce qui évite de payer le détail de propositions
/// que personne ne retient.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.title,
    required this.subtitle,
  });

  final String placeId;
  final String title;
  final String subtitle;
}

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

  Future<Map<String, dynamic>> _appelerPlaceSearch(
    Map<String, dynamic> corps,
  ) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('Utilisateur non authentifié');

    final reponse = await http.post(
      Uri.parse(_placeSearchUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(corps),
    );

    final data = jsonDecode(reponse.body) as Map<String, dynamic>;
    if (reponse.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['error']?['message'] ?? 'La recherche a échoué',
      );
    }
    return data['data'] as Map<String, dynamic>;
  }

  /// Propose des lieux pendant la frappe.
  ///
  /// [sessionToken] doit rester le même du premier caractère jusqu'au choix du
  /// lieu : Google facture alors l'ensemble comme une seule session, au lieu de
  /// facturer chaque frappe.
  Future<List<PlaceSuggestion>> suggestPlaces(
    String input, {
    required String sessionToken,
  }) async {
    if (input.trim().length < 3) return const [];

    final data = await _appelerPlaceSearch({
      'input': input.trim(),
      'sessionToken': sessionToken,
    });

    return (data['suggestions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (s) => PlaceSuggestion(
            placeId: s['placeId'] as String,
            title: s['title'] as String? ?? '',
            subtitle: s['subtitle'] as String? ?? '',
          ),
        )
        .toList();
  }

  /// Récupère les coordonnées du lieu retenu, ce qui clôt la session.
  Future<LocationData> placeDetails(
    String placeId, {
    required String sessionToken,
  }) async {
    final data = await _appelerPlaceSearch({
      'placeId': placeId,
      'sessionToken': sessionToken,
    });

    final p = data['place'] as Map<String, dynamic>;
    return LocationData(
      latitude: (p['latitude'] as num).toDouble(),
      longitude: (p['longitude'] as num).toDouble(),
      formattedAddress: p['formattedAddress'] as String? ?? '',
      street: p['street'] as String?,
      postalCode: p['postalCode'] as String?,
      city: p['city'] as String?,
      country: p['country'] as String?,
    );
  }

  /// Cherche un lieu par son nom et renvoie les correspondances trouvées.
  ///
  /// On ne se fait pas forcément livrer là où l'on se trouve : taper
  /// « Adidogomé » ou « Hôtel du 2 Février » doit suffire à déplacer la carte,
  /// sans avoir à la faire défiler à la main depuis sa propre position.
  ///
  /// L'appel passe par la Cloud Function `geocodeSearch` et non par le paquet
  /// `geocoding` : celui-ci ne gère qu'Android et iOS, si bien que la recherche
  /// ne rendait jamais rien sur le web. Un seul chemin sert donc les trois
  /// plateformes, et la clé Google reste côté serveur.
  Future<List<LocationData>> searchAddress(String query) async {
    final terme = query.trim();
    if (terme.isEmpty) return const [];

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final reponse = await http.post(
      Uri.parse(_geocodeSearchUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'query': terme}),
    );

    final data = jsonDecode(reponse.body) as Map<String, dynamic>;
    if (reponse.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['error']?['message'] ?? 'La recherche d\'adresse a échoué',
      );
    }

    final resultats = (data['data']?['results'] as List<dynamic>? ?? []);
    return resultats
        .cast<Map<String, dynamic>>()
        .map(
          (r) => LocationData(
            latitude: (r['latitude'] as num).toDouble(),
            longitude: (r['longitude'] as num).toDouble(),
            formattedAddress: r['formattedAddress'] as String? ?? terme,
            street: r['street'] as String?,
            postalCode: r['postalCode'] as String?,
            city: r['city'] as String?,
            country: r['country'] as String?,
          ),
        )
        .toList();
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
