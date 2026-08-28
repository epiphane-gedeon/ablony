import '../entities/entities.dart';

/// Interface du repository pour les produits.
///
/// Définit les opérations CRUD pour la gestion des produits.
abstract class ProductRepository {
  // ============================================================
  // CRÉATION ET MODIFICATION
  // ============================================================

  /// Crée un nouveau produit
  ///
  /// [product] : Le produit à créer
  /// Retourne le produit créé avec son ID
  Future<Product> createProduct(Product product);

  /// Met à jour un produit existant
  ///
  /// [product] : Le produit à mettre à jour
  Future<Product> updateProduct(Product product);

  /// Supprime un produit
  ///
  /// [productId] : ID du produit à supprimer
  Future<void> deleteProduct(String productId);

  // ============================================================
  // LECTURE
  // ============================================================

  /// Récupère un produit par son ID
  Future<Product> getProductById(String productId);

  /// Récupère tous les produits
  ///
  /// [limit] : Nombre maximum de produits à récupérer
  /// [startAfter] : ID du dernier produit pour pagination
  Future<List<Product>> getProducts({int limit = 20, String? startAfter});

  /// Récupère les produits d'un vendeur
  ///
  /// [sellerId] : ID du vendeur
  Future<List<Product>> getProductsBySeller(String sellerId);

  /// Récupère les produits d'une catégorie
  ///
  /// [categoryId] : ID de la catégorie
  /// [subcategoryId] : ID de la sous-catégorie (optionnel)
  Future<List<Product>> getProductsByCategory({
    required String categoryId,
    String? subcategoryId,
  });

  /// Recherche des produits par titre
  ///
  /// [query] : Terme de recherche
  Future<List<Product>> searchProducts(String query);

  /// Récupère toutes les catégories
  Future<List<Category>> getAllCategories();

  /// Récupère toutes les sous-catégories
  Future<List<Subcategory>> getAllSubcategories();

  // ============================================================
  // STREAMS (Temps réel)
  // ============================================================

  /// Stream d'un produit (écoute en temps réel)
  Stream<Product> getProductStream(String productId);

  /// Stream des produits d'un vendeur
  Stream<List<Product>> getProductsBySellerStream(String sellerId);

  // ============================================================
  // STATISTIQUES
  // ============================================================

  /// Incrémente le compteur de vues d'un produit
  Future<void> incrementViewsCount(String productId);

  /// Incrémente le compteur de favoris d'un produit
  Future<void> incrementFavoritesCount(String productId);

  /// Décrémente le compteur de favoris d'un produit
  Future<void> decrementFavoritesCount(String productId);

  /// Marque un produit comme vendu
  Future<void> markAsSold(String productId);

  /// Marque un produit comme réservé — indisponible temporairement à
  /// l'achat (le vendeur discute avec un acheteur), sans le vendre pour
  /// autant. Exclu des listes publiques (accueil, recherche, catégories)
  /// comme un produit vendu, mais reste visible pour le vendeur.
  Future<void> markAsReserved(String productId);

  /// Annule la réservation d'un produit, qui redevient visible et
  /// achetable normalement.
  Future<void> unmarkAsReserved(String productId);

  /// Masque une annonce — retirée des listes publiques à la demande du
  /// vendeur, sans être supprimée ni vendue.
  Future<void> hideProduct(String productId);

  /// Republie une annonce masquée, qui redevient visible dans les listes
  /// publiques.
  Future<void> unhideProduct(String productId);

  // ============================================================
  // BOOST
  // ============================================================
  //
  // Le boost est payant (voir BoostBottomSheet / Cloud Function
  // `finalizeBoost`) — ce repository n'expose donc volontairement aucune
  // méthode d'écriture directe sur isBoosted/boostExpiresAt (firestore.rules
  // l'interdit d'ailleurs explicitement pour le client).

  /// Récupère les produits actuellement boostés (boost non expiré, non vendus)
  ///
  /// [limit] : Nombre maximum de produits boostés à récupérer
  Future<List<Product>> getActiveBoostedProducts({int limit = 50});
}
