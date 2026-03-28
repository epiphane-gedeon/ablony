# Feature Location

Cette feature fournit une fonctionnalité de sélection de localisation réutilisable dans toute l'application.

## Structure

```
lib/features/location/
├── data/
│   └── models/
│       └── location_data.dart          # Modèle de données de localisation
├── presentation/
│   ├── providers/
│   │   └── location_provider.dart      # Service de localisation (GPS + geocoding)
│   └── pages/
│       └── select_location_page.dart   # Page de sélection sur carte
```

## Utilisation

### 1. Dans votre page

```dart
import '../../location/data/models/location_data.dart';
import '../../location/presentation/pages/select_location_page.dart';

class YourPage extends StatefulWidget {
  // ...
}

class _YourPageState extends State<YourPage> {
  LocationData? _selectedLocation;

  Future<void> _selectLocation() async {
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectLocationPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _selectLocation,
          child: Text('Choisir une localisation'),
        ),
        if (_selectedLocation != null)
          Text(_selectedLocation!.formattedAddress),
      ],
    );
  }
}
```

### 2. Données disponibles

Le modèle `LocationData` contient :

- `latitude` : Latitude GPS
- `longitude` : Longitude GPS
- `formattedAddress` : Adresse complète formatée
- `street` : Nom de la rue (optionnel)
- `postalCode` : Code postal (optionnel)
- `city` : Ville (optionnel)
- `country` : Pays (optionnel)

### 3. Fonctionnalités de SelectLocationPage

La page offre deux moyens de sélectionner une localisation :

1. **Position actuelle** : Bouton GPS flottant qui récupère la position actuelle de l'utilisateur
2. **Sélection manuelle** : Tap sur la carte ou drag du marker pour choisir précisément

## Configuration requise

Voir [GOOGLE_MAPS_SETUP.md](../../../GOOGLE_MAPS_SETUP.md) pour les instructions de configuration complètes.

### Packages

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
```

### Permissions Android

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Permissions iOS

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Description de l'utilisation de la localisation</string>
```

## Activation du code

Le code de la carte Google Maps est actuellement commenté. Pour l'activer :

1. Configurez vos clés API Google Maps (voir GOOGLE_MAPS_SETUP.md)
2. Décommentez le code dans :
   - `location_provider.dart` (imports et méthodes)
   - `select_location_page.dart` (widget GoogleMap)

## Exemple d'utilisation actuelle

Actuellement utilisé dans :
- **AddAddressPage** : Pour sélectionner la localisation d'une adresse de livraison

## Réutilisabilité

Cette feature peut être utilisée pour :
- ✅ Adresses de livraison
- ✅ Points de retrait / relais
- ✅ Localisation de magasins
- ✅ Points d'intérêt
- ✅ Toute fonctionnalité nécessitant une sélection de localisation

## Service de localisation

Le `LocationService` (via `locationServiceProvider`) expose :

```dart
// Obtenir la position actuelle
Future<LocationData?> getCurrentLocation()

// Convertir coordonnées → adresse
Future<LocationData?> getAddressFromCoordinates(double lat, double lng)

// Ouvrir les paramètres de localisation du système
Future<void> openLocationSettings()
```
