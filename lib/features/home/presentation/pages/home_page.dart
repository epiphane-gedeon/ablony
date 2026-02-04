import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/filter_chip_list.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../core/utils/category_translator.dart';
import '../../../product/presentation/providers/category_provider.dart';
import '../../../product/presentation/providers/paginated_products_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../product/domain/entities/category.dart';
import '../../../product/domain/entities/product.dart';

/// Page d'accueil principale de l'application Ablony.
///
/// Cette page affiche une barre de recherche et les catégories principales.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategoryId; // null = "Voir tout"

  @override
  void initState() {
    super.initState();
    // Écouter le scroll pour charger plus de produits
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedProductsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(paginatedProductsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche
            _buildSearchBar(context, l10n),

            // Filtres / Catégories
            categoriesAsync.when(
              data: (categories) => _buildCategoryFilters(context, categories),
              loading: () => const SizedBox(
                height: 52,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SizedBox(
                height: 52,
                child: Center(
                  child: Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                ),
              ),
            ),

            // Grille de produits
            Expanded(
              child: productsAsync.when(
                data: (products) => products.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref
                              .read(paginatedProductsProvider.notifier)
                              .refresh();
                        },
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio:
                                    0.5, // Carte plus haute pour une image plus longue
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                              ),
                          itemCount:
                              products.length +
                              (ref
                                      .read(paginatedProductsProvider.notifier)
                                      .isLoadingMore
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index >= products.length) {
                              // Indicateur de chargement en bas
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final product = products[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                context.push('/product/${product.id}');
                              },
                            );
                          },
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(paginatedProductsProvider.notifier)
                              .loadInitialProducts();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// État vide quand il n'y a pas de produits
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun produit disponible',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Mapper l'état du produit avec traduction
  String _getConditionLabel(ProductCondition condition) {
    final l10n = AppLocalizations.of(context)!;

    // Mapper l'enum vers la valeur string française (celle stockée en BDD)
    String conditionValue;
    switch (condition) {
      case ProductCondition.newWithTags:
        conditionValue = 'Neuf avec étiquette';
        break;
      case ProductCondition.excellent:
        conditionValue = 'Excellent état';
        break;
      case ProductCondition.good:
        conditionValue = 'Bon état';
        break;
      case ProductCondition.satisfactory:
        conditionValue = 'Satisfaisant';
        break;
      case ProductCondition.worn:
        conditionValue = 'Usé';
        break;
    }

    // Utiliser CategoryTranslator qui a déjà toutes les traductions
    return CategoryTranslator.translateAttributeValue(l10n, conditionValue);
  }

  /// Barre de recherche simple qui redirige vers la page de recherche
  Widget _buildSearchBar(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => context.push('/searching'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.searchArticlesPlaceholder,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Filtres de catégories chargées depuis Firestore
  Widget _buildCategoryFilters(
    BuildContext context,
    List<Category> categories,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Ajouter "Voir tout" en premier
    final allCategories = [
      Category(
        id: 'all',
        name: l10n.seeAll,
        children: [],
        order: 0,
        iconUrl: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ...categories,
    ];

    return FilterChipList(
      items: allCategories.map((category) {
        final isSelected =
            (category.id == 'all' && _selectedCategoryId == null) ||
            (category.id == _selectedCategoryId);

        return FilterItem(
          label: CategoryTranslator.translate(l10n, category.id, category.name),
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedCategoryId = category.id == 'all' ? null : category.id;
            });
            // Recharger les produits avec le filtre de catégorie
            ref
                .read(paginatedProductsProvider.notifier)
                .filterByCategory(_selectedCategoryId);
          },
        );
      }).toList(),
    );
  }
}
