import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/dynamic_ui/dynamic_selection_view.dart';
import '../../../../core/presentation/pages/selection_screen.dart';
import '../../../../core/presentation/pages/selection_sheet.dart';
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

  const SearchResultsPage({super.key, required this.query});

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
  List<ProductCondition> _selectedConditions = [];
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
        final brand =
            product.attributes['brand']?.toString() ??
            product.attributes['marque']?.toString();
        return brand != null && _selectedBrands.contains(brand);
      }).toList();
    }

    // Filtre par couleur
    if (_selectedColors.isNotEmpty) {
      filtered = filtered.where((product) {
        final color =
            product.attributes['color']?.toString() ??
            product.attributes['couleur']?.toString();
        return color != null && _selectedColors.contains(color);
      }).toList();
    }

    // Filtre par taille
    if (_selectedSizes.isNotEmpty) {
      filtered = filtered.where((product) {
        // Chercher dans tous les attributs de taille possibles
        for (var key in product.attributes.keys) {
          if (key.toLowerCase().contains('size') ||
              key.toLowerCase().contains('taille') ||
              key.toLowerCase().contains('pointure')) {
            final size = product.attributes[key]?.toString();
            if (size != null && _selectedSizes.contains(size)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }

    // Filtre par état/condition
    if (_selectedConditions.isNotEmpty) {
      filtered = filtered.where((product) {
        return _selectedConditions.contains(product.condition);
      }).toList();
    }

    // Filtre par matière
    if (_selectedMaterials.isNotEmpty) {
      filtered = filtered.where((product) {
        final material =
            product.attributes['material']?.toString() ??
            product.attributes['matiere']?.toString() ??
            product.attributes['matière']?.toString();
        return material != null && _selectedMaterials.contains(material);
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
                      ? _selectedSizes.join(', ')
                      : '${_selectedSizes.take(3).join(', ')}...',
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
                      ? _selectedBrands.join(', ')
                      : '${_selectedBrands.take(3).join(', ')}...',
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
                      ? _selectedConditions.map((c) => c.label).join(', ')
                      : '${_selectedConditions.take(2).map((c) => c.label).join(', ')}...',
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
                      ? _selectedColors.join(', ')
                      : '${_selectedColors.take(3).join(', ')}...',
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
                      ? _selectedMaterials.join(', ')
                      : '${_selectedMaterials.take(2).join(', ')}...',
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
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.5,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: _filteredResults.length,
                            itemBuilder: (context, index) {
                              final product = _filteredResults[index];
                              return ProductCard(
                                imageUrl: product.imageUrls.isNotEmpty
                                    ? product.imageUrls.first
                                    : null,
                                brand:
                                    product.attributes['brand']?.toString() ??
                                    product.title,
                                size:
                                    product.attributes['size_haut']
                                        ?.toString() ??
                                    product.attributes['size_bas']
                                        ?.toString() ??
                                    product.attributes['pointure']?.toString(),
                                condition: product.condition.label,
                                price: product.price,
                                priceWithProtection: product.price * 1.05,
                                favoritesCount: product.favoritesCount,
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

  /// Affiche le filtre Marque
  void _showBrandFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final brandsAsync = ref.read(allBrandsProvider);
    final contentKey = GlobalKey<DynamicSelectionViewState>();

    brandsAsync.whenOrNull(
      data: (brands) {
        if (!mounted || brands.isEmpty) return;

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
              'brands': (_) async =>
                  brands.map((brand) => {'id': brand, 'name': brand}).toList(),
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
      },
    );
  }

  /// Affiche le filtre Couleur
  void _showColorFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final colorsAsync = ref.read(allColorsProvider);
    final contentKey = GlobalKey<DynamicSelectionViewState>();

    colorsAsync.whenOrNull(
      data: (colors) {
        if (!mounted || colors.isEmpty) return;

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
              'colors': (_) async =>
                  colors.map((color) => {'id': color, 'name': color}).toList(),
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
      },
    );
  }

  /// Affiche le filtre Taille
  void _showSizeFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final sizesAsync = ref.read(allSizesProvider);

    sizesAsync.whenOrNull(
      data: (allSizes) {
        if (!mounted || allSizes.isEmpty) return;

        // Détecter le type de tailles dans les résultats actuels
        bool hasNumericSizes = false;
        bool hasLetterSizes = false;

        for (var product in _results) {
          for (var key in product.attributes.keys) {
            if (key.toLowerCase().contains('size') ||
                key.toLowerCase().contains('taille')) {
              final size = product.attributes[key];
              if (size != null && size.toString().isNotEmpty) {
                if (int.tryParse(size.toString().split('.')[0]) != null) {
                  hasNumericSizes = true;
                } else {
                  hasLetterSizes = true;
                }
              }
            }
          }
        }

        // Séparer les tailles numériques et lettres
        final numericSizes = allSizes
            .where((s) => int.tryParse(s.split('.')[0]) != null)
            .toList();
        final letterSizes = allSizes
            .where((s) => int.tryParse(s) == null)
            .toList();

        // Trier intelligemment
        numericSizes.sort((a, b) {
          final aNum = double.tryParse(a) ?? 0;
          final bNum = double.tryParse(b) ?? 0;
          return aNum.compareTo(bNum);
        });
        letterSizes.sort();

        // Sélectionner selon le type détecté
        List<String> filteredSizes = [];
        if (hasNumericSizes && !hasLetterSizes) {
          filteredSizes = numericSizes;
        } else if (hasLetterSizes && !hasNumericSizes) {
          filteredSizes = letterSizes;
        } else {
          filteredSizes = [...numericSizes, ...letterSizes];
        }

        if (filteredSizes.isEmpty) return;

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
              'sizes': (_) async => filteredSizes
                  .map((size) => {'id': size, 'name': size})
                  .toList(),
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
      },
    );
  }

  /// Affiche le filtre Matière
  void _showMaterialFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final materialsAsync = ref.read(allMaterialsProvider);
    final contentKey = GlobalKey<DynamicSelectionViewState>();

    materialsAsync.whenOrNull(
      data: (materials) {
        if (!mounted || materials.isEmpty) return;

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
              'materials': (_) async => materials
                  .map((material) => {'id': material, 'name': material})
                  .toList(),
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
      },
    );
  }

  /// Récupère le label traduit d'une condition
  String _getConditionLabel(AppLocalizations l10n, ProductCondition condition) {
    switch (condition) {
      case ProductCondition.newWithTags:
        return l10n.conditionNew;
      case ProductCondition.excellent:
        return l10n.conditionExcellent;
      case ProductCondition.good:
        return l10n.conditionGood;
      case ProductCondition.satisfactory:
        return l10n
            .conditionFair; // Using 'fair' as translation for 'satisfactory'
      case ProductCondition.worn:
        return l10n
            .conditionFair; // Using 'fair' as translation for 'worn' (can be adjusted)
    }
  }

  /// Affiche le filtre État/Condition
  void _showConditionFilter() {
    final l10n = AppLocalizations.of(context)!;
    final contentKey = GlobalKey<DynamicSelectionViewState>();
    final conditions = ProductCondition.values
        .map(
          (condition) => {
            'id': condition.name,
            'name': _getConditionLabel(l10n, condition),
            'condition': condition,
          },
        )
        .toList();

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
        initialData: {
          'selectedIds': _selectedConditions.map((c) => c.name).toList(),
        },
        dataSources: {'conditions': (_) async => conditions},
        onResult: (result) {
          if (result != null && result['selectedIds'] != null) {
            setState(() {
              final selectedNames = List<String>.from(result['selectedIds']);
              _selectedConditions = ProductCondition.values
                  .where((c) => selectedNames.contains(c.name))
                  .toList();
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  /// Affiche le filtre Prix
  void _showPriceFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prix'),
        content: const Text('Filtre de prix en cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
