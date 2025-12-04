import '../entities/entities.dart';

/// Interface du repository pour les catégories et sous-catégories.
///
/// Définit les opérations CRUD pour la gestion de la hiérarchie de catégories.
abstract class CategoryRepository {
  // ============================================================
  // CATÉGORIES (Niveau 1)
  // ============================================================

  /// Récupère toutes les catégories de niveau 1
  Future<List<Category>> getCategories();

  /// Récupère une catégorie par son ID
  Future<Category> getCategoryById(String id);

  /// Stream des catégories (écoute en temps réel)
  Stream<List<Category>> getCategoriesStream();

  // ============================================================
  // SOUS-CATÉGORIES (Tous niveaux)
  // ============================================================

  /// Récupère toutes les sous-catégories
  Future<List<Subcategory>> getSubcategories();

  /// Récupère une sous-catégorie par son ID
  Future<Subcategory> getSubcategoryById(String id);

  /// Récupère les sous-catégories enfants d'une catégorie/sous-catégorie
  ///
  /// [parentId] : ID de la catégorie ou sous-catégorie parente
  Future<List<Subcategory>> getSubcategoriesByParent(String parentId);

  /// Stream des sous-catégories par parent (écoute en temps réel)
  Stream<List<Subcategory>> getSubcategoriesByParentStream(String parentId);

  // ============================================================
  // ATTRIBUTS
  // ============================================================

  /// Récupère tous les attributs
  Future<List<ProductAttribute>> getAttributes();

  /// Récupère un attribut par son ID
  Future<ProductAttribute> getAttributeById(String id);

  /// Récupère plusieurs attributs par leurs IDs
  ///
  /// [attributeIds] : Liste des IDs d'attributs à récupérer
  Future<List<ProductAttribute>> getAttributesByIds(List<String> attributeIds);

  /// Stream des attributs (écoute en temps réel)
  Stream<List<ProductAttribute>> getAttributesStream();
}
