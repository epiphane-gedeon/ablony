import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../l10n/app_localizations.dart';
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

  // ── Recherche de lieu ────────────────────────────────────────────────
  final TextEditingController _rechercheControleur = TextEditingController();
  final FocusNode _rechercheFocus = FocusNode();
  List<PlaceSuggestion> _suggestions = const [];
  bool _rechercheEnCours = false;
  String? _messageRecherche;

  /// On n'interroge pas Google à chaque touche : on attend une courte pause
  /// dans la frappe. Sans cela, « Adidogomé » déclencherait dix appels — dix
  /// fois facturés — pour une seule recherche.
  Timer? _debounce;
  static const Duration _delaiFrappe = Duration(milliseconds: 350);

  /// Identifie une recherche, du premier caractère jusqu'au lieu retenu.
  /// Google facture alors l'ensemble comme une seule session.
  String? _jetonSession;

  /// Le plafond doit tenir sur 31 bits : compilé en JavaScript, `1 << 32` vaut
  /// 0 — les opérations binaires y sont sur 32 bits — et `nextInt(0)` lève une
  /// exception. Sur mobile la même ligne passait, si bien que la recherche ne
  /// cassait que sur le web, sans le moindre message.
  String _nouveauJeton() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7FFFFFFF)}';

  @override
  void dispose() {
    _debounce?.cancel();
    _rechercheControleur.dispose();
    _rechercheFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Appelé à chaque frappe : relance le compte à rebours, sans interroger
  /// Google tant que la saisie continue.
  void _onSaisieChangee(String saisie) {
    _debounce?.cancel();

    if (saisie.trim().length < 3) {
      setState(() {
        _suggestions = const [];
        _messageRecherche = null;
      });
      return;
    }

    // Ce qui est jeté ici part depuis `onChanged`, donc de façon synchrone :
    // sans ce filet, l'erreur remonte hors du champ de saisie et l'écran ne
    // montre rien du tout — ni suggestion, ni message. C'est exactement ce qui
    // masquait la panne du jeton de session.
    try {
      _jetonSession ??= _nouveauJeton();
    } catch (e) {
      setState(() {
        _messageRecherche = AppLocalizations.of(context)!.locationSearchFailed;
      });
      return;
    }

    _debounce = Timer(_delaiFrappe, () => _proposer(saisie));
  }

  Future<void> _proposer(String saisie) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _rechercheEnCours = true;
      _messageRecherche = null;
    });

    try {
      final trouves = await ref.read(locationServiceProvider).suggestPlaces(
            saisie,
            sessionToken: _jetonSession!,
          );
      if (!mounted) return;
      // La saisie a pu changer pendant l'appel : une réponse en retard ne doit
      // pas écraser des suggestions plus récentes.
      if (_rechercheControleur.text.trim() != saisie.trim()) return;
      setState(() {
        _suggestions = trouves;
        _messageRecherche =
            trouves.isEmpty ? l10n.locationSearchNoResult(saisie.trim()) : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _messageRecherche = l10n.locationSearchFailed);
    } finally {
      if (mounted) setState(() => _rechercheEnCours = false);
    }
  }

  /// L'utilisateur retient une suggestion : on va chercher ses coordonnées,
  /// ce qui clôt la session de facturation, puis la carte s'y rend.
  Future<void> _choisirSuggestion(PlaceSuggestion suggestion) async {
    final l10n = AppLocalizations.of(context)!;
    _debounce?.cancel();
    _rechercheFocus.unfocus();
    setState(() {
      _rechercheEnCours = true;
      _suggestions = const [];
      _rechercheControleur.text = suggestion.title;
    });

    try {
      final lieu = await ref.read(locationServiceProvider).placeDetails(
            suggestion.placeId,
            sessionToken: _jetonSession!,
          );
      if (!mounted) return;
      _jetonSession = null; // la session est close
      setState(() {
        _selectedLocation = lieu;
        _rechercheControleur.text = lieu.formattedAddress;
      });
      _updateMarker(lieu.latitude, lieu.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lieu.latitude, lieu.longitude), 16),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _messageRecherche = l10n.locationSearchFailed);
    } finally {
      if (mounted) setState(() => _rechercheEnCours = false);
    }
  }

  /// Repli sur la touche Entrée : une recherche par géocodage, qui ne dépend
  /// pas de Places. Si les suggestions sont indisponibles, taper son lieu puis
  /// valider fonctionne quand même.
  Future<void> _rechercheDirecte(String saisie) async {
    final terme = saisie.trim();
    if (terme.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    _debounce?.cancel();
    _rechercheFocus.unfocus();
    setState(() {
      _rechercheEnCours = true;
      _messageRecherche = null;
      _suggestions = const [];
    });

    try {
      final trouves =
          await ref.read(locationServiceProvider).searchAddress(terme);
      if (!mounted) return;
      if (trouves.isEmpty) {
        setState(() => _messageRecherche = l10n.locationSearchNoResult(terme));
        return;
      }
      final lieu = trouves.first;
      setState(() {
        _selectedLocation = lieu;
        _rechercheControleur.text = lieu.formattedAddress;
      });
      _updateMarker(lieu.latitude, lieu.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lieu.latitude, lieu.longitude), 16),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _messageRecherche = l10n.locationSearchFailed);
    } finally {
      if (mounted) setState(() => _rechercheEnCours = false);
    }
  }

  void _effacerRecherche() {
    _debounce?.cancel();
    setState(() {
      _rechercheControleur.clear();
      _suggestions = const [];
      _messageRecherche = null;
    });
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.locationCurrentFailed),
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

  /// Appelé quand l'utilisateur sélectionne une position (tap ou déplacement
  /// du marqueur).
  ///
  /// On pose d'abord une localisation minimale, à partir des seules
  /// coordonnées, pour que le bouton « Confirmer » apparaisse *immédiatement*.
  /// Le géocodage inverse ne fait qu'enrichir l'adresse ; s'il échoue (réseau,
  /// point sans adresse connue), il ne doit pas empêcher de valider — sinon on
  /// se retrouve avec un point choisi sur la carte mais aucun bouton pour
  /// continuer.
  Future<void> _onLocationSelected(double latitude, double longitude) async {
    final repli = LocationData(
      latitude: latitude,
      longitude: longitude,
      formattedAddress:
          'Point sélectionné (${latitude.toStringAsFixed(5)}, '
          '${longitude.toStringAsFixed(5)})',
    );
    if (mounted) {
      setState(() => _selectedLocation = repli);
    }

    try {
      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getAddressFromCoordinates(
        latitude,
        longitude,
      );
      if (location != null && mounted) {
        setState(() => _selectedLocation = location);
      }
    } catch (_) {
      // Géocodage indisponible : on garde le repli (coordonnées), le point
      // reste validable.
    }
  }

  /// Confirme et retourne la localisation sélectionnée
  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop(_selectedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.locationSelectPrompt)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.locationPickTitle),
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

          // Recherche de lieu, en tête de carte : on ne se fait pas forcément
          // livrer là où l'on se trouve.
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _BarreRecherche(
              controleur: _rechercheControleur,
              focus: _rechercheFocus,
              enCours: _rechercheEnCours,
              suggestions: _suggestions,
              message: _messageRecherche,
              onChanged: _onSaisieChangee,
              onSubmit: _rechercheDirecte,
              onClear: _effacerRecherche,
              onChoisir: _choisirSuggestion,
            ),
          ),

          // L'ancien bouton « Adresse par défaut » posait une adresse en dur
          // (Boulevard du 13 Janvier, Lomé). C'était un échafaudage de
          // développement, marqué « temporaire », du temps où la carte n'avait
          // pas de recherche : il livrait tout le monde au même endroit. La
          // recherche de lieu et le bouton « ma position » le remplacent.

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

