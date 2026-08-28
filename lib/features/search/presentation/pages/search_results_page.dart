import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/dynamic_ui/dynamic_selection_view.dart';
import '../../../../core/presentation/pages/selection_screen.dart';
import '../../../../core/presentation/pages/selection_sheet.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/utils/category_translator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/filter_chip_list.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../product/domain/entities/entities.dart';
import '../../../product/presentation/providers/category_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';

/// Page des résultats de recherche
///
/// Affiche les produits correspondant à la requête de recherche
class SearchResultsPage extends ConsumerStatefulWidget {
  final String query;
  final String? categoryId;
  final String? categoryName;

  const SearchResultsPage({
    super.key,
    required this.query,
    this.categoryId,
    this.categoryName,
  });

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  List<Product> _results = [];
  bool _isLoading = true;

  // État des filtres
  List<String> _selectedBrands = [];
  List<String> _selectedColors = [];
  List<String> _selectedSizes = [];
  List<String> _selectedConditions = [];
  List<String> _selectedMaterials = [];
  double? _minPrice;
  double? _maxPrice;
  String? _sortBy;
  String? _selectedCategoryId; // ID de catégorie ou sous-catégorie
  String? _selectedCategoryName; // Nom pour affichage

  // Cache pour vérifier les catégories intermédiaires
  final Map<String, String> _subcategoryParentCache = {};

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _selectedCategoryName = widget.categoryName;
    _performSearch();
  }

  /// Effectue la recherche
  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(productRepositoryProvider);
      final products = await repository.searchProducts(widget.query);

      setState(() {
        _results = products;
        _isLoading = false;
      });

      // Précharger les sous-catégories pour le filtrage
      _loadSubcategoriesCache();
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  /// Précharge le cache des sous-catégories
  Future<void> _loadSubcategoriesCache() async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final categories = await categoryRepo.getCategories();

      // Pour chaque catégorie, charger ses sous-catégories
      for (final category in categories) {
        final subcats = await categoryRepo.getSubcategoriesByParent(
          category.id,
        );
        for (final subcat in subcats) {
          _subcategoryParentCache[subcat.id] = category.id;

          // Si la sous-catégorie a elle-même des enfants, les charger aussi
          if (subcat.isBranch) {
            final deepSubcats = await categoryRepo.getSubcategoriesByParent(
              subcat.id,
            );
            for (final deepSubcat in deepSubcats) {
              _subcategoryParentCache[deepSubcat.id] = subcat.id;
            }
          }
        }
      }
    } catch (e) {
      // Ignorer les erreurs de préchargement
    }
  }

  /// Vérifie si une sous-catégorie appartient à la catégorie sélectionnée
  bool _isSubcategoryInSelectedCategory(String? subcategoryId) {
    if (subcategoryId == null || _selectedCategoryId == null) {
      return false;
    }

    // Parcourir récursivement la hiérarchie des parents
    String? currentId = subcategoryId;
    final visited = <String>{}; // Pour éviter les boucles infinies

    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);

      // Vérifier si le parent correspond
      final parentId = _subcategoryParentCache[currentId];
      if (parentId == _selectedCategoryId) {
        return true;
      }

      // Remonter au niveau supérieur
      currentId = parentId;
    }

    return false;
  }

  /// Applique les filtres sur les résultats
  List<Product> get _filteredResults {
    List<Product> filtered = List.from(_results);

    // Filtre par catégorie/sous-catégorie
    if (_selectedCategoryId != null) {
      // Pour gérer les catégories intermédiaires, on va vérifier de manière
      // plus approfondie en chargeant les sous-catégories si nécessaire
      filtered = filtered.where((product) {
        // Cas 1: Le produit appartient directement à la catégorie (ex: categoryId = "femme")
        if (product.categoryId == _selectedCategoryId) {
          return true;
        }

        // Cas 2: Le produit appartient directement à la sous-catégorie (ex: subcategoryId = "short_homme")
        if (product.subcategoryId == _selectedCategoryId) {
          return true;
        }

        // Cas 3: Catégorie intermédiaire - Il faut vérifier si la sous-catégorie
        // du produit appartient à la catégorie sélectionnée
        // On utilise les données de la sous-catégorie pour vérifier son parentId
        // Cette vérification sera faite via un helper method
        return _isSubcategoryInSelectedCategory(product.subcategoryId);
      }).toList();
    }

    // Filtre par marque
    if (_selectedBrands.isNotEmpty) {
      filtered = filtered.where((product) {
        for (var selection in _selectedBrands) {
          final parts = selection.split(':');
          if (parts.length == 2) {
            final attrId = parts[0];
            final valueIndexStr = parts[1];
            final productValue = product.attributes[attrId];
            if (productValue != null && productValue.toString() == valueIndexStr) {
              return true;
            }
          } else {
            final brand = product.attributes['brand']?.toString() ??
                          product.attributes['marque']?.toString();
            if (brand != null && selection == brand) return true;
          }
        }
        return false;
      }).toList();
    }

    // Filtre par couleur
    if (_selectedColors.isNotEmpty) {
      filtered = filtered.where((product) {
        for (var selection in _selectedColors) {
          final parts = selection.split(':');
          if (parts.length == 2) {
            final attrId = parts[0];
            final valueIndexStr = parts[1];
            final productValue = product.attributes[attrId];
            if (productValue != null && productValue.toString() == valueIndexStr) {
              return true;
            }
          } else {
            final color = product.attributes['color']?.toString() ??
                          product.attributes['couleur']?.toString();
            if (color != null && selection == color) return true;
          }
        }
        return false;
      }).toList();
    }

    // Filtre par taille
    if (_selectedSizes.isNotEmpty) {
      filtered = filtered.where((product) {
        // Le format de _selectedSizes est "attributeId:valueIndex"
        for (var selection in _selectedSizes) {
          final parts = selection.split(':');
          if (parts.length == 2) {
            final attrId = parts[0];
            final valueIndexStr = parts[1];
            
            final productValue = product.attributes[attrId];
            if (productValue != null && productValue.toString() == valueIndexStr) {
              return true;
            }
          } else {
            // Fallback pour compatibilité avec d'anciennes sélections
            for (var key in product.attributes.keys) {
              if (key.toLowerCase().contains('size') ||
                  key.toLowerCase().contains('taille') ||
                  key.toLowerCase().contains('pointure')) {
                if (product.attributes[key]?.toString() == selection) return true;
              }
            }
          }
        }
        return false;
      }).toList();
    }

    // Filtre par état/condition
    if (_selectedConditions.isNotEmpty) {
      filtered = filtered.where((product) {
        return _selectedConditions.contains(product.condition.index.toString());
      }).toList();
    }

    // Filtre par matière
    if (_selectedMaterials.isNotEmpty) {
      filtered = filtered.where((product) {
        for (var selection in _selectedMaterials) {
          final parts = selection.split(':');
          if (parts.length == 2) {
            final attrId = parts[0];
            final valueIndexStr = parts[1];
            final productValue = product.attributes[attrId];
            if (productValue != null && productValue.toString() == valueIndexStr) {
              return true;
            }
          } else {
            final materialValue = product.attributes['material'] ??
                                product.attributes['matiere'] ??
                                product.attributes['matière'];
            if (materialValue != null && selection == materialValue.toString()) return true;
          }
        }
        return false;
      }).toList();
    }

    // Filtre par prix
    if (_minPrice != null || _maxPrice != null) {
      filtered = filtered.where((product) {
        if (_minPrice != null && product.price < _minPrice!) return false;
        if (_maxPrice != null && product.price > _maxPrice!) return false;
        return true;
      }).toList();
    }

    // Tri
    if (_sortBy != null) {
      switch (_sortBy) {
        case 'price_asc':
          filtered.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          filtered.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'recent':
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'popular':
          filtered.sort((a, b) => b.favoritesCount.compareTo(a.favoritesCount));
          break;
      }
    }

    return filtered;
  }

  /// Vérifie si au moins un filtre est actif
  bool _hasActiveFilters() {
    return _selectedCategoryId != null ||
        _selectedBrands.isNotEmpty ||
        _selectedColors.isNotEmpty ||
        _selectedSizes.isNotEmpty ||
        _selectedConditions.isNotEmpty ||
        _selectedMaterials.isNotEmpty ||
        _minPrice != null ||
        _maxPrice != null ||
        _sortBy != null;
  }

  /// Efface tous les filtres
  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedBrands = [];
      _selectedColors = [];
      _selectedSizes = [];
      _selectedConditions = [];
      _selectedMaterials = [];
      _minPrice = null;
      _maxPrice = null;
      _sortBy = null;
    });
  }

  /// Affiche le panneau de tous les filtres
  void _showAllFilters() {
    final l10n = AppLocalizations.of(context)!;
    SelectionSheet.show(
      context: context,
      title: l10n.filterTitle,
      onClear: () {
        _clearFilters();
        Navigator.pop(context);
      },
      content: Column(
        children: [
          // Section Classer par
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sortBy,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _showSortFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _sortBy == null
                              ? l10n.sortRelevance
                              : _sortBy == 'recent'
                              ? l10n.sortRecent
                              : _sortBy == 'price_asc'
                              ? l10n.sortPriceAsc
                              : _sortBy == 'price_desc'
                              ? l10n.sortPriceDesc
                              : l10n.sortPopular,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),

          // Liste des filtres
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildFilterItem(
                  l10n.filterCategory,
                  _selectedCategoryName ?? l10n.filterAllCategories,
                  _showCategoryFilter,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                _buildFilterItem(
                  l10n.filterSize,
                  _selectedSizes.isEmpty
                      ? l10n.filterAll
                      : _selectedSizes.length <= 3
                      ? _selectedSizes.map((selection) {
                          final parts = selection.split(':');
                          if (parts.length == 2) {
                            return ref.watch(attributeLabelProvider((
                              attributeId: parts[0],
                              value: int.tryParse(parts[1]) ?? parts[1]
                            ))).value ?? selection;
                          }
                          return selection;
                        }).join(', ')
                      : '${_selectedSizes.length} sélectionné(s)',
                  _showSizeFilter,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                _buildFilterItem(
                  l10n.filterBrand,
                  _selectedBrands.isEmpty
                      ? l10n.filterAll
                      : _selectedBrands.length <= 3
                      ? _selectedBrands.map((selection) {
                          final parts = selection.split(':');
                          if (parts.length == 2) {
                            return ref.watch(attributeLabelProvider((
                              attributeId: parts[0],
                              value: int.tryParse(parts[1]) ?? parts[1]
                            ))).value ?? selection;
                          }
                          return selection;
                        }).join(', ')
                      : '${_selectedBrands.length} sélectionné(s)',
                  _showBrandFilter,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                _buildFilterItem(
                  l10n.filterCondition,
                  _selectedConditions.isEmpty
                      ? l10n.filterAll
                      : _selectedConditions.length <= 2
                      ? _selectedConditions.map((id) {
                          return ref.watch(attributeLabelProvider((attributeId: 'condition', value: int.tryParse(id) ?? id))).value ?? id;
                        }).join(', ')
                      : '${_selectedConditions.take(2).map((id) {
                          return ref.watch(attributeLabelProvider((attributeId: 'condition', value: int.tryParse(id) ?? id))).value ?? id;
                        }).join(', ')}...',
                  _showConditionFilter,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                _buildFilterItem(
                  l10n.filterColor,
                  _selectedColors.isEmpty
                      ? l10n.filterAll
                      : _selectedColors.length <= 3
                      ? _selectedColors.map((selection) {
                          final parts = selection.split(':');
                          if (parts.length == 2) {
                            return ref.watch(attributeLabelProvider((
                              attributeId: parts[0],
                              value: int.tryParse(parts[1]) ?? parts[1]
                            ))).value ?? selection;
                          }
                          return selection;
                        }).join(', ')
                      : '${_selectedColors.length} sélectionné(s)',
                  _showColorFilter,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                _buildFilterItem(
                  l10n.filterPrice,
                  _minPrice != null || _maxPrice != null
                      ? l10n.filterCustomPrice
                      : l10n.filterAll,
                  _showPriceFilter,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
                _buildFilterItem(
                  l10n.filterMaterial,
                  _selectedMaterials.isEmpty
                      ? l10n.filterAll
                      : _selectedMaterials.length <= 2
                      ? _selectedMaterials.map((selection) {
                          final parts = selection.split(':');
                          if (parts.length == 2) {
                            return ref.watch(attributeLabelProvider((
                              attributeId: parts[0],
                              value: int.tryParse(parts[1]) ?? parts[1]
                            ))).value ?? selection;
                          }
                          return selection;
                        }).join(', ')
                      : '${_selectedMaterials.length} sélectionné(s)',
                  _showMaterialFilter,
                ),
              ],
            ),
          ),

          // Bouton de validation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
            ),
            child: PrimaryButton(
              text: l10n.filterShowResults,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Recherche récursive du nom de catégorie par ID
  Future<String?> _findCategoryName(String categoryId, String? parentId) async {
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final subcats = await categoryRepo.getSubcategoriesByParent(parentId ?? '');

    for (final subcat in subcats) {
      if (subcat.id == categoryId) {
        return subcat.name;
      }
      // Recherche récursive si c'est une branche
      if (subcat.isBranch) {
        final foundName = await _findCategoryName(categoryId, subcat.id);
        if (foundName != null) {
          return foundName;
        }
      }
    }
    return null;
  }

  /// Affiche le filtre Catégorie avec navigation récursive
  void _showCategoryFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = await ref
        .read(categoryRepositoryProvider)
        .getCategories();

    if (!mounted) return;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/category-filter'),
        builder: (context) => SelectionScreen(
          title: l10n.filterCategory,
          content: DynamicSelectionView(
            initialData: _selectedCategoryId != null
                ? {
                    'selectedIds': [_selectedCategoryId],
                  }
                : null,
            config: {
              'type': 'list',
              'dataSource': 'categories',
              'itemKey': 'id',
              'itemLabel': 'name',
              'nextAction': 'navigate_recursive',
              'multiSelect': true,
              'maxSelection': 1, // Radio button behavior
              'showAllOption':
                  true, // Show "Tous" option in filters (search feature only)
            },
            dataSources: {
              'categories': (_) async => categoriesAsync
                  .map(
                    (cat) => {
                      'id': cat.id,
                      'name': CategoryTranslator.translate(
                        l10n,
                        cat.id,
                        cat.name,
                      ),
                      'hasChildren': true,
                    },
                  )
                  .toList(),
              'subcategories': (parentId) async {
                final subcats = await ref
                    .read(categoryRepositoryProvider)
                    .getSubcategoriesByParent(parentId ?? '');
                return subcats
                    .map(
                      (sub) => {
                        'id': sub.id,
                        'name': CategoryTranslator.translate(
                          l10n,
                          sub.id,
                          sub.name,
                        ),
                        'hasChildren': sub.isBranch,
                      },
                    )
                    .toList();
              },
            },
            onResult: (result) {
              // Just pop with the result - it will propagate through all levels
              if (result != null && result['selectedIds'] != null) {
                // Return the result even if empty (for reset)
                Navigator.of(
                  context,
                ).pop({'selectedIds': result['selectedIds']});
              }
            },
          ),
        ),
      ),
    );

    // Apply the filter when returning from category selection
    if (result != null) {
      if (result['reset'] == true) {
        // "Tous" at first level = reset filter
        setState(() {
          _selectedCategoryId = null;
          _selectedCategoryName = null;
        });
      } else if (result['selectedIds'] != null) {
        final selectedIds = result['selectedIds'] as List<dynamic>;
        if (selectedIds.isEmpty) {
          // Empty selection = reset filter
          setState(() {
            _selectedCategoryId = null;
            _selectedCategoryName = null;
          });
        } else if (selectedIds.isNotEmpty) {
          final selectedId = selectedIds.first as String;
          // Find the category name - check main categories first
          var selectedName = categoriesAsync
              .where((cat) => cat.id == selectedId)
              .map(
                (cat) => CategoryTranslator.translate(l10n, cat.id, cat.name),
              )
              .firstOrNull;

          // If not found in main categories, search recursively in subcategories
          if (selectedName == null) {
            for (final category in categoriesAsync) {
              selectedName = await _findCategoryName(selectedId, category.id);
              if (selectedName != null) {
                // Traduire le nom trouvé
                selectedName = CategoryTranslator.translate(
                  l10n,
                  selectedId,
                  selectedName,
                );
                break;
              }
            }
          }

          setState(() {
            _selectedCategoryId = selectedId;
            _selectedCategoryName = selectedName ?? l10n.filterCategory;
          });
        }
      }
    }
  }

  /// Construit un item de filtre dans la liste
  Widget _buildFilterItem(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            Row(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec barre de recherche
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Bouton retour
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  // Barre de recherche
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.push(
                          '/searching?q=${Uri.encodeComponent(widget.query)}',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 20,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.query,
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Icône favoris
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Filtres en chips
            FilterChipList(
              items: [
                FilterItem(
                  label: 'Filtrer',
                  icon: Icons.tune,
                  isSelected: _hasActiveFilters(),
                  onTap: _showAllFilters,
                ),
                FilterItem(
                  label: 'Couleur',
                  isSelected: _selectedColors.isNotEmpty,
                  onTap: _showColorFilter,
                ),
                FilterItem(
                  label: 'Taille',
                  isSelected: _selectedSizes.isNotEmpty,
                  onTap: _showSizeFilter,
                ),
                FilterItem(
                  label: 'Marque',
                  isSelected: _selectedBrands.isNotEmpty,
                  onTap: _showBrandFilter,
                ),
                FilterItem(
                  label: 'État',
                  isSelected: _selectedConditions.isNotEmpty,
                  onTap: _showConditionFilter,
                ),
                FilterItem(
                  label: 'Prix',
                  isSelected: _minPrice != null || _maxPrice != null,
                  onTap: _showPriceFilter,
                ),
                FilterItem(
                  label: 'Matière',
                  isSelected: _selectedMaterials.isNotEmpty,
                  onTap: _showMaterialFilter,
                ),
                FilterItem(
                  label: 'Classer par',
                  isSelected: _sortBy != null,
                  onTap: _showSortFilter,
                ),
              ],
            ),

            // Contenu selon l'état
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.searchNoResults,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Nombre de résultats
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_filteredResults.length} résultat${_filteredResults.length > 1 ? 's' : ''}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Résultats de recherche',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Grille de produits
                        Expanded(
                          child: ResponsiveProductGrid<Product>(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.pagePadding,
                            ),
                            itemsBuilder: (_) => _filteredResults,
                            itemBuilder: (context, product) {
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  context.push('/product/${product.id}');
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche le filtre Marque de manière contextuelle
  void _showBrandFilter() async {
    final l10n = AppLocalizations.of(context)!;
    
    final attributeIds = <String>{};
    for (var product in _results) {
      final id = product.primaryBrandAttributeId;
      if (id != null) attributeIds.add(id);
    }

    if (attributeIds.isEmpty) return;

    final List<ProductAttribute> attributes = [];
    for (var id in attributeIds) {
      final attr = await ref.read(attributeByIdProvider(id).future);
      attributes.add(attr);
    }

    final Map<String, String> options = {};
    for (var attr in attributes) {
      for (var i = 0; i < attr.values.length; i++) {
        options['${attr.id}:$i'] = attr.values[i];
      }
    }

    if (options.isEmpty) return;

    final entries = options.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));

    if (!mounted) return;
    final contentKey = GlobalKey<DynamicSelectionViewState>();

    SelectionSheet.show(
      context: context,
      title: l10n.filterBrand,
      onClear: () {
        contentKey.currentState?.clearSelections();
      },
      content: DynamicSelectionView(
        key: contentKey,
        config: {
          'type': 'list',
          'dataSource': 'brands',
          'itemKey': 'id',
          'itemLabel': 'name',
          'multiSelect': true,
        },
        initialData: {'selectedIds': _selectedBrands},
        dataSources: {
          'brands': (_) async => entries.map((e) => {
            'id': e.key,
            'name': e.value,
          }).toList(),
        },
        onResult: (result) {
          if (result != null && result['selectedIds'] != null) {
            setState(() {
              _selectedBrands = List<String>.from(result['selectedIds']);
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Affiche le filtre Couleur de manière contextuelle
  void _showColorFilter() async {
    final l10n = AppLocalizations.of(context)!;
    
    final attributeIds = <String>{};
    for (var product in _results) {
      final id = product.primaryColorAttributeId;
      if (id != null) attributeIds.add(id);
    }

    if (attributeIds.isEmpty) return;

    final List<ProductAttribute> attributes = [];
    for (var id in attributeIds) {
      final attr = await ref.read(attributeByIdProvider(id).future);
      attributes.add(attr);
    }

    final Map<String, String> options = {};
    for (var attr in attributes) {
      for (var i = 0; i < attr.values.length; i++) {
        options['${attr.id}:$i'] = attr.values[i];
      }
    }

    if (options.isEmpty) return;

    final entries = options.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));

    if (!mounted) return;
    final contentKey = GlobalKey<DynamicSelectionViewState>();

    SelectionSheet.show(
      context: context,
      title: l10n.filterColor,
      onClear: () {
        contentKey.currentState?.clearSelections();
      },
      content: DynamicSelectionView(
        key: contentKey,
        config: {
          'type': 'list',
          'dataSource': 'colors',
          'itemKey': 'id',
          'itemLabel': 'name',
          'multiSelect': true,
        },
        initialData: {'selectedIds': _selectedColors},
        dataSources: {
          'colors': (_) async => entries.map((e) => {
            'id': e.key,
            'name': e.value,
          }).toList(),
        },
        onResult: (result) {
          if (result != null && result['selectedIds'] != null) {
            setState(() {
              _selectedColors = List<String>.from(result['selectedIds']);
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Affiche le filtre Taille de manière contextuelle
  void _showSizeFilter() async {
    final l10n = AppLocalizations.of(context)!;
    
    // 1. Identifier les IDs d'attributs de taille présents dans les résultats
    final sizeAttributeIds = <String>{};
    for (var product in _results) {
      final id = product.primarySizeAttributeId;
      if (id != null) sizeAttributeIds.add(id);
    }

    if (sizeAttributeIds.isEmpty) return;

    // 2. Récupérer les définitions complètes de ces attributs
    final List<ProductAttribute> sizeAttributes = [];
    for (var id in sizeAttributeIds) {
      final attr = await ref.read(attributeByIdProvider(id).future);
      sizeAttributes.add(attr);
    }

    // 3. Collecter toutes les valeurs possibles et leurs libellés
    // Map de id_global -> label
    final Map<String, String> sizeOptions = {};
    
    for (var attr in sizeAttributes) {
      for (var i = 0; i < attr.values.length; i++) {
        final label = attr.values[i];
        // On utilise "attrId:index" comme ID unique pour le filtre
        sizeOptions['${attr.id}:$i'] = label;
      }
    }

    if (sizeOptions.isEmpty) return;

    // 4. Trier les options (Numérique vs Lettres)
    final entries = sizeOptions.entries.toList();
    entries.sort((a, b) {
      final aLabel = a.value;
      final bLabel = b.value;
      
      final aNum = double.tryParse(aLabel.split(RegExp(r'[^0-9.]')).first);
      final bNum = double.tryParse(bLabel.split(RegExp(r'[^0-9.]')).first);
      
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      if (aNum != null) return -1;
      if (bNum != null) return 1;
      return aLabel.compareTo(bLabel);
    });

    if (!mounted) return;

    final contentKey = GlobalKey<DynamicSelectionViewState>();

    SelectionSheet.show(
      context: context,
      title: l10n.filterSize,
      onClear: () {
        contentKey.currentState?.clearSelections();
      },
      content: DynamicSelectionView(
        key: contentKey,
        config: {
          'type': 'list',
          'dataSource': 'sizes',
          'itemKey': 'id',
          'itemLabel': 'name',
          'multiSelect': true,
        },
        initialData: {'selectedIds': _selectedSizes},
        dataSources: {
          'sizes': (_) async => entries.map((e) => {
            'id': e.key,
            'name': e.value,
          }).toList(),
        },
        onResult: (result) {
          if (result != null && result['selectedIds'] != null) {
            setState(() {
              _selectedSizes = List<String>.from(result['selectedIds']);
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Affiche le filtre Matière de manière contextuelle
  void _showMaterialFilter() async {
    final l10n = AppLocalizations.of(context)!;
    
    final attributeIds = <String>{};
    for (var product in _results) {
      final id = product.primaryMaterialAttributeId;
      if (id != null) attributeIds.add(id);
    }

    if (attributeIds.isEmpty) return;

    final List<ProductAttribute> attributes = [];
    for (var id in attributeIds) {
      final attr = await ref.read(attributeByIdProvider(id).future);
      attributes.add(attr);
    }

    final Map<String, String> options = {};
    for (var attr in attributes) {
      for (var i = 0; i < attr.values.length; i++) {
        options['${attr.id}:$i'] = attr.values[i];
      }
    }

    if (options.isEmpty) return;

    final entries = options.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));

    if (!mounted) return;
    final contentKey = GlobalKey<DynamicSelectionViewState>();

    SelectionSheet.show(
      context: context,
      title: l10n.filterMaterial,
      onClear: () {
        contentKey.currentState?.clearSelections();
      },
      content: DynamicSelectionView(
        key: contentKey,
        config: {
          'type': 'list',
          'dataSource': 'materials',
          'itemKey': 'id',
          'itemLabel': 'name',
          'multiSelect': true,
        },
        initialData: {'selectedIds': _selectedMaterials},
        dataSources: {
          'materials': (_) async => entries.map((e) => {
            'id': e.key,
            'name': e.value,
          }).toList(),
        },
        onResult: (result) {
          if (result != null && result['selectedIds'] != null) {
            setState(() {
              _selectedMaterials = List<String>.from(result['selectedIds']);
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }


  /// Affiche le filtre État/Condition
  void _showConditionFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final conditionsAsync = ref.read(allConditionsProvider);
    final contentKey = GlobalKey<DynamicSelectionViewState>();

    conditionsAsync.whenOrNull(
      data: (conditions) {
        if (!mounted || conditions.isEmpty) return;

        SelectionSheet.show(
          context: context,
          title: l10n.filterCondition,
          onClear: () {
            contentKey.currentState?.clearSelections();
          },
          content: DynamicSelectionView(
            key: contentKey,
            config: {
              'type': 'list',
              'dataSource': 'conditions',
              'itemKey': 'id',
              'itemLabel': 'name',
              'multiSelect': true,
            },
            initialData: {'selectedIds': _selectedConditions},
            dataSources: {
              'conditions': (_) async => conditions.asMap().entries.map((entry) {
                return {'id': entry.key.toString(), 'name': entry.value};
              }).toList(),
            },
            onResult: (result) {
              if (result != null && result['selectedIds'] != null) {
                setState(() {
                  _selectedConditions = List<String>.from(result['selectedIds']);
                });
                Navigator.pop(context);
              }
            },
          ),
        );
      },
    );
  }

  /// Affiche le filtre Prix (min / max en FCFA), appliqué dans
  /// [_filteredResults] (déjà câblé sur `_minPrice`/`_maxPrice`).
  void _showPriceFilter() {
    final l10n = AppLocalizations.of(context)!;
    final minController = TextEditingController(
      text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '',
    );
    final maxController = TextEditingController(
      text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.filterPrice),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.minPrice,
                    suffixText: l10n.currency,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.maxPrice,
                    suffixText: l10n.currency,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = null;
                });
                Navigator.pop(context);
              },
              child: Text(l10n.resetFilter),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                var min = double.tryParse(minController.text.trim());
                var max = double.tryParse(maxController.text.trim());
                // Si les deux bornes sont inversées, on les échange plutôt
                // que de renvoyer une liste vide sans explication.
                if (min != null && max != null && min > max) {
                  final tmp = min;
                  min = max;
                  max = tmp;
                }
                setState(() {
                  _minPrice = min;
                  _maxPrice = max;
                });
                Navigator.pop(context);
              },
              child: Text(l10n.apply),
            ),
          ],
        );
      },
    );
  }

  /// Affiche le filtre Tri
  void _showSortFilter() {
    final l10n = AppLocalizations.of(context)!;
    final sortOptions = [
      {'id': 'recent', 'name': l10n.sortRecent},
      {'id': 'price_asc', 'name': l10n.sortPriceAsc},
      {'id': 'price_desc', 'name': l10n.sortPriceDesc},
      {'id': 'popular', 'name': l10n.sortPopular},
    ];

    SelectionSheet.show(
      context: context,
      title: l10n.sortBy,
      content: DynamicSelectionView(
        config: {
          'type': 'list',
          'dataSource': 'sortOptions',
          'itemKey': 'id',
          'itemLabel': 'name',
          'multiSelect': false,
        },
        dataSources: {'sortOptions': (_) async => sortOptions},
        onResult: (result) {
          if (result != null && result['id'] != null) {
            setState(() {
              _sortBy = result['id'] as String;
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
