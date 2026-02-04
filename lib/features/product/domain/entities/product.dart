/// État/condition du produit
enum ProductCondition {
  newWithTags('Neuf avec étiquette'),
  excellent('Excellent état'),
  good('Bon état'),
  satisfactory('Satisfaisant'),
  worn('Usé');

  final String label;
  const ProductCondition(this.label);
}

/// Entité représentant un produit mis en vente.
///
/// Un produit appartient à une catégorie finale (feuille) et possède
/// des attributs dynamiques en fonction de cette catégorie.
class Product {
  /// Identifiant unique du produit
  final String id;

  /// Titre du produit
  final String title;

  /// Description détaillée
  final String description;

  /// Prix en FCFA
  final double price;

  /// URLs des images (1 à 6 photos)
  final List<String> imageUrls;

  /// État/condition du produit
  final ProductCondition condition;

  /// ID de l'utilisateur vendeur
  final String sellerId;

  /// ID de la catégorie de niveau 1
  final String categoryId;

  /// ID de la sous-catégorie finale (feuille)
  final String subcategoryId;

  /// Attributs dynamiques du produit
  /// 
  /// Map où :
  /// - key = ID de l'attribut (ex: 'brand', 'size_haut', 'color')
  /// - value = valeur sélectionnée (ex: 'Nike', 'M', 'Bleu')
  /// 
  /// Exemple :
  /// ```dart
  /// {
  ///   'brand': 'Nike',
  ///   'size_haut': 'M',
  ///   'color': 'Bleu',
  ///   'material': 'Coton'
  /// }
  /// ```
  final Map<String, dynamic> attributes;

  /// Indique si le produit est boosté (mis en avant)
  final bool isBoosted;

  /// Date d'expiration du boost (si boosté)
  final DateTime? boostExpiresAt;

  /// Indique si le produit est vendu
  final bool isSold;

  /// Date de vente (si vendu)
  final DateTime? soldAt;

  /// Nombre de vues
  final int viewsCount;

  /// Nombre de favoris
  final int favoritesCount;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.condition,
    required this.sellerId,
    required this.categoryId,
    required this.subcategoryId,
    this.attributes = const {},
    this.isBoosted = false,
    this.boostExpiresAt,
    this.isSold = false,
    this.soldAt,
    this.viewsCount = 0,
    this.favoritesCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée une copie avec certains champs modifiés
  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    List<String>? imageUrls,
    ProductCondition? condition,
    String? sellerId,
    String? categoryId,
    String? subcategoryId,
    Map<String, dynamic>? attributes,
    bool? isBoosted,
    DateTime? boostExpiresAt,
    bool? isSold,
    DateTime? soldAt,
    int? viewsCount,
    int? favoritesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      condition: condition ?? this.condition,
      sellerId: sellerId ?? this.sellerId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      attributes: attributes ?? this.attributes,
      isBoosted: isBoosted ?? this.isBoosted,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      isSold: isSold ?? this.isSold,
      soldAt: soldAt ?? this.soldAt,
      viewsCount: viewsCount ?? this.viewsCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Récupère l'ID de l'attribut de taille principal détecté
  String? get primarySizeAttributeId {
    // Ordre de priorité pour les clés exactes
    const priorityKeys = ['size', 'taille', 'size_haut', 'size_bas', 'pointure'];
    for (final key in priorityKeys) {
      if (attributes.containsKey(key)) return key;
    }

    // Recherche par mot-clé si aucune clé prioritaire n'est trouvée
    for (final key in attributes.keys) {
      final k = key.toLowerCase();
      if (k.contains('size') || k.contains('taille') || k.contains('pointure')) {
        return key;
      }
    }
    return null;
  }

  /// Récupère la valeur de l'attribut de taille principal
  dynamic get primarySizeValue {
    final id = primarySizeAttributeId;
    return id != null ? attributes[id] : null;
  }

  /// Récupère l'ID de l'attribut de marque principal détecté
  String? get primaryBrandAttributeId {
    const priorityKeys = ['brand', 'marque'];
    for (final key in priorityKeys) {
      if (attributes.containsKey(key)) return key;
    }

    for (final key in attributes.keys) {
      final k = key.toLowerCase();
      if (k.contains('brand') || k.contains('marque')) {
        return key;
      }
    }
    return null;
  }

  /// Récupère la valeur de l'attribut de marque principal
  dynamic get primaryBrandValue {
    final id = primaryBrandAttributeId;
    return id != null ? attributes[id] : null;
  }

  /// Récupère l'ID de l'attribut de couleur principal détecté
  String? get primaryColorAttributeId {
    const priorityKeys = ['color', 'couleur'];
    for (final key in priorityKeys) {
      if (attributes.containsKey(key)) return key;
    }

    for (final key in attributes.keys) {
      final k = key.toLowerCase();
      if (k.contains('color') || k.contains('couleur')) {
        return key;
      }
    }
    return null;
  }

  /// Récupère la valeur de l'attribut de couleur principal
  dynamic get primaryColorValue {
    final id = primaryColorAttributeId;
    return id != null ? attributes[id] : null;
  }

  /// Récupère l'ID de l'attribut de matière principal détecté
  String? get primaryMaterialAttributeId {
    const priorityKeys = ['material', 'matiere', 'matière'];
    for (final key in priorityKeys) {
      if (attributes.containsKey(key)) return key;
    }

    for (final key in attributes.keys) {
      final k = key.toLowerCase();
      if (k.contains('material') || k.contains('matiere') || k.contains('matière')) {
        return key;
      }
    }
    return null;
  }

  /// Récupère la valeur de l'attribut de matière principal
  dynamic get primaryMaterialValue {
    final id = primaryMaterialAttributeId;
    return id != null ? attributes[id] : null;
  }

  @override
  String toString() =>
      'Product(id: $id, title: $title, price: $price FCFA, seller: $sellerId)';
}
