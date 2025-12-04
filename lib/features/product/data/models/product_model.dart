import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

/// Modèle Firestore pour Product.
///
/// Gère la conversion entre l'entité Product et les documents Firestore.
class ProductModel {
  /// Convertit un document Firestore en entité Product
  static Product fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Product(
      id: snapshot.id,
      title: data['title'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      condition: _parseCondition(data['condition'] as String),
      sellerId: data['sellerId'] as String,
      categoryId: data['categoryId'] as String,
      subcategoryId: data['subcategoryId'] as String,
      attributes: Map<String, dynamic>.from(data['attributes'] ?? {}),
      isBoosted: data['isBoosted'] as bool? ?? false,
      boostExpiresAt: data['boostExpiresAt'] != null
          ? (data['boostExpiresAt'] as Timestamp).toDate()
          : null,
      isSold: data['isSold'] as bool? ?? false,
      soldAt: data['soldAt'] != null
          ? (data['soldAt'] as Timestamp).toDate()
          : null,
      viewsCount: data['viewsCount'] as int? ?? 0,
      favoritesCount: data['favoritesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convertit une entité Product en Map pour Firestore
  static Map<String, dynamic> toFirestore(Product product) {
    return {
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'imageUrls': product.imageUrls,
      'condition': _conditionToString(product.condition),
      'sellerId': product.sellerId,
      'categoryId': product.categoryId,
      'subcategoryId': product.subcategoryId,
      'attributes': product.attributes,
      'isBoosted': product.isBoosted,
      'boostExpiresAt': product.boostExpiresAt != null
          ? Timestamp.fromDate(product.boostExpiresAt!)
          : null,
      'isSold': product.isSold,
      'soldAt':
          product.soldAt != null ? Timestamp.fromDate(product.soldAt!) : null,
      'viewsCount': product.viewsCount,
      'favoritesCount': product.favoritesCount,
      'createdAt': Timestamp.fromDate(product.createdAt),
      'updatedAt': Timestamp.fromDate(product.updatedAt),
    };
  }

  /// Crée une entité Product depuis une Map
  static Product fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      title: data['title'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      condition: _parseCondition(data['condition'] as String),
      sellerId: data['sellerId'] as String,
      categoryId: data['categoryId'] as String,
      subcategoryId: data['subcategoryId'] as String,
      attributes: Map<String, dynamic>.from(data['attributes'] ?? {}),
      isBoosted: data['isBoosted'] as bool? ?? false,
      boostExpiresAt: data['boostExpiresAt'] != null
          ? (data['boostExpiresAt'] as Timestamp).toDate()
          : null,
      isSold: data['isSold'] as bool? ?? false,
      soldAt: data['soldAt'] != null
          ? (data['soldAt'] as Timestamp).toDate()
          : null,
      viewsCount: data['viewsCount'] as int? ?? 0,
      favoritesCount: data['favoritesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Parse la condition depuis une string
  static ProductCondition _parseCondition(String condition) {
    switch (condition) {
      case 'newWithTags':
        return ProductCondition.newWithTags;
      case 'excellent':
        return ProductCondition.excellent;
      case 'good':
        return ProductCondition.good;
      case 'satisfactory':
        return ProductCondition.satisfactory;
      case 'worn':
        return ProductCondition.worn;
      default:
        return ProductCondition.good;
    }
  }

  /// Convertit la condition en string
  static String _conditionToString(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.newWithTags:
        return 'newWithTags';
      case ProductCondition.excellent:
        return 'excellent';
      case ProductCondition.good:
        return 'good';
      case ProductCondition.satisfactory:
        return 'satisfactory';
      case ProductCondition.worn:
        return 'worn';
    }
  }
}
