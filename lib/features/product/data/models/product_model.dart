import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_status.dart';

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
      condition: _parseCondition(data['condition']),
      sellerId: data['sellerId'] as String,
      categoryId: data['categoryId'] as String,
      subcategoryId: data['subcategoryId'] as String,
      attributes: Map<String, dynamic>.from(data['attributes'] ?? {}),
      isBoosted: data['isBoosted'] as bool? ?? false,
      boostExpiresAt: data['boostExpiresAt'] != null
          ? (data['boostExpiresAt'] as Timestamp).toDate()
          : null,
      status: _lireStatut(data),
      moderationStatus: ModerationStatus.fromWire(
        data['moderationStatus'] as String?,
      ),
      reviewDecision: data['reviewDecision'] as String?,
      reviewReason: data['reviewReason'] as String?,
      reviewNote: data['reviewNote'] as String?,
      soldAt: data['soldAt'] != null
          ? (data['soldAt'] as Timestamp).toDate()
          : null,
      viewsCount: data['viewsCount'] as int? ?? 0,
      favoritesCount: data['favoritesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Lit le cycle de vie, quelle que soit la forme du document.
  ///
  /// Les deux formes coexistent le temps que la reprise passe et que la
  /// nouvelle version soit adoptée : `status` s'il est là, les trois
  /// booléens sinon. Sans ce repli, une annonce non encore reprise
  /// apparaîtrait masquée.
  static ProductStatus _lireStatut(Map<String, dynamic> data) {
    final brut = data['status'] as String?;
    if (brut != null) return ProductStatus.fromWire(brut);
    return ProductStatus.fromLegacy(
      isSold: data['isSold'] as bool? ?? false,
      isReserved: data['isReserved'] as bool? ?? false,
      isHidden: data['isHidden'] as bool? ?? false,
    );
  }

  /// Convertit une entité Product en Map pour Firestore
  static Map<String, dynamic> toFirestore(Product product) {
    return {
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'imageUrls': product.imageUrls,
      'condition': product.condition.index, // Sauvegarder l'index numérique
      'sellerId': product.sellerId,
      'categoryId': product.categoryId,
      'subcategoryId': product.subcategoryId,
      'attributes': product.attributes,
      'isBoosted': product.isBoosted,
      'boostExpiresAt': product.boostExpiresAt != null
          ? Timestamp.fromDate(product.boostExpiresAt!)
          : null,
      'status': product.status.wireValue,
      'soldAt':
          product.soldAt != null ? Timestamp.fromDate(product.soldAt!) : null,
      // Les trois booléens restent écrits le temps que la nouvelle version
      // soit adoptée : une version ancienne encore installée continue de
      // fonctionner. À retirer deux à quatre semaines après la publication.
      'isSold': product.isSold,
      'isReserved': product.isReserved,
      'isHidden': product.isHidden,
      // `moderationStatus`, `isListable` et les champs `review*` ne sont
      // **pas** écrits ici : ils appartiennent au serveur. Les écrire depuis
      // le client effacerait `reviewDecision` au moment même où le vendeur
      // corrige — et le déclencheur, ne voyant plus la décision, ne remettrait
      // jamais l'annonce en file.
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
      condition: _parseCondition(data['condition']),
      sellerId: data['sellerId'] as String,
      categoryId: data['categoryId'] as String,
      subcategoryId: data['subcategoryId'] as String,
      attributes: Map<String, dynamic>.from(data['attributes'] ?? {}),
      isBoosted: data['isBoosted'] as bool? ?? false,
      boostExpiresAt: data['boostExpiresAt'] != null
          ? (data['boostExpiresAt'] as Timestamp).toDate()
          : null,
      status: _lireStatut(data),
      moderationStatus: ModerationStatus.fromWire(
        data['moderationStatus'] as String?,
      ),
      reviewDecision: data['reviewDecision'] as String?,
      reviewReason: data['reviewReason'] as String?,
      reviewNote: data['reviewNote'] as String?,
      soldAt: data['soldAt'] != null
          ? (data['soldAt'] as Timestamp).toDate()
          : null,
      viewsCount: data['viewsCount'] as int? ?? 0,
      favoritesCount: data['favoritesCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Parse la condition depuis Firestore (supporte int, numeric string ou legacy string)
  static ProductCondition _parseCondition(dynamic condition) {
    if (condition is int) {
      if (condition >= 0 && condition < ProductCondition.values.length) {
        return ProductCondition.values[condition];
      }
      return ProductCondition.good;
    }

    if (condition is String) {
      // Support des strings numériques
      final intValue = int.tryParse(condition);
      if (intValue != null) {
        if (intValue >= 0 && intValue < ProductCondition.values.length) {
          return ProductCondition.values[intValue];
        }
      }

      // Support des anciens IDs textuels
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
      }
    }

    return ProductCondition.good;
  }


}
