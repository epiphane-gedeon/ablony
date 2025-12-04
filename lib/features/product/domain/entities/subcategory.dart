/// Entité représentant une sous-catégorie (tous niveaux).
///
/// Une sous-catégorie peut être :
/// - **Branche** : a des enfants (children non vide)
/// - **Feuille** : n'a pas d'enfants (children vide) et définit des attributs produit
///
/// Exemples :
/// - Haut (branche) → children: [chemise, tshirt, pull]
/// - Chemise (feuille) → attributes: [brand, size_haut, color, material]
class Subcategory {
  /// Identifiant unique de la sous-catégorie
  final String id;

  /// Nom affiché de la sous-catégorie
  final String name;

  /// ID de la catégorie ou sous-catégorie parente
  final String parentId;

  /// Liste des IDs des sous-catégories enfants (vide si feuille)
  final List<String> children;

  /// Liste des IDs des attributs applicables aux produits (uniquement pour les feuilles)
  /// 
  /// Exemples : ['brand', 'size_haut', 'color', 'material', 'dressLength']
  final List<String> attributes;

  /// Ordre d'affichage (optionnel)
  final int? order;

  /// URL de l'icône/image (optionnel)
  final String? iconUrl;

  /// Indique si la sous-catégorie est active
  final bool isActive;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime updatedAt;

  const Subcategory({
    required this.id,
    required this.name,
    required this.parentId,
    this.children = const [],
    this.attributes = const [],
    this.order,
    this.iconUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Indique si cette sous-catégorie est une feuille (catégorie finale)
  bool get isLeaf => children.isEmpty;

  /// Indique si cette sous-catégorie est une branche (a des enfants)
  bool get isBranch => children.isNotEmpty;

  /// Crée une copie avec certains champs modifiés
  Subcategory copyWith({
    String? id,
    String? name,
    String? parentId,
    List<String>? children,
    List<String>? attributes,
    int? order,
    String? iconUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subcategory(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      attributes: attributes ?? this.attributes,
      order: order ?? this.order,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Subcategory(id: $id, name: $name, parent: $parentId, isLeaf: $isLeaf, attributes: ${attributes.length})';
}
