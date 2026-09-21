import 'product_status.dart';

/// État/condition du produit
enum ProductCondition {
  newWithTags('Neuf avec étiquette'),
  excellent('Excellent état'),
  good('Bon état'),
  satisfactory('Satisfaisant'),
  worn('Usé'),
  // Ajoutés en fin de liste, et non insérés à leur place « logique » : des
  // annonces d'avant stockent encore l'état sous forme d'indice, que tout
  // déplacement décalerait.
  newWithoutTags('Neuf sans étiquette'),
  forParts('Pour pièces');

  final String label;
  const ProductCondition(this.label);

  /// Retrouve l'état à partir de son libellé tel qu'il est enregistré.
  ///
  /// C'est le chemin normal depuis que les attributs sont stockés en clair :
  /// `'Bon état'` plutôt que `2`. Les libellés doivent rester identiques à ceux
  /// de `tools/seed_data/attributes.json`, seule source des valeurs proposées.
  static ProductCondition? parLibelle(String libelle) {
    for (final etat in ProductCondition.values) {
      if (etat.label == libelle) return etat;
    }
    return null;
  }
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

  /// Où en est l'annonce dans son cycle de vie.
  ///
  /// Un seul champ là où trois booléens coexistaient : `isSold`,
  /// `isReserved` et `isHidden` permettaient huit combinaisons, dont « vendu
  /// et réservé » et « masqué et vendu », que rien n'empêchait d'écrire.
  final ProductStatus status;

  /// Ce que la modération a décidé.
  ///
  /// Orthogonal à [status] : une annonce peut être vendue **et** approuvée.
  final ModerationStatus moderationStatus;

  /// Le degré de la décision de modération : `correction` ou `violation`.
  ///
  /// Nul tant que personne n'a tranché. C'est ce champ qui décide si le
  /// vendeur peut encore agir : une photo floue se corrige, une contrefaçon
  /// se retire. Les règles Firestore appliquent exactement cette distinction.
  final String? reviewDecision;

  /// Le motif retenu, en clair côté serveur : `blurry_photos`,
  /// `wrong_category`, `counterfeit`… Traduit à l'affichage.
  final String? reviewReason;

  /// Le mot du modérateur, écrit pour le vendeur.
  final String? reviewNote;

  /// Date de vente (si vendue)
  final DateTime? soldAt;

  // ── Compatibilité ───────────────────────────────────────────────────────
  // Les trois booléens survivent en accesseurs le temps que les appels du
  // code soient repris un à un. Ils se déduisent de [status] : impossible
  // qu'ils divergent.

  /// Vendu — définitif.
  bool get isSold => status == ProductStatus.sold;

  /// Réservé : temporairement indisponible, le vendeur discutant avec un
  /// acheteur potentiel, sans être vendu pour autant.
  bool get isReserved => status == ProductStatus.reserved;

  /// Retiré des listes publiques à la demande du vendeur, ou archivé.
  bool get isHidden =>
      status == ProductStatus.hidden || status == ProductStatus.archived;

  /// Visible dans les listes de vente.
  ///
  /// Reflète le champ `isListable` que le serveur calcule et que toutes les
  /// requêtes interrogent. Recalculé ici pour l'affichage local — la suspension
  /// du vendeur n'y entre pas, elle ne concerne pas l'écran d'un acheteur qui
  /// regarde déjà la fiche.
  bool get isListable =>
      status == ProductStatus.active &&
      moderationStatus != ModerationStatus.rejected;

  /// L'annonce attend une retouche du vendeur.
  ///
  /// C'est le seul cas où un rejet laisse la main : le vendeur corrige, et le
  /// serveur la remet en file tout seul.
  bool get attendCorrection =>
      moderationStatus == ModerationStatus.rejected &&
      reviewDecision == 'correction';

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
    this.status = ProductStatus.active,
    this.moderationStatus = ModerationStatus.pending,
    this.reviewDecision,
    this.reviewReason,
    this.reviewNote,
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
    ProductStatus? status,
    ModerationStatus? moderationStatus,
    String? reviewDecision,
    String? reviewReason,
    String? reviewNote,
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
      status: status ?? this.status,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      reviewDecision: reviewDecision ?? this.reviewDecision,
      reviewReason: reviewReason ?? this.reviewReason,
      reviewNote: reviewNote ?? this.reviewNote,
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
