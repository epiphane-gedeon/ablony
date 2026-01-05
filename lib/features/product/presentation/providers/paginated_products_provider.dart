import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entities.dart';
import 'product_provider.dart';

/// Provider pour la pagination des produits
///
/// Gère le chargement progressif des produits avec pagination.
///
/// Utilisation :
/// ```dart
/// final paginatedProducts = ref.watch(paginatedProductsProvider);
/// ```
class PaginatedProductsNotifier extends Notifier<AsyncValue<List<Product>>> {
  static const int pageSize = 20;
  bool hasMore = true;
  bool isLoadingMore = false;
  String? _currentCategoryId; // null = tous les produits

  @override
  AsyncValue<List<Product>> build() {
    // Charger les produits initiaux
    loadInitialProducts();
    return const AsyncValue.loading();
  }

  /// Charge les premiers produits
  Future<void> loadInitialProducts() async {
    state = const AsyncValue.loading();
    try {
      print(
        '🔍 [PaginatedProducts] loadInitialProducts - categoryId: $_currentCategoryId',
      );

      final products = _currentCategoryId == null
          ? await ref
                .read(productRepositoryProvider)
                .getProducts(limit: pageSize)
          : await ref
                .read(productRepositoryProvider)
                .getProductsByCategory(categoryId: _currentCategoryId!);

      print('📦 [PaginatedProducts] Produits récupérés: ${products.length}');
      hasMore = products.length >= pageSize;
      state = AsyncValue.data(products);
    } catch (e, stack) {
      print('❌ [PaginatedProducts] Erreur: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Charge plus de produits (pagination)
  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;

    final currentProducts = state.value ?? [];
    if (currentProducts.isEmpty) return;

    isLoadingMore = true;

    try {
      // Pour l'instant, la pagination n'est supportée que pour "tous les produits"
      // Pour les catégories, on charge tout en une fois
      if (_currentCategoryId != null) {
        isLoadingMore = false;
        return;
      }

      final newProducts = await ref
          .read(productRepositoryProvider)
          .getProducts(limit: pageSize, startAfter: currentProducts.last.id);

      hasMore = newProducts.length >= pageSize;

      state = AsyncValue.data([...currentProducts, ...newProducts]);
    } catch (e, stack) {
      // En cas d'erreur, on garde les produits actuels
      state = AsyncValue.error(e, stack);
    } finally {
      isLoadingMore = false;
    }
  }

  /// Rafraîchit la liste
  Future<void> refresh() async {
    hasMore = true;
    await loadInitialProducts();
  }

  /// Filtre les produits par catégorie
  Future<void> filterByCategory(String? categoryId) async {
    print('🎯 [PaginatedProducts] filterByCategory appelé avec: $categoryId');
    _currentCategoryId = categoryId;
    hasMore = true;
    await loadInitialProducts();
  }
}

/// Provider pour les produits paginés
final paginatedProductsProvider =
    NotifierProvider<PaginatedProductsNotifier, AsyncValue<List<Product>>>(
      PaginatedProductsNotifier.new,
    );
