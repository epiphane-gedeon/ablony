import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

/// Implémentation Firestore du ProductRepository.
///
/// Gère les opérations CRUD des produits dans Firestore.
class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================
  // CRÉATION ET MODIFICATION
  // ============================================================

  /// Crée un nouveau produit dans Firestore.
  ///
  /// Cette méthode génère automatiquement un ID unique pour le produit
  /// et le sauvegarde dans la collection `products`.
  ///
  /// **Exemple d'utilisation :**
  /// ```dart
  /// final product = Product(
  ///   id: '', // Sera généré automatiquement
  ///   title: 'Chemise bleue Nike',
  ///   description: 'Belle chemise en excellent état',
  ///   price: 15000,
  ///   imageUrls: ['https://storage.../img1.jpg'],
  ///   condition: ProductCondition.excellent,
  ///   sellerId: 'user_123',
  ///   categoryId: 'femme',
  ///   subcategoryId: 'chemise_femme',
  ///   attributes: {'brand': 'Nike', 'size_haut': 'M', 'color': 'Bleu'},
  ///   createdAt: DateTime.now(),
  ///   updatedAt: DateTime.now(),
  /// );
  ///
  /// final createdProduct = await productRepo.createProduct(product);
  /// print(createdProduct.id); // 'abc123xyz' (ID généré)
  /// ```
  ///
  /// **Paramètres :**
  /// - [product] : Le produit à créer (l'ID sera remplacé par un ID généré)
  ///
  /// **Retourne :**
  /// - Le produit créé avec son ID Firestore
  ///
  /// **Throws :**
  /// - [Exception] si une erreur Firestore se produit
  @override
  Future<Product> createProduct(Product product) async {
    try {
      // Générer un ID unique
      final docRef = _firestore.collection('products').doc();
      final productWithId = product.copyWith(id: docRef.id);
      
      // Sauvegarder dans Firestore
      await docRef.set(ProductModel.toFirestore(productWithId));
      
      return productWithId;
    } on FirebaseException catch (e) {
      throw Exception('Erreur lors de la création du produit : ${e.message}');
    }
  }

  @override
  Future<Product> updateProduct(Product product) async {
    try {
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(ProductModel.toFirestore(updatedProduct));
      
      return updatedProduct;
    } on FirebaseException catch (e) {
      throw Exception('Erreur lors de la mise à jour du produit : ${e.message}');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } on FirebaseException catch (e) {
      throw Exception('Erreur lors de la suppression du produit : ${e.message}');
    }
  }

  // ============================================================
  // LECTURE
  // ============================================================

  @override
  Future<Product> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) {
        throw Exception('Produit non trouvé : $productId');
      }

      return ProductModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw Exception('Erreur lors du chargement du produit : ${e.message}');
    }
  }

  @override
  Future<List<Product>> getProducts({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Erreur lors du chargement des produits : ${e.message}');
    }
  }

  @override
  Future<List<Product>> getProductsBySeller(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur lors du chargement des produits du vendeur : ${e.message}',
      );
    }
  }

  /// Récupère les produits d'une catégorie ou sous-catégorie.
  ///
  /// Cette méthode permet de filtrer les produits par catégorie niveau 1
  /// et optionnellement par sous-catégorie finale.
  ///
  /// **Cas d'usage 1 - Tous les produits d'une catégorie :**
  /// ```dart
  /// final products = await repo.getProductsByCategory(categoryId: 'femme');
  /// // Retourne tous les produits de la catégorie Femme (tous types confondus)
  /// ```
  ///
  /// **Cas d'usage 2 - Produits d'une sous-catégorie spécifique :**
  /// ```dart
  /// final products = await repo.getProductsByCategory(
  ///   categoryId: 'femme',
  ///   subcategoryId: 'chemise_femme',
  /// );
  /// // Retourne uniquement les chemises femme
  /// ```
  ///
  /// **Filtres appliqués :**
  /// - `categoryId == categoryId` : Filtre par catégorie niveau 1
  /// - `subcategoryId == subcategoryId` : Filtre par sous-catégorie (si fourni)
  /// - `isSold == false` : Exclut les produits déjà vendus
  /// - Triés par `createdAt` (décroissant, les plus récents en premier)
  ///
  /// **Paramètres :**
  /// - [categoryId] : ID de la catégorie niveau 1 (obligatoire)
  /// - [subcategoryId] : ID de la sous-catégorie finale (optionnel)
  ///
  /// **Throws :**
  /// - [Exception] si une erreur Firestore se produit
  @override
  Future<List<Product>> getProductsByCategory({
    required String categoryId,
    String? subcategoryId,
  }) async {
    try {
      Query query = _firestore
          .collection('products')
          .where('categoryId', isEqualTo: categoryId)
          .where('isSold', isEqualTo: false);

      // Ajouter le filtre de sous-catégorie si fourni
      if (subcategoryId != null) {
        query = query.where('subcategoryId', isEqualTo: subcategoryId);
      }

      final snapshot =
          await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur lors du chargement des produits par catégorie : ${e.message}',
      );
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      // Note: Pour une recherche full-text, il faudrait utiliser Algolia ou similar
      // Pour l'instant, on fait une recherche simple sur le titre
      final snapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Erreur lors de la recherche de produits : ${e.message}');
    }
  }

  // ============================================================
  // STREAMS (Temps réel)
  // ============================================================

  @override
  Stream<Product> getProductStream(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((doc) => ProductModel.fromMap(doc.data()!, doc.id));
  }

  @override
  Stream<List<Product>> getProductsBySellerStream(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  @override
  Future<void> incrementViewsCount(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur lors de l\'incrémentation des vues : ${e.message}',
      );
    }
  }

  @override
  Future<void> incrementFavoritesCount(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'favoritesCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur lors de l\'incrémentation des favoris : ${e.message}',
      );
    }
  }

  @override
  Future<void> decrementFavoritesCount(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'favoritesCount': FieldValue.increment(-1),
      });
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur lors de la décrémentation des favoris : ${e.message}',
      );
    }
  }

  @override
  Future<void> markAsSold(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isSold': true,
        'soldAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception(
        'Erreur lors du marquage du produit comme vendu : ${e.message}',
      );
    }
  }

  // ============================================================
  // BOOST
  // ============================================================

  @override
  Future<void> boostProduct(String productId, Duration duration) async {
    try {
      final expiresAt = DateTime.now().add(duration);
      
      await _firestore.collection('products').doc(productId).update({
        'isBoosted': true,
        'boostExpiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Erreur lors du boost du produit : ${e.message}');
    }
  }
}
