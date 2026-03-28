# Configuration Google Maps

Ce document explique comment configurer Google Maps pour la fonctionnalité de localisation dans l'application Ablony.

## 1. Obtenir une clé API Google Maps

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez les APIs suivantes :
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API**
4. Créez des identifiants (clé API)
5. Restreignez la clé API par application (recommandé pour la sécurité)

## 2. Configuration Android

### android/app/src/main/AndroidManifest.xml

Ajoutez la clé API et les permissions dans le fichier `AndroidManifest.xml` :

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissions de localisation -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="ablony"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Clé API Google Maps -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="VOTRE_CLE_API_ANDROID"/>

        <!-- Reste de la configuration -->
        <activity
            android:name=".MainActivity"
            ... >
        </activity>
    </application>
</manifest>
```

### android/app/build.gradle.kts

Assurez-vous que `minSdkVersion` est au moins 21 :

```kotlin
android {
    defaultConfig {
        minSdk = 21  // Minimum requis pour Google Maps
        targetSdk = flutter.targetSdkVersion
    }
}
```

## 3. Configuration iOS

### ios/Runner/AppDelegate.swift

Ajoutez l'import et la configuration de la clé API :

```swift
import UIKit
import Flutter
import GoogleMaps  // Ajoutez cette ligne

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurez la clé API Google Maps
    GMSServices.provideAPIKey("VOTRE_CLE_API_IOS")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### ios/Runner/Info.plist

Ajoutez les descriptions pour les permissions de localisation :

```xml
<dict>
    <!-- Autres configurations -->
    
    <!-- Permission de localisation -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Nous avons besoin de votre localisation pour faciliter la saisie de votre adresse de livraison</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Nous avons besoin de votre localisation pour faciliter la saisie de votre adresse de livraison</string>
</dict>
```

### ios/Podfile

Assurez-vous que la version minimale d'iOS est au moins 13.0 :

```ruby
platform :ios, '13.0'  # Minimum requis pour Google Maps
```

Puis exécutez :

```bash
cd ios
pod install
cd ..
```

## 4. Décommenter le code

Une fois les clés API configurées, décommentez le code dans les fichiers suivants :

### lib/features/location/presentation/providers/location_provider.dart
- Décommentez les imports `geolocator` et `geocoding`
- Décommentez les méthodes `_checkPermissions()`, `getCurrentLocation()`, `getAddressFromCoordinates()`

### lib/features/location/presentation/pages/select_location_page.dart
- Décommentez l'import `google_maps_flutter`
- Décommentez les déclarations de variables (GoogleMapController, CameraPosition, Markers)
- Décommentez le widget `GoogleMap`
- Décommentez la méthode `_updateMarker()`

## 5. Test de la configuration

1. Lancez l'application sur un appareil réel (la localisation ne fonctionne pas bien sur émulateur)
2. Allez dans la page "Ajouter une adresse"
3. Cliquez sur "Choisir ma localisation"
4. La carte devrait s'afficher
5. Testez le bouton de position actuelle (GPS)

## 6. Sécurité

⚠️ **Important :** Ne partagez jamais vos clés API publiquement

- Restreignez vos clés API par application
- Utilisez des variables d'environnement pour les builds de production
- Configurez des quotas dans Google Cloud Console

## 7. Dépannage

### La carte ne s'affiche pas
- Vérifiez que la clé API est correcte
- Vérifiez que les APIs sont activées dans Google Cloud Console
- Vérifiez les logs pour les erreurs de permission

### La localisation ne fonctionne pas
- Assurez-vous d'être sur un appareil réel
- Vérifiez que les permissions sont accordées dans les paramètres de l'appareil
- Vérifiez que les services de localisation sont activés

### Geocoding ne retourne rien
- Vérifiez que l'API Geocoding est activée
- Vérifiez votre quota dans Google Cloud Console
- Assurez-vous d'avoir une connexion internet

## 8. Ressources

- [Documentation Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Documentation Geolocator](https://pub.dev/packages/geolocator)
- [Documentation Geocoding](https://pub.dev/packages/geocoding)
- [Google Cloud Console](https://console.cloud.google.com/)
