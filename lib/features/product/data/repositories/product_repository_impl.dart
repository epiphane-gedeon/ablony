import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/exceptions/exceptions.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';
import '../../domain/entities/search_page.dart';

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
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) throw ProductNotFoundException(productId: productId);

      final statut = ProductStatus.fromWire(doc.data()?['status'] as String?);
      if (statut == ProductStatus.sold) {
        throw ProductSoldCannotBeDeletedException();
      }

      // On archive, on n'efface pas. L'annonce peut être en favori, citée
      // dans une conversation, ou **signalée** — et un vendeur qui efface son
      // annonce effacerait la pièce à conviction. Elle disparaît de partout
      // où le vendeur la voyait ; le document reste.
      await _firestore.collection('products').doc(productId).update({
        'status': ProductStatus.archived.wireValue,
        'isHidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on AppException {
      rethrow;
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
          // Un seul champ, calculé par le serveur : il vaut vrai si
          // l'annonce est active, non rejetée, et son vendeur non
          // suspendu. Voir docs/produit/19-modele-annonce.md.
          .where('isListable', isEqualTo: true)
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
          // Un seul champ, calculé par le serveur : il vaut vrai si
          // l'annonce est active, non rejetée, et son vendeur non
          // suspendu. Voir docs/produit/19-modele-annonce.md.
          .where('isListable', isEqualTo: true);

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

  /// Vingt résultats par page. Un écran en montre six ; charger davantage
  /// fait payer des lectures pour ce que personne ne fait défiler.
  static const int _tailleDePage = 20;

  @override
  Future<SearchPage> searchProducts(String query, {String? startAfter}) async {
    try {
      // Firestore limite `arrayContainsAny` à 30 valeurs, et au-delà de
      // quelques mots la requête ne discrimine plus rien.
      final mots = _motsDeRecherche(query).take(10).toList();

      // Requête vide (navigation par catégorie, clic sur une marque, ou simple
      // parcours) : on liste TOUTES les annonces en ligne, de la plus récente.
      // Les filtres de l'écran affinent ensuite. Auparavant on renvoyait vide,
      // et tout filtre posé sur rien ne donnait rien.
      Query<Map<String, dynamic>> requete = mots.isEmpty
          ? _firestore
              .collection('products')
              .where('isListable', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(_tailleDePage)
          : _firestore
              .collection('products')
              .where('searchTokens', arrayContainsAny: mots)
              .where('isListable', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(_tailleDePage);

      if (startAfter != null) {
        final dernier = await _firestore
            .collection('products')
            .doc(startAfter)
            .get();
        if (dernier.exists) requete = requete.startAfterDocument(dernier);
      }

      final snapshot = await requete.get();
      final produits = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();

      // Reclassement en mémoire, sur la page seulement : `arrayContainsAny`
      // remonte les annonces portant **au moins un** des mots, donc « robe
      // wax » ramène les robes et les articles en wax. Compter les mots
      // correspondants remet les plus pertinentes devant, pour un coût nul.
      if (mots.length > 1) {
        produits.sort((a, b) {
          final scoreA = _pertinence(a, mots);
          final scoreB = _pertinence(b, mots);
          if (scoreA != scoreB) return scoreB.compareTo(scoreA);
          return b.createdAt.compareTo(a.createdAt);
        });
      }

      return SearchPage(
        products: produits,
        nextCursor:
            snapshot.docs.length < _tailleDePage ? null : snapshot.docs.last.id,
      );
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

  /// Correspondance des lettres accentuées vers leur forme simple.
  ///
  /// Le serveur normalise en NFD et retire les signes diacritiques, ce que la
  /// bibliothèque standard de Dart ne sait pas faire. Cette table couvre le
  /// supplément latin-1 en entier : une lettre oubliée ici découperait le mot
  /// en morceaux, là où le serveur l'aurait gardé entier — et « señor » ne
  /// trouverait jamais « Señor ».
  static const Map<String, String> _sansAccent = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'œ': 'oe',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ß': 'ss',
  };

  /// Mots trop courants pour discriminer quoi que ce soit.
  ///
  /// Doit rester identique à `MOTS_VIDES` côté serveur : un mot filtré d'un
  /// côté et pas de l'autre, et la requête cherche ce que l'index n'a pas
  /// enregistré.
  static const Set<String> _motsVides = {
    'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'et', 'ou',
    'pour', 'sans', 'avec', 'dans', 'sur', 'par', 'aux', 'au', 'en',
    'ce', 'cet', 'cette', 'mon', 'ma', 'mes', 'son', 'sa', 'ses',
  };

  /// Découpe une requête comme le serveur découpe les annonces.
  ///
  /// Deux formes par mot, et la seconde compte : « H&M » découpé donne « h »
  /// et « m », écartés pour leur longueur — la marque devenait introuvable.
  /// La forme compacte, « hm », la rattrape, comme « t-shirt » → « tshirt ».
  ///
  /// Les deux découpages doivent rester identiques : si l'un supprime les
  /// accents et pas l'autre, « vêtement » ne trouve jamais « Vêtement ».
  static List<String> _motsDeRecherche(String query) {
    final tampon = StringBuffer();
    for (final lettre in query.toLowerCase().split('')) {
      tampon.write(_sansAccent[lettre] ?? lettre);
    }

    final sortie = <String>{};
    for (final mot in tampon.toString().split(RegExp(r'\s+'))) {
      for (final part in mot.split(RegExp('[^a-z0-9]+'))) {
        if (part.length >= 2 && !_motsVides.contains(part)) sortie.add(part);
      }
      final compact = mot.replaceAll(RegExp('[^a-z0-9]+'), '');
      if (compact.length >= 2 && !_motsVides.contains(compact)) {
        sortie.add(compact);
      }
    }
    return sortie.toList();
  }

  /// Combien de mots de la requête l'annonce porte-t-elle ?
  static int _pertinence(Product produit, List<String> mots) {
    final titre = _motsDeRecherche(produit.title).toSet();
    return mots.where(titre.contains).length;
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
        // `status` autant que le booléen hérité : depuis que toutes les
        // annonces portent `status`, ne basculer que `isSold` ne change rien
        // — l'annonce resterait visible dans les listes.
        'status': 'sold',
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
          // Un seul champ, calculé par le serveur : il vaut vrai si
          // l'annonce est active, non rejetée, et son vendeur non
          // suspendu. Voir docs/produit/19-modele-annonce.md.
          .where('isListable', isEqualTo: true)
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
