import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/entities.dart';
import './category_provider.dart';

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

/// Provider pour récupérer un attribut complet par son ID.
final attributeByIdProvider = FutureProvider.family<ProductAttribute, String>((
  ref,
  id,
) async {
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  return categoryRepo.getAttributeById(id);
});

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
  // Garder en cache pour réutiliser entre les pages (produit → chat → paiement)
  ref.keepAlive();
  return ref.watch(productRepositoryProvider).getProductById(productId);
});

/// Provider pour récupérer toutes les valeurs d'un attribut par son nom
/// (ex: 'brand', 'color', 'size', 'material')
/// Récupère TOUTES les valeurs possibles depuis la base, pas seulement celles utilisées dans les produits
final attributeValuesByNameProvider =
    FutureProvider.family<List<String>, String>((ref, attributeName) async {
      final categoryRepo = ref.watch(categoryRepositoryProvider);
      try {
        final attributes = await categoryRepo.getAttributes();

        // Chercher tous les attributs qui correspondent au nom
        final matchingAttributes = attributes
            .where(
              (attr) =>
                  attr.name.toLowerCase() == attributeName.toLowerCase() ||
                  attr.id.toLowerCase().contains(attributeName.toLowerCase()),
            )
            .toList();

        if (matchingAttributes.isEmpty) {
          return [];
        }

        // Combiner toutes les valeurs si plusieurs attributs correspondent
        final allValues = <String>{};
        for (var attr in matchingAttributes) {
          allValues.addAll(attr.values);
        }

        return allValues.toList()..sort();
      } catch (e) {
        return [];
      }
    });

/// Provider pour toutes les marques depuis la base
final allBrandsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(attributeValuesByNameProvider('brand').future);
});

/// Provider pour toutes les couleurs depuis la base
final allColorsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(attributeValuesByNameProvider('color').future);
});

/// Provider pour toutes les tailles depuis la base
final allSizesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(attributeValuesByNameProvider('size').future);
});

/// Provider pour toutes les matières depuis la base
final allMaterialsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(attributeValuesByNameProvider('material').future);
});

/// Provider pour tous les états (conditions) depuis la base
final allConditionsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(attributeValuesByNameProvider('condition').future);
});

/// Provider pour récupérer le label d'un attribut par son ID et sa valeur (index ou string)
final attributeLabelProvider =
    FutureProvider.family<String, ({String attributeId, dynamic value})>((
      ref,
      params,
    ) async {
      final value = params.value;
      if (value == null) return 'Non spécifié';
      if (value is! int) return value.toString();

      final categoryRepo = ref.watch(categoryRepositoryProvider);
      try {
        // On essaie de trouver l'attribut par son ID
        final attribute = await categoryRepo.getAttributeById(
          params.attributeId,
        );
        if (params.value >= 0 && params.value < attribute.values.length) {
          return attribute.values[params.value];
        }
      } catch (e) {
        // Si l'attribut par ID échoue, on peut essayer de chercher par nom ou rester sur la valeur brute
      }

      return value.toString();
    });
