import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/product_fav_repository.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_provider.dart';

final productFavRepositoryProvider = Provider<ProductFavRepository>((ref) {
  return ProductFavRepository();
});

final authUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userFavoriteProductIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authUserProvider).value;
  if (user == null) {
    return Stream.value(<String>{});
  }

  return FirebaseFirestore.instance
      .collection('fav')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => doc.data()['productId'])
            .whereType<String>()
            .toSet(),
      );
});

final isProductFavoriteProvider = Provider.family<bool, String>((
  ref,
  productId,
) {
  final favoriteIds = ref.watch(userFavoriteProductIdsProvider).value;
  if (favoriteIds == null) return false;
  return favoriteIds.contains(productId);
});

final productFavoriteCountProvider = StreamProvider.family<int, String>((
  ref,
  productId,
) {
  return FirebaseFirestore.instance
      .collection('fav')
      .where('productId', isEqualTo: productId)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

extension ProductFavHelpers on WidgetRef {
  Future<void> toggleFavorite(String productId) async {
    final repository = read(productFavRepositoryProvider);
    await repository.toggleFavorite(productId);
  }

  bool isFavorite(String productId) {
    return watch(isProductFavoriteProvider(productId));
  }
}

final favoriteProductsProvider = FutureProvider<List<Product>>((ref) async {
  final idsAsync = ref.watch(userFavoriteProductIdsProvider);
  final ids = idsAsync.value;
  if (ids == null || ids.isEmpty) return [];

  final productRepo = ref.watch(productRepositoryProvider);
  try {
    final futures = ids.map((id) async {
      try {
        return await productRepo.getProductById(id);
      } catch (_) {
        return null;
      }
    });
    final products = await Future.wait(futures);
    return products.whereType<Product>().toList();
  } catch (e) {
    return [];
  }
});
