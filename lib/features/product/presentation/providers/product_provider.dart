import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/entities.dart';

/// Provider pour le repository des produits.
///
/// Ce provider fournit une instance unique de ProductRepository
/// utilisée pour toutes les opérations CRUD sur les produits.
///
/// Utilisation :
/// ```dart
/// final repo = ref.read(productRepositoryProvider);
/// await repo.createProduct(product);
/// ```
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl();
});

/// Provider pour récupérer tous les produits.
///
/// Charge automatiquement la liste des produits depuis Firestore.
/// Le résultat est mis en cache par Riverpod.
///
/// Utilisation :
/// ```dart
/// final productsAsync = ref.watch(allProductsProvider);
/// productsAsync.when(
///   data: (products) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Erreur: $err'),
/// );
/// ```
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productRepositoryProvider).getProducts();
});

/// Provider pour récupérer les produits d'un vendeur spécifique.
///
/// Paramètre family : ID du vendeur
///
/// Utilisation :
/// ```dart
/// final userProductsAsync = ref.watch(sellerProductsProvider('user_123'));
/// ```
final sellerProductsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  sellerId,
) async {
  return ref.watch(productRepositoryProvider).getProductsBySeller(sellerId);
});

/// Provider pour récupérer un produit par son ID.
///
/// Paramètre family : ID du produit
///
/// Utilisation :
/// ```dart
/// final productAsync = ref.watch(productByIdProvider('product_abc'));
/// ```
final productByIdProvider = FutureProvider.family<Product, String>((
  ref,
  productId,
) async {
  return ref.watch(productRepositoryProvider).getProductById(productId);
});
