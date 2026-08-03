import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  GoogleMapController? _mapController;
  LocationData? _selectedLocation;
  bool _isLoadingCurrentLocation = false;

  // Position initiale (Lomé, Togo)
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(6.1256, 1.2221),
    zoom: 14,
  );

  Set<Marker> _markers = {};

  @override
  void dispose() {
    _mapController?.dispose();
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
        });
        // Déplacer la caméra vers la position actuelle
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(location.latitude, location.longitude)),
        );
        // Ajouter un marker
        _updateMarker(location.latitude, location.longitude);
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
                _updateMarker(6.1256, 1.2221);
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
