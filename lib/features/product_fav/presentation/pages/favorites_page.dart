import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/product_card.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../product/domain/entities/entities.dart';
import '../providers/product_fav_provider.dart';

/// Page affichant les favoris de l'utilisateur avec recherche locale
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(favoriteProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher dans les favoris...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : Text(AppLocalizations.of(context)!.favorites),
        centerTitle: !_isSearching,
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty && !_isSearching) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun favori pour le moment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          // Filtrer les produits
          final filteredProducts = products.where((product) {
            final titleMatch = product.title.toLowerCase().contains(_searchQuery);
             // On peut aussi chercher dans la description ou la marque
            final descMatch = product.description.toLowerCase().contains(_searchQuery);
            return titleMatch || descMatch;
          }).toList();

          if (filteredProducts.isEmpty && _isSearching) {
            return Center(
              child: Text(
                'Aucun résultat pour "$_searchQuery"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return ResponsiveProductGrid<Product>(
            itemsBuilder: (_) => filteredProducts,
            itemBuilder: (context, product) {
              return ProductCard(
                product: product,
                onTap: () {
                  context.push('/product/${product.id}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(AppLocalizations.of(context)!.errorGenericMsg(error.toString()))),
      ),
    );
  }
}
