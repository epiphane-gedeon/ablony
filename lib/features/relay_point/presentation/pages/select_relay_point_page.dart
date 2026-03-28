import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/input.dart';

/// Page de sélection d'un point relais
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Carte
                _buildMapTab(theme),

                // Tab Liste des relais
                _buildListTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Carte interactive',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'À implémenter avec Google Maps',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(ThemeData theme) {
    // Liste générique de points relais pour démonstration
    final relayPoints = [
      {
        'name': 'Point Relais Lomé Centre',
        'address': '12 Avenue de la Libération, Lomé',
        'distance': '1.2 km',
        'hours': 'Lun-Sam: 8h-18h',
      },
      {
        'name': 'Relais Express Tokoin',
        'address': '45 Rue du Commerce, Tokoin',
        'distance': '2.5 km',
        'hours': 'Lun-Ven: 9h-17h',
      },
      {
        'name': 'Point Relais Hédzranawoé',
        'address': '23 Boulevard Circulaire, Hédzranawoé',
        'distance': '3.8 km',
        'hours': 'Lun-Sam: 8h-19h',
      },
      {
        'name': 'Relais Agoè',
        'address': '67 Route Nationale, Agoè',
        'distance': '5.1 km',
        'hours': 'Lun-Dim: 8h-20h',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: relayPoints.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final relay = relayPoints[index];
        return _buildRelayCard(relay, theme);
      },
    );
  }

  Widget _buildRelayCard(Map<String, String> relay, ThemeData theme) {
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
          onTap: () {
            // TODO: Sélectionner ce point relais
            Navigator.pop(context, relay);
          },
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
                    color: theme.colorScheme.primary.withOpacity(0.1),
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
                        relay['name']!,
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
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              relay['address']!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
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
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            relay['hours']!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Distance
                Column(
                  children: [
                    Text(
                      relay['distance']!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
