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
  State<DynamicSelectionView> createState() => DynamicSelectionViewState();
}

class DynamicSelectionViewState extends State<DynamicSelectionView> {
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<Map<String, dynamic>>>? _dataFuture;
  Set<String> _selectedItems = {}; // Pour la sélection multiple

  // Configuration extraite
  late List<dynamic> _fields;
  late Map<String, dynamic> _action;
  late String _type; // 'form' (default) or 'list'
  late bool _multiSelect; // Mode multi-sélection

  /// Méthode publique pour vider les sélections
  void clearSelections() {
    setState(() {
      _selectedItems.clear();
    });
  }

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

  late int? _maxSelection; // Limite de sélection (null = illimité)

  void _parseConfig() {
    _type = widget.config['type'] as String? ?? 'form';
    _fields = widget.config['fields'] as List<dynamic>? ?? [];
    _action = widget.config['action'] as Map<String, dynamic>? ?? {};
    _multiSelect = widget.config['multiSelect'] as bool? ?? false;
    _maxSelection = widget.config['maxSelection'] as int?;

    // Initialiser les contrôleurs si c'est un formulaire
    if (_type == 'form') {
      for (var field in _fields) {
        final key = field['key'] as String;
        final initialValue = widget.initialData?[key]?.toString() ?? '';
        _controllers[key] = TextEditingController(text: initialValue);
      }
    }

    // Initialiser les items sélectionnés si c'est une liste multi-select
    if (_type == 'list' && _multiSelect && widget.initialData != null) {
      final selectedIds = widget.initialData!['selectedIds'];
      if (selectedIds is List) {
        _selectedItems = Set<String>.from(selectedIds.map((e) => e.toString()));
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
    final l10n = AppLocalizations.of(context)!;
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

              // Check if we should show "Tous" option (configurable via showAllOption)
              final showAllOption =
                  (widget.config['showAllOption'] as bool? ?? false) &&
                  nextAction == 'navigate_recursive' &&
                  items.isNotEmpty;
              final listItemCount = items.length + (showAllOption ? 1 : 0);

              return ListView.separated(
                itemCount: listItemCount,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                itemBuilder: (context, index) {
                  // If showing "Tous" option, it's the first item
                  if (showAllOption && index == 0) {
                    final fetchParam = widget.config['fetchParam'] as String?;
                    final parentName = widget.config['parentName'] as String?;
                    final isParentSelected = fetchParam != null
                        ? _selectedItems.contains(fetchParam)
                        : _selectedItems
                              .isEmpty; // At first level, "Tous" = no selection

                    return ListTile(
                      title: Text(
                        l10n.filterAllCategories,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      leading: const Icon(Icons.grid_view_rounded),
                      trailing: _multiSelect
                          ? (_maxSelection == 1
                                ? Icon(
                                    isParentSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 20,
                                    color: isParentSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.4),
                                  )
                                : Checkbox(
                                    value: isParentSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          if (fetchParam != null) {
                                            _selectedItems.add(fetchParam);
                                          } else {
                                            _selectedItems.clear();
                                          }
                                        } else {
                                          if (fetchParam != null) {
                                            _selectedItems.remove(fetchParam);
                                          }
                                        }
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ))
                          : Icon(
                              Icons.circle_outlined,
                              size: 20,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                            ),
                      onTap: () {
                        if (_multiSelect) {
                          setState(() {
                            _selectedItems.clear();
                            if (fetchParam != null) {
                              // Sub-level: select parent category
                              _selectedItems.add(fetchParam);
                            }
                            // Else: first level, keep empty = reset filter
                          });
                        } else {
                          // For single select, return immediately
                          if (fetchParam != null) {
                            widget.onResult({
                              'id': fetchParam,
                              'name': parentName ?? l10n.filterAllCategories,
                            });
                          } else {
                            // First level: return null to reset filter
                            widget.onResult({'reset': true});
                          }
                        }
                      },
                    );
                  }

                  // Adjust index if "Tous" was added
                  final itemIndex = showAllOption ? index - 1 : index;
                  final item = items[itemIndex];
                  final hasChildren = item['hasChildren'] == true;
                  final itemId = item[itemKey] as String? ?? '';
                  final isSelected = _selectedItems.contains(itemId);

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
                        : _multiSelect
                        ? (_maxSelection == 1
                              ? Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface
                                            .withOpacity(0.4),
                                )
                              : Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedItems.add(itemId);
                                      } else {
                                        _selectedItems.remove(itemId);
                                      }
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ))
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
                      } else if (_multiSelect) {
                        // Mode multi-select: toggle selection
                        setState(() {
                          if (_selectedItems.contains(itemId)) {
                            _selectedItems.remove(itemId);
                          } else {
                            // Si maxSelection est défini, limiter la sélection
                            if (_maxSelection != null &&
                                _selectedItems.length >= _maxSelection!) {
                              _selectedItems.clear();
                            }
                            _selectedItems.add(itemId);
                          }
                        });
                      } else {
                        // Mode single-select: return result immediately
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

        // Bouton de validation pour la sélection multiple
        if (_multiSelect)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
            ),
            child: PrimaryButton(
              text: l10n.filterValidate,
              onPressed: () {
                // Retourner les items sélectionnés (peut être vide pour tout désélectionner)
                widget.onResult({'selectedIds': _selectedItems.toList()});
              },
            ),
          ),
      ],
    );
  }

  Future<void> _navigateToNextLevel(
    Map<String, dynamic> item,
    String keyField,
  ) async {
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
      'parentName': item['name'], // Pass parent name for "Tous" option
      'itemKey': 'id',
      'itemLabel': 'name',
      'itemIcon': 'iconUrl',
      'nextAction': 'navigate_recursive', // Continue recursion
      'multiSelect': widget.config['multiSelect'], // Preserve multiSelect
      'maxSelection': widget.config['maxSelection'], // Preserve maxSelection
      'showAllOption': widget.config['showAllOption'], // Preserve showAllOption
    };

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/category-filter-sub'),
        builder: (context) => SelectionScreen(
          title: item['name'] as String? ?? 'Sélection',
          content: DynamicSelectionView(
            config: nextConfig,
            initialData: _selectedItems.isNotEmpty
                ? {'selectedIds': _selectedItems.toList()}
                : null, // Propagate current selection
            dataSources: widget.dataSources, // Pass the registry
            onResult: widget.onResult, // Pass the original callback
          ),
        ),
      ),
    );

    // If we got a result from deeper level, propagate it up
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }
}
