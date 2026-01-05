import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/filter_chip_list.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../product/domain/entities/entities.dart';
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
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
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
                  isSelected: false,
                  onTap: () {},
                ),
                FilterItem(label: 'Couleur', isSelected: true, onTap: () {}),
                FilterItem(
                  label: 'Classer par',
                  isSelected: true,
                  onTap: () {},
                ),
                FilterItem(label: 'Taille', isSelected: false, onTap: () {}),
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
                                '${_results.length} résultat${_results.length > 1 ? 's' : ''}',
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
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final product = _results[index];
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
                                  // TODO: Navigate to product details
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
}
