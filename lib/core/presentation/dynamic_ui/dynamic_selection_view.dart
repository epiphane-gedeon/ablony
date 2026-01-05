import 'package:flutter/material.dart';

import 'package:ablony/shared/widgets/buttons/primary_button.dart';
import 'package:ablony/shared/widgets/input.dart';
import '../../../l10n/app_localizations.dart';
import '../pages/selection_screen.dart';
import 'json_component_mapper.dart';

typedef DataFetcher =
    Future<List<Map<String, dynamic>>> Function(String? param);

/// Vue dynamique générée à partir d'une configuration JSON.
class DynamicSelectionView extends StatefulWidget {
  final Map<String, dynamic> config;
  final Map<String, dynamic>? initialData;
  final ValueChanged<dynamic> onResult;
  final Map<String, DataFetcher> dataSources;

  const DynamicSelectionView({
    super.key,
    required this.config,
    this.initialData,
    required this.onResult,
    this.dataSources = const {},
  });

  @override
  State<DynamicSelectionView> createState() => _DynamicSelectionViewState();
}

class _DynamicSelectionViewState extends State<DynamicSelectionView> {
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<Map<String, dynamic>>>? _dataFuture;

  // Configuration extraite
  late List<dynamic> _fields;
  late Map<String, dynamic> _action;
  late String _type; // 'form' (default) or 'list'

  @override
  void initState() {
    super.initState();
    _parseConfig();
    _initDataFuture();
  }

  void _initDataFuture() {
    if (_type == 'list') {
      final dataSourceKey = widget.config['dataSource'] as String?;
      final fetchParam = widget.config['fetchParam'] as String?;
      if (dataSourceKey != null &&
          widget.dataSources.containsKey(dataSourceKey)) {
        _dataFuture = widget.dataSources[dataSourceKey]!(fetchParam);
      }
    }
  }

  void _parseConfig() {
    _type = widget.config['type'] as String? ?? 'form';
    _fields = widget.config['fields'] as List<dynamic>? ?? [];
    _action = widget.config['action'] as Map<String, dynamic>? ?? {};

    // Initialiser les contrôleurs si c'est un formulaire
    if (_type == 'form') {
      for (var field in _fields) {
        final key = field['key'] as String;
        final initialValue = widget.initialData?[key]?.toString() ?? '';
        _controllers[key] = TextEditingController(text: initialValue);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _validate() {
    // Pour l'instant, on suppose une validation simple : required
    // TODO: Implémenter une validation plus robuste basée sur le JSON

    final returnKey = _action['returnKey'] as String?;
    if (returnKey != null) {
      // Retourne la valeur brute (String pour l'instant)
      // L'appelant devra convertir si nécessaire (ex: double.parse)
      final value = _controllers[returnKey]?.text;
      widget.onResult(value);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_type == 'list') {
      return _buildList();
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._fields.map((field) {
            final key = field['key'] as String;
            final type = field['type'] as String;
            final props = field['props'] as Map<String, dynamic>? ?? {};

            if (type == 'input') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (props['label'] != null) ...[
                      Text(
                        props['label'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Input(
                      controller: _controllers[key],
                      placeholder: props['placeholder'],
                      type: JsonComponentMapper.getInputType(
                        props['inputType'],
                      ),
                      autofocus: props['autofocus'] ?? false,
                      suffixIcon: props['suffixIcon'] != null
                          ? Icon(
                              JsonComponentMapper.getIcon(props['suffixIcon']),
                            )
                          : null,
                      onSubmitted: (_) => _validate(),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink(); // Type inconnu
          }),

          const Spacer(),

          if (_action.isNotEmpty)
            PrimaryButton(
              text: _action['label'] ?? 'Valider',
              onPressed: _validate,
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildList() {
    final itemKey = widget.config['itemKey'] as String? ?? 'id';
    final itemLabel = widget.config['itemLabel'] as String? ?? 'label';
    final itemIcon = widget.config['itemIcon'] as String? ?? 'icon';
    final nextAction =
        widget.config['nextAction'] as String?; // 'navigate_recursive'

    if (_dataFuture == null) {
      return const Center(child: Text('Source de données manquante'));
    }

    return Column(
      children: [
        // Search Bar (Outside FutureBuilder to keep focus and state)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Input(
            controller: _searchController,
            placeholder: AppLocalizations.of(context)!.searchPlaceholder,
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              final allItems = snapshot.data ?? [];
              final items = allItems.where((item) {
                if (_searchQuery.isEmpty) return true;
                final label = (item[itemLabel] as String? ?? '').toLowerCase();
                return label.contains(_searchQuery.toLowerCase());
              }).toList();

              if (items.isEmpty) {
                return const Center(child: Text('Aucun élément trouvé'));
              }

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final hasChildren = item['hasChildren'] == true;
                  return ListTile(
                    title: Text(
                      item[itemLabel] as String? ?? 'Inconnu',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    leading: item[itemIcon] != null
                        ? Icon(
                            JsonComponentMapper.getIcon(
                              item[itemIcon] as String,
                            ),
                          )
                        : null,
                    trailing: hasChildren
                        ? const Icon(Icons.chevron_right, color: Colors.grey)
                        : Icon(
                            Icons.circle_outlined,
                            size: 20,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                          ),
                    onTap: () {
                      if (nextAction == 'navigate_recursive' && hasChildren) {
                        _navigateToNextLevel(item, itemKey);
                      } else {
                        // Return result - parent will handle navigation
                        widget.onResult(item);
                      }
                    },
                    selected: widget.initialData?[itemKey] == item[itemKey],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToNextLevel(Map<String, dynamic> item, String keyField) {
    // Configuration récursive
    // On suppose que le prochain niveau utilise une source différente ou paramétrée
    final currentSource = widget.config['dataSource'] as String;
    String nextSource = currentSource;
    if (currentSource == 'categories') {
      nextSource = 'subcategories';
    }

    final nextConfig = {
      'type': 'list',
      'dataSource': nextSource,
      'fetchParam': item[keyField], // Pass ID as param
      'itemKey': 'id',
      'itemLabel': 'name',
      'itemIcon': 'iconUrl',
      'nextAction': 'navigate_recursive', // Continue recursion
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectionScreen(
          title: item['name'] as String? ?? 'Sélection',
          content: DynamicSelectionView(
            config: nextConfig,
            dataSources: widget.dataSources, // Pass the registry
            onResult: widget.onResult, // Pass the original callback
          ),
        ),
      ),
    );
  }
}
