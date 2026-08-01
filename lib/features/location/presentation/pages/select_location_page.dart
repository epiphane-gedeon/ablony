// IMPORTANT: Cette page nécessite l'installation des packages suivants :
//
// Dans pubspec.yaml:
//   google_maps_flutter: ^2.5.0
//   geolocator: ^10.1.0
//   geocoding: ^2.1.1
//
// Configuration Android (android/app/src/main/AndroidManifest.xml):
//   <application>
//     <meta-data
//       android:name="com.google.android.geo.API_KEY"
//       android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
//   </application>
//
// Configuration iOS (ios/Runner/AppDelegate.swift):
//   import GoogleMaps
//   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/widgets/buttons/buttons.dart';
import '../../data/models/location_data.dart';
import '../providers/location_provider.dart';

/// Page pour sélectionner une localisation sur la carte
class SelectLocationPage extends ConsumerStatefulWidget {
  const SelectLocationPage({super.key});

  @override
  ConsumerState<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends ConsumerState<SelectLocationPage> {
  // GoogleMapController? _mapController;
  LocationData? _selectedLocation;
  bool _isLoadingCurrentLocation = false;

  // Position initiale (Lomé, Togo)
  // final CameraPosition _initialPosition = const CameraPosition(
  //   target: LatLng(6.1256, 1.2221),
  //   zoom: 14,
  // );

  // Set<Marker> _markers = {};

  @override
  void dispose() {
    // _mapController?.dispose();
    super.dispose();
  }

  /// Récupère et utilise la position actuelle
  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);

    try {
      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();

      if (location != null) {
        setState(() {
          _selectedLocation = location;
          // Déplacer la caméra vers la position actuelle
          // _mapController?.animateCamera(
          //   CameraUpdate.newLatLng(LatLng(location.latitude, location.longitude)),
          // );
          // Ajouter un marker
          // _updateMarker(location.latitude, location.longitude);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de récupérer votre position'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Paramètres',
              onPressed: () {
                ref.read(locationServiceProvider).openLocationSettings();
              },
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingCurrentLocation = false);
    }
  }

  /// Met à jour le marker sur la carte
  void _updateMarker(double lat, double lng) {
    // TODO: Décommenter après installation de google_maps_flutter
    /*
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(lat, lng),
          draggable: true,
          onDragEnd: (newPosition) {
            _onLocationSelected(newPosition.latitude, newPosition.longitude);
          },
        ),
      };
    });
    */
  }

  /// Appelé quand l'utilisateur sélectionne une position
  Future<void> _onLocationSelected(double latitude, double longitude) async {
    final locationService = ref.read(locationServiceProvider);
    final location = await locationService.getAddressFromCoordinates(
      latitude,
      longitude,
    );

    if (location != null) {
      setState(() {
        _selectedLocation = location;
      });
    }
  }

  /// Confirme et retourne la localisation sélectionnée
  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop(_selectedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une localisation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une localisation'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmLocation,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Carte Google Maps
          // TODO: Décommenter après installation de google_maps_flutter
          /*
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            onTap: (position) {
              _updateMarker(position.latitude, position.longitude);
              _onLocationSelected(position.latitude, position.longitude);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          */

          // Placeholder temporaire
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Google Maps', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Installez les packages requis:\n'
                    '• google_maps_flutter: ^2.5.0\n'
                    '• geolocator: ^10.1.0\n'
                    '• geocoding: ^2.1.1\n\n'
                    'Puis configurez votre clé API Google Maps',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Bouton adresse par défaut (temporaire, sans Google Maps API)
          Positioned(
            left: 16,
            bottom: _selectedLocation != null ? 200 : 100,
            child: FloatingActionButton.extended(
              heroTag: 'default_location',
              onPressed: () {
                setState(() {
                  _selectedLocation = const LocationData(
                    latitude: 6.1256,
                    longitude: 1.2221,
                    formattedAddress: 'Boulevard du 13 Janvier, Lomé, Togo',
                    street: 'Boulevard du 13 Janvier',
                    city: 'Lomé',
                    postalCode: '',
                    country: 'Togo',
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Adresse par défaut sélectionnée (Lomé)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Adresse par défaut'),
            ),
          ),

          // Bouton position actuelle
          Positioned(
            right: 16,
            bottom: _selectedLocation != null ? 200 : 100,
            child: FloatingActionButton(
              heroTag: 'current_location',
              onPressed: _isLoadingCurrentLocation ? null : _useCurrentLocation,
              backgroundColor: theme.colorScheme.surface,
              child: _isLoadingCurrentLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.my_location, color: theme.colorScheme.primary),
            ),
          ),

          // Carte d'information de l'adresse sélectionnée
          if (_selectedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Localisation sélectionnée',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedLocation!.formattedAddress,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          onPressed: _confirmLocation,
                          text: 'Confirmer cette localisation',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