/// La barre de recherche posée sur la carte, et la liste des lieux trouvés.
///
/// Les résultats s'affichent juste sous le champ plutôt que dans une page à
/// part : on voit la carte bouger en choisissant, et on peut rectifier sans
/// repartir en arrière.
class _BarreRecherche extends StatelessWidget {
  const _BarreRecherche({
    required this.controleur,
    required this.focus,
    required this.enCours,
    required this.suggestions,
    required this.message,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onChoisir,
  });

  final TextEditingController controleur;
  final FocusNode focus;
  final bool enCours;
  final List<PlaceSuggestion> suggestions;
  final String? message;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  final ValueChanged<PlaceSuggestion> onChoisir;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
          // Le champ ne se reconstruit pas de lui-même à la frappe : on écoute
          // le contrôleur pour que la croix d'effacement suive la saisie.
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controleur,
            builder: (context, valeur, _) => TextField(
              controller: controleur,
              focusNode: focus,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmit,
              decoration: InputDecoration(
                hintText: l10n.locationSearchHint,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: enCours
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (valeur.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: onClear,
                          )),
              ),
            ),
          ),
        ),
        if (message != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message!, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = suggestions[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: s.subtitle.isEmpty
                      ? null
                      : Text(
                          s.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => onChoisir(s),
                );
              },
            ),
          ),
      ],
    );
  }
}
