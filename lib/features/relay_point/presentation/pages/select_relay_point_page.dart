import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/widgets/input.dart';
import '../../domain/models/relay_point.dart';
import '../providers/relay_point_provider.dart';

/// Page de sélection d'un point relais, alimentée par la collection
/// Firestore `relayPoints` (carte + liste, mêmes données).
class SelectRelayPointPage extends ConsumerStatefulWidget {
  const SelectRelayPointPage({super.key});

  @override
  ConsumerState<SelectRelayPointPage> createState() =>
      _SelectRelayPointPageState();
}

class _SelectRelayPointPageState extends ConsumerState<SelectRelayPointPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  static const _initialPosition = CameraPosition(
    target: LatLng(6.1256, 1.2221), // Lomé
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectRelayPoint(RelayPoint relayPoint) {
    Navigator.pop(context, relayPoint);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relayPointsAsync = ref.watch(relayPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un point relay'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: Input(
              controller: _searchController,
              placeholder: 'Ville, nom de rue ou code postal',
              prefixIcon: const Icon(Icons.search),
            ),
          ),

          // Tabs: Carte & Liste des relais
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Carte'),
              Tab(text: 'Liste des relais'),
            ],
          ),

          // Contenu des tabs
          Expanded(
            child: relayPointsAsync.when(
              data: (relayPoints) {
                if (relayPoints.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMapTab(relayPoints),
                    _buildListTab(relayPoints, theme),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Erreur de chargement : $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun point relais disponible pour le moment',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(List<RelayPoint> relayPoints) {
    final markers = relayPoints
        .map(
          (relay) => Marker(
            markerId: MarkerId(relay.id),
            position: LatLng(relay.latitude, relay.longitude),
            infoWindow: InfoWindow(
              title: relay.name,
              snippet: relay.address,
              onTap: () => _selectRelayPoint(relay),
            ),
            onTap: () => _selectRelayPoint(relay),
          ),
        )
        .toSet();

    return GoogleMap(
      initialCameraPosition: _initialPosition,
      markers: markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  Widget _buildListTab(List<RelayPoint> relayPoints, ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: relayPoints.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildRelayCard(relayPoints[index], theme);
      },
    );
  }

  Widget _buildRelayCard(RelayPoint relay, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectRelayPoint(relay),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône du point relais
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.store,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Infos du point relais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom
                      Text(
                        relay.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Adresse
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              relay.address,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Horaires
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            relay.hours,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
