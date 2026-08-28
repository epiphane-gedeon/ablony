import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/exceptions/exceptions.dart';
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
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la création du produit',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la mise à jour du produit',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la suppression du produit',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
        throw ProductNotFoundException(productId: productId);
      }

      return ProductModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement du produit',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Product>> getProducts({
    int limit = 20,
    String? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .where('isReserved', isEqualTo: false)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Si startAfter est fourni, on récupère le document et on commence après
      if (startAfter != null) {
        final lastDoc = await _firestore
            .collection('products')
            .doc(startAfter)
            .get();

        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des produits',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des produits du vendeur',
        originalException: e as Exception?,
        stackTrace: stackTrace,
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
          .where('isSold', isEqualTo: false)
          .where('isReserved', isEqualTo: false)
          .where('isHidden', isEqualTo: false);

      // Ajouter le filtre de sous-catégorie si fourni
      if (subcategoryId != null) {
        query = query.where('subcategoryId', isEqualTo: subcategoryId);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map(
            (doc) => ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des produits par catégorie',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      final queryLower = query.toLowerCase();

      // Récupérer toutes les catégories et sous-catégories pour la recherche
      // IMPORTANT : Les catégories sont dans config/categories/items et config/subcategories/items
      final categoriesSnapshot = await _firestore
          .collection('config')
          .doc('categories')
          .collection('items')
          .get();
      final subcategoriesSnapshot = await _firestore
          .collection('config')
          .doc('subcategories')
          .collection('items')
          .get();

      // Créer des maps pour rechercher par nom
      final Map<String, String> categoryIdsByName = {};
      final Map<String, String> subcategoryIdsByName = {};

      for (var doc in categoriesSnapshot.docs) {
        final name = (doc.data()['name'] ?? '').toString().toLowerCase();
        categoryIdsByName[name] = doc.id;
      }

      for (var doc in subcategoriesSnapshot.docs) {
        final name = (doc.data()['name'] ?? '').toString().toLowerCase();
        subcategoryIdsByName[name] = doc.id;
      }

      // Trouver les IDs de catégories/sous-catégories qui correspondent à la recherche
      final Set<String> matchingCategoryIds = {};
      final Set<String> matchingSubcategoryIds = {};

      categoryIdsByName.forEach((name, id) {
        if (name.contains(queryLower)) {
          matchingCategoryIds.add(id);
        }
      });

      subcategoryIdsByName.forEach((name, id) {
        if (name.contains(queryLower)) {
          matchingSubcategoryIds.add(id);
        }
      });

      // Récupérer tous les produits non vendus, non réservés et non masqués
      final snapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .where('isReserved', isEqualTo: false)
          .where('isHidden', isEqualTo: false)
          .get();

      // Filtrer côté client pour chercher dans titre, description, marque, catégorie et sous-catégorie
      final results = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .where((product) {
            // Recherche dans le titre
            if (product.title.toLowerCase().contains(queryLower)) {
              return true;
            }

            // Recherche dans la description
            if (product.description?.toLowerCase().contains(queryLower) ??
                false) {
              return true;
            }

            // Recherche dans la marque
            final brand =
                product.attributes['brand'] ?? product.attributes['marque'];
            if (brand != null &&
                brand.toString().toLowerCase().contains(queryLower)) {
              return true;
            }

            // Recherche par catégorie
            if (matchingCategoryIds.contains(product.categoryId)) {
              return true;
            }

            // Recherche par sous-catégorie
            if (matchingSubcategoryIds.contains(product.subcategoryId)) {
              return true;
            }

            return false;
          })
          .toList();

      return results;
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la recherche de produits',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Category>> getAllCategories() async {
    try {
      final snapshot = await _firestore
          .collection('config')
          .doc('categories')
          .collection('items')
          .get();

      return snapshot.docs
          .map(
            (doc) => Category(
              id: doc.id,
              name: doc.data()['name'] as String,
              children: List<String>.from(doc.data()['children'] ?? []),
              order: doc.data()['order'] as int?,
              iconUrl: doc.data()['iconUrl'] as String?,
              isActive: doc.data()['isActive'] as bool? ?? true,
              createdAt: (doc.data()['createdAt'] as Timestamp).toDate(),
              updatedAt: (doc.data()['updatedAt'] as Timestamp).toDate(),
            ),
          )
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la récupération des catégories',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Subcategory>> getAllSubcategories() async {
    try {
      final snapshot = await _firestore
          .collection('config')
          .doc('subcategories')
          .collection('items')
          .get();

      return snapshot.docs
          .map(
            (doc) => Subcategory(
              id: doc.id,
              name: doc.data()['name'] as String,
              parentId: doc.data()['parentId'] as String,
              children: List<String>.from(doc.data()['children'] ?? []),
              attributes: List<String>.from(doc.data()['attributes'] ?? []),
              order: doc.data()['order'] as int?,
              iconUrl: doc.data()['iconUrl'] as String?,
              isActive: doc.data()['isActive'] as bool? ?? true,
              createdAt: (doc.data()['createdAt'] as Timestamp).toDate(),
              updatedAt: (doc.data()['updatedAt'] as Timestamp).toDate(),
            ),
          )
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la récupération des sous-catégories',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
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
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de l\'incrémentation des vues',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> incrementFavoritesCount(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'favoritesCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de l\'incrémentation des favoris',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> decrementFavoritesCount(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'favoritesCount': FieldValue.increment(-1),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la décrémentation des favoris',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> markAsSold(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isSold': true,
        'soldAt': FieldValue.serverTimestamp(),
        // On lève une éventuelle réservation : le produit est de toute
        // façon déjà exclu des listes publiques une fois vendu.
        'isReserved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du marquage du produit comme vendu',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> markAsReserved(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isReserved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du marquage du produit comme réservé',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> unmarkAsReserved(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isReserved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de l\'annulation de la réservation',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> hideProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isHidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du masquage du produit',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> unhideProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isHidden': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors de la republication du produit',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // BOOST
  // ============================================================

  @override
  Future<List<Product>> getActiveBoostedProducts({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isBoosted', isEqualTo: true)
          .where('isSold', isEqualTo: false)
          .where('isReserved', isEqualTo: false)
          .where('isHidden', isEqualTo: false)
          .where('boostExpiresAt', isGreaterThan: Timestamp.now())
          .orderBy('boostExpiresAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des produits boostés',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }
}
