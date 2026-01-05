import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/exceptions/exceptions.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import '../models/product_attribute_model.dart';

/// Implémentation Firestore du CategoryRepository.
///
/// Gère les opérations de lecture des catégories, sous-catégories et attributs
/// depuis Firestore.
class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================
  // CATÉGORIES (Niveau 1)
  // ============================================================

  /// Récupère toutes les catégories de niveau 1 actives.
  ///
  /// Cette méthode charge toutes les catégories racines (Femme, Homme, etc.)
  /// depuis Firestore, triées par ordre d'affichage.
  ///
  /// **Structure Firestore :**
  /// ```
  /// config/categories/items/{categoryId}
  /// ```
  ///
  /// **Exemple d'utilisation :**
  /// ```dart
  /// final categories = await categoryRepository.getCategories();
  /// // Retourne : [Category(id: 'femme', name: 'Femme'), Category(id: 'homme', name: 'Homme')]
  /// ```
  ///
  /// **Filtres appliqués :**
  /// - Seules les catégories actives (`isActive == true`)
  /// - Triées par le champ `order` (croissant)
  ///
  /// **Throws :**
  /// - [Exception] si une erreur Firestore se produit
  @override
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('config')
          .doc('categories')
          .collection('items')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des catégories',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Category> getCategoryById(String id) async {
    try {
      final doc = await _firestore
          .collection('config')
          .doc('categories')
          .collection('items')
          .doc(id)
          .get();

      if (!doc.exists) {
        throw CategoryNotFoundException(categoryId: id);
      }

      return CategoryModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement de la catégorie',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<List<Category>> getCategoriesStream() {
    return _firestore
        .collection('config')
        .doc('categories')
        .collection('items')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ============================================================
  // SOUS-CATÉGORIES (Tous niveaux)
  // ============================================================

  @override
  Future<List<Subcategory>> getSubcategories() async {
    try {
      final snapshot = await _firestore
          .collection('config')
          .doc('subcategories')
          .collection('items')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => SubcategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des sous-catégories',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Subcategory> getSubcategoryById(String id) async {
    try {
      final doc = await _firestore
          .collection('config')
          .doc('subcategories')
          .collection('items')
          .doc(id)
          .get();

      if (!doc.exists) {
        throw CategoryNotFoundException(categoryId: id);
      }

      return SubcategoryModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement de la sous-catégorie',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  /// Récupère les sous-catégories enfants d'une catégorie ou sous-catégorie.
  ///
  /// Cette méthode permet de naviguer dans la hiérarchie de catégories
  /// en récupérant tous les enfants directs d'un parent donné.
  ///
  /// **Cas d'usage :**
  /// 1. Récupérer les sous-catégories d'une catégorie niveau 1
  /// 2. Récupérer les enfants d'une sous-catégorie (branche)
  ///
  /// **Exemple 1 - Enfants d'une catégorie :**
  /// ```dart
  /// final subcats = await repo.getSubcategoriesByParent('femme');
  /// // Retourne : [Haut, Bas, Chaussures, Accessoires]
  /// ```
  ///
  /// **Exemple 2 - Enfants d'une sous-catégorie :**
  /// ```dart
  /// final items = await repo.getSubcategoriesByParent('haut_femme');
  /// // Retourne : [Chemise, T-shirt, Pull, Veste]
  /// ```
  ///
  /// **Filtres appliqués :**
  /// - `parentId == parentId` : Filtre par parent
  /// - `isActive == true` : Seules les sous-catégories actives
  /// - Triées par `order` (croissant)
  ///
  /// **Paramètres :**
  /// - [parentId] : ID de la catégorie ou sous-catégorie parente
  ///
  /// **Throws :**
  /// - [Exception] si une erreur Firestore se produit
  @override
  Future<List<Subcategory>> getSubcategoriesByParent(String parentId) async {
    try {
      final snapshot = await _firestore
          .collection('config')
          .doc('subcategories')
          .collection('items')
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => SubcategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des sous-catégories',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<List<Subcategory>> getSubcategoriesByParentStream(String parentId) {
    return _firestore
        .collection('config')
        .doc('subcategories')
        .collection('items')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubcategoryModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ============================================================
  // ATTRIBUTS
  // ============================================================

  @override
  Future<List<ProductAttribute>> getAttributes() async {
    try {
      final snapshot = await _firestore
          .collection('config')
          .doc('attributes')
          .collection('items')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => ProductAttributeModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des attributs',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<ProductAttribute> getAttributeById(String id) async {
    try {
      final doc = await _firestore
          .collection('config')
          .doc('attributes')
          .collection('items')
          .doc(id)
          .get();

      if (!doc.exists) {
        throw CategoryNotFoundException(categoryId: id);
      }

      return ProductAttributeModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement de l\'attribut',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  /// Récupère plusieurs attributs par leurs IDs.
  ///
  /// Cette méthode est utilisée pour charger les attributs d'une catégorie finale.
  /// Elle gère automatiquement le batching car Firestore limite les requêtes `whereIn`
  /// à 10 éléments maximum.
  ///
  /// **Exemple d'utilisation :**
  /// ```dart
  /// // Une sous-catégorie "Chemise" a ces attributs
  /// final subcategory = Subcategory(
  ///   id: 'chemise_femme',
  ///   attributes: ['brand', 'size_haut', 'color', 'material'],
  /// );
  ///
  /// // Charger les définitions complètes des attributs
  /// final attrs = await repo.getAttributesByIds(subcategory.attributes);
  /// // Retourne : [
  /// //   ProductAttribute(id: 'brand', name: 'Marque', values: ['Nike', 'Zara', ...]),
  /// //   ProductAttribute(id: 'size_haut', name: 'Taille', values: ['XS', 'S', 'M', ...]),
  /// //   ...
  /// // ]
  /// ```
  ///
  /// **Gestion du batching :**
  /// Si plus de 10 IDs sont fournis, la méthode fait plusieurs requêtes
  /// automatiquement par lots de 10.
  ///
  /// **Paramètres :**
  /// - [attributeIds] : Liste des IDs d'attributs à récupérer
  ///
  /// **Retourne :**
  /// - Liste vide si `attributeIds` est vide
  /// - Liste des attributs trouvés (dans l'ordre de Firestore, pas l'ordre des IDs)
  ///
  /// **Throws :**
  /// - [Exception] si une erreur Firestore se produit
  @override
  Future<List<ProductAttribute>> getAttributesByIds(
    List<String> attributeIds,
  ) async {
    if (attributeIds.isEmpty) return [];

    try {
      // Firestore limite les requêtes 'in' à 10 éléments
      // On fait plusieurs requêtes si nécessaire (batching)
      final List<ProductAttribute> attributes = [];

      // Traiter par lots de 10
      for (int i = 0; i < attributeIds.length; i += 10) {
        final batch = attributeIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection('config')
            .doc('attributes')
            .collection('items')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        attributes.addAll(
          snapshot.docs.map(
            (doc) => ProductAttributeModel.fromMap(doc.data(), doc.id),
          ),
        );
      }

      return attributes;
    } on FirebaseException catch (e, stackTrace) {
      throw handleFirebaseException(e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      throw UnknownException(
        message: 'Erreur lors du chargement des attributs',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<List<ProductAttribute>> getAttributesStream() {
    return _firestore
        .collection('config')
        .doc('attributes')
        .collection('items')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductAttributeModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
